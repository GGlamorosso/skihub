import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/beta_feedback.dart';
import '../../core/services/analytics_service.dart';
import '../../core/config/app_config.dart';

part 'feedback_service.g.dart';

class FeedbackService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AnalyticsService _analytics = AnalyticsService();

  // Submit detailed feedback
  Future<BetaFeedback> submitFeedback({
    required String userId,
    required String subject,
    required String description,
    required FeedbackCategory category,
    int? rating,
    String? screenshotUrl,
  }) async {
    try {
      // Get device info
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      final response = await _supabase.functions.invoke(
        'submit-beta-feedback',
        body: {
          'user_id': userId,
          'subject': subject,
          'description': description,
          'category': category.value,
          'rating': rating,
          'app_version': packageInfo.version,
          'device_info': deviceInfo,
          'screenshot_url': screenshotUrl,
        },
      );

      if (response.error != null) {
        throw Exception('Failed to submit feedback: ${response.error}');
      }

      final feedbackData = response.data;
      final feedback = BetaFeedback.fromJson({
        ...feedbackData,
        'category': category,
        'status': FeedbackStatus.fromString(feedbackData['status']),
        'priority': FeedbackPriority.fromString(feedbackData['priority']),
        'created_at': feedbackData['created_at'],
        'updated_at': feedbackData['updated_at'],
      });

      // Track analytics
      _analytics.track('beta_feedback_submitted', {
        'category': category.value,
        'has_rating': rating != null,
        'has_screenshot': screenshotUrl != null,
        'description_length': description.length,
      });

      return feedback;
    } catch (e) {
      _analytics.track('beta_feedback_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  // Submit quick feedback (thumbs up/down)
  Future<void> logQuickFeedback({
    required String userId,
    required bool positive,
    required String context,
  }) async {
    try {
      await _supabase.functions.invoke(
        'log-quick-feedback',
        body: {
          'user_id': userId,
          'positive': positive,
          'context': context,
          'session_id': 'current-session-id', // Get from session manager
          'device_info': await _getDeviceInfo(),
        },
      );

      _analytics.track('quick_feedback_given', {
        'positive': positive,
        'context': context,
      });
    } catch (e) {
      debugPrint('Quick feedback error: $e');
    }
  }

  // Upload screenshot
  Future<String> uploadScreenshot(String userId, File imageFile) async {
    try {
      final fileName = 'feedback_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/screenshots/$fileName';

      final response = await _supabase.storage
          .from('feedback_attachments')
          .upload(path, imageFile);

      if (response.error != null) {
        throw Exception('Screenshot upload failed: ${response.error!.message}');
      }

      return path;
    } catch (e) {
      throw Exception('Failed to upload screenshot: $e');
    }
  }

  // Get user feedback history
  Future<List<BetaFeedback>> getUserFeedback(String userId) async {
    try {
      final response = await _supabase
          .from('beta_feedback')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => BetaFeedback.fromJson({
        ...json,
        'category': FeedbackCategory.fromString(json['category']),
        'status': FeedbackStatus.fromString(json['status']),
        'priority': FeedbackPriority.fromString(json['priority']),
        'created_at': json['created_at'],
        'updated_at': json['updated_at'],
        'processed_at': json['processed_at'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to get user feedback: $e');
    }
  }

  // Get feedback metrics for admin
  Future<FeedbackMetrics> getFeedbackMetrics() async {
    try {
      final response = await _supabase.functions.invoke(
        'get-feedback-metrics',
        body: {},
      );

      if (response.error != null) {
        throw Exception('Failed to get metrics: ${response.error}');
      }

      return FeedbackMetrics.fromJson({
        ...response.data,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to get feedback metrics: $e');
    }
  }

  // Check if user should see quick feedback prompt
  Future<bool> shouldShowQuickFeedback(String userId) async {
    try {
      // Check if user has given feedback recently
      final recentFeedback = await _supabase
          .from('beta_feedback')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .limit(1);

      // Also check quick feedback
      final recentQuickFeedback = await _supabase
          .from('quick_feedback') 
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 3)).toIso8601String())
          .limit(1);

      return recentFeedback.isEmpty && recentQuickFeedback.isEmpty;
    } catch (e) {
      return false; // Don't show on error
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'device': androidInfo.device,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'system_version': iosInfo.systemVersion,
          'name': iosInfo.name,
          'identifier_for_vendor': iosInfo.identifierForVendor,
        };
      } else {
        return {
          'platform': 'unknown',
        };
      }
    } catch (e) {
      return {
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }
}

// Riverpod providers
@riverpod
FeedbackService feedbackService(FeedbackServiceRef ref) {
  return FeedbackService();
}

@riverpod
class UserFeedbackHistory extends _$UserFeedbackHistory {
  @override
  AsyncValue<List<BetaFeedback>> build(String userId) {
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(feedbackServiceProvider);
      final feedback = await service.getUserFeedback(userId);
      state = AsyncValue.data(feedback);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> submitFeedback({
    required String subject,
    required String description,
    required FeedbackCategory category,
    int? rating,
    String? screenshotUrl,
  }) async {
    try {
      final service = ref.read(feedbackServiceProvider);
      await service.submitFeedback(
        userId: userId,
        subject: subject,
        description: description,
        category: category,
        rating: rating,
        screenshotUrl: screenshotUrl,
      );
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

@riverpod
class QuickFeedbackState extends _$QuickFeedbackState {
  @override
  bool build(String userId) {
    _checkIfShouldShow();
    return false; // Default to not showing
  }

  Future<void> _checkIfShouldShow() async {
    try {
      final service = ref.read(feedbackServiceProvider);
      final shouldShow = await service.shouldShowQuickFeedback(userId);
      state = shouldShow;
    } catch (e) {
      state = false;
    }
  }

  void markAsShown() {
    state = false;
  }

  void reset() {
    state = true;
  }
}
