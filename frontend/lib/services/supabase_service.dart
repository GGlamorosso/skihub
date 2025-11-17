import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../config/env_config.dart';

/// CrewSnow Supabase Service - Singleton pour gérer connexion
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  static final Logger _logger = Logger();
  
  /// Initialiser Supabase avec configuration env
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        debug: EnvConfig.isDevelopment,
      );
      _logger.i('✅ Supabase initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize Supabase: $e');
      rethrow;
    }
  }
  
  /// Client Supabase principal
  SupabaseClient get client => Supabase.instance.client;
  
  /// Auth helpers
  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;
  
  /// Database helpers
  PostgrestQueryBuilder from(String table) => client.from(table);
  PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params}) => client.rpc(fn, params: params);
  
  /// Storage helpers
  SupabaseStorageClient get storage => client.storage;
  
  /// Functions helpers
  FunctionsClient get functions => client.functions;
  
  /// Realtime helpers
  RealtimeClient get realtime => client.realtime;
  
  /// Auth state stream
  Stream<AuthState> get authStateStream => auth.onAuthStateChange;
  
  /// Sign up with email/password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      _logger.i('✅ User signed up: ${response.user?.email}');
      return response;
    } catch (e) {
      _logger.e('❌ Sign up failed: $e');
      rethrow;
    }
  }
  
  /// Sign in with email/password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );
      _logger.i('✅ User signed in: ${response.user?.email}');
      return response;
    } catch (e) {
      _logger.e('❌ Sign in failed: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      _logger.i('✅ User signed out');
    } catch (e) {
      _logger.e('❌ Sign out failed: $e');
      rethrow;
    }
  }
  
  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    Map<String, String>? metadata,
  }) async {
    try {
      await storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          metadata: metadata,
        ),
      );
      _logger.i('✅ File uploaded: $bucket/$path');
      return path;
    } catch (e) {
      _logger.e('❌ File upload failed: $e');
      rethrow;
    }
  }
  
  /// Get signed URL
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
  }) async {
    try {
      final url = await storage.from(bucket).createSignedUrl(
        path,
        expiresIn,
      );
      return url;
    } catch (e) {
      _logger.e('❌ Get signed URL failed: $e');
      rethrow;
    }
  }
  
  /// Call Edge Function
  Future<FunctionResponse> callFunction({
    required String functionName,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await functions.invoke(
        functionName,
        body: body,
      );
      _logger.i('✅ Function called: $functionName');
      return response;
    } catch (e) {
      _logger.e('❌ Function call failed ($functionName): $e');
      rethrow;
    }
  }
  
  /// Subscribe to realtime changes
  RealtimeChannel subscribeToTable({
    required String table,
    required String filter,
    required void Function(PostgresChangePayload) onInsert,
    required void Function(PostgresChangePayload) onUpdate,
    required void Function(PostgresChangePayload) onDelete,
  }) {
    final channel = client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
            schema: 'public',
            table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: filter,
          ),
          callback: (payload) => onInsert(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
            schema: 'public',
            table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: filter,
          ),
          callback: (payload) => onUpdate(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
            schema: 'public',
            table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: filter,
          ),
          callback: (payload) => onDelete(payload),
        )
        .subscribe();
        
    _logger.i('✅ Subscribed to realtime: $table ($filter)');
    return channel;
  }
}
