import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../features/chat/controllers/matches_controller.dart';

/// Navigation principale de l'application
class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
  });
  
  final int currentIndex;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(totalUnreadCountProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Feed
              _buildNavItem(
                icon: Icons.explore,
                label: 'Découvrir',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/feed'),
              ),
              
              // Matches
              _buildNavItem(
                icon: Icons.favorite,
                label: 'Matches',
                isSelected: currentIndex == 1,
                badge: unreadCount > 0 ? unreadCount : null,
                onTap: () => context.go('/matches'),
              ),
              
              // Tracker
              _buildNavItem(
                icon: Icons.my_location,
                label: 'Tracker',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/tracker'),
              ),
              
              // Profil
              _buildNavItem(
                icon: Icons.person,
                label: 'Profil',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.buttonGradient : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec badge
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                    ? Colors.white 
                    : AppColors.textSecondary,
                  size: 24,
                ),
                
                // Badge notifications
                if (badge != null && badge > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Label
            Text(
              label,
              style: AppTypography.small.copyWith(
                color: isSelected 
                  ? Colors.white 
                  : AppColors.textSecondary,
                fontWeight: isSelected 
                  ? FontWeight.w600 
                  : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scaffold avec navigation intégrée
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.showBottomNav = true,
  });
  
  final Widget body;
  final int currentIndex;
  final bool showBottomNav;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: showBottomNav
        ? AppBottomNavigation(currentIndex: currentIndex)
        : null,
    );
  }
}

/// Helper pour obtenir index navigation depuis route
class NavigationHelper {
  static int getIndexFromRoute(String route) {
    if (route.startsWith('/feed')) return 0;
    if (route.startsWith('/matches')) return 1;
    if (route.startsWith('/chat')) return 2;
    if (route.startsWith('/profile')) return 3;
    return 0; // Default feed
  }
  
  static String getRouteFromIndex(int index) {
    switch (index) {
      case 0: return '/feed';
      case 1: return '/matches';
      case 2: return '/chat';
      case 3: return '/profile';
      default: return '/feed';
    }
  }
}
