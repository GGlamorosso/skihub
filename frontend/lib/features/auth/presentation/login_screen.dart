import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../router/app_router.dart';
import '../controllers/auth_controller.dart';

/// Écran de connexion
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
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
                      context.go(AppRoutes.auth);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  'Connexion',
                  style: AppTypography.h3,
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Formulaire
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bon retour ! 👋',
                      style: AppTypography.h2,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Connecte-toi pour retrouver ton crew.',
                      style: AppTypography.body,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse email',
                        hintText: 'ton-email@exemple.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'email est obligatoire';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Format d\'email invalide';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        hintText: 'Ton mot de passe',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: GhostButton(
                        text: 'Mot de passe oublié ?',
                        onPressed: () => context.go('/forgot-password'),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton connexion
                    PrimaryButton(
                      text: 'Se connecter',
                      isLoading: authState.isLoading,
                      onPressed: _handleLogin,
                    ),
                    
                    if (authState.hasError) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getErrorMessage(authState.error),
                                style: AppTypography.small.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Lien vers inscription
                    Center(
                      child: GhostButton(
                        text: 'Pas encore de compte ? S\'inscrire',
                        onPressed: () => context.go('/signup'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    
    ref.read(authControllerProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      onSuccess: () {
        // TODO S2: vérifier si onboarding complet, sinon redirect
        context.go('/feed');
      },
    );
  }
  
  String _getErrorMessage(String? error) {
    if (error == null) return 'Erreur inconnue';
    
    // Mapper les erreurs Supabase vers messages user-friendly
    if (error.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (error.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email';
    }
    if (error.contains('Too many requests')) {
      return 'Trop de tentatives, réessayez dans quelques minutes';
    }
    
    return 'Erreur de connexion: $error';
  }
}
