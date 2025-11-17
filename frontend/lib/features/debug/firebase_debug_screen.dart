import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/firebase_service.dart';
import '../../utils/firebase_test.dart';

/// Écran de debug Firebase pour tester et vérifier l'intégration
class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  bool _isRunningTests = false;
  Map<String, bool> _testResults = {};
  String _statusMessage = 'Prêt pour les tests Firebase';
  
  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }
  
  Future<void> _checkFirebaseStatus() async {
    setState(() {
      _statusMessage = 'Vérification du statut Firebase...';
    });
    
    try {
      await FirebaseTest.instance.quickStatusCheck();
      setState(() {
        _statusMessage = FirebaseService.instance.isInitialized 
            ? '✅ Firebase est initialisé et prêt' 
            : '❌ Firebase n\'est pas initialisé';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur lors de la vérification: $e';
      });
    }
  }
  
  Future<void> _runFirebaseTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
      _statusMessage = 'Exécution des tests Firebase...';
    });
    
    try {
      final results = await FirebaseTest.instance.runCompleteTests();
      
      setState(() {
        _testResults = results;
        _isRunningTests = false;
        
        final passedCount = results.values.where((v) => v).length;
        final totalCount = results.length;
        
        _statusMessage = 'Tests terminés: $passedCount/$totalCount réussis';
      });
      
    } catch (e) {
      setState(() {
        _isRunningTests = false;
        _statusMessage = 'Erreur lors des tests: $e';
      });
    }
  }
  
  Future<void> _testCustomEvent() async {
    try {
      await FirebaseService.instance.logCustomEvent('debug_screen_test', {
        'button_pressed': 'custom_event_test',
        'timestamp': DateTime.now().toIso8601String(),
        'user_action': true,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Événement custom envoyé à Firebase!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _testErrorLogging() async {
    try {
      await FirebaseService.instance.recordError(
        Exception('Test error from debug screen'),
        StackTrace.current,
        reason: 'Manual test from debug screen',
        fatal: false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de test envoyée à Crashlytics!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _testCrashlytics() async {
    if (!kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test de crash uniquement disponible en mode debug'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Afficher une confirmation avant le crash
    final shouldCrash = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Test de crash'),
        content: const Text(
          'Ceci va forcer un crash de l\'application pour tester Crashlytics. '
          'L\'app va se fermer et redémarrer.\n\n'
          'Voulez-vous continuer?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Forcer le crash'),
          ),
        ],
      ),
    );
    
    if (shouldCrash == true) {
      // Enregistrer un événement avant le crash
      await FirebaseService.instance.logCustomEvent('about_to_crash', {
        'test_crash': true,
        'initiated_by': 'debug_screen',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Attendre un peu pour que l'événement soit envoyé
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Déclencher le crash
      await FirebaseService.instance.testCrashlytics();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Firebase Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              color: FirebaseService.instance.isInitialized 
                  ? Colors.green.shade50 
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut Firebase',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _checkFirebaseStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Rafraîchir statut'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test buttons
            Text(
              'Tests manuels',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isRunningTests ? null : _runFirebaseTests,
              icon: _isRunningTests 
                  ? const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunningTests ? 'Tests en cours...' : 'Lancer tous les tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testCustomEvent,
                    icon: const Icon(Icons.event),
                    label: const Text('Événement custom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testErrorLogging,
                    icon: const Icon(Icons.error_outline),
                    label: const Text('Erreur test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (kDebugMode)
              ElevatedButton.icon(
                onPressed: _testCrashlytics,
                icon: const Icon(Icons.warning),
                label: const Text('⚠️ Test crash (Debug)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Test results
            if (_testResults.isNotEmpty) ...[
              Text(
                'Résultats des tests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: _testResults.entries.map((entry) {
                        final testName = entry.key;
                        final passed = entry.value;
                        
                        return ListTile(
                          leading: Icon(
                            passed ? Icons.check_circle : Icons.error,
                            color: passed ? Colors.green : Colors.red,
                          ),
                          title: Text(testName.replaceAll('_', ' ').toUpperCase()),
                          trailing: Text(
                            passed ? 'RÉUSSI' : 'ÉCHOUÉ',
                            style: TextStyle(
                              color: passed ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
            
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Instructions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Lancez "Tous les tests" pour une vérification complète\n'
                      '• Testez les événements et erreurs individuellement\n'
                      '• Vérifiez Firebase Console pour voir les données\n'
                      '• Le test de crash ne fonctionne qu\'en mode debug',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
