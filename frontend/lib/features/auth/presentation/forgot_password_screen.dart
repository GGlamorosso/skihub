import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../router/app_router.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/error_handler.dart';

/// Écran de récupération mot de passe
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  'Mot de passe oublié',
                  style: AppTypography.h3,
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // Contenu principal
            AppCard(
              child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône et titre
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: AppColors.primaryPink,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Réinitialiser ton mot de passe',
            textAlign: TextAlign.center,
            style: AppTypography.h2,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Entre ton adresse email et nous t\'enverrons un lien pour créer un nouveau mot de passe.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          
          const SizedBox(height: 32),
          
          // Champ email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              hintText: 'ton-email@exemple.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'L\'email est obligatoire';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Format d\'email invalide';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),
          
          const SizedBox(height: 32),
          
          // Bouton envoi
          PrimaryButton(
            text: 'Envoyer le lien',
            isLoading: _isLoading,
            onPressed: _handleResetPassword,
          ),
          
          // Erreur
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
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
                      _error!,
                      style: AppTypography.small.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Lien retour
          Center(
            child: GhostButton(
              text: 'Retour à la connexion',
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessContent() {
    return Column(
      children: [
        // Icône succès
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Email envoyé !',
          style: AppTypography.h2.copyWith(color: AppColors.success),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Nous avons envoyé un lien de réinitialisation à ${_emailController.text}',
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Vérifie tes emails (et le dossier spam) puis suis les instructions.',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
        
        const SizedBox(height: 32),
        
        SecondaryButton(
          text: 'Renvoyer l\'email',
          icon: Icons.refresh,
          onPressed: () {
            setState(() {
              _emailSent = false;
              _error = null;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        PrimaryButton(
          text: 'Retour à la connexion',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
  
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await SupabaseService.instance.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'https://crewsnow.app/reset-password', // TODO: URL réelle
      );
      
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = ErrorHandler.getReadableError(e);
      });
      
      ErrorHandler.logError(
        context: 'ForgotPasswordScreen._handleResetPassword',
        error: e,
        additionalData: {'email': _emailController.text.trim()},
      );
    }
  }
}
