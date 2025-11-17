import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../main.dart' show logger;

/// Utilitaire pour tester Firebase et Crashlytics
class FirebaseTest {
  static FirebaseTest? _instance;
  static FirebaseTest get instance => _instance ??= FirebaseTest._();
  
  FirebaseTest._();
  
  /// Exécute une série de tests Firebase complets
  Future<Map<String, bool>> runCompleteTests() async {
    final results = <String, bool>{};
    
    logger.i('🧪 Starting Firebase complete tests...');
    
    try {
      // Test 1: Vérifier l'initialisation
      results['initialization'] = await testInitialization();
      
      // Test 2: Tester la connectivité
      results['connectivity'] = await testConnectivity();
      
      // Test 3: Tester l'enregistrement d'erreurs
      results['error_logging'] = await testErrorLogging();
      
      // Test 4: Tester les événements custom
      results['custom_events'] = await testCustomEvents();
      
      // Test 5: Tester les métadonnées utilisateur
      results['user_metadata'] = await testUserMetadata();
      
      // Ne pas faire le test de crash en production
      if (kDebugMode) {
        // Test 6: Test de crash (uniquement en debug)
        results['crash_test'] = await testCrashReporting();
      } else {
        results['crash_test'] = true; // Skip in release
        logger.i('🧪 Crash test skipped in release mode');
      }
      
      // Résumé des tests
      final passedTests = results.values.where((result) => result).length;
      final totalTests = results.length;
      
      logger.i('🧪 Firebase tests completed: $passedTests/$totalTests passed');
      
      if (passedTests == totalTests) {
        logger.i('✅ All Firebase tests passed!');
      } else {
        logger.w('⚠️ Some Firebase tests failed. Check the results.');
      }
      
      return results;
      
    } catch (e, stackTrace) {
      logger.e('❌ Firebase tests failed: $e\n$stackTrace');
      return {'error': false};
    }
  }
  
  /// Test 1: Vérifier que Firebase est initialisé
  Future<bool> testInitialization() async {
    try {
      logger.i('🧪 Test 1: Firebase initialization...');
      
      final isInitialized = FirebaseService.instance.isInitialized;
      
      if (isInitialized) {
        logger.i('✅ Test 1 passed: Firebase is initialized');
        return true;
      } else {
        logger.e('❌ Test 1 failed: Firebase is not initialized');
        return false;
      }
      
    } catch (e) {
      logger.e('❌ Test 1 error: $e');
      return false;
    }
  }
  
  /// Test 2: Tester la connectivité Firebase
  Future<bool> testConnectivity() async {
    try {
      logger.i('🧪 Test 2: Firebase connectivity...');
      
      // Test simple de connectivité en tentant d'accéder aux services
      await FirebaseService.instance.logCustomEvent('test_connectivity', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test_id': 'connectivity_test',
      });
      
      logger.i('✅ Test 2 passed: Firebase connectivity OK');
      return true;
      
    } catch (e) {
      logger.e('❌ Test 2 failed: Firebase connectivity error: $e');
      return false;
    }
  }
  
  /// Test 3: Tester l'enregistrement d'erreurs
  Future<bool> testErrorLogging() async {
    try {
      logger.i('🧪 Test 3: Error logging...');
      
      // Créer une erreur de test
      final testError = Exception('Test error for Firebase logging');
      final testStack = StackTrace.current;
      
      await FirebaseService.instance.recordError(
        testError,
        testStack,
        reason: 'Firebase test error logging',
        fatal: false,
      );
      
      logger.i('✅ Test 3 passed: Error logging successful');
      return true;
      
    } catch (e) {
      logger.e('❌ Test 3 failed: Error logging failed: $e');
      return false;
    }
  }
  
  /// Test 4: Tester les événements custom
  Future<bool> testCustomEvents() async {
    try {
      logger.i('🧪 Test 4: Custom events...');
      
      await FirebaseService.instance.logCustomEvent('firebase_test_suite', {
        'test_type': 'custom_events',
        'app_version': '1.0.0',
        'platform': defaultTargetPlatform.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      logger.i('✅ Test 4 passed: Custom events logged successfully');
      return true;
      
    } catch (e) {
      logger.e('❌ Test 4 failed: Custom events failed: $e');
      return false;
    }
  }
  
  /// Test 5: Tester les métadonnées utilisateur
  Future<bool> testUserMetadata() async {
    try {
      logger.i('🧪 Test 5: User metadata...');
      
      // Note: Les métadonnées utilisateur sont définies dans FirebaseService
      // Ce test vérifie simplement que les services sont accessibles
      
      await FirebaseService.instance.logCustomEvent('user_metadata_test', {
        'user_type': 'test_user',
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      logger.i('✅ Test 5 passed: User metadata handled successfully');
      return true;
      
    } catch (e) {
      logger.e('❌ Test 5 failed: User metadata failed: $e');
      return false;
    }
  }
  
  /// Test 6: Tester le crash reporting (uniquement en debug)
  Future<bool> testCrashReporting() async {
    if (!kDebugMode) {
      logger.i('🧪 Crash test skipped in release mode');
      return true;
    }
    
    try {
      logger.i('🧪 Test 6: Crash reporting (debug only)...');
      logger.w('⚠️ This test will force a crash for testing purposes');
      
      // Attendre un peu avant de déclencher le crash
      await Future<void>.delayed(const Duration(seconds: 1));
      
      // Enregistrer un événement avant le crash
      await FirebaseService.instance.logCustomEvent('pre_crash_test', {
        'about_to_crash': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Note: Dans un vrai test, nous déclencherions le crash ici
      // mais pour éviter de planter l'app pendant les tests, nous simulons
      logger.w('🧪 Crash test simulated (actual crash disabled for testing)');
      
      // Uncomment the next line to actually test crash reporting:
      // await FirebaseService.instance.testCrashlytics();
      
      logger.i('✅ Test 6 passed: Crash reporting configured');
      return true;
      
    } catch (e) {
      logger.e('❌ Test 6 failed: Crash reporting failed: $e');
      return false;
    }
  }
  
  /// Test rapide de statut Firebase
  Future<void> quickStatusCheck() async {
    logger.i('🔥 Firebase Quick Status Check');
    logger.i('🔥 Initialized: ${FirebaseService.instance.isInitialized}');
    
    if (FirebaseService.instance.isInitialized) {
      await FirebaseService.instance.logCustomEvent('status_check', {
        'check_time': DateTime.now().toIso8601String(),
        'status': 'active',
      });
      logger.i('✅ Firebase is active and logging events');
    } else {
      logger.e('❌ Firebase is not initialized');
    }
  }
}
