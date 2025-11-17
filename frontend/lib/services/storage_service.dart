import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service pour gestion du stockage (photos, fichiers)
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  final _supabase = SupabaseService.instance;
  final _uuid = const Uuid();
  
  /// Préparer une image pour upload (compression, resize)
  Future<Uint8List?> prepareImageForUpload(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Vérifier taille (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Image trop lourde (max 5MB)');
      }
      
      // TODO S5: Compression/resize si nécessaire
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error preparing image: $e');
      return null;
    }
  }
  
  /// Upload image vers bucket profile_photos
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
    bool isMain = false,
  }) async {
    try {
      final preparedBytes = await prepareImageForUpload(imageFile);
      if (preparedBytes == null) return null;
      
      final fileName = '${userId}_${isMain ? 'main' : _uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profile_photos/$userId/$fileName';
      
      await _supabase.storage
          .from('profile_photos')
          .uploadBinary(
            path,
            preparedBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );
      
      debugPrint('✅ Photo uploaded: $path');
      return path;
    } catch (e) {
      debugPrint('❌ Photo upload failed: $e');
      return null;
    }
  }
  
  /// Obtenir URL signée pour une photo
  Future<String?> getSignedPhotoUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    try {
      final url = await _supabase.storage
          .from('profile_photos')
          .createSignedUrl(storagePath, expiresInSeconds);
      
      return url;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }
  
  /// Obtenir URL publique pour photo approuvée
  String getPublicPhotoUrl(String storagePath) {
    return _supabase.storage
        .from('profile_photos')
        .getPublicUrl(storagePath);
  }
  
  /// Supprimer une photo
  Future<bool> deletePhoto(String storagePath) async {
    try {
      await _supabase.storage
          .from('profile_photos')
          .remove([storagePath]);
      
      debugPrint('✅ Photo deleted: $storagePath');
      return true;
    } catch (e) {
      debugPrint('❌ Photo deletion failed: $e');
      return false;
    }
  }
  
  /// Lister photos d'un utilisateur
  Future<List<dynamic>> getUserPhotos(String userId) async {
    try {
      final files = await _supabase.storage
          .from('profile_photos')
          .list(path: 'profile_photos/$userId');
      
      return files;
    } catch (e) {
      debugPrint('Error listing user photos: $e');
      return [];
    }
  }
  
  /// Picker image depuis galerie ou caméra
  Future<File?> pickImage({
    required ImageSource source,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  /// Valider format et taille d'image
  bool validateImageFile(File imageFile) {
    try {
      final extension = imageFile.path.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Format non supporté (JPG, PNG, WebP uniquement)');
      }
      
      return true;
    } catch (e) {
      debugPrint('Image validation failed: $e');
      return false;
    }
  }
  
  /// Upload avec retry automatique
  Future<String?> uploadWithRetry({
    required String userId,
    required File imageFile,
    bool isMain = false,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
        isMain: isMain,
      );
      
      if (result != null) return result;
      
      if (attempt < maxRetries) {
        debugPrint('Upload attempt $attempt failed, retrying...');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }
}
