import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_photo.dart';
import '../utils/error_handler.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

/// Repository pour gestion des photos utilisateur
class PhotoRepository {
  static PhotoRepository? _instance;
  static PhotoRepository get instance => _instance ??= PhotoRepository._();
  
  PhotoRepository._();
  
  final _supabase = SupabaseService.instance;
  final _storageService = StorageService.instance;
  final _uuid = const Uuid();
  
  // Cache URLs signées
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlCacheExpiry = {};
  
  /// Récupérer toutes les photos d'un utilisateur
  Future<List<UserPhoto>> fetchPhotos(String userId) async {
    try {
      final response = await _supabase.from('profile_photos')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final List<UserPhoto> photos = [];
      
      for (final photoData in response) {
        final photo = UserPhoto.fromJson(photoData);
        
        // Générer URL signée si approuvée ou pour le propriétaire
        String? signedUrl;
        if (photo.moderationStatus == ModerationStatus.approved || 
            userId == _supabase.currentUserId) {
          signedUrl = await _getSignedUrl(photo.storagePath);
        }
        
        photos.add(photo.copyWith(signedUrl: signedUrl));
      }
      
      return photos;
    } catch (e) {
      ErrorHandler.logError(
        context: 'PhotoRepository.fetchPhotos',
        error: e,
        additionalData: {'user_id': userId},
      );
      
      throw Exception(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Upload nouvelle photo
  Future<PhotoUploadResult> uploadPhoto({
    required File imageFile,
    bool isMain = false,
  }) async {
    try {
      final userId = _supabase.currentUserId!;
      
      // Validation
      final fileSize = await imageFile.length();
      final validation = PhotoGalleryConfig.validateImageFile(
        imageFile.path,
        fileSize,
      );
      
      if (validation != null) {
        return PhotoUploadResult.error(validation);
      }
      
      // Vérifier limite photos
      final existingPhotos = await fetchPhotos(userId);
      if (!PhotoGalleryConfig.canAddMorePhotos(existingPhotos.length)) {
        return PhotoUploadResult.error(PhotoGalleryConfig.maxPhotosMessage);
      }
      
      // Préparer fichier
      final preparedBytes = await _storageService.prepareImageForUpload(imageFile);
      if (preparedBytes == null) {
        return PhotoUploadResult.error('Erreur de préparation de l\'image');
      }
      
      // ✅ Corrigé : Le chemin doit être userId/filename (sans préfixe profile_photos/)
      // La RLS vérifie que le premier élément du chemin = auth.uid()
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$fileName';
      
      // Upload vers Storage
      await _supabase.storage
          .from('profile_photos')
          .uploadBinary(
            storagePath,
            preparedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              metadata: {
                'user_id': userId,
                'is_main': isMain.toString(),
                'original_name': imageFile.path.split('/').last,
              },
            ),
          );
      
      // Si première photo ou isMain demandé, désactiver autres mains
      if (isMain || existingPhotos.isEmpty) {
        await _setAllPhotosNotMain(userId);
      }
      
      // Insérer en DB
      // ✅ Corrigé : Ajouter file_size_bytes pour éviter l'erreur NOT NULL
      final photoData = await _supabase.from('profile_photos').insert({
        'user_id': userId,
        'storage_path': storagePath,
        'file_size_bytes': preparedBytes.length, // ✅ Taille du fichier en bytes
        'is_main': isMain || existingPhotos.isEmpty,
        'moderation_status': 'pending',
      }).select().single();
      
      final photo = UserPhoto.fromJson(photoData);
      
      // Générer URL signée pour preview
      final signedUrl = await _getSignedUrl(storagePath);
      
      return PhotoUploadResult.success(
        photo.copyWith(signedUrl: signedUrl),
      );
    } catch (e) {
      ErrorHandler.logError(
        context: 'PhotoRepository.uploadPhoto',
        error: e,
        additionalData: {
          'is_main': isMain,
          'file_path': imageFile.path,
        },
      );
      
      return PhotoUploadResult.error(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Définir photo comme principale
  Future<bool> setMainPhoto(String photoId) async {
    try {
      final userId = _supabase.currentUserId!;
      
      // Vérifier que la photo peut être main (approuvée)
      final photoResponse = await _supabase.from('profile_photos')
          .select()
          .eq('id', photoId)
          .eq('user_id', userId)
          .single();
      
      final photo = UserPhoto.fromJson(photoResponse);
      
      if (!photo.canBeMain) {
        throw Exception('Seules les photos approuvées peuvent être principales');
      }
      
      // Transaction : désactiver toutes, activer celle-ci
      await _setAllPhotosNotMain(userId);
      
      await _supabase.from('profile_photos')
          .update({'is_main': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', photoId);
      
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'PhotoRepository.setMainPhoto',
        error: e,
        additionalData: {'photo_id': photoId},
      );
      
      return false;
    }
  }
  
  /// Supprimer photo
  Future<bool> deletePhoto(String photoId) async {
    try {
      final userId = _supabase.currentUserId!;
      
      // Récupérer info photo
      final photoResponse = await _supabase.from('profile_photos')
          .select()
          .eq('id', photoId)
          .eq('user_id', userId)
          .single();
      
      final photo = UserPhoto.fromJson(photoResponse);
      
      // Vérifier si peut être supprimée
      final allPhotos = await fetchPhotos(userId);
      if (!photo.canBeDeleted(allPhotos)) {
        throw Exception('Impossible de supprimer la seule photo principale');
      }
      
      // Supprimer du storage
      await _supabase.storage
          .from('profile_photos')
          .remove([photo.storagePath]);
      
      // Supprimer de la DB
      await _supabase.from('profile_photos')
          .delete()
          .eq('id', photoId);
      
      // Clear cache URL
      _urlCache.remove(photo.storagePath);
      _urlCacheExpiry.remove(photo.storagePath);
      
      // Si c'était la photo principale, promouvoir une autre
      if (photo.isMain) {
        await _promoteNextMainPhoto(userId);
      }
      
      return true;
    } catch (e) {
      ErrorHandler.logError(
        context: 'PhotoRepository.deletePhoto',
        error: e,
        additionalData: {'photo_id': photoId},
      );
      
      return false;
    }
  }
  
  /// Remplacer photo rejetée
  Future<PhotoUploadResult> replaceRejectedPhoto({
    required String photoId,
    required File newImageFile,
  }) async {
    try {
      final userId = _supabase.currentUserId!;
      
      // Vérifier que la photo est bien rejetée
      final photoResponse = await _supabase.from('profile_photos')
          .select()
          .eq('id', photoId)
          .eq('user_id', userId)
          .single();
      
      final oldPhoto = UserPhoto.fromJson(photoResponse);
      
      if (oldPhoto.moderationStatus != ModerationStatus.rejected) {
        return PhotoUploadResult.error('Seules les photos rejetées peuvent être remplacées');
      }
      
      // Supprimer ancienne photo
      await deletePhoto(photoId);
      
      // Upload nouvelle photo
      return await uploadPhoto(
        imageFile: newImageFile,
        isMain: oldPhoto.isMain,
      );
    } catch (e) {
      return PhotoUploadResult.error(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Obtenir URL signée avec cache
  Future<String?> _getSignedUrl(String storagePath) async {
    try {
      // Vérifier cache
      final cached = _urlCache[storagePath];
      final expiry = _urlCacheExpiry[storagePath];
      
      if (cached != null && expiry != null && DateTime.now().isBefore(expiry)) {
        return cached;
      }
      
      // Générer nouvelle URL
      final url = await _supabase.storage
          .from('profile_photos')
          .createSignedUrl(
            storagePath,
            PhotoGalleryConfig.signedUrlExpiryMinutes * 60,
          );
      
      // Mettre en cache
      _urlCache[storagePath] = url;
      _urlCacheExpiry[storagePath] = DateTime.now().add(
        const Duration(minutes: PhotoGalleryConfig.signedUrlExpiryMinutes - 5),
      );
      
      return url;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }
  
  /// Désactiver toutes photos comme main
  Future<void> _setAllPhotosNotMain(String userId) async {
    await _supabase.from('profile_photos')
        .update({'is_main': false})
        .eq('user_id', userId);
  }
  
  /// Promouvoir prochaine photo approuvée comme main
  Future<void> _promoteNextMainPhoto(String userId) async {
    try {
      final response = await _supabase.from('profile_photos')
          .select()
          .eq('user_id', userId)
          .eq('moderation_status', 'approved')
          .order('created_at', ascending: true)
          .limit(1);
      
      if (response.isNotEmpty) {
        final nextPhotoId = response.first['id'];
        await _supabase.from('profile_photos')
            .update({'is_main': true})
            .eq('id', nextPhotoId);
      }
    } catch (e) {
      debugPrint('Error promoting next main photo: $e');
    }
  }
  
  /// Récupérer photo principale approuvée
  Future<UserPhoto?> getMainPhoto(String userId) async {
    try {
      final response = await _supabase.from('profile_photos')
          .select()
          .eq('user_id', userId)
          .eq('is_main', true)
          .eq('moderation_status', 'approved')
          .single();
      
      final photo = UserPhoto.fromJson(response);
      final signedUrl = await _getSignedUrl(photo.storagePath);
      
      return photo.copyWith(signedUrl: signedUrl);
    } catch (e) {
      // Pas de photo principale approuvée
      return null;
    }
  }
  
  /// Récupérer toutes photos approuvées pour profil public
  Future<List<UserPhoto>> getApprovedPhotos(String userId) async {
    try {
      final response = await _supabase.from('profile_photos')
          .select()
          .eq('user_id', userId)
          .eq('moderation_status', 'approved')
          .order('is_main', ascending: false)
          .order('created_at', ascending: false);
      
      final List<UserPhoto> photos = [];
      
      for (final photoData in response) {
        final photo = UserPhoto.fromJson(photoData);
        final signedUrl = await _getSignedUrl(photo.storagePath);
        photos.add(photo.copyWith(signedUrl: signedUrl));
      }
      
      return photos;
    } catch (e) {
      debugPrint('Error fetching approved photos: $e');
      return [];
    }
  }
  
  /// Clear cache URLs (logout, refresh)
  void clearUrlCache() {
    _urlCache.clear();
    _urlCacheExpiry.clear();
  }
  
  /// Refresh URL signée spécifique
  Future<String?> refreshSignedUrl(String storagePath) async {
    _urlCache.remove(storagePath);
    _urlCacheExpiry.remove(storagePath);
    return await _getSignedUrl(storagePath);
  }
  
  /// Obtenir statistiques photos utilisateur
  Future<Map<String, int>> getPhotoStats(String userId) async {
    try {
      final response = await _supabase.from('profile_photos')
          .select('moderation_status')
          .eq('user_id', userId);
      
      final stats = <String, int>{
        'total': response.length,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };
      
      for (final photo in response) {
        final status = photo['moderation_status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error getting photo stats: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }
}
