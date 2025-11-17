import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Écran 1 – Choix connexion / inscription
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Column(
        children: [
          const SizedBox(height: 60),
          
          // Logo et titre
          Column(
            children: [
              // Logo mini en haut
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [AppColors.cardShadow],
                ),
                child: const Center(
                  child: Text(
                    '⛷️',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'CrewSnow',
                style: AppTypography.h1.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '🏔️ ❄️',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 80),
          
          // Message principal
          AppCard(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              children: [
                Text(
                  'Connecte-toi pour trouver ton crew sur les pistes.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                
                const SizedBox(height: 32),
                
                // Bouton Apple (pour S1, désactivé)
                const PrimaryButton(
                  text: 'Continuer avec Apple',
                  icon: Icons.apple,
                  onPressed: null, // S1: pas encore implémenté
                  isEnabled: false,
                ),
                
                const SizedBox(height: 16),
                
                // Bouton email
                SecondaryButton(
                  text: 'Continuer avec mon email',
                  icon: Icons.email_outlined,
                  onPressed: () => context.go('/signup'),
                ),
                
                const SizedBox(height: 24),
                
                // Séparateur
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.inputBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: AppTypography.caption,
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.inputBorder)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Lien connexion existante
                GhostButton(
                  text: 'Déjà un compte ? Se connecter',
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // CGU en bas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'En continuant, tu acceptes nos Conditions Générales d\'Utilisation et notre Politique de Confidentialité.',
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}