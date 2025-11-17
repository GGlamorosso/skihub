import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';

/// Écran 2 – Nom & prénom
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});
  
  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Charger données existantes si disponibles
    final onboardingData = ref.read(onboardingControllerProvider);
    _firstNameController.text = onboardingData.firstName ?? '';
    _lastNameController.text = onboardingData.lastName ?? '';
    
    // Listener pour activer/désactiver bouton
    _firstNameController.addListener(_updateState);
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
  
  void _updateState() {
    setState(() {});
  }
  
  bool get _canContinue => _firstNameController.text.trim().isNotEmpty;
  
  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      progress: 0.15, // 1/7 étapes environ
      title: 'Comment tu t\'appelles ?',
      subtitle: 'On montre ton prénom sur ton profil.',
      onNext: _handleNext,
      onBack: () => context.go('/auth'),
      isNextEnabled: _canContinue,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            // Prénom (requis)
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                hintText: 'Ton prénom',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prénom est obligatoire';
                }
                if (value.trim().length < 2) {
                  return 'Au moins 2 caractères';
                }
                if (value.trim().length > 30) {
                  return 'Maximum 30 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Nom (optionnel)
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ton nom (optionnel)',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty && value.trim().length > 50) {
                  return 'Maximum 50 caractères';
                }
                return null;
              },
            ),
            
            const Spacer(),
            
            // Info en bas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seul ton prénom sera visible des autres utilisateurs.',
                      style: AppTypography.small.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    
    // Sauvegarder dans le state d'onboarding
    ref.read(onboardingControllerProvider.notifier).updateName(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty 
        ? null 
        : _lastNameController.text.trim(),
    );
    
    // Naviguer vers étape suivante
    context.go('/onboarding/age');
  }
}
