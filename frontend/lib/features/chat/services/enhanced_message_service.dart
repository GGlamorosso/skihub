import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../premium/services/quota_manager.dart';
import '../../premium/models/subscription.dart';
import '../../../core/services/supabase_service.dart';

class EnhancedMessageService {
  final SupabaseClient _supabase = SupabaseService.client;

  // Enhanced send message with quota checking
  Future<MessageResult> sendMessageWithQuota({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String matchId,
    required String content,
  }) async {
    try {
      // Check quota first
      final canMessage = await QuotaManager.checkMessageQuota(
        context: context,
        ref: ref,
        userId: userId,
        matchId: matchId,
      );

      if (!canMessage) {
        return MessageResult(
          success: false,
          quotaLimited: true,
          message: 'Limite de messages quotidiens atteinte',
        );
      }

      // Send the message
      final response = await _supabase
          .from('messages')
          .insert({
            'match_id': matchId,
            'sender_id': userId,
            'content': content,
            'message_type': 'text',
          })
          .select()
          .single();

      // Update quota after successful send
      final quotaService = ref.read(quotaServiceProvider);
      final quotaResult = await quotaService.checkActionQuota(userId, 'message');
      ref.read(userQuotaStateProvider(userId).notifier).updateQuota(quotaResult.quotaInfo);

      return MessageResult(
        success: true,
        quotaLimited: false,
        messageId: response['id'],
        quotaInfo: quotaResult.quotaInfo,
      );
    } catch (e) {
      debugPrint('Enhanced message send error: $e');
      return MessageResult(
        success: false,
        quotaLimited: false,
        message: 'Erreur lors de l\'envoi: $e',
      );
    }
  }

  // Get messages with premium features
  Future<List<Map<String, dynamic>>> getMessages({
    required String matchId,
    required String userId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      var query = _supabase
          .from('messages')
          .select('''
            *,
            sender:users!inner(id, username)
          ''')
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (beforeMessageId != null) {
        query = query.lt('created_at', beforeMessageId);
      }

      final response = await query;
      
      // Check if user has premium for read receipts
      final isPremium = await _checkUserPremium(userId);
      
      if (isPremium) {
        // Mark messages as read for premium users
        await _supabase
            .from('messages')
            .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
            .eq('match_id', matchId)
            .neq('sender_id', userId);
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting messages: $e');
      rethrow;
    }
  }

  // Mark message as read (premium feature)
  Future<void> markAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      final isPremium = await _checkUserPremium(userId);
      if (!isPremium) return; // Only premium users get read receipts

      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Future<bool> _checkUserPremium(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_premium, premium_expires_at')
          .eq('id', userId)
          .single();

      final isPremium = response['is_premium'] as bool? ?? false;
      final expiresAt = response['premium_expires_at'] as String?;

      if (!isPremium) return false;
      if (expiresAt == null) return true;

      return DateTime.parse(expiresAt).isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}

class MessageResult {
  final bool success;
  final bool quotaLimited;
  final String? message;
  final String? messageId;
  final QuotaInfo? quotaInfo;

  MessageResult({
    required this.success,
    required this.quotaLimited,
    this.message,
    this.messageId,
    this.quotaInfo,
  });
}
