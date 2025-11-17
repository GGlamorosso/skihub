import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import '../models/consent.dart';
import '../services/privacy_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class VideoVerificationScreen extends ConsumerStatefulWidget {
  const VideoVerificationScreen({super.key});

  @override
  ConsumerState<VideoVerificationScreen> createState() => _VideoVerificationScreenState();
}

class _VideoVerificationScreenState extends ConsumerState<VideoVerificationScreen> {
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isUploading = false;
  String? _videoPath;
  int _recordingDuration = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur caméra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationStatus = ref.watch(verificationStatusProvider('current-user-id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification Vidéo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: verificationStatus.when(
        data: (request) => _buildContent(request),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(VerificationRequest? existingRequest) {
    if (existingRequest != null) {
      return _buildExistingRequestStatus(existingRequest);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          _buildInstructions(),
          const SizedBox(height: AppSpacing.xl),
          
          // Camera preview or video player
          _buildCameraSection(),
          const SizedBox(height: AppSpacing.xl),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildExistingRequestStatus(VerificationRequest request) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: request.statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(request.status),
              size: 60,
              color: request.statusColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          Text(
            request.statusDisplay,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          
          Text(
            _getStatusDescription(request),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          if (request.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raison du rejet:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(request.rejectionReason!),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          if (request.canRetry)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Recommencer la vérification',
                onPressed: _retryVerification,
                variant: AppButtonVariant.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Vérification d\'identité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            const Text(
              'Pour garantir la sécurité de la communauté, nous demandons une vérification vidéo.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            ...[
              '1. Assurez-vous d\'être dans un endroit bien éclairé',
              '2. Regardez directement la caméra',
              '3. Enregistrez un clip de 5-10 secondes',
              '4. Montrez clairement votre visage',
              '5. Ne portez pas de masque ou lunettes de soleil',
            ].map((instruction) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(instruction, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return AppCard(
      child: SizedBox(
        height: 400,
        child: _videoPath != null ? _buildVideoPreview() : _buildCameraPreview(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Initialisation de la caméra...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
        
        // Recording indicator
        if (_isRecording)
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${_recordingDuration}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    if (_videoPlayerController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
        ),
        
        // Play/pause overlay
        Positioned.fill(
          child: Center(
            child: IconButton(
              onPressed: () {
                setState(() {
                  _videoPlayerController!.value.isPlaying
                      ? _videoPlayerController!.pause()
                      : _videoPlayerController!.play();
                });
              },
              icon: Icon(
                _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (_videoPath != null) {
      // Video recorded - show preview controls
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Recommencer',
                  onPressed: _retakeVideo,
                  variant: AppButtonVariant.outline,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: _isUploading ? 'Envoi...' : 'Envoyer',
                  onPressed: _isUploading ? null : _uploadVideo,
                  variant: AppButtonVariant.primary,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Camera ready - show record button
      return Center(
        child: GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.videocam,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _cameraController == null) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });
      
      // Start duration counter
      _startDurationCounter();
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    try {
      final videoFile = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = videoFile.path;
      });
      
      await _initializeVideoPlayer(videoFile.path);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _startDurationCounter() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() => _recordingDuration++);
        
        // Auto-stop at 30 seconds
        if (_recordingDuration >= 30) {
          _stopRecording();
        } else {
          _startDurationCounter();
        }
      }
    });
  }

  Future<void> _initializeVideoPlayer(String path) async {
    try {
      _videoPlayerController = VideoPlayerController.file(File(path));
      await _videoPlayerController!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _retakeVideo() {
    setState(() {
      _videoPath = null;
      _recordingDuration = 0;
    });
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  Future<void> _uploadVideo() async {
    if (_videoPath == null) return;

    setState(() => _isUploading = true);

    try {
      final videoFile = File(_videoPath!);
      final fileSize = await videoFile.length();
      
      // Upload to Supabase Storage
      const userId = 'current-user-id'; // Get from auth
      final fileName = 'verification_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final storagePath = '$userId/$fileName';
      
      final storageResponse = await ref.read(privacyServiceProvider)._repository._supabase
          .storage
          .from('verification_videos')
          .upload(storagePath, videoFile);
      
      if (storageResponse.error != null) {
        throw Exception('Upload failed: ${storageResponse.error!.message}');
      }

      // Submit verification request
      await ref.read(verificationStatusProvider('current-user-id').notifier)
          .submitVerification(
            videoPath: storagePath,
            durationSeconds: _recordingDuration,
            sizeBytes: fileSize,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vidéo envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _retryVerification() {
    // Reset existing request and start over
    ref.invalidate(verificationStatusProvider);
    setState(() {
      _videoPath = null;
      _recordingDuration = 0;
    });
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _getStatusDescription(VerificationRequest request) {
    switch (request.status) {
      case 'pending':
        return 'Votre vidéo est en cours de vérification. '
               'Vous recevrez une notification dans les 24-48h.';
      case 'approved':
        return 'Félicitations ! Votre identité a été vérifiée. '
               'Votre profil affiche maintenant le badge vérifié.';
      case 'rejected':
        return 'Votre vérification a été refusée. '
               'Veuillez suivre les instructions et recommencer.';
      case 'expired':
        return 'Votre demande de vérification a expiré. '
               'Veuillez recommencer le processus.';
      default:
        return 'Statut de vérification inconnu.';
    }
  }
}

class VerificationBadge extends ConsumerWidget {
  final String userId;
  final double? size;

  const VerificationBadge({
    super.key,
    required this.userId,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationStatus = ref.watch(verificationStatusProvider(userId));

    return verificationStatus.when(
      data: (request) {
        if (request?.isApproved ?? false) {
          return Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified,
              color: Colors.white,
              size: size,
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class VerificationStatusCard extends ConsumerWidget {
  final String userId;

  const VerificationStatusCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationStatus = ref.watch(verificationStatusProvider(userId));

    return verificationStatus.when(
      data: (request) => _buildStatusCard(context, request),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusCard(BuildContext context, VerificationRequest? request) {
    if (request == null) {
      // No verification request - show call to action
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: Colors.orange[600]),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Profil non vérifié',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Vérifiez votre identité pour obtenir plus de matchs et gagner la confiance de la communauté.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const VideoVerificationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Vérifier mon identité'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has verification request - show status
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(request.status),
                  color: request.statusColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    request.statusDisplay,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: request.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: request.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Soumis le ${_formatDate(request.submittedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
