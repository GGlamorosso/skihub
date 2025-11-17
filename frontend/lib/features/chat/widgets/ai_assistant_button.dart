import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../privacy/services/privacy_service.dart';
import '../../privacy/models/consent.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

part 'ai_assistant_button.g.dart';

class AIAssistantButton extends ConsumerStatefulWidget {
  final String userId;
  final String matchId;
  final TextEditingController messageController;
  final VoidCallback? onSuggestionUsed;

  const AIAssistantButton({
    super.key,
    required this.userId,
    required this.matchId,
    required this.messageController,
    this.onSuggestionUsed,
  });

  @override
  ConsumerState<AIAssistantButton> createState() => _AIAssistantButtonState();
}

class _AIAssistantButtonState extends ConsumerState<AIAssistantButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Check if user has AI assistance consent
    final hasConsent = ref.watch(consentCheckProvider(widget.userId, 'ai_assistance'));

    return hasConsent.when(
      data: (consent) => consent
          ? _buildAssistantButton()
          : _buildConsentRequired(),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildAssistantButton() {
    return IconButton(
      onPressed: _isLoading ? null : _getAISuggestion,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.lightbulb_outline),
      tooltip: 'Assistant IA',
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildConsentRequired() {
    return IconButton(
      onPressed: _showConsentDialog,
      icon: Icon(
        Icons.lightbulb_outline,
        color: Colors.grey[400],
      ),
      tooltip: 'Assistant IA (consentement requis)',
    );
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assistant IA'),
        content: const Text(
          'L\'assistant IA peut vous aider à briser la glace avec des suggestions de messages personnalisées.\n\n'
          'Voulez-vous activer cette fonctionnalité ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _grantAIConsent();
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  Future<void> _grantAIConsent() async {
    try {
      final privacyService = ref.read(privacyServiceProvider);
      await privacyService.grantConsent(widget.userId, 'ai_assistance');
      
      // Refresh consent state
      ref.invalidate(consentCheckProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assistant IA activé !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getAISuggestion() async {
    setState(() => _isLoading = true);

    try {
      final privacyService = ref.read(privacyServiceProvider);
      final suggestion = await privacyService.getAIIcebreaker(
        userId: widget.userId,
        matchId: widget.matchId,
        contextType: widget.messageController.text.isEmpty ? 'first_message' : 'follow_up',
      );

      if (mounted) {
        _showSuggestionModal(suggestion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur IA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuggestionModal(String suggestion) {
    showDialog(
      context: context,
      builder: (context) => AISuggestionModal(
        suggestion: suggestion,
        onUse: () {
          widget.messageController.text = suggestion;
          widget.onSuggestionUsed?.call();
          Navigator.of(context).pop();
        },
        onRegenerate: () {
          Navigator.of(context).pop();
          _getAISuggestion();
        },
      ),
    );
  }
}

class AISuggestionModal extends StatelessWidget {
  final String suggestion;
  final VoidCallback onUse;
  final VoidCallback onRegenerate;

  const AISuggestionModal({
    super.key,
    required this.suggestion,
    required this.onUse,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Suggestion IA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Suggestion
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Autre suggestion'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUse,
                    icon: const Icon(Icons.send),
                    label: const Text('Utiliser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            // Disclaimer
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cette suggestion est générée par IA. '
              'Personnalisez-la selon votre style.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MessageModerationIndicator extends StatelessWidget {
  final bool isBlocked;
  final bool needsReview;
  final String? blockedReason;

  const MessageModerationIndicator({
    super.key,
    required this.isBlocked,
    required this.needsReview,
    this.blockedReason,
  });

  @override
  Widget build(BuildContext context) {
    if (isBlocked) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red[600], size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message bloqué',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (blockedReason != null)
                    Text(
                      blockedReason!,
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (needsReview) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 12, color: Colors.orange[800]),
            const SizedBox(width: 2),
            Text(
              'En révision',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
}

// Providers
@riverpod
Future<bool> consentCheck(ConsentCheckRef ref, String userId, String purpose) async {
  final repository = PrivacyRepository();
  return await repository.checkConsent(userId, purpose);
}
