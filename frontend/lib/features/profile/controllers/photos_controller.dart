import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../../models/user_photo.dart';
import '../../../services/photo_repository.dart';
import '../../../services/storage_service.dart';
import '../../../utils/error_handler.dart';
import '../../auth/controllers/auth_controller.dart' show currentUserProvider;

/// État des photos utilisateur
@immutable
class PhotosState {
  const PhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.stats = const {},
  });
  
  final List<UserPhoto> photos;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final Map<String, int> stats;
  
  bool get hasError => error != null;
  bool get hasPhotos => photos.isNotEmpty;
  bool get canAddMorePhotos => PhotoGalleryConfig.canAddMorePhotos(photos.length);
  
  UserPhoto? get mainPhoto => photos.where((p) => p.isMain).firstOrNull;
  List<UserPhoto> get approvedPhotos => photos.where((p) => p.isPubliclyVisible).toList();
  List<UserPhoto> get pendingPhotos => photos.where((p) => p.isPending).toList();
  List<UserPhoto> get rejectedPhotos => photos.where((p) => p.isRejected).toList();
  
  int get totalPhotos => stats['total'] ?? photos.length;
  int get approvedCount => stats['approved'] ?? approvedPhotos.length;
  int get pendingCount => stats['pending'] ?? pendingPhotos.length;
  int get rejectedCount => stats['rejected'] ?? rejectedPhotos.length;
  
  PhotosState copyWith({
    List<UserPhoto>? photos,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    Map<String, int>? stats,
  }) {
    return PhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

/// Controller pour gestion des photos
class PhotosController extends StateNotifier<PhotosState> {
  PhotosController(this.userId) : super(const PhotosState()) {
    _init();
  }
  
  final String userId;
  final _photoRepository = PhotoRepository.instance;
  final _storageService = StorageService.instance;
  
  /// Initialisation
  Future<void> _init() async {
    await loadPhotos();
    await _loadStats();
  }
  
  /// Charger photos
  Future<void> loadPhotos() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final photos = await _photoRepository.fetchPhotos(userId);
      state = state.copyWith(
        photos: photos,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'PhotosController.loadPhotos',
        error: e,
        additionalData: {'user_id': userId},
      );
    }
  }
  
  /// Upload nouvelle photo
  Future<bool> uploadPhoto(File imageFile, {bool isMain = false}) async {
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      error: null,
    );
    
    try {
      // Simulation progress upload
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        state = state.copyWith(uploadProgress: i / 10);
      }
      
      final result = await _photoRepository.uploadPhoto(
        imageFile: imageFile,
        isMain: isMain,
      );
      
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      );
      
      if (result.success && result.photo != null) {
        // Ajouter photo à la liste
        final updatedPhotos = [result.photo!, ...state.photos];
        state = state.copyWith(photos: updatedPhotos);
        
        // Refresh stats
        await _loadStats();
        
        return true;
      } else {
        state = state.copyWith(error: result.error);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: ErrorHandler.getReadableError(e),
      );
      
      return false;
    }
  }
  
  /// Définir photo principale
  Future<bool> setMainPhoto(String photoId) async {
    state = state.copyWith(error: null);
    
    try {
      final success = await _photoRepository.setMainPhoto(photoId);
      
      if (success) {
        // Mettre à jour état local
        final updatedPhotos = state.photos.map((photo) {
          if (photo.id == photoId) {
            return photo.copyWith(isMain: true);
          } else if (photo.isMain) {
            return photo.copyWith(isMain: false);
          }
          return photo;
        }).toList();
        
        state = state.copyWith(photos: updatedPhotos);
        return true;
      } else {
        state = state.copyWith(error: 'Impossible de définir comme photo principale');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Supprimer photo
  Future<bool> deletePhoto(String photoId) async {
    state = state.copyWith(error: null);
    
    try {
      final success = await _photoRepository.deletePhoto(photoId);
      
      if (success) {
        // Retirer de la liste locale
        final updatedPhotos = state.photos
            .where((photo) => photo.id != photoId)
            .toList();
        
        state = state.copyWith(photos: updatedPhotos);
        
        // Refresh stats
        await _loadStats();
        
        return true;
      } else {
        state = state.copyWith(error: 'Impossible de supprimer la photo');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.getReadableError(e));
      return false;
    }
  }
  
  /// Remplacer photo rejetée
  Future<bool> replaceRejectedPhoto({
    required String photoId,
    required File newImageFile,
  }) async {
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      error: null,
    );
    
    try {
      final result = await _photoRepository.replaceRejectedPhoto(
        photoId: photoId,
        newImageFile: newImageFile,
      );
      
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      );
      
      if (result.success && result.photo != null) {
        // Remplacer dans la liste
        final updatedPhotos = state.photos.map((photo) {
          if (photo.id == photoId) {
            return result.photo!;
          }
          return photo;
        }).toList();
        
        state = state.copyWith(photos: updatedPhotos);
        return true;
      } else {
        state = state.copyWith(error: result.error);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: ErrorHandler.getReadableError(e),
      );
      
      return false;
    }
  }
  
  /// Charger statistiques
  Future<void> _loadStats() async {
    try {
      final stats = await _photoRepository.getPhotoStats(userId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      debugPrint('Error loading photo stats: $e');
    }
  }
  
  /// Refresh photos (pull-to-refresh)
  Future<void> refresh() async {
    await loadPhotos();
    await _loadStats();
  }
  
  /// Clear erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Obtenir photo par ID
  UserPhoto? getPhotoById(String photoId) {
    try {
      return state.photos.firstWhere((photo) => photo.id == photoId);
    } catch (e) {
      return null;
    }
  }
  
  /// Simuler changement statut (pour tests modération)
  void simulateModerationResult(String photoId, ModerationStatus status, {String? reason}) {
    final updatedPhotos = state.photos.map((photo) {
      if (photo.id == photoId) {
        return photo.copyWith(
          moderationStatus: status,
          moderationReason: reason,
        );
      }
      return photo;
    }).toList();
    
    state = state.copyWith(photos: updatedPhotos);
  }
}

/// Provider pour photos controller (par user ID)
final photosControllerProvider = StateNotifierProvider.family<PhotosController, PhotosState, String>((ref, userId) {
  return PhotosController(userId);
});

/// Provider pour photos actuelles utilisateur
final currentUserPhotosProvider = Provider<PhotosState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const PhotosState();
  
  return ref.watch(photosControllerProvider(userId));
});

/// Provider pour photo principale
final mainPhotoProvider = Provider<UserPhoto?>((ref) {
  return ref.watch(currentUserPhotosProvider).mainPhoto;
});

/// Provider pour nombre photos approuvées
final approvedPhotosCountProvider = Provider<int>((ref) {
  return ref.watch(currentUserPhotosProvider).approvedCount;
});
