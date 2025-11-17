import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../privacy/services/privacy_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final privacySettings = ref.watch(privacySettingsProvider('current-user-id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: privacySettings.when(
        data: (settings) => _buildContent(settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(PrivacySettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Push notifications
          _buildPushNotificationsSection(settings),
          const SizedBox(height: AppSpacing.lg),
          
          // Email notifications
          _buildEmailNotificationsSection(settings),
          const SizedBox(height: AppSpacing.lg),
          
          // Safety notifications
          _buildSafetyNotificationsSection(),
          const SizedBox(height: AppSpacing.lg),
          
          // Notification management
          _buildNotificationManagement(),
        ],
      ),
    );
  }

  Widget _buildPushNotificationsSection(PrivacySettings settings) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Notifications Push',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            SwitchListTile(
              title: const Text('Notifications générales'),
              subtitle: const Text('Activer toutes les notifications push'),
              value: settings.notificationsPush,
              onChanged: (value) => _updatePushSetting('notifications_push', value),
              activeThumbColor: AppColors.primary,
            ),
            
            if (settings.notificationsPush) ...[
              const Divider(),
              
              _buildNotificationOption(
                title: 'Nouveaux matchs',
                subtitle: 'Quand quelqu\'un vous like en retour',
                icon: Icons.favorite,
                enabled: true, // Would come from user preferences
                onChanged: (value) => _updateNotificationOption('matches', value),
              ),
              
              _buildNotificationOption(
                title: 'Nouveaux messages',
                subtitle: 'Quand vous recevez un message',
                icon: Icons.message,
                enabled: true,
                onChanged: (value) => _updateNotificationOption('messages', value),
              ),
              
              _buildNotificationOption(
                title: 'Photos approuvées',
                subtitle: 'Quand vos photos sont approuvées',
                icon: Icons.photo_library,
                enabled: true,
                onChanged: (value) => _updateNotificationOption('photos', value),
              ),
              
              _buildNotificationOption(
                title: 'Vérification',
                subtitle: 'Mises à jour de vérification vidéo',
                icon: Icons.verified_user,
                enabled: true,
                onChanged: (value) => _updateNotificationOption('verification', value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailNotificationsSection(PrivacySettings settings) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Notifications Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            SwitchListTile(
              title: const Text('Emails généraux'),
              subtitle: const Text('Résumés et notifications importantes'),
              value: settings.notificationsEmail,
              onChanged: (value) => _updatePushSetting('notifications_email', value),
              activeThumbColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: const Text('Marketing et promotions'),
              subtitle: const Text('Offres spéciales et nouveautés'),
              value: settings.notificationsMarketing,
              onChanged: (value) => _updatePushSetting('notifications_marketing', value),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyNotificationsSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.red[600]),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Notifications de Sécurité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ces notifications ne peuvent pas être désactivées pour votre sécurité',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: Icon(Icons.block, color: Colors.red[600]),
              title: const Text('Messages bloqués'),
              subtitle: const Text('Quand vos messages sont bloqués par la modération'),
              trailing: Icon(Icons.lock, color: Colors.grey[400]),
            ),
            
            const Divider(),
            
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange[600]),
              title: const Text('Alertes de sécurité'),
              subtitle: const Text('Avertissements importants et violations'),
              trailing: Icon(Icons.lock, color: Colors.grey[400]),
            ),
            
            const Divider(),
            
            ListTile(
              leading: Icon(Icons.gavel, color: Colors.purple[600]),
              title: const Text('Décisions de modération'),
              subtitle: const Text('Résultats des vérifications et appels'),
              trailing: Icon(Icons.lock, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationManagement() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.manage_accounts, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Gestion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Mode Ne Pas Déranger'),
              subtitle: const Text('Programmer des heures de silence'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showDoNotDisturbSettings,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Effacer toutes les notifications'),
              subtitle: const Text('Supprimer les notifications en attente'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _clearAllNotifications,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.test_tube),
              title: const Text('Notification de test'),
              subtitle: const Text('Tester vos paramètres de notification'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _sendTestNotification,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: enabled,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
      dense: true,
    );
  }

  Future<void> _updatePushSetting(String key, bool value) async {
    setState(() => _isLoading = true);

    try {
      // Update setting via privacy service
      final currentSettings = ref.read(privacySettingsProvider('current-user-id')).value;
      if (currentSettings == null) return;

      // This would update the specific notification setting
      // Implementation would depend on your privacy settings structure
      
      // Update notification topics
      await _notificationService.updateNotificationTopics(
        userId: 'current-user-id',
        marketingEnabled: value && key == 'notifications_marketing',
        matchesEnabled: currentSettings.notificationsPush,
        messagesEnabled: currentSettings.notificationsPush,
      );

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

  Future<void> _updateNotificationOption(String type, bool enabled) async {
    // Update specific notification type
    try {
      await _notificationService.updateNotificationTopics(
        userId: 'current-user-id',
        marketingEnabled: type == 'marketing' ? enabled : false,
        matchesEnabled: type == 'matches' ? enabled : true,
        messagesEnabled: type == 'messages' ? enabled : true,
      );
    } catch (e) {
      debugPrint('Error updating notification option: $e');
    }
  }

  void _showDoNotDisturbSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Ne Pas Déranger'),
        content: const Text(
          'Fonctionnalité à venir.\n\n'
          'Vous pourrez programmer des heures de silence pour '
          'ne pas être dérangé pendant certaines périodes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été effacées'),
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
    }
  }

  void _sendTestNotification() async {
    try {
      await _notificationService.showSafetyNotification(
        title: 'Test Notification',
        body: 'Ceci est une notification de test pour CrewSnow',
        type: 'test',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification de test envoyée'),
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
    }
  }
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : count.toString()),
      child: child,
    );
  }
}

class SafetyAlert extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const SafetyAlert({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning,
    this.color = Colors.orange,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(message),
        trailing: onDismiss != null
            ? IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              )
            : const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class ModerationNotificationCard extends StatelessWidget {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final VoidCallback? onAction;
  final String? actionText;

  const ModerationNotificationCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(), color: _getTypeColor()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (type) {
      case 'message_blocked':
        return Icons.block;
      case 'photo_rejected':
        return Icons.photo_camera;
      case 'verification_result':
        return Icons.verified_user;
      case 'user_reported':
        return Icons.flag;
      default:
        return Icons.info;
    }
  }

  Color _getTypeColor() {
    switch (type) {
      case 'message_blocked':
        return Colors.red;
      case 'photo_rejected':
        return Colors.orange;
      case 'verification_result':
        return Colors.blue;
      case 'user_reported':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}j';
    }
  }
}
