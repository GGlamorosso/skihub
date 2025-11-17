import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import '../repositories/privacy_repository.dart';
import '../models/consent.dart';
import '../../core/services/analytics_service.dart';

class VideoVerificationService {
  final PrivacyRepository _repository;
  final AnalyticsService _analytics = AnalyticsService();

  VideoVerificationService(this._repository);

  // Check camera permissions
  Future<bool> checkCameraPermission() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      if (cameraStatus.isDenied || microphoneStatus.isDenied) {
        return await requestCameraPermission();
      }

      return cameraStatus.isGranted && microphoneStatus.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  // Request camera permissions
  Future<bool> requestCameraPermission() async {
    try {
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      return permissions[Permission.camera]?.isGranted == true &&
             permissions[Permission.microphone]?.isGranted == true;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  // Initialize camera
  Future<CameraController?> initializeCamera() async {
    try {
      final hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission required');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      return controller;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _analytics.track('camera_initialization_failed', {'error': e.toString()});
      rethrow;
    }
  }

  // Record verification video
  Future<XFile> recordVideo(CameraController controller, int maxDurationSeconds) async {
    try {
      if (!controller.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      _analytics.track('verification_recording_started');

      await controller.startVideoRecording();
      
      // This would be handled by the UI component
      // The actual stopping is done when user taps stop
      throw UnimplementedError('Recording duration should be handled by UI');
      
    } catch (e) {
      debugPrint('Error recording video: $e');
      _analytics.track('verification_recording_failed', {'error': e.toString()});
      rethrow;
    }
  }

  // Upload verification video
  Future<VerificationRequest> uploadVerificationVideo({
    required String userId,
    required String videoPath,
    required File videoFile,
  }) async {
    try {
      // Get file info
      final fileSize = await videoFile.length();
      final durationSeconds = await _getVideoDuration(videoFile);

      // Validate file
      await _validateVideoFile(videoFile, fileSize, durationSeconds);

      _analytics.track('verification_upload_started', {
        'file_size': fileSize,
        'duration_seconds': durationSeconds,
      });

      // Submit verification request
      final request = await _repository.submitVideoVerification(
        userId: userId,
        videoPath: videoPath,
        durationSeconds: durationSeconds,
        sizeBytes: fileSize,
      );

      _analytics.track('verification_upload_success', {
        'request_id': request.id,
        'file_size': fileSize,
        'duration_seconds': durationSeconds,
      });

      return request;
    } catch (e) {
      _analytics.track('verification_upload_failed', {'error': e.toString()});
      rethrow;
    }
  }

  // Get latest verification status
  Future<VerificationRequest?> getVerificationStatus(String userId) async {
    try {
      return await _repository.getLatestVerificationRequest(userId);
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      return null;
    }
  }

  // Validate video file
  Future<void> _validateVideoFile(File file, int sizeBytes, int? durationSeconds) async {
    // File size check (max 50MB)
    if (sizeBytes > 50 * 1024 * 1024) {
      throw Exception('Fichier vidéo trop volumineux (max 50MB)');
    }

    // Duration check (5-120 seconds)
    if (durationSeconds != null) {
      if (durationSeconds < 5) {
        throw Exception('Vidéo trop courte (minimum 5 secondes)');
      }
      if (durationSeconds > 120) {
        throw Exception('Vidéo trop longue (maximum 2 minutes)');
      }
    }

    // File format check
    final extension = file.path.toLowerCase().split('.').last;
    if (!['mp4', 'mov', 'avi'].contains(extension)) {
      throw Exception('Format vidéo non supporté (MP4, MOV, AVI uniquement)');
    }
  }

  // Get video duration (simplified - would need video processing package)
  Future<int?> _getVideoDuration(File videoFile) async {
    try {
      // This would use a video processing package to get actual duration
      // For now, return null (duration will be estimated)
      return null;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return null;
    }
  }

  // Delete verification video
  Future<void> deleteVerificationVideo(String userId, String storagePath) async {
    try {
      await _repository._supabase.storage
          .from('verification_videos')
          .remove([storagePath]);

      _analytics.track('verification_video_deleted', {
        'user_id': userId,
        'storage_path': storagePath,
      });
    } catch (e) {
      debugPrint('Error deleting verification video: $e');
      rethrow;
    }
  }

  // Handle verification result notification
  void handleVerificationResult(VerificationRequest request) {
    _analytics.track('verification_result_received', {
      'request_id': request.id,
      'status': request.status,
      'verification_score': request.verificationScore,
    });

    // This would trigger local notifications
    // or update app state accordingly
  }

  // Get verification requirements
  Map<String, dynamic> getVerificationRequirements() {
    return {
      'min_duration_seconds': 5,
      'max_duration_seconds': 120,
      'max_file_size_bytes': 50 * 1024 * 1024, // 50MB
      'allowed_formats': ['mp4', 'mov', 'avi'],
      'requirements': [
        'Bien éclairé',
        'Visage clairement visible',
        'Pas de masque ou lunettes de soleil',
        'Regarder directement la caméra',
        'Montrer le visage pendant 5-10 secondes',
      ],
    };
  }
}
