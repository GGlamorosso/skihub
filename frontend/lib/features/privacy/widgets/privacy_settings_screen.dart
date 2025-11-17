import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consent.dart';
import '../repositories/privacy_repository.dart';
import '../services/privacy_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final privacySettings = ref.watch(privacySettingsProvider('current-user-id'));
    final consents = ref.watch(userConsentsProvider('current-user-id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité et Sécurité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: privacySettings.when(
        data: (settings) => _buildContent(settings, consents),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(PrivacySettings settings, AsyncValue<List<Consent>> consents) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile visibility section
          _buildProfileSection(settings),
          const SizedBox(height: AppSpacing.xl),
          
          // Notifications section  
          _buildNotificationsSection(settings),
          const SizedBox(height: AppSpacing.xl),
          
          // Consents section
          _buildConsentsSection(consents),
          const SizedBox(height: AppSpacing.xl),
          
          // Data management section
          _buildDataManagementSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection(PrivacySettings settings) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Visibilité du Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            SwitchListTile(
              title: const Text('Mode invisible'),
              subtitle: const Text('Votre profil n\'apparaît que si vous likez en premier'),
              value: settings.isInvisible,
              onChanged: _isLoading ? null : (value) => _updateSetting('is_invisible', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Masquer l\'âge'),
              subtitle: const Text('Votre âge ne sera pas affiché publiquement'),
              value: settings.hideAge,
              onChanged: _isLoading ? null : (value) => _updateSetting('hide_age', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Masquer le niveau'),
              subtitle: const Text('Votre niveau de ski ne sera pas affiché'),
              value: settings.hideLevel,
              onChanged: _isLoading ? null : (value) => _updateSetting('hide_level', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Masquer les statistiques'),
              subtitle: const Text('Vos stats de ski resteront privées'),
              value: settings.hideStats,
              onChanged: _isLoading ? null : (value) => _updateSetting('hide_stats', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Masquer la dernière activité'),
              subtitle: const Text('Votre dernière connexion ne sera pas visible'),
              value: settings.hideLastActive,
              onChanged: _isLoading ? null : (value) => _updateSetting('hide_last_active', value),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(PrivacySettings settings) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            SwitchListTile(
              title: const Text('Notifications push'),
              subtitle: const Text('Nouveaux matchs, messages, et mises à jour importantes'),
              value: settings.notificationsPush,
              onChanged: _isLoading ? null : (value) => _updateSetting('notifications_push', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Notifications email'),
              subtitle: const Text('Résumés hebdomadaires et notifications importantes'),
              value: settings.notificationsEmail,
              onChanged: _isLoading ? null : (value) => _updateSetting('notifications_email', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Communications marketing'),
              subtitle: const Text('Offres spéciales, nouveautés et événements'),
              value: settings.notificationsMarketing,
              onChanged: _isLoading ? null : (value) => _updateSetting('notifications_marketing', value),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentsSection(AsyncValue<List<Consent>> consentsAsync) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Consentements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gérez vos consentements pour les différentes fonctionnalités',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            consentsAsync.when(
              data: (consents) => _buildConsentsList(consents),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Erreur: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentsList(List<Consent> consents) {
    // Create map for easy lookup
    final consentMap = {
      for (final consent in consents) consent.purpose: consent
    };

    // All possible consents
    final allPurposes = [
      'gps_tracking',
      'ai_moderation', 
      'ai_assistance',
      'marketing',
      'analytics',
      'photo_analysis',
    ];

    return Column(
      children: allPurposes.map((purpose) {
        final consent = consentMap[purpose];
        final hasConsent = consent?.isActive ?? false;
        
        // Create dummy consent for display
        final displayConsent = consent ?? Consent(
          id: '',
          userId: 'current-user-id',
          purpose: purpose,
          version: 1,
          granted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return Column(
          children: [
            SwitchListTile(
              title: Text(displayConsent.purposeDisplay),
              subtitle: Text(displayConsent.description),
              value: hasConsent,
              onChanged: _isLoading ? null : (value) => _updateConsent(purpose, value),
              activeThumbColor: AppColors.primary,
              secondary: Icon(displayConsent.icon),
            ),
            if (purpose != allPurposes.last) const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDataManagementSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_usage, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Gestion des Données',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exporter mes données'),
              subtitle: const Text('Télécharger toutes vos données personnelles'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _exportUserData,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historique des consentements'),
              subtitle: const Text('Voir l\'historique de vos consentements'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showConsentHistory,
            ),
            
            const Divider(),
            
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red[600]),
              title: Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red[600]),
              ),
              subtitle: const Text('Suppression définitive de toutes vos données'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() => _isLoading = true);
    
    try {
      final currentSettings = ref.read(privacySettingsProvider('current-user-id')).value;
      if (currentSettings == null) return;

      final newSettings = _copySettingsWith(currentSettings, key, value);
      
      final privacyService = ref.read(privacyServiceProvider);
      await privacyService.updatePrivacySettings('current-user-id', newSettings);
      
      // Update local state
      ref.invalidate(privacySettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètre mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConsent(String purpose, bool granted) async {
    setState(() => _isLoading = true);
    
    try {
      final privacyService = ref.read(privacyServiceProvider);
      
      if (granted) {
        await privacyService.grantConsent('current-user-id', purpose);
      } else {
        // Show warning for important consents
        if (['gps_tracking', 'location_sharing'].contains(purpose)) {
          final confirmed = await _showRevokeWarning(purpose);
          if (!confirmed) {
            setState(() => _isLoading = false);
            return;
          }
        }
        
        await privacyService.revokeConsent('current-user-id', purpose);
      }
      
      // Refresh consents
      ref.invalidate(userConsentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted ? 'Consentement accordé' : 'Consentement révoqué'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showRevokeWarning(String purpose) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la révocation'),
        content: Text(_getRevokeWarningText(purpose)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _getRevokeWarningText(String purpose) {
    switch (purpose) {
      case 'gps_tracking':
        return 'En désactivant le suivi GPS, le tracker de ski sera désactivé et vous n\'apparaîtrez plus dans les recherches par localisation.';
      case 'ai_moderation':
        return 'En désactivant la modération IA, vos messages ne seront plus protégés contre le contenu inapproprié automatiquement.';
      case 'location_sharing':
        return 'En désactivant le partage de localisation, vous ne pourrez plus matcher avec des utilisateurs près de vous.';
      default:
        return 'Êtes-vous sûr de vouloir révoquer ce consentement ?';
    }
  }

  void _exportUserData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: AppSpacing.lg),
              Text('Préparation de l\'export...'),
            ],
          ),
        ),
      );

      final privacyService = ref.read(privacyServiceProvider);
      await privacyService.requestDataExport('current-user-id');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export demandé. Vous recevrez un email avec vos données.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConsentHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConsentHistoryScreen(),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.\n\n'
          'Ceci inclut votre profil, matchs, messages, photos et statistiques.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() async {
    // This would trigger account deletion process
    // Should require additional confirmation steps
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Suppression en cours'),
        content: Text('Votre demande de suppression a été enregistrée. '
                     'Vous recevrez un email de confirmation.'),
      ),
    );
  }

  PrivacySettings _copySettingsWith(PrivacySettings settings, String key, dynamic value) {
    switch (key) {
      case 'is_invisible':
        return settings.copyWith(isInvisible: value as bool);
      case 'hide_age':
        return settings.copyWith(hideAge: value as bool);
      case 'hide_level':
        return settings.copyWith(hideLevel: value as bool);
      case 'hide_stats':
        return settings.copyWith(hideStats: value as bool);
      case 'hide_last_active':
        return settings.copyWith(hideLastActive: value as bool);
      case 'notifications_push':
        return settings.copyWith(notificationsPush: value as bool);
      case 'notifications_email':
        return settings.copyWith(notificationsEmail: value as bool);
      case 'notifications_marketing':
        return settings.copyWith(notificationsMarketing: value as bool);
      default:
        return settings;
    }
  }
}

class ConsentHistoryScreen extends ConsumerWidget {
  const ConsentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consents = ref.watch(userConsentsProvider('current-user-id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Consentements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: consents.when(
        data: (consentsList) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: consentsList.length,
          itemBuilder: (context, index) {
            final consent = consentsList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ListTile(
                leading: Icon(consent.icon),
                title: Text(consent.purposeDisplay),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(consent.statusDisplay),
                    if (consent.grantedAt != null)
                      Text(
                        'Accordé le ${_formatDate(consent.grantedAt!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (consent.revokedAt != null)
                      Text(
                        'Révoqué le ${_formatDate(consent.revokedAt!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: consent.isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    consent.isActive ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 10,
                      color: consent.isActive ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
