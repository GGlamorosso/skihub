import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/feedback_service.dart';
import '../models/beta_feedback.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/l10n/app_localizations.dart';

class BetaFeedbackScreen extends ConsumerStatefulWidget {
  const BetaFeedbackScreen({super.key});

  @override
  ConsumerState<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends ConsumerState<BetaFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  int? _rating;
  XFile? _screenshot;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendFeedback),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: AppSpacing.xl),
              
              // Rating
              _buildRatingSection(),
              const SizedBox(height: AppSpacing.lg),
              
              // Category
              _buildCategorySection(),
              const SizedBox(height: AppSpacing.lg),
              
              // Subject
              _buildSubjectField(),
              const SizedBox(height: AppSpacing.lg),
              
              // Description  
              _buildDescriptionField(),
              const SizedBox(height: AppSpacing.lg),
              
              // Screenshot
              _buildScreenshotSection(),
              const SizedBox(height: AppSpacing.xl),
              
              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.feedback,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Votre avis compte !',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Aidez-nous à améliorer CrewSnow en partageant vos commentaires, '
              'suggestions ou en signalant des problèmes.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comment évaluez-vous votre expérience ?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Semantics(
                    button: true,
                    label: '$star étoile${star > 1 ? 's' : ''}',
                    child: Icon(
                      _rating != null && _rating! >= star
                          ? Icons.star
                          : Icons.star_border,
                      size: 40,
                      color: _rating != null && _rating! >= star
                          ? Colors.amber[600]
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            if (_rating != null) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  _getRatingText(_rating!),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catégorie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: FeedbackCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category.displayName),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  avatar: Icon(category.icon, size: 16),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectField() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sujet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Résumez votre retour en quelques mots',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un sujet';
                }
                if (value.trim().length < 5) {
                  return 'Le sujet doit faire au moins 5 caractères';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Décrivez votre expérience, problème ou suggestion en détail...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez décrire votre retour';
                }
                if (value.trim().length < 10) {
                  return 'Veuillez donner plus de détails (min. 10 caractères)';
                }
                return null;
              },
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capture d\'écran (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Ajoutez une capture pour nous aider à mieux comprendre',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            
            if (_screenshot != null) 
              _buildSelectedScreenshot()
            else
              _buildScreenshotButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedScreenshot() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_screenshot!.path),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectFromGallery,
                icon: const Icon(Icons.image),
                label: const Text('Changer'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _screenshot = null),
                icon: const Icon(Icons.delete),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScreenshotButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _takeScreenshot,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Prendre photo'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectFromGallery,
            icon: const Icon(Icons.image),
            label: const Text('Galerie'),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedLoadingButton(
        text: 'Envoyer le feedback',
        onPressed: _isSubmitting ? null : _submitFeedback,
        isLoading: _isSubmitting,
        icon: Icons.send,
      ),
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() => _screenshot = image);
      }
    } catch (e) {
      _showError('Erreur lors de la capture: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() => _screenshot = image);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final feedbackService = ref.read(feedbackServiceProvider);
      
      String? screenshotUrl;
      if (_screenshot != null) {
        screenshotUrl = await feedbackService.uploadScreenshot(
          'current-user-id', // Get from auth
          File(_screenshot!.path),
        );
      }

      await feedbackService.submitFeedback(
        userId: 'current-user-id',
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        rating: _rating,
        screenshotUrl: screenshotUrl,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre retour ! Nous l\'examinerons rapidement.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        // Close screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Erreur lors de l\'envoi: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Très déçu';
      case 2:
        return 'Déçu';
      case 3:
        return 'Neutre';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Très satisfait';
      default:
        return '';
    }
  }
}

class QuickFeedbackWidget extends ConsumerStatefulWidget {
  final String? context;

  const QuickFeedbackWidget({
    super.key,
    this.context,
  });

  @override
  ConsumerState<QuickFeedbackWidget> createState() => _QuickFeedbackWidgetState();
}

class _QuickFeedbackWidgetState extends ConsumerState<QuickFeedbackWidget> {
  bool _isVisible = true;
  bool _hasResponded = false;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _hasResponded) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.blue[600]),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Vous appréciez CrewSnow ?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isVisible = false),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleQuickResponse(false),
                      child: const Text('Non'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleQuickResponse(true),
                      child: const Text('Oui'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuickResponse(bool positive) {
    setState(() => _hasResponded = true);
    
    final feedbackService = ref.read(feedbackServiceProvider);
    feedbackService.logQuickFeedback(
      userId: 'current-user-id',
      positive: positive,
      context: widget.context ?? 'general',
    );

    if (positive) {
      // Show thank you message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci ! Ça nous fait plaisir 😊'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Offer to send detailed feedback
      _showDetailedFeedbackOption();
    }
  }

  void _showDetailedFeedbackOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aidez-nous à nous améliorer'),
        content: const Text(
          'Nous sommes désolés que votre expérience ne soit pas parfaite. '
          'Voulez-vous nous dire ce qui pourrait être amélioré ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BetaFeedbackScreen(),
                ),
              );
            },
            child: const Text('Donner des détails'),
          ),
        ],
      ),
    );
  }
}

class FeedbackFloatingButton extends StatelessWidget {
  const FeedbackFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BetaFeedbackScreen(),
          ),
        );
      },
      icon: const Icon(Icons.feedback),
      label: const Text('Feedback'),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    );
  }
}

class FeedbackBadge extends StatelessWidget {
  final int count;

  const FeedbackBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
