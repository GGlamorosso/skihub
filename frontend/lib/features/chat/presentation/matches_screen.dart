import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../components/bottom_navigation.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/match.dart';
import '../../../services/supabase_service.dart';
import '../controllers/matches_controller.dart';

/// Écran liste des matches
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});
  
  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Setup infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMatches();
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadMoreMatches() {
    final matchesState = ref.read(matchesControllerProvider);
    if (matchesState.hasMoreMatches && !matchesState.isLoadingMore) {
      ref.read(matchesControllerProvider.notifier).loadMatches();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final matchesState = ref.watch(matchesControllerProvider);
    
    return AppScaffold(
      currentIndex: 1, // Matches = index 1
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(matchesState.totalUnreadCount),
            
            // Contenu principal
            Expanded(
              child: _buildMatchesList(matchesState),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Matches',
            style: AppTypography.h1,
          ),
          
          if (unreadCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: AppTypography.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          
          const Spacer(),
          
          // Bouton refresh
          IconButton(
            onPressed: () => ref.read(matchesControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: AppColors.primaryPink),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMatchesList(MatchesState matchesState) {
    if (matchesState.isLoading) {
      return _buildLoadingState();
    }
    
    if (matchesState.hasError) {
      return _buildErrorState(matchesState.error!);
    }
    
    if (!matchesState.hasMatches) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () => ref.read(matchesControllerProvider.notifier).refresh(),
      color: AppColors.primaryPink,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: matchesState.matches.length + (matchesState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator en bas
          if (index >= matchesState.matches.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryPink),
              ),
            );
          }
          
          final match = matchesState.matches[index];
          final photoUrl = matchesState.photoUrls[match.getOtherUserId(SupabaseService.instance.currentUserId!)];
          
          return _buildMatchTile(match, photoUrl);
        },
      ),
    );
  }
  
  Widget _buildMatchTile(Match match, String? photoUrl) {
    final otherUser = match.otherUser;
    if (otherUser == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(match),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: match.hasUnreadMessages
                ? Border.all(color: AppColors.primaryPink, width: 2)
                : null,
              boxShadow: [
                if (match.hasUnreadMessages) 
                  AppColors.primaryShadow
                else
                  AppColors.cardShadow,
              ],
            ),
            child: Row(
              children: [
                // Photo profil
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: match.hasUnreadMessages 
                            ? AppColors.primaryPink 
                            : AppColors.inputBorder,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.inputBorder,
                                child: const Icon(Icons.person, color: AppColors.textSecondary),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.inputBorder,
                                child: const Icon(Icons.person, color: AppColors.textSecondary),
                              ),
                            )
                          : Container(
                              color: AppColors.inputBorder,
                              child: const Icon(Icons.person, color: AppColors.textSecondary),
                            ),
                      ),
                    ),
                    
                    // Badge nouveau match
                    if (match.isRecent)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Infos conversation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom + niveau
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUser.username,
                              style: AppTypography.bodyBold.copyWith(
                                color: match.hasUnreadMessages 
                                  ? AppColors.primaryPink 
                                  : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            otherUser.level.displayName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Preview dernier message
                      Text(
                        match.messagePreview,
                        style: AppTypography.body.copyWith(
                          color: match.hasUnreadMessages 
                            ? AppColors.textPrimary 
                            : AppColors.textSecondary,
                          fontWeight: match.hasUnreadMessages 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Time + badge unread
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.lastActivityDisplay,
                      style: AppTypography.small.copyWith(
                        color: match.hasUnreadMessages 
                          ? AppColors.primaryPink 
                          : AppColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    if (match.hasUnreadMessages)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          match.unreadBadge,
                          style: AppTypography.small.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryPink),
          SizedBox(height: 16),
          Text('Chargement des conversations...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Réessayer',
            onPressed: () => ref.read(matchesControllerProvider.notifier).refresh(),
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          
          Text(
            'Aucun match pour le moment',
            style: AppTypography.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Retourne sur le feed pour trouver ton crew !',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          
          const SizedBox(height: 32),
          
          PrimaryButton(
            text: 'Découvrir des profils',
            icon: Icons.explore,
            onPressed: () => context.go('/feed'),
            width: 250,
          ),
        ],
      ),
    );
  }
  
  void _openChat(Match match) {
    // Marquer comme lu immédiatement
    ref.read(matchesControllerProvider.notifier).markMatchAsRead(match.id);
    
    // Navigation vers chat
    context.go('/chat/${match.id}');
  }
}
