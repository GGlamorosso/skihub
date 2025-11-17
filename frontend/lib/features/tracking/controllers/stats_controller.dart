import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ride_stats.dart';
import '../../../services/supabase_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../utils/error_handler.dart';

/// Statistiques totales utilisateur
@immutable
class TotalStats {
  const TotalStats({
    required this.totalDistanceKm,
    required this.maxSpeedKmh,
    required this.totalElevationM,
    required this.totalTimeMin,
    required this.sessionsCount,
    required this.averageDistanceKm,
    required this.averageSpeedKmh,
  });
  
  final double totalDistanceKm;
  final double maxSpeedKmh;
  final int totalElevationM;
  final int totalTimeMin;
  final int sessionsCount;
  final double averageDistanceKm;
  final double averageSpeedKmh;
  
  String get totalTimeDisplay {
    final hours = totalTimeMin ~/ 60;
    final minutes = totalTimeMin % 60;
    return '${hours}h ${minutes}min';
  }
}

/// État des statistiques
@immutable
class StatsState {
  const StatsState({
    this.totalStats,
    this.recentStats = const [],
    this.allStats = const [],
    this.stationStats = const {},
    this.isLoading = false,
    this.error,
  });
  
  final TotalStats? totalStats;
  final List<RideStats> recentStats; // 7 derniers jours
  final List<RideStats> allStats; // Historique complet (premium)
  final Map<String, double> stationStats; // Distance par station
  final bool isLoading;
  final String? error;
  
  bool get hasError => error != null;
  bool get hasStats => totalStats != null;
  bool get hasRecentStats => recentStats.isNotEmpty;
  
