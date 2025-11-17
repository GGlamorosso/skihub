import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../privacy/repositories/privacy_repository.dart';
import '../../../core/services/analytics_service.dart';

part 'ai_chat_service.g.dart';

class AIChatService {
  final PrivacyRepository _privacyRepository;
  final AnalyticsService _analytics = AnalyticsService();

  AIChatService(this._privacyRepository);

  // Get AI icebreaker suggestion
  Future<AISuggestionResult> getIcebreaker({
    required String userId,
    required String matchId,
    String contextType = 'first_message',
  }) async {
    try {
      // Check AI assistance consent
      final hasConsent = await _privacyRepository.checkConsent(userId, 'ai_assistance');
      if (!hasConsent) {
        return AISuggestionResult(
          success: false,
          error: 'Consentement IA requis',
          needsConsent: true,
        );
      }

      final suggestion = await _privacyRepository.getAIIcebreaker(
        userId: userId,
        matchId: matchId,
        contextType: contextType,
      );

      _analytics.track('ai_icebreaker_generated', {
        'match_id': matchId,
        'context_type': contextType,
        'suggestion_length': suggestion.length,
      });

      return AISuggestionResult(
        success: true,
        suggestion: suggestion,
        interactionId: _generateInteractionId(), // Would come from backend
      );
    } catch (e) {
      _analytics.track('ai_icebreaker_failed', {
        'error': e.toString(),
      });
      
      return AISuggestionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Mark suggestion as used
  Future<void> markSuggestionUsed(String interactionId, String suggestion) async {
    try {
      await _privacyRepository.markAIInteractionUsed(interactionId);
      
      _analytics.track('ai_suggestion_used', {
        'interaction_id': interactionId,
        'suggestion_length': suggestion.length,
      });
    } catch (e) {
      debugPrint('Error marking suggestion as used: $e');
    }
  }

  // Rate AI suggestion
  Future<void> rateSuggestion({
    required String interactionId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _privacyRepository.rateAIInteraction(
        interactionId: interactionId,
        rating: rating,
        feedback: feedback,
      );
      
      _analytics.track('ai_suggestion_rated', {
        'interaction_id': interactionId,
        'rating': rating,
        'has_feedback': feedback != null,
      });
    } catch (e) {
      debugPrint('Error rating suggestion: $e');
    }
  }

  // Get conversation starters based on profile compatibility
  List<String> getConversationStarters({
    required Map<String, dynamic> otherUserProfile,
    required Map<String, dynamic> currentUserProfile,
  }) {
    final starters = <String>[];

    // Level-based starters
    final otherLevel = otherUserProfile['level'] as String?;
    final currentLevel = currentUserProfile['level'] as String?;

    if (otherLevel == currentLevel) {
      switch (otherLevel) {
        case 'beginner':
          starters.add('Salut ! Débutant aussi ? Ça pourrait être sympa d\'apprendre ensemble !');
          break;
        case 'intermediate':
          starters.add('Hello ! On a l\'air d\'avoir le même niveau. Ça te dit qu\'on se fasse quelques descentes ?');
          break;
        case 'advanced':
          starters.add('Salut ! Je vois qu\'on est tous les deux avancés. Tu cherches un buddy pour les pistes rouges ?');
          break;
        case 'expert':
          starters.add('Hey ! Expert aussi ? Tu connais les bonnes pistes hors-piste par ici ?');
          break;
      }
    }

    // Ride style-based starters
    final otherStyles = (otherUserProfile['ride_styles'] as List?)?.cast<String>() ?? [];
    final currentStyles = (currentUserProfile['ride_styles'] as List?)?.cast<String>() ?? [];
    final commonStyles = otherStyles.where(currentStyles.contains).toList();

    if (commonStyles.contains('freestyle')) {
      starters.add('Salut ! Je vois qu\'on aime tous les deux le freestyle. Tu fréquentes souvent le snowpark ?');
    }
    if (commonStyles.contains('freeride')) {
      starters.add('Hey ! Freeride passion aussi ? Tu connais les bons spots powder ?');
    }
    if (commonStyles.contains('touring')) {
      starters.add('Hello ! Ski de rando aussi ? Tu as prévu des sorties cette saison ?');
    }

    // Language-based starters
    final otherLanguages = (otherUserProfile['languages'] as List?)?.cast<String>() ?? [];
    final commonLanguages = otherLanguages.where((lang) => 
        (currentUserProfile['languages'] as List?)?.contains(lang) ?? false).toList();

    if (commonLanguages.length > 1) {
      starters.add('Salut ! Je vois qu\'on parle les mêmes langues. D\'où viens-tu ?');
    }

    // Station-based starters
    final stationName = otherUserProfile['current_station'] as String?;
    if (stationName != null) {
      starters.addAll([
        'Salut ! Je vois qu\'on est tous les deux à $stationName. Tu y es pour combien de temps ?',
        'Hello ! $stationName est magnifique en ce moment. Tu as testé le nouveau télésiège ?',
        'Hey ! Tu connais les bons spots pour le lunch à $stationName ?',
      ]);
    }

    // Weather/seasonal starters
    starters.addAll([
      'Salut ! La neige a l\'air parfaite aujourd\'hui. Tu vas profiter des pistes ?',
      'Hello ! Cette météo de rêve me donne envie de sortir. Et toi ?',
      'Hey ! J\'espère que tu profites bien de cette poudreuse ⛷️',
    ]);

    // If no specific starters, add general ones
    if (starters.isEmpty) {
      starters.addAll([
        'Salut ! Super qu\'on se soit match. Comment ça va ?',
        'Hello ! Content qu\'on ait matché. Tu skies depuis longtemps ?',
        'Hey ! Sympa ce match ! Tu as prévu quoi comme sorties ?',
      ]);
    }

    return starters..shuffle();
  }

  String _generateInteractionId() {
    // This would typically come from the backend response
    // For now, generate a temporary ID
    return 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class AISuggestionResult {
  final bool success;
  final String? suggestion;
  final String? interactionId;
  final String? error;
  final bool needsConsent;

  AISuggestionResult({
    required this.success,
    this.suggestion,
    this.interactionId,
    this.error,
    this.needsConsent = false,
  });
}

class MessageModerationService {
  final AnalyticsService _analytics = AnalyticsService();

  // Pre-send message filtering
  Future<MessageModerationResult> checkMessage({
    required String userId,
    required String content,
    required String matchId,
  }) async {
    try {
      // This would call the ai-message-filter Edge Function
      // For now, implement basic client-side checks
      
      final result = await _basicContentCheck(content);
      
      _analytics.track('message_moderation_check', {
        'content_length': content.length,
        'is_safe': result.isSafe,
        'needs_review': result.needsReview,
      });

      return result;
    } catch (e) {
      debugPrint('Message moderation error: $e');
      // On error, allow message
      return MessageModerationResult(
        isSafe: true,
        isBlocked: false,
        needsReview: false,
        confidenceScore: 0.0,
      );
    }
  }

  // Basic client-side content check
  Future<MessageModerationResult> _basicContentCheck(String content) async {
    final lowerContent = content.toLowerCase();
    
    // Check for obvious inappropriate content
    final blockedKeywords = [
      // Personal info sharing
      'whatsapp', 'instagram', 'snapchat', 'telegram',
      'phone', 'number', '@', '.com',
      // Inappropriate content
      'sex', 'nude', 'naked',
      // Spam/scam
      'money', 'bitcoin', 'crypto', 'investment',
    ];

    final hasBlocked = blockedKeywords.any((keyword) => lowerContent.contains(keyword));
    
    // Check for ALL CAPS (potential shouting)
    final capsRatio = content.replaceAll(RegExp(r'[^A-Z]'), '').length / content.length;
    final tooMuchCaps = capsRatio > 0.7 && content.length > 10;

    // Check for excessive punctuation
    final punctuationRatio = content.replaceAll(RegExp(r'[^!?.]'), '').length / content.length;
    final excessivePunctuation = punctuationRatio > 0.3;

    final needsReview = tooMuchCaps || excessivePunctuation;
    
    return MessageModerationResult(
      isSafe: !hasBlocked && !needsReview,
      isBlocked: hasBlocked,
      needsReview: needsReview && !hasBlocked,
      confidenceScore: hasBlocked ? 0.9 : (needsReview ? 0.6 : 0.1),
      blockedReason: hasBlocked ? 'Contenu potentiellement inapproprié détecté' : null,
      suggestedReplacement: hasBlocked ? _getSuggestionReplacement(content) : null,
    );
  }

  String? _getSuggestionReplacement(String content) {
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('whatsapp') || lowerContent.contains('instagram')) {
      return 'Continuons notre conversation ici avant d\'échanger nos coordonnées !';
    }
    if (lowerContent.contains('sex') || lowerContent.contains('nude')) {
      return 'J\'aimerais mieux vous connaître d\'abord !';
    }
    if (lowerContent.contains('money') || lowerContent.contains('bitcoin')) {
      return 'Parlons plutôt de nos passions communes !';
    }
    
    return 'Que diriez-vous de parler de ski à la place ?';
  }
}

class MessageModerationResult {
  final bool isSafe;
  final bool isBlocked;
  final bool needsReview;
  final double confidenceScore;
  final String? blockedReason;
  final String? suggestedReplacement;

  MessageModerationResult({
    required this.isSafe,
    required this.isBlocked,
    required this.needsReview,
    required this.confidenceScore,
    this.blockedReason,
    this.suggestedReplacement,
  });
}

// Riverpod providers
@riverpod
AIChatService aiChatService(AiChatServiceRef ref) {
  return AIChatService(PrivacyRepository());
}

@riverpod
MessageModerationService messageModerationService(MessageModerationServiceRef ref) {
  return MessageModerationService();
}
