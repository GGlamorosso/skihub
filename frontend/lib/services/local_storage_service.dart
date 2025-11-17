import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/ride_stats.dart';

/// Service stockage local pour tracking GPS
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  
  LocalStorageService._();
  
  Database? _database;
  
  /// Initialiser base de données locale
  Future<void> initialize() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'crewsnow_tracking.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );
      
      debugPrint('✅ Local storage initialized');
    } catch (e) {
      debugPrint('❌ Local storage initialization failed: $e');
    }
  }
  
  /// Créer tables
  Future<void> _createTables(Database db, int version) async {
    // Table sessions tracking
    await db.execute('''
      CREATE TABLE tracking_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        status TEXT NOT NULL,
        station_id TEXT,
        current_distance REAL DEFAULT 0,
        current_max_speed REAL DEFAULT 0,
        current_elevation_gain INTEGER DEFAULT 0,
        paused_time_min INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // Table points GPS
    await db.execute('''
      CREATE TABLE track_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        speed REAL,
        accuracy REAL,
        heading REAL,
        FOREIGN KEY (session_id) REFERENCES tracking_sessions (id)
      )
    ''');
    
    // Table stats locales (cache)
    await db.execute('''
      CREATE TABLE local_ride_stats (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        distance_km REAL NOT NULL,
        vmax_kmh REAL NOT NULL,
        elevation_gain_m INTEGER NOT NULL,
        moving_time_min INTEGER NOT NULL,
        runs_count INTEGER NOT NULL,
        station_id TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, date)
      )
    ''');
    
    // Index pour performance
    await db.execute('CREATE INDEX idx_sessions_user_id ON tracking_sessions (user_id)');
    await db.execute('CREATE INDEX idx_points_session_id ON track_points (session_id)');
    await db.execute('CREATE INDEX idx_stats_user_date ON local_ride_stats (user_id, date)');
  }
  
  /// Upgrade tables si nécessaire
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Future migrations
  }
  
  /// Sauvegarder session tracking
  Future<void> saveTrackingSession(TrackingSession session) async {
    final db = await _getDatabase();
    
    await db.insert(
      'tracking_sessions',
      {
        'id': session.id,
        'user_id': session.userId,
        'started_at': session.startedAt.toIso8601String(),
        'ended_at': session.endedAt?.toIso8601String(),
        'status': session.status.name,
        'station_id': session.stationId,
        'current_distance': session.currentDistance,
        'current_max_speed': session.currentMaxSpeed,
        'current_elevation_gain': session.currentElevationGain,
        'paused_time_min': session.pausedTimeMin,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Sauvegarder points
    if (session.points.isNotEmpty) {
      final batch = db.batch();
      
      // Clear points existants pour cette session
      batch.delete('track_points', where: 'session_id = ?', whereArgs: [session.id]);
      
      // Insérer nouveaux points
      for (final point in session.points) {
        batch.insert('track_points', {
          'session_id': session.id,
          'timestamp': point.timestamp.toIso8601String(),
          'latitude': point.latitude,
          'longitude': point.longitude,
          'altitude': point.altitude,
          'speed': point.speed,
          'accuracy': point.accuracy,
          'heading': point.heading,
        });
      }
      
      await batch.commit();
    }
  }
  
  /// Ajouter point GPS à session
  Future<void> addTrackPoint(String sessionId, TrackPoint point) async {
    final db = await _getDatabase();
    
    await db.insert('track_points', {
      'session_id': sessionId,
      'timestamp': point.timestamp.toIso8601String(),
      'latitude': point.latitude,
      'longitude': point.longitude,
      'altitude': point.altitude,
      'speed': point.speed,
      'accuracy': point.accuracy,
      'heading': point.heading,
    });
  }
  
  /// Récupérer session active
  Future<TrackingSession?> getActiveTrackingSession() async {
    final db = await _getDatabase();
    
    final sessions = await db.query(
      'tracking_sessions',
      where: 'status IN (?, ?)',
      whereArgs: ['active', 'paused'],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    
    if (sessions.isEmpty) return null;
    
    final sessionData = sessions.first;
    
    // Récupérer points
    final points = await db.query(
      'track_points',
      where: 'session_id = ?',
      whereArgs: [sessionData['id']],
      orderBy: 'timestamp ASC',
    );
    
    final trackPoints = points.map((pointData) => TrackPoint(
      timestamp: DateTime.parse(pointData['timestamp'] as String),
      latitude: pointData['latitude'] as double,
      longitude: pointData['longitude'] as double,
      altitude: pointData['altitude'] as double?,
      speed: pointData['speed'] as double?,
      accuracy: pointData['accuracy'] as double?,
      heading: pointData['heading'] as double?,
    )).toList();
    
    return TrackingSession(
      id: sessionData['id'] as String,
      userId: sessionData['user_id'] as String,
      startedAt: DateTime.parse(sessionData['started_at'] as String),
      endedAt: sessionData['ended_at'] != null 
        ? DateTime.parse(sessionData['ended_at'] as String)
        : null,
      points: trackPoints,
      status: SessionStatus.values.firstWhere(
        (status) => status.name == sessionData['status'],
      ),
      stationId: sessionData['station_id'] as String?,
      currentDistance: sessionData['current_distance'] as double,
      currentMaxSpeed: sessionData['current_max_speed'] as double,
      currentElevationGain: sessionData['current_elevation_gain'] as int,
      pausedTimeMin: sessionData['paused_time_min'] as int,
    );
  }
  
  /// Supprimer session
  Future<void> deleteTrackingSession(String sessionId) async {
    final db = await _getDatabase();
    
    final batch = db.batch();
    batch.delete('track_points', where: 'session_id = ?', whereArgs: [sessionId]);
    batch.delete('tracking_sessions', where: 'id = ?', whereArgs: [sessionId]);
    
    await batch.commit();
  }
  
  /// Sauvegarder stats localement
  Future<void> saveRideStats(RideStats stats) async {
    final db = await _getDatabase();
    
    await db.insert(
      'local_ride_stats',
      {
        'id': stats.id,
        'user_id': stats.userId,
        'date': stats.date.toIso8601String().split('T')[0],
        'distance_km': stats.distanceKm,
        'vmax_kmh': stats.vmaxKmh,
        'elevation_gain_m': stats.elevationGainM,
        'moving_time_min': stats.movingTimeMin,
        'runs_count': stats.runsCount,
        'station_id': stats.stationId,
        'is_synced': stats.isSynced ? 1 : 0,
        'created_at': stats.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Récupérer stats locales
  Future<List<RideStats>> getLocalRideStats({
    required String userId,
    int limit = 30,
  }) async {
    final db = await _getDatabase();
    
    final results = await db.query(
      'local_ride_stats',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );
    
    return results.map((data) => RideStats(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      date: DateTime.parse(data['date'] as String),
      distanceKm: data['distance_km'] as double,
      vmaxKmh: data['vmax_kmh'] as double,
      elevationGainM: data['elevation_gain_m'] as int,
      movingTimeMin: data['moving_time_min'] as int,
      runsCount: data['runs_count'] as int,
      stationId: data['station_id'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      isSynced: (data['is_synced'] as int) == 1,
    )).toList();
  }
  
  /// Nettoyer anciennes données
  Future<void> cleanupOldData({int keepDays = 30}) async {
    final db = await _getDatabase();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    final cutoffString = cutoffDate.toIso8601String();
    
    // Supprimer sessions anciennes terminées
    await db.delete(
      'tracking_sessions',
      where: 'status = ? AND ended_at < ?',
      whereArgs: ['completed', cutoffString],
    );
    
    // Supprimer stats locales synchronisées anciennes
    await db.delete(
      'local_ride_stats',
      where: 'is_synced = 1 AND created_at < ?',
      whereArgs: [cutoffString],
    );
    
    debugPrint('🧹 Local data cleanup completed');
  }
  
  /// Obtenir taille base de données
  Future<int> getDatabaseSize() async {
    try {
      final db = await _getDatabase();
      
      final sessionsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tracking_sessions'),
      ) ?? 0;
      
      final pointsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM track_points'),
      ) ?? 0;
      
      final statsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM local_ride_stats'),
      ) ?? 0;
      
      debugPrint('📊 Local DB: $sessionsCount sessions, $pointsCount points, $statsCount stats');
      
      return pointsCount; // Approximation
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }
  
  /// Obtenir database instance
  Future<Database> _getDatabase() async {
    if (_database == null) {
      await initialize();
    }
    return _database!;
  }
  
  /// Fermer database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
