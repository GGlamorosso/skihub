import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/buttons.dart';
import '../../../components/bottom_navigation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/ride_stats.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/error_handler.dart';
import '../controllers/tracking_controller.dart';
import '../../profile/controllers/profile_controller.dart';

/// Écran tracker GPS
class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});
  
  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Pulse si tracking actif
    _updatePulseAnimation();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _updatePulseAnimation() {
    final trackingState = ref.read(trackingControllerProvider);
    
    if (trackingState.isTracking && !trackingState.isPaused) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final currentStation = profileState.currentStation;
    
    // Update animation selon état
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePulseAnimation();
    });
    
    return AppScaffold(
      currentIndex: 2, // Tracker = index 2 (remplace Chat placeholder)
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(currentStation),
              
              // Status permissions/consent
              if (!trackingState.hasPermissions || !trackingState.hasConsent)
                _buildPermissionsSection(trackingState),
              
              // Zone tracking principale
              Expanded(
                child: trackingState.hasActiveSession
                  ? _buildActiveTrackingSection(trackingState)
                  : _buildReadyToTrackSection(trackingState),
              ),
              
              // Contrôles
              _buildTrackingControls(trackingState, currentStation?.stationId),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(currentStation) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            '🎿 Tracker',
            style: AppTypography.h2,
          ),
          
          const Spacer(),
          
          // Station actuelle
          if (currentStation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [AppColors.cardShadow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primaryPink,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentStation.station?.name ?? 'Station',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Menu options
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: AppColors.primaryPink),
                    const SizedBox(width: 8),
                    Text('Mes statistiques', style: AppTypography.body),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'economy',
                child: Row(
                  children: [
                    Icon(
                      Icons.battery_saver,
                      color: ref.watch(trackingControllerProvider).economyMode
                        ? AppColors.success
                        : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text('Mode économie', style: AppTypography.body),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Test GPS', style: AppTypography.body),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionsSection(TrackingState trackingState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_outlined, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Configuration requise',
                style: AppTypography.bodyBold.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (!trackingState.hasPermissions) ...[
            Row(
              children: [
                const Icon(Icons.location_off, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions GPS requises',
                    style: AppTypography.body,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(trackingControllerProvider.notifier).requestPermissions(),
                  child: const Text('Autoriser'),
                ),
              ],
            ),
          ],
          
          if (!trackingState.hasConsent) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.privacy_tip, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consent tracking GPS requis',
                    style: AppTypography.body,
                  ),
                ),
                TextButton(
                  onPressed: _showConsentDialog,
                  child: const Text('Accepter'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActiveTrackingSection(TrackingState trackingState) {
    final session = trackingState.currentSession!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur tracking actif
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: trackingState.isTracking && !trackingState.isPaused
                  ? _pulseAnimation.value
                  : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: trackingState.isPaused
                      ? LinearGradient(
                          colors: [AppColors.warning, AppColors.warning.withOpacity(0.7)],
                        )
                      : AppColors.buttonGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (trackingState.isPaused ? AppColors.warning : AppColors.primaryPink)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      trackingState.isPaused ? Icons.pause : Icons.gps_fixed,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Text(
            trackingState.isPaused ? 'Session en pause' : 'Tracking actif',
            style: AppTypography.h3.copyWith(
              color: trackingState.isPaused ? AppColors.warning : AppColors.success,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Stats temps réel
          _buildStatsGrid(trackingState),
          
          const SizedBox(height: 24),
          
          // Infos session
          _buildSessionInfo(session),
        ],
      ),
    );
  }
  
  Widget _buildReadyToTrackSection(TrackingState trackingState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône GPS
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: trackingState.canStartTracking
                ? AppColors.primaryPink.withOpacity(0.1)
                : AppColors.textSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: trackingState.canStartTracking
                  ? AppColors.primaryPink
                  : AppColors.textSecondary,
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.my_location,
                size: 48,
                color: trackingState.canStartTracking
                  ? AppColors.primaryPink
                  : AppColors.textSecondary,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Prêt à tracker vos runs ?',
            style: AppTypography.h2,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Suivez votre distance, vitesse et dénivelé en temps réel.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          
          const SizedBox(height: 32),
          
          // Avantages tracking
          _buildTrackingBenefits(),
          
          if (trackingState.lastGPSTest != null) ...[
            const SizedBox(height: 24),
            _buildGPSTestResult(trackingState.lastGPSTest!),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid(TrackingState trackingState) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Distance',
          value: '${trackingState.currentDistance.toStringAsFixed(1)} km',
          icon: Icons.straighten,
          color: AppColors.primaryPink,
        ),
        _buildStatCard(
          title: 'Vitesse max',
          value: '${trackingState.currentMaxSpeed.toStringAsFixed(1)} km/h',
          icon: Icons.speed,
          color: AppColors.success,
        ),
        _buildStatCard(
          title: 'Dénivelé',
          value: '${trackingState.currentElevationGain} m',
          icon: Icons.terrain,
          color: AppColors.warning,
        ),
        _buildStatCard(
          title: 'Durée',
          value: _formatDuration(trackingState.sessionDuration),
          icon: Icons.timer,
          color: Colors.blue,
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h3.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionInfo(TrackingSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Points GPS:', style: AppTypography.caption),
              Text('${session.pointsCount}', style: AppTypography.bodyBold),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Démarré:', style: AppTypography.caption),
              Text(
                '${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}',
                style: AppTypography.bodyBold,
              ),
            ],
          ),
          if (session.pausedTimeMin > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Temps pause:', style: AppTypography.caption),
                Text(
                  '${session.pausedTimeMin}min',
                  style: AppTypography.bodyBold.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTrackingBenefits() {
    const benefits = [
      'Distance parcourue en temps réel',
      'Vitesse maximum atteinte',
      'Dénivelé total gravi',
      'Historique et comparaisons',
    ];
    
    return Column(
      children: benefits.map((benefit) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                benefit,
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
  
  Widget _buildGPSTestResult(Map<String, dynamic> testResult) {
    final success = testResult['success'] as bool;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success 
          ? AppColors.success.withOpacity(0.1)
          : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success 
            ? AppColors.success.withOpacity(0.3)
            : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.gps_fixed : Icons.gps_off,
                color: success ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'GPS opérationnel' : 'Problème GPS',
                style: AppTypography.bodyBold.copyWith(
                  color: success ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          
          if (success) ...[
            const SizedBox(height: 8),
            Text(
              'Précision: ${(testResult['accuracy'] as double).toStringAsFixed(1)}m',
              style: AppTypography.small,
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              testResult['error'] as String,
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTrackingControls(TrackingState trackingState, String? stationId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Erreur
          if (trackingState.hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trackingState.error!,
                      style: AppTypography.small.copyWith(color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(trackingControllerProvider.notifier).clearError(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Boutons principaux
          if (!trackingState.isTracking) ...[
            PrimaryButton(
              text: 'Démarrer session',
              icon: Icons.play_arrow,
              onPressed: trackingState.canStartTracking
                ? () => _startTracking(stationId)
                : null,
            ),
          ] else ...[
            Row(
              children: [
                if (trackingState.canPauseTracking) ...[
                  Expanded(
                    child: SecondaryButton(
                      text: 'Pause',
                      icon: Icons.pause,
                      onPressed: () => ref.read(trackingControllerProvider.notifier).pauseTracking(),
                    ),
                  ),
                ] else if (trackingState.canResumeTracking) ...[
                  Expanded(
                    child: PrimaryButton(
                      text: 'Reprendre',
                      icon: Icons.play_arrow,
                      onPressed: () => ref.read(trackingControllerProvider.notifier).resumeTracking(),
                    ),
                  ),
                ],
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _confirmStopTracking,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop, size: 20),
                          const SizedBox(width: 8),
                          Text('Terminer', style: AppTypography.buttonSecondary.copyWith(
                            color: AppColors.success,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bouton annuler (danger)
            GhostButton(
              text: 'Annuler session',
              onPressed: _confirmCancelTracking,
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'stats':
        context.push('/stats');
        break;
      case 'economy':
        ref.read(trackingControllerProvider.notifier).toggleEconomyMode();
        break;
      case 'test':
        ref.read(trackingControllerProvider.notifier).testGPS();
        break;
    }
  }
  
  Future<void> _startTracking(String? stationId) async {
    final success = await ref
        .read(trackingControllerProvider.notifier)
        .startTracking(stationId: stationId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎿 Session démarrée ! Bon ski !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
  
  void _confirmStopTracking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la session'),
        content: const Text('Vos stats seront sauvegardées et synchronisées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopTracking();
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
  
  void _confirmCancelTracking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la session'),
        content: const Text('Toutes les données seront perdues. Êtes-vous sûr ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(trackingControllerProvider.notifier).cancelTracking();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _stopTracking() async {
    final success = await ref
        .read(trackingControllerProvider.notifier)
        .stopTracking();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🏁 Session terminée et synchronisée !'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Navigation vers stats
      context.push('/stats');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur synchronisation. Session sauvegardée localement.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
  
  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autorisation GPS'),
        content: const Text(
          'CrewSnow souhaite accéder à votre localisation pour tracker vos sessions de ski. '
          'Vos données restent privées et vous pouvez désactiver à tout moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Refuser'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _grantGPSConsent();
            },
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _grantGPSConsent() async {
    try {
      // ✅ Corrigé : Utiliser 'gps' au lieu de 'gps_tracking' (format Edge Function)
      await SupabaseService.instance.callFunction(
        functionName: 'manage-consent',
        body: {
          'action': 'grant',
          'purpose': 'gps', // Edge Function accepte 'gps', pas 'gps_tracking'
          'version': 1,
        },
      );
      
      // Refresh état
      await ref.read(trackingControllerProvider.notifier).refreshPermissions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Consent GPS accordé'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${ErrorHandler.getReadableError(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
