import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../models/candidate.dart' hide QuotaInfo;
import '../models/subscription.dart' show QuotaInfo, QuotaType;
import '../utils/error_handler.dart';
import 'supabase_service.dart';
import 'quota_service.dart';
import 'tracking_service.dart';

/// Service pour gestion du matching et swipes
class MatchService {
  static MatchService? _instance;
  static MatchService get instance => _instance ??= MatchService._();
  
  MatchService._();
  
  final _supabase = SupabaseService.instance;
  final _quotaService = QuotaService();
  final _trackingService = TrackingService.instance;
  
  /// Récupérer candidats potentiels
  Future<List<Candidate>> fetchCandidates({
    int limit = 10,
    String? cursor,
    SwipeFilters? filters,
  }) async {
    try {
      final body = <String, dynamic>{
        'limit': limit,
      };
      
      if (cursor != null) body['cursor'] = cursor;
      if (filters != null) body.addAll(filters.toApiParams());
      
      // Ajouter la localisation GPS si disponible
      try {
        final position = await _trackingService.getCurrentPosition();
        final fallbackPosition = position ?? _trackingService.lastKnownPosition;
        if (fallbackPosition != null) {
          body['latitude'] = fallbackPosition.latitude;
          body['longitude'] = fallbackPosition.longitude;
          debugPrint('📍 GPS position sent: ${fallbackPosition.latitude}, ${fallbackPosition.longitude}');
        } else {
          debugPrint('⚠️ GPS position not available (no current or last known position)');
        }
      } catch (e) {
        debugPrint('⚠️ Error getting GPS position: $e');
        // Continue sans GPS (l'API peut gérer ça)
      }
      
      final response = await _supabase.callFunction(
        functionName: 'match-candidates',
        body: body,
      );
      
      if (response.status != 200) {
        throw Exception('API Error: ${response.status}');
      }
      
      final data = response.data as Map<String, dynamic>;
      final candidatesJson = data['candidates'] as List? ?? [];
      
      debugPrint('📊 Match-candidates returned ${candidatesJson.length} candidates');
      
      if (candidatesJson.isEmpty) {
        debugPrint('⚠️ No candidates returned - check Edge Function logs');
        debugPrint('   Response data: $data');
      }
      
      // ✅ Convertir snake_case vers camelCase pour correspondre au modèle Candidate
      return candidatesJson.map((json) {
        try {
          final data = json as Map<String, dynamic>;
          
          // Valeurs par défaut pour les dates (maintenant + 7 jours)
          final defaultFrom = DateTime.now();
          final defaultTo = defaultFrom.add(const Duration(days: 7));
          
          final mapped = <String, dynamic>{
            // Mapping des clés SQL vers le modèle Candidate
            'id': data['candidate_id'] ?? data['id'] ?? '',
            'username': data['username'] ?? 'Utilisateur',
            'age': 25, // TODO: Calculer depuis birth_date si disponible
            'level': data['level'] ?? 'beginner',
            'isPremium': data['is_premium'] ?? false,
            'score': (data['compatibility_score'] ?? 0.0) as num,
            'distanceKm': (data['distance_km'] ?? 999.0) as num,
            'photoUrl': data['photo_url'],
            'rideStyles': <dynamic>[], // ✅ Liste vide, pas null
            'languages': <dynamic>[], // ✅ Liste vide, pas null
            'stationName': data['station_name'] ?? 'Non spécifiée',
            'availableFrom': defaultFrom.toIso8601String(), // ✅ Convertir DateTime en String
            'availableTo': defaultTo.toIso8601String(), // ✅ Convertir DateTime en String
            'boostMultiplier': 1.0,
            'bio': data['bio'],
            'maxSpeed': null,
            'isVerified': false,
          };
          
          return Candidate.fromJson(mapped);
        } catch (e, stackTrace) {
          debugPrint('❌ Error mapping candidate: $e');
          debugPrint('   JSON data: $json');
          debugPrint('   Stack trace: $stackTrace');
          // Re-throw pour que l'erreur soit visible
          rethrow;
        }
      }).toList();
    } catch (e) {
      ErrorHandler.logError(
        context: 'MatchService.fetchCandidates',
        error: e,
        additionalData: {
          'limit': limit,
          'cursor': cursor,
          'filters': filters?.toJson(),
        },
      );
      
      throw Exception(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Effectuer un swipe (like/dislike)
  Future<SwipeResult> swipe({
    required String likedId,
    required SwipeDirection direction,
  }) async {
    try {
      // Check quota before swipe (if it's a like)
      if (direction == SwipeDirection.like || direction == SwipeDirection.superLike) {
        final quotaCheck = await _quotaService.checkQuotaForSwipe();
        if (!quotaCheck.isAllowed) {
          return SwipeResult.quotaExceeded(
            quotaInfo: quotaCheck.quotaInfo!,
            message: quotaCheck.message ?? 'Quota exceeded',
          );
        }
      }
      
      final body = {
        'liked_id': likedId,
        'direction': direction.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase.callFunction(
        functionName: 'swipe-enhanced',
        body: body,
      );
      
      if (response.status != 200) {
        throw Exception('Swipe failed: ${response.status}');
      }
      
      final data = response.data as Map<String, dynamic>;
      
      // Parse quota info from response
      final quotaInfo = _quotaService.parseQuotaFromResponse(data);
      
      // Parse match result
      final matchResult = MatchResult.fromJson(data);
      
      return SwipeResult.success(
        matchResult: matchResult,
        quotaInfo: quotaInfo,
      );
    } catch (e) {
      ErrorHandler.logError(
        context: 'MatchService.swipe',
        error: e,
        additionalData: {
          'liked_id': likedId,
          'direction': direction.name,
        },
      );
      
      return SwipeResult.error(ErrorHandler.getReadableError(e));
    }
  }
  
  /// Super like (boost)
  Future<SwipeResult> superLike({
    required String likedId,
  }) async {
    return swipe(likedId: likedId, direction: SwipeDirection.superLike);
  }
  
  /// Récupérer quotas actuels
  Future<QuotaInfo> getCurrentQuotas() async {
    try {
      final response = await _supabase.callFunction(
        functionName: 'gatekeeper',
        body: {'action': 'swipe'}, // Use 'swipe' action to get quota info
      );
      
      if (response.status != 200) {
        throw Exception('Quota check failed: ${response.status}');
      }
      
      final data = response.data;
      
      // Handle null or invalid response
      if (data == null) {
        throw Exception('Gatekeeper returned null response');
      }
      
      // Ensure data is a Map
      if (data is! Map<String, dynamic>) {
        throw Exception('Gatekeeper returned invalid format: ${data.runtimeType}');
      }
      
      // Try to get quotaInfo from response (gatekeeper returns quotaInfo directly)
      final quotaData = data['quotaInfo'] as Map<String, dynamic>?;
      
      if (quotaData != null) {
        return QuotaInfo.fromJson(quotaData);
      }
      
      // Fallback: use QuotaService to get quota info
      return await _quotaService.getQuotaInfo();
    } catch (e) {
      ErrorHandler.logError(
        context: 'MatchService.getCurrentQuotas',
        error: e,
      );
      
      // Retourner quota par défaut en cas d'erreur
      return QuotaInfo(
        swipeRemaining: 20,
        messageRemaining: 50,
        limitReached: false,
        limitType: QuotaType.none,
        dailySwipeLimit: 20,
        dailyMessageLimit: 50,
        resetsAt: DateTime.now().add(const Duration(hours: 24)), // Reset dans 24h par défaut
      );
    }
  }
  
  /// Récupérer profils déjà vus (pour éviter doublons)
  Future<List<String>> getSeenProfileIds() async {
    try {
      // Récupérer likes/dislikes récents pour éviter de re-proposer
      final response = await _supabase.from('likes')
          .select('liked_id')
          .eq('liker_id', _supabase.currentUserId!)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(100);
      
      return (response as List)
          .map((row) => row['liked_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error fetching seen profiles: $e');
      return [];
    }
  }
  
  /// Marquer profil comme vu (cache local)
  final Set<String> _seenProfileIds = {};
  
  void markAsSeen(String profileId) {
    _seenProfileIds.add(profileId);
  }
  
  bool hasBeenSeen(String profileId) {
    return _seenProfileIds.contains(profileId);
  }
  
  void clearSeenProfiles() {
    _seenProfileIds.clear();
  }
  
  /// Pré-charger URLs signées pour photos
  Future<Map<String, String>> preloadPhotoUrls(List<Candidate> candidates) async {
    final Map<String, String> urls = {};
    
    for (final candidate in candidates) {
      if (candidate.photoUrl != null) {
        try {
          final signedUrl = await _supabase.getSignedUrl(
            bucket: 'profile_photos',
            path: candidate.photoUrl!,
            expiresIn: 3600,
          );
          urls[candidate.id] = signedUrl;
        } catch (e) {
          debugPrint('Error preloading photo for ${candidate.id}: $e');
        }
      }
    }
    
    return urls;
  }
  
  /// Récupérer détails profil complet (pour modal détails)
  Future<Candidate?> getCandidateDetails(String candidateId) async {
    try {
      final response = await _supabase.from('public_profiles_v')
          .select()
          .eq('id', candidateId)
          .single();
      
      return Candidate.fromJson(response);
    } catch (e) {
      ErrorHandler.logError(
        context: 'MatchService.getCandidateDetails',
        error: e,
        additionalData: {'candidate_id': candidateId},
      );
      return null;
    }
  }
}

/// Direction du swipe
enum SwipeDirection {
  @JsonValue('dislike')
  dislike,
  
  @JsonValue('like')
  like,
  
  @JsonValue('super_like')
  superLike;
  
  String get displayName {
    switch (this) {
      case SwipeDirection.dislike:
        return 'Pass';
      case SwipeDirection.like:
        return 'Like';
      case SwipeDirection.superLike:
        return 'Super Like';
    }
  }
  
  String get emoji {
    switch (this) {
      case SwipeDirection.dislike:
        return '👎';
      case SwipeDirection.like:
        return '💕';
      case SwipeDirection.superLike:
        return '⭐';
    }
  }
}

/// Result of a swipe action with quota information
class SwipeResult {
  final bool success;
  final MatchResult? matchResult;
  final QuotaInfo? quotaInfo;
  final String? message;
  final String? error;
  final bool quotaExceeded;

  const SwipeResult._({
    required this.success,
    this.matchResult,
    this.quotaInfo,
    this.message,
    this.error,
    this.quotaExceeded = false,
  });

  factory SwipeResult.success({
    required MatchResult matchResult,
    required QuotaInfo quotaInfo,
  }) => SwipeResult._(
    success: true,
    matchResult: matchResult,
    quotaInfo: quotaInfo,
  );

  factory SwipeResult.quotaExceeded({
    required QuotaInfo quotaInfo,
    required String message,
  }) => SwipeResult._(
    success: false,
    quotaInfo: quotaInfo,
    message: message,
    quotaExceeded: true,
  );

  factory SwipeResult.error(String error) => SwipeResult._(
    success: false,
    error: error,
  );
}
