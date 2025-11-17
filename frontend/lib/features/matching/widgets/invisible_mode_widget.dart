import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../privacy/services/privacy_service.dart';
import '../../privacy/models/consent.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class InvisibleModeToggle extends ConsumerWidget {
  final String userId;

  const InvisibleModeToggle({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacySettings = ref.watch(privacySettingsProvider(userId));

    return privacySettings.when(
      data: (settings) => _buildToggle(context, ref, settings),
      loading: () => const ListTile(
        title: Text('Mode invisible'),
        trailing: CircularProgressIndicator(),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildToggle(BuildContext context, WidgetRef ref, PrivacySettings settings) {
    return SwitchListTile(
      title: const Text('Mode invisible'),
      subtitle: const Text('Apparaissez seulement aux personnes que vous likez'),
      value: settings.isInvisible,
      onChanged: (value) => _toggleInvisibleMode(context, ref, value),
      activeThumbColor: AppColors.primary,
      secondary: Icon(
        settings.isInvisible ? Icons.visibility_off : Icons.visibility,
        color: AppColors.primary,
      ),
    );
  }

  Future<void> _toggleInvisibleMode(BuildContext context, WidgetRef ref, bool enabled) async {
    try {
      final currentSettings = ref.read(privacySettingsProvider(userId)).value;
      if (currentSettings == null) return;

      final newSettings = currentSettings.copyWith(isInvisible: enabled);
      
      final privacyService = ref.read(privacyServiceProvider);
      await privacyService.updatePrivacySettings(userId, newSettings);
      
      // Update state
      ref.read(privacySettingsProvider(userId).notifier).updateSettings(newSettings);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled 
                ? 'Mode invisible activé' 
                : 'Mode invisible désactivé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

class InvisibleModeIndicator extends ConsumerWidget {
  final String userId;

  const InvisibleModeIndicator({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacySettings = ref.watch(privacySettingsProvider(userId));

    return privacySettings.when(
      data: (settings) => settings.isInvisible
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 14,
                    color: Colors.purple[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mode invisible',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class PrivacyAwareProfile extends ConsumerWidget {
  final String userId;
  final Map<String, dynamic> userProfile;

  const PrivacyAwareProfile({
    super.key,
    required this.userId,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If viewing own profile, show everything
    const currentUserId = 'current-user-id'; // Get from auth
    if (userId == currentUserId) {
      return _buildFullProfile(userProfile);
    }

    // For other users, respect privacy settings
    return _buildFilteredProfile(userProfile);
  }

  Widget _buildFullProfile(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full profile info - no filtering
        if (profile['age'] != null)
          ListTile(
            leading: const Icon(Icons.cake),
            title: Text('${profile['age']} ans'),
          ),
        if (profile['level'] != null)
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text('Niveau: ${profile['level']}'),
          ),
        if (profile['last_active_at'] != null)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('Actif: ${_formatLastActive(profile['last_active_at'])}'),
          ),
        // Stats if available
        if (profile['stats_visible'] == true)
          const ListTile(
            leading: Icon(Icons.analytics),
            title: Text('Statistiques disponibles'),
          ),
      ],
    );
  }

  Widget _buildFilteredProfile(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age (privacy-aware)
        if (profile['hide_age'] != true && profile['age'] != null)
          ListTile(
            leading: const Icon(Icons.cake),
            title: Text('${profile['age']} ans'),
          )
        else if (profile['hide_age'] == true)
          ListTile(
            leading: Icon(Icons.cake, color: Colors.grey[400]),
            title: Text(
              'Âge masqué',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        
        // Level (privacy-aware)
        if (profile['hide_level'] != true && profile['level'] != null)
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text('Niveau: ${profile['level']}'),
          )
        else if (profile['hide_level'] == true)
          ListTile(
            leading: Icon(Icons.trending_up, color: Colors.grey[400]),
            title: Text(
              'Niveau masqué',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        
        // Last active (privacy-aware)
        if (profile['hide_last_active'] != true && profile['last_active_at'] != null)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('Actif: ${_formatLastActive(profile['last_active_at'])}'),
          )
        else if (profile['hide_last_active'] == true)
          ListTile(
            leading: Icon(Icons.access_time, color: Colors.grey[400]),
            title: Text(
              'Activité masquée',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        
        // Stats (privacy-aware)
        if (profile['hide_stats'] != true && profile['stats_visible'] == true)
          const ListTile(
            leading: Icon(Icons.analytics),
            title: Text('Statistiques disponibles'),
          )
        else if (profile['hide_stats'] == true)
          ListTile(
            leading: Icon(Icons.analytics, color: Colors.grey[400]),
            title: Text(
              'Statistiques masquées',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  String _formatLastActive(dynamic lastActive) {
    if (lastActive == null) return 'Inconnu';
    
    try {
      final date = lastActive is DateTime 
          ? lastActive 
          : DateTime.parse(lastActive.toString());
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inDays}j';
      }
    } catch (e) {
      return 'Récemment';
    }
  }
}

class PrivacyInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const PrivacyInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info,
    this.color = Colors.blue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
