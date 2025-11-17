import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../../privacy/models/consent.dart';
import 'ai_assistant_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class EnhancedMessageBubble extends ConsumerWidget {
  final Message message;
  final bool isCurrentUser;
  final String currentUserId;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isBlocked) {
      return _buildBlockedMessage(context);
    }

    return _buildNormalMessage(context);
  }

  Widget _buildNormalMessage(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppColors.primary 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isCurrentUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                  bottomLeft: isCurrentUser 
                      ? const Radius.circular(18) 
                      : const Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  
                  // AI moderation indicators
                  if (message.needsReview)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 12,
                            color: isCurrentUser ? Colors.white70 : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'En révision',
                            style: TextStyle(
                              fontSize: 10,
                              color: isCurrentUser ? Colors.white70 : Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Timestamp and read status
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (isCurrentUser && message.isRead) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 12,
                    color: Colors.blue[600],
                  ),
                ] else if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedMessage(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, color: Colors.red[600], size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        'Message bloqué',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ce message a été bloqué pour non-conformité aux règles de la communauté.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (message.blockedReason != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Raison: ${message.blockedReason}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  // Appeal button for sender
                  if (isCurrentUser) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _appealBlock(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          side: BorderSide(color: Colors.red[400]!),
                        ),
                        child: const Text(
                          'Contester',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Timestamp
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _appealBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contester le blocage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Votre message a été bloqué automatiquement. '
              'Si vous pensez que c\'est une erreur, vous pouvez demander une révision manuelle.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Explication (optionnel)',
                hintText: 'Pourquoi ce message devrait être autorisé?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitAppeal();
            },
            child: const Text('Demander une révision'),
          ),
        ],
      ),
    );
  }

  void _submitAppeal() {
    // This would submit an appeal request
    // For now, just show confirmation
    debugPrint('Appeal submitted for message: ${message.id}');
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

class MessageModerationFilter extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String userId;
  final String matchId;
  final Function(String) onMessageFiltered;

  const MessageModerationFilter({
    super.key,
    required this.controller,
    required this.userId,
    required this.matchId,
    required this.onMessageFiltered,
  });

  @override
  ConsumerState<MessageModerationFilter> createState() => _MessageModerationFilterState();
}

class _MessageModerationFilterState extends ConsumerState<MessageModerationFilter> {
  bool _isChecking = false;
  String? _suggestion;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.length > 50) {
      // Start checking for inappropriate content after reasonable length
      _checkContent();
    }
  }

  Future<void> _checkContent() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    try {
      // This would call AI moderation in real implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock inappropriate content detection
      if (widget.controller.text.toLowerCase().contains('inappropriate')) {
        setState(() {
          _suggestion = 'Ce message pourrait être considéré comme inapproprié. '
                      'Voici une suggestion: "J\'aimerais mieux vous connaître !"';
        });
        _showModerationSuggestion();
      }
    } catch (e) {
      debugPrint('Content moderation error: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _showModerationSuggestion() {
    if (_suggestion == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggestion de modération'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, color: Colors.orange, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(_suggestion!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer tel quel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.controller.text = 'J\'aimerais mieux vous connaître !';
              widget.onMessageFiltered(widget.controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Utiliser la suggestion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // This is a logic component, no UI
  }
}
