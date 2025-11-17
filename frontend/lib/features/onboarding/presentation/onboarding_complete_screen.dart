import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Écran 9 – Onboarding terminé
class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});
  
  @override
  ConsumerState<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends ConsumerState<OnboardingCompleteScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isCompleting = false;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    
    return GradientScaffold(
      body: Column(
        children: [
          const SizedBox(height: 60),
          
          // Animation de réussite
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Titre principal
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Ton profil est prêt !',
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sous-titre
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Tu peux maintenant matcher avec des riders dans ta station.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Résumé du profil
          FadeTransition(
            opacity: _fadeAnimation,
            child: AppCard(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Photo + nom
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryPink,
                            width: 2,
                          ),
                        ),
                        child: onboardingData.photoFile != null
                          ? ClipOval(
                              child: Image.file(
                                onboardingData.photoFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline,
                              color: AppColors.textSecondary,
                              size: 32,
                            ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${onboardingData.firstName ?? 'Prénom'}, ${onboardingData.age ?? '?'}',
                              style: AppTypography.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              onboardingData.level?.displayName ?? 'Niveau',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Styles et langues
                  if (onboardingData.rideStyles.isNotEmpty) ...[
                    _buildInfoRow(
                      'Styles',
                      onboardingData.rideStyles.map((e) => e.displayName).join(', '),
                      Icons.snowboarding_outlined,
                    ),
                  ],
                  
                  if (onboardingData.languages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Langues',
                      onboardingData.languages.join(', '),
                      Icons.translate_outlined,
                    ),
                  ],
                  
                  if (onboardingData.objectives.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Objectifs',
                      onboardingData.objectives.take(2).join(', '),
                      Icons.flag_outlined,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Boutons d'action
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  PrimaryButton(
                    text: 'Commencer à swiper',
                    icon: Icons.favorite_outline,
                    onPressed: _handleStartSwiping,
                    isLoading: _isCompleting,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SecondaryButton(
                    text: 'Voir mon profil',
                    icon: Icons.person_outline,
                    onPressed: () {
                      // TODO S2: naviguer vers écran profil
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil disponible dans la prochaine version'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primaryPink,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.small,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: AppTypography.small,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _handleStartSwiping() async {
    setState(() => _isCompleting = true);
    
    try {
      // Finaliser l'onboarding en envoyant toutes les données vers Supabase
      final success = await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
      
      if (success) {
        // Actualiser le profil dans l'auth controller
        await ref.read(authControllerProvider.notifier).refreshProfile();
        
        // Navigation vers le feed principal
        context.go('/feed');
      } else {
        _showError('Erreur lors de la finalisation du profil');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isCompleting = false);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
