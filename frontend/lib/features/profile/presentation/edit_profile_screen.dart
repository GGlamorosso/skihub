import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../components/chips.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/user_profile.dart';
import '../../../utils/form_validators.dart';
import '../controllers/profile_controller.dart';

/// Écran d'édition de profil
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  UserLevel? _selectedLevel;
  Set<RideStyle> _selectedStyles = {};
  Set<String> _selectedLanguages = {};
  Set<String> _selectedObjectives = {};
  
  @override
  void initState() {
    super.initState();
    
    // Charger données actuelles
    final profile = ref.read(profileControllerProvider).profile;
    if (profile != null) {
      _usernameController.text = profile.username;
      _bioController.text = profile.bio ?? '';
      _selectedLevel = profile.level;
      _selectedStyles = profile.rideStyles.toSet();
      _selectedLanguages = profile.languages.toSet();
      _selectedObjectives = profile.objectives.toSet();
    }
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    
    return GradientScaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                        context.go(AppRoutes.profile);
                      }
                    },
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    'Modifier le profil',
                    style: AppTypography.h3,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: profileState.isUpdating ? null : _saveChanges,
                    child: Text(
                      'Sauver',
                      style: AppTypography.buttonGhost.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Nom d'utilisateur
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nom d\'utilisateur', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'ton_username',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: FormValidators.username,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bio
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('À propos de moi', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        hintText: 'Raconte-nous qui tu es...',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      validator: FormValidators.bio,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Niveau
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niveau de ski', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    SingleSelectChips(
                      options: UserLevel.values.map((e) => e.displayName).toList(),
                      selectedOption: _selectedLevel?.displayName,
                      onChanged: (levelName) {
                        setState(() {
                          _selectedLevel = UserLevel.values.firstWhere(
                            (e) => e.displayName == levelName,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Styles de ride
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Styles de ride', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    MultiSelectChips(
                      options: RideStyle.values.map((e) => e.displayName).toList(),
                      selectedOptions: _selectedStyles.map((e) => e.displayName).toSet(),
                      onChanged: (styleNames) {
                        setState(() {
                          _selectedStyles = styleNames.map((name) {
                            return RideStyle.values.firstWhere(
                              (e) => e.displayName == name,
                            );
                          }).toSet();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Langues
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Langues parlées', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    MultiSelectChips(
                      options: const [
                        'Français', 'Anglais', 'Espagnol', 'Italien', 
                        'Allemand', 'Russe', 'Japonais', 'Chinois'
                      ],
                      selectedOptions: _selectedLanguages,
                      onChanged: (languages) {
                        setState(() => _selectedLanguages = languages);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Objectifs
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Objectifs', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    MultiSelectChips(
                      options: const [
                        'Rider à 2', 'Agrandir mon groupe', 'Hors-piste en binôme',
                        'Faire des rencontres', 'After-ski / soirées', 'Apprendre et progresser',
                        'Partager mes spots', 'Challenges et compétitions'
                      ],
                      selectedOptions: _selectedObjectives,
                      onChanged: (objectives) {
                        setState(() => _selectedObjectives = objectives);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Boutons d'action
              if (profileState.isUpdating) ...[
                const Center(child: CircularProgressIndicator()),
              ] else ...[
                PrimaryButton(
                  text: 'Sauvegarder les modifications',
                  onPressed: _saveChanges,
                ),
                
                const SizedBox(height: 16),
                
                SecondaryButton(
                  text: 'Annuler',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.profile);
                    }
                  },
                ),
              ],
              
              // Erreur
              if (profileState.hasError) ...[
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
                          profileState.error!,
                          style: AppTypography.small.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLevel == null || _selectedStyles.isEmpty || _selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final success = await ref.read(profileControllerProvider.notifier).updateProfile(
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      level: _selectedLevel,
      rideStyles: _selectedStyles.toList(),
      languages: _selectedLanguages.toList(),
      objectives: _selectedObjectives.toList(),
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
    }
  }
}
