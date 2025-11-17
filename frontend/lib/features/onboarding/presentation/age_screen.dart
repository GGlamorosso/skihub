import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../controllers/onboarding_controller.dart';

/// Écran 3 – Âge
class AgeScreen extends ConsumerStatefulWidget {
  const AgeScreen({super.key});
  
  @override
  ConsumerState<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends ConsumerState<AgeScreen> {
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    
    // Charger données existantes
    final onboardingData = ref.read(onboardingControllerProvider);
    if (onboardingData.age != null) {
      _ageController.text = onboardingData.age.toString();
    }
    
    _ageController.addListener(_updateState);
  }
  
  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }
  
  void _updateState() {
    setState(() {});
  }
  
  bool get _canContinue {
    final text = _ageController.text.trim();
    if (text.isEmpty) return false;
    final age = int.tryParse(text);
    return age != null && age >= 16 && age <= 99;
  }
  
  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      progress: 0.25, // 2/8 étapes environ
      title: 'Tu as quel âge ?',
      subtitle: 'Pour la sécurité et les filtres d\'âge.',
      onNext: _handleNext,
      onBack: () => context.go('/onboarding/name'),
      isNextEnabled: _canContinue,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            // Champ âge numérique centré
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                  hintText: '25',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffix: Text('ans'),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTypography.h2,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Âge obligatoire';
                  }
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Âge invalide';
                  }
                  if (age < 16) {
                    return 'Tu dois avoir au moins 16 ans';
                  }
                  if (age > 99) {
                    return 'Âge maximum 99 ans';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Alternative: sélecteur de date
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Ou choisis ta date de naissance',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showDatePicker(),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _getDateButtonText(),
                      style: AppTypography.buttonGhost,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Information confidentialité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Confidentialité',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'On affiche seulement ton âge, pas ta date de naissance complète. Tu peux masquer ton âge dans les paramètres.',
                    style: AppTypography.small.copyWith(
                      color: Colors.blue.shade600,
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
    
    final age = int.tryParse(_ageController.text.trim());
    if (age != null) {
      // Calculer date de naissance approximative si pas définie
      final onboardingData = ref.read(onboardingControllerProvider);
      DateTime? birthDate = onboardingData.birthDate;
      
      if (birthDate == null) {
        final now = DateTime.now();
        birthDate = DateTime(now.year - age, now.month, now.day);
      }
      
      ref.read(onboardingControllerProvider.notifier).updateAge(
        age: age,
        birthDate: birthDate,
      );
      
      context.go('/onboarding/photo');
    }
  }
  
  void _showDatePicker() async {
    final now = DateTime.now();
    final initialDate = now.subtract(const Duration(days: 365 * 25)); // 25 ans par défaut
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 16),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryPink,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      final age = DateTime.now().year - selectedDate.year;
      _ageController.text = age.toString();
      
      ref.read(onboardingControllerProvider.notifier).updateAge(
        age: age,
        birthDate: selectedDate,
      );
    }
  }
  
  String _getDateButtonText() {
    final onboardingData = ref.watch(onboardingControllerProvider);
    
    if (onboardingData.birthDate != null) {
      final date = onboardingData.birthDate!;
      return '${date.day}/${date.month}/${date.year}';
    }
    
    return 'Sélectionner une date';
  }
}
