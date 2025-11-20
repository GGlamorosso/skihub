import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// Header de section avec titre et badge optionnel
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.badgeColor,
    this.actionButton,
  });
  
  final String title;
  final String? badge; // Ex: "IMPORTANT", "+30%"
  final Color? badgeColor;
  final Widget? actionButton; // Ex: bouton "AJOUTER"
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (actionButton != null) actionButton!,
        ],
      ),
    );
  }
}

