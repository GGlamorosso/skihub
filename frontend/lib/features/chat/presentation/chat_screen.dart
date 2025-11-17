import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../router/app_router.dart';
import '../../../models/match.dart';
import '../../../services/supabase_service.dart';
import '../controllers/chat_controller.dart';
import '../controllers/matches_controller.dart';

/// Écran de conversation
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
  });
  
  final String matchId;
  
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    // Setup scroll pour charger plus de messages
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreMessages();
      }
    });
    
    // Auto-scroll vers le bas quand nouveaux messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
  
  void _loadMoreMessages() {
    final chatState = ref.read(chatControllerProvider(widget.matchId));
    if (chatState.canLoadMore) {
      ref.read(chatControllerProvider(widget.matchId).notifier).loadMoreMessages();
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider(widget.matchId));
    final match = chatState.match;
    
    // Écouter nouveaux messages pour auto-scroll
    ref.listen<ChatState>(chatControllerProvider(widget.matchId), (previous, current) {
      if (current.messages.length > (previous?.messages.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(match, chatState.realtimeConnected),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _buildMessagesList(chatState),
          ),
          
          // Input message
          _buildMessageInput(chatState),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(Match? match, bool realtimeConnected) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.matches);
          }
        },
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
      ),
      title: match?.otherUser != null
        ? Row(
            children: [
              // Photo mini
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: ClipOval(
                  child: match!.otherUserPhotoUrl != null
                    ? Image.network(
                        match.otherUserPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 20);
                        },
                      )
                    : const Icon(Icons.person, size: 20),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Nom + statut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.otherUser!.username,
                      style: AppTypography.bodyBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: realtimeConnected 
                              ? AppColors.success 
                              : AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          realtimeConnected ? 'En ligne' : 'Hors ligne',
                          style: AppTypography.small.copyWith(
                            color: realtimeConnected 
                              ? AppColors.success 
                              : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : Text('Conversation', style: AppTypography.h3),
      actions: [
        // Menu options
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Voir le profil', style: AppTypography.body),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  const Icon(Icons.block, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Bloquer', style: AppTypography.body),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Supprimer', style: AppTypography.body),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleMenuAction(value, match),
        ),
      ],
    );
  }
  
  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }
    
    if (chatState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(chatState.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(chatControllerProvider(widget.matchId).notifier).refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (!chatState.hasMessages) {
      return _buildEmptyChat();
    }
    
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Messages récents en bas
      padding: const EdgeInsets.all(16),
      itemCount: chatState.messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator en haut
        if (index >= chatState.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            ),
          );
        }
        
        final messageIndex = chatState.messages.length - 1 - index;
        final message = chatState.messages[messageIndex];
        final isFromMe = message.isFromCurrentUser(SupabaseService.instance.currentUserId!);
        
        // Grouper messages du même sender
        final showAvatar = _shouldShowAvatar(chatState.messages, messageIndex, isFromMe);
        final showTime = _shouldShowTime(chatState.messages, messageIndex);
        
        return _buildMessageBubble(
          message: message,
          isFromMe: isFromMe,
          showAvatar: showAvatar,
          showTime: showTime,
        );
      },
    );
  }
  
  Widget _buildMessageBubble({
    required Message message,
    required bool isFromMe,
    required bool showAvatar,
    required bool showTime,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar autre utilisateur
          if (!isFromMe) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              child: showAvatar
                ? Container(
                    decoration: const BoxDecoration(
                      color: AppColors.inputBorder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const SizedBox(),
            ),
          ],
          
          // Bulle message
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe 
                  ? AppColors.primaryPink 
                  : AppColors.inputBorder.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isFromMe ? 20 : 4),
                  bottomRight: Radius.circular(isFromMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenu message
                  Text(
                    message.content,
                    style: AppTypography.body.copyWith(
                      color: isFromMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  
                  // Heure + statut
                  if (showTime) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.timeDisplay,
                          style: AppTypography.small.copyWith(
                            color: isFromMe 
                              ? Colors.white70 
                              : AppColors.textSecondary,
                          ),
                        ),
                        
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.statusIcon,
                            size: 12,
                            color: message.statusColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Espace pour équilibrer si message de moi
          if (isFromMe) const SizedBox(width: 40),
        ],
      ),
    );
  }
  
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat,
            size: 64,
            color: AppColors.primaryPink,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Nouveau match ! 🎉',
            style: AppTypography.h3,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Dites-vous bonjour et planifiez votre session de ski !',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          
          const SizedBox(height: 24),
          
          // Messages suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Salut ! 👋'),
              _buildSuggestionChip('Prêt pour les pistes ? 🎿'),
              _buildSuggestionChip('Quel est ton spot préféré ?'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _messageFocusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryPink),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: AppColors.primaryPink,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageInput(ChatState chatState) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.inputBorder),
        ),
      ),
      child: Row(
        children: [
          // Champ texte
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Écrivez votre message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: AppTypography.body,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                onChanged: (text) {
                  // TODO S4: Indicateur typing
                  setState(() {});
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Bouton envoi
          GestureDetector(
            onTap: chatState.isSending || _messageController.text.trim().isEmpty
              ? null
              : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _messageController.text.trim().isNotEmpty
                  ? AppColors.buttonGradient
                  : null,
                color: _messageController.text.trim().isEmpty
                  ? AppColors.textSecondary.withOpacity(0.3)
                  : null,
                shape: BoxShape.circle,
              ),
              child: chatState.isSending
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _shouldShowAvatar(List<Message> messages, int index, bool isFromMe) {
    if (isFromMe) return false; // Pas d'avatar pour mes messages
    
    // Montrer avatar si c'est le dernier message du sender ou si sender change
    if (index == messages.length - 1) return true;
    
    final nextMessage = messages[index + 1];
    return nextMessage.senderId != messages[index].senderId;
  }
  
  bool _shouldShowTime(List<Message> messages, int index) {
    if (index == messages.length - 1) return true; // Dernier message
    
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    
    // Montrer heure si plus de 5 minutes d'écart
    return nextMessage.createdAt.difference(currentMessage.createdAt).inMinutes > 5;
  }
  
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    // Clear input immédiatement
    _messageController.clear();
    
    final success = await ref
        .read(chatControllerProvider(widget.matchId).notifier)
        .sendMessage(content);
    
    if (success) {
      // Auto-scroll vers nouveau message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      // Restaurer message en cas d'erreur
      _messageController.text = content;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer le message'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _handleMenuAction(String action, Match? match) {
    switch (action) {
      case 'profile':
        // TODO S4: Navigation vers profil autre utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil utilisateur S4')),
        );
        break;
        
      case 'block':
        _showBlockConfirmation(match);
        break;
        
      case 'delete':
        _showDeleteConfirmation(match);
        break;
    }
  }
  
  void _showBlockConfirmation(Match? match) {
    if (match == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer cet utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir bloquer ${match.otherUser?.username} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockMatch(match.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(Match? match) {
    if (match == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette conversation'),
        content: const Text(
          'Cette conversation sera supprimée définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMatch(match.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _blockMatch(String matchId) async {
    await ref.read(matchesControllerProvider.notifier).blockMatch(matchId);
    if (context.canPop()) {
      context.pop(); // Retour à la liste matches
    } else {
      context.go(AppRoutes.matches);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Utilisateur bloqué'),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  Future<void> _deleteMatch(String matchId) async {
    await ref.read(matchesControllerProvider.notifier).deleteMatch(matchId);
    if (context.canPop()) {
      context.pop(); // Retour à la liste matches
    } else {
      context.go(AppRoutes.matches);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation supprimée'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