  StatsState copyWith({
    TotalStats? totalStats,
    List<RideStats>? recentStats,
    List<RideStats>? allStats,
    Map<String, double>? stationStats,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      totalStats: totalStats ?? this.totalStats,
      recentStats: recentStats ?? this.recentStats,
      allStats: allStats ?? this.allStats,
      stationStats: stationStats ?? this.stationStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller pour statistiques
class StatsController extends StateNotifier<StatsState> {
  StatsController() : super(const StatsState()) {
    _init();
  }
  
  final _supabase = SupabaseService.instance;
  final _localStorage = LocalStorageService.instance;
  
  /// Initialisation
  Future<void> _init() async {
    await loadStats();
  }
  
  /// Charger toutes les statistiques
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final userId = _supabase.currentUserId!;
      
      // Charger depuis backend et local
      final backendStats = await _loadBackendStats(userId);
      final localStats = await _localStorage.getLocalRideStats(userId: userId);
      
      // Combiner et dédupliquer
      final allStats = _mergeStats(backendStats, localStats);
      
      // Calculer stats totales
      final totalStats = _calculateTotalStats(allStats);
      
      // Stats récentes (7 jours)
      final now = DateTime.now();
      final recentStats = allStats.where((stat) {
        return now.difference(stat.date).inDays <= 7;
      }).toList();
      
      // Stats par station
      final stationStats = _calculateStationStats(allStats);
      
      state = state.copyWith(
        totalStats: totalStats,
        recentStats: recentStats,
        allStats: allStats,
        stationStats: stationStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getReadableError(e),
      );
      
      ErrorHandler.logError(
        context: 'StatsController.loadStats',
        error: e,
      );
    }
  }
  
  /// Charger stats depuis backend
  Future<List<RideStats>> _loadBackendStats(String userId) async {
    try {
      final response = await _supabase.from('ride_stats_daily')
          .select('''
            *,
            stations(name)
          ''')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(90); // 3 mois max
      
      return (response as List).map((data) {
        return RideStats(
          id: data['id'] ?? '',
          userId: data['user_id'],
          date: DateTime.parse(data['date']),
          distanceKm: (data['distance_km'] as num).toDouble(),
          vmaxKmh: (data['vmax_kmh'] as num).toDouble(),
          elevationGainM: data['elevation_gain_m'] as int,
          movingTimeMin: data['moving_time_min'] as int,
          runsCount: data['runs_count'] as int,
          stationId: data['station_id'],
          createdAt: DateTime.parse(data['created_at']),
          stationName: data['stations']?['name'],
          isSynced: true,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading backend stats: $e');
      return [];
    }
  }
  
  /// Fusionner stats backend + local
  List<RideStats> _mergeStats(List<RideStats> backend, List<RideStats> local) {
    final Map<String, RideStats> merged = {};
    
    // Ajouter backend (priorité)
    for (final stat in backend) {
      final key = '${stat.userId}_${stat.date.toIso8601String().split('T')[0]}';
      merged[key] = stat;
    }
    
    // Ajouter local si pas déjà en backend
    for (final stat in local) {
      final key = '${stat.userId}_${stat.date.toIso8601String().split('T')[0]}';
      if (!merged.containsKey(key)) {
        merged[key] = stat;
      }
    }
    
    final result = merged.values.toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    
    return result;
  }
  
  /// Calculer statistiques totales
  TotalStats _calculateTotalStats(List<RideStats> allStats) {
    if (allStats.isEmpty) {
      return const TotalStats(
        totalDistanceKm: 0,
        maxSpeedKmh: 0,
        totalElevationM: 0,
        totalTimeMin: 0,
        sessionsCount: 0,
        averageDistanceKm: 0,
        averageSpeedKmh: 0,
      );
    }
    
    final totalDistance = allStats.fold<double>(0, (sum, stat) => sum + stat.distanceKm);
    final maxSpeed = allStats.fold<double>(0, (max, stat) => math.max(max, stat.vmaxKmh));
    final totalElevation = allStats.fold<int>(0, (sum, stat) => sum + stat.elevationGainM);
    final totalTime = allStats.fold<int>(0, (sum, stat) => sum + stat.movingTimeMin);
    final sessions = allStats.length;
    
    return TotalStats(
      totalDistanceKm: totalDistance,
      maxSpeedKmh: maxSpeed,
      totalElevationM: totalElevation,
      totalTimeMin: totalTime,
      sessionsCount: sessions,
      averageDistanceKm: sessions > 0 ? totalDistance / sessions : 0,
      averageSpeedKmh: sessions > 0 
        ? allStats.fold<double>(0, (sum, stat) => sum + stat.vmaxKmh) / sessions
        : 0,
    );
  }
  
  /// Calculer stats par station
  Map<String, double> _calculateStationStats(List<RideStats> allStats) {
    final Map<String, double> stationDistance = {};
    
    for (final stat in allStats) {
      final stationName = stat.stationName ?? 'Autre';
      stationDistance[stationName] = (stationDistance[stationName] ?? 0) + stat.distanceKm;
    }
    
    return stationDistance;
  }
  
  /// Ajouter nouvelle session (depuis tracking)
  void addNewSession(RideStats stats) {
    final updatedRecent = [stats, ...state.recentStats];
    final updatedAll = [stats, ...state.allStats];
    
    // Recalculer totales
    final newTotal = _calculateTotalStats(updatedAll);
    final newStationStats = _calculateStationStats(updatedAll);
    
    state = state.copyWith(
      totalStats: newTotal,
      recentStats: updatedRecent,
      allStats: updatedAll,
      stationStats: newStationStats,
    );
  }
  
  /// Refresh stats
  Future<void> refresh() async {
    await loadStats();
  }
  
  /// Clear erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Obtenir meilleure session
  RideStats? getBestSession({String criteria = 'distance'}) {
    if (state.allStats.isEmpty) return null;
    
    switch (criteria) {
      case 'distance':
        return state.allStats.reduce((a, b) => a.distanceKm > b.distanceKm ? a : b);
      case 'speed':
        return state.allStats.reduce((a, b) => a.vmaxKmh > b.vmaxKmh ? a : b);
      case 'elevation':
        return state.allStats.reduce((a, b) => a.elevationGainM > b.elevationGainM ? a : b);
      default:
        return null;
    }
  }
  
  /// Obtenir streak (jours consécutifs)
  int getCurrentStreak() {
    if (state.allStats.isEmpty) return 0;
    
    int streak = 0;
    final now = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final hasSession = state.allStats.any((stat) {
        return stat.date.year == date.year &&
               stat.date.month == date.month &&
               stat.date.day == date.day;
      });
      
      if (hasSession) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

/// Providers pour statistiques
final statsControllerProvider = StateNotifierProvider<StatsController, StatsState>((ref) {
  return StatsController();
});

final totalStatsProvider = Provider<TotalStats?>((ref) {
  return ref.watch(statsControllerProvider).totalStats;
});

final recentStatsProvider = Provider<List<RideStats>>((ref) {
  return ref.watch(statsControllerProvider).recentStats;
});

final currentStreakProvider = Provider<int>((ref) {
  return ref.read(statsControllerProvider.notifier).getCurrentStreak();
});
