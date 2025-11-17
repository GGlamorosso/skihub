import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/ai_chat_service.dart';
import 'ai_assistant_button.dart';
import 'enhanced_message_bubble.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class EnhancedChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String otherUserId;
  final String otherUsername;

  const EnhancedChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showAISuggestion = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUsername),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showChatOptions(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.when(
              data: (messagesList) => _buildMessagesList(messagesList),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
            ),
          ),
          
          // AI suggestion banner (if available)
          if (_showAISuggestion) _buildAISuggestionBanner(),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Dites bonjour !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Commencez la conversation avec ${widget.otherUsername}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _getAISuggestion(),
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Demander une suggestion IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == 'current-user-id'; // Get from auth
        
        return EnhancedMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          currentUserId: 'current-user-id',
        );
      },
    );
  }

  Widget _buildAISuggestionBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.blue[600]),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'L\'IA peut vous aider à briser la glace !',
              style: TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _getAISuggestion,
            child: const Text('Essayer'),
          ),
          IconButton(
            onPressed: () => setState(() => _showAISuggestion = false),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // AI Assistant button
            AIAssistantButton(
              userId: 'current-user-id',
              matchId: widget.matchId,
              messageController: _messageController,
              onSuggestionUsed: () => _focusInput(),
            ),
            
            // Message input
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tapez votre message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            
            // Send button
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Check content moderation first
      final moderationService = ref.read(messageModerationServiceProvider);
      final moderationResult = await moderationService.checkMessage(
        userId: 'current-user-id',
        content: content,
        matchId: widget.matchId,
      );

      if (moderationResult.isBlocked) {
        _showModerationDialog(moderationResult);
        return;
      }

      // Clear input immediately for better UX
      _messageController.clear();

      // Send message (this would call your enhanced message service)
      // For now, just simulate success
      await Future.delayed(const Duration(seconds: 1));

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Update AI suggestion banner visibility
      if (_showAISuggestion) {
        setState(() => _showAISuggestion = false);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showModerationDialog(MessageModerationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: AppSpacing.sm),
            Text('Message bloqué'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.blockedReason != null) ...[
              Text('Raison: ${result.blockedReason}'),
              const SizedBox(height: AppSpacing.md),
            ],
            if (result.suggestedReplacement != null) ...[
              const Text(
                'Suggestion:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(result.suggestedReplacement!),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Modifier'),
          ),
          if (result.suggestedReplacement != null)
            ElevatedButton(
              onPressed: () {
                _messageController.text = result.suggestedReplacement!;
                Navigator.of(context).pop();
              },
              child: const Text('Utiliser la suggestion'),
            ),
        ],
      ),
    );
  }

  Future<void> _getAISuggestion() async {
    try {
      final aiChatService = ref.read(aiChatServiceProvider);
      final result = await aiChatService.getIcebreaker(
        userId: 'current-user-id',
        matchId: widget.matchId,
        contextType: _messageController.text.isEmpty ? 'first_message' : 'follow_up',
      );

      if (!result.success) {
        if (result.needsConsent) {
          _showConsentDialog();
        } else {
          _showError(result.error ?? 'Erreur IA');
        }
        return;
      }

      if (result.suggestion != null && mounted) {
        _showSuggestionDialog(result.suggestion!, result.interactionId);
      }
    } catch (e) {
      _showError('Erreur lors de la génération: $e');
    }
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assistant IA'),
        content: const Text(
          'L\'assistant IA peut vous aider avec des suggestions de messages personnalisées.\n\n'
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
              // Grant AI consent and retry
              // This would be handled by privacy service
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDialog(String suggestion, String? interactionId) {
    showDialog(
      context: context,
      builder: (context) => AISuggestionModal(
        suggestion: suggestion,
        onUse: () {
          _messageController.text = suggestion;
          if (interactionId != null) {
            ref.read(aiChatServiceProvider).markSuggestionUsed(interactionId, suggestion);
          }
          _focusInput();
          Navigator.of(context).pop();
        },
        onRegenerate: () {
          Navigator.of(context).pop();
          _getAISuggestion();
        },
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Signaler/Bloquer'),
              onTap: () {
                Navigator.of(context).pop();
                _reportUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Couper les notifications'),
              onTap: () {
                Navigator.of(context).pop();
                _muteConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Supprimer la conversation'),
              onTap: () {
                Navigator.of(context).pop();
                _deleteConversation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cet utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pourquoi signalez-vous cet utilisateur ?'),
            const SizedBox(height: AppSpacing.md),
            ...[
              'Contenu inapproprié',
              'Harcèlement',
              'Spam ou arnaque',
              'Faux profil',
              'Autre',
            ].map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: null, // Would be managed by state
              onChanged: (value) {
                // Handle report reason selection
              },
            )),
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
              _submitReport();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  void _submitReport() {
    // This would submit a user report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Utilisateur signalé. Merci pour votre vigilance.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _muteConversation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications désactivées pour cette conversation'),
      ),
    );
  }

  void _deleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text(
          'Cette action supprimera tous les messages de cette conversation. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to matches list
              _performDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _performDelete() {
    // This would delete the conversation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation supprimée'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _focusInput() {
    FocusScope.of(context).requestFocus();
  }

  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Mock providers - these would be real implementations
final chatMessagesProvider = FutureProvider.family<List<Message>, String>((ref, matchId) async {
  // This would fetch actual messages
  return <Message>[];
});

// Mock Message model
class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final bool isBlocked;
  final bool needsReview;
  final String? blockedReason;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.isBlocked = false,
    this.needsReview = false,
    this.blockedReason,
    this.isRead = false,
    required this.createdAt,
  });
}
