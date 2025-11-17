import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../privacy/widgets/privacy_settings_screen.dart';
import '../../privacy/widgets/video_verification_screen.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class SafetyCenterScreen extends ConsumerWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre de Sécurité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: AppSpacing.xl),
            
            // Verification section
            _buildVerificationSection(context),
            const SizedBox(height: AppSpacing.lg),
            
            // Privacy section
            _buildPrivacySection(context),
            const SizedBox(height: AppSpacing.lg),
            
            // Safety tools
            _buildSafetyToolsSection(context),
            const SizedBox(height: AppSpacing.lg),
            
            // Help & Support
            _buildHelpSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votre sécurité avant tout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Gérez vos paramètres de confidentialité et sécurité',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vérification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text('Vérification vidéo'),
                subtitle: const Text('Vérifiez votre identité pour plus de confiance'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VideoVerificationScreen(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Modération des photos'),
                subtitle: const Text('Statut de vos photos en cours de modération'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showPhotoModerationStatus(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confidentialité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Paramètres de confidentialité'),
                subtitle: const Text('Contrôlez qui peut voir quoi'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Mode invisible'),
                subtitle: const Text('Gérer votre visibilité'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showInvisibleModeInfo(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.data_usage),
                title: const Text('Mes données'),
                subtitle: const Text('Exporter ou supprimer mes données'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showDataManagement(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outils de Sécurité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Signaler un utilisateur'),
                subtitle: const Text('Signaler un comportement inapproprié'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showReportFlow(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Utilisateurs bloqués'),
                subtitle: const Text('Gérer votre liste d\'utilisateurs bloqués'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showBlockedUsers(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Modération IA'),
                subtitle: const Text('Configuration de la modération automatique'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showAIModerationSettings(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aide et Support',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Centre d\'aide'),
                subtitle: const Text('FAQ et guides d\'utilisation'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _openHelpCenter(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.contact_support),
                title: const Text('Contacter le support'),
                subtitle: const Text('Besoin d\'aide ? Contactez notre équipe'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _contactSupport(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Règles de la communauté'),
                subtitle: const Text('Lisez nos règles et conditions'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showCommunityGuidelines(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPhotoModerationStatus(BuildContext context) {
    // Show photo moderation status screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modération des Photos'),
        content: const Text('Ici s\'afficherait le statut de modération de vos photos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showInvisibleModeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Invisible'),
        content: const Text(
          'En mode invisible, votre profil n\'apparaît dans les résultats de recherche '
          'que des personnes que vous likez en premier.\n\n'
          'Cela vous donne plus de contrôle sur qui peut vous voir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showDataManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestion des Données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exporter mes données'),
              onTap: () {
                Navigator.of(context).pop();
                // Trigger data export
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                // Show account deletion flow
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportFlow(BuildContext context) {
    // Show report user flow
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un Utilisateur'),
        content: const Text('Sélectionnez l\'utilisateur à signaler depuis votre liste de conversations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsers(BuildContext context) {
    // Show blocked users list
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Utilisateurs Bloqués'),
        content: const Text('Aucun utilisateur bloqué pour le moment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAIModerationSettings(BuildContext context) {
    // Show AI moderation settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modération IA'),
        content: const Text(
          'La modération IA analyse automatiquement les messages pour détecter '
          'le contenu inapproprié et protéger la communauté.',
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

  void _openHelpCenter() {
    // Open help center URL
    debugPrint('Opening help center');
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le Support'),
        content: const Text('Support: support@crewsnow.com\n\nNous répondons dans les 24h.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCommunityGuidelines() {
    // Show community guidelines
    debugPrint('Showing community guidelines');
  }
}
