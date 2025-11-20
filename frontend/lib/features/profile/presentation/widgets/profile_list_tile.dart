import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// ListTile personnalisé pour les champs du profil
class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    required this.title,
    this.value,
    this.icon,
    this.onTap,
    this.showChevron = true,
  });
  
  final String title;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showChevron;
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppColors.primaryPink,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (value != null && value!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      value!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (value == null || value!.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Non renseigné',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

