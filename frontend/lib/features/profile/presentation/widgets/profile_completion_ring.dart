import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// Widget pour afficher le cercle de progression de complétion du profil
class ProfileCompletionRing extends StatelessWidget {
  const ProfileCompletionRing({
    super.key,
    required this.completionPercentage,
    this.size = 80.0,
  });
  
  final double completionPercentage; // 0.0 à 1.0
  final double size;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de fond
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: completionPercentage,
              strokeWidth: 6,
              backgroundColor: AppColors.inputBorder,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
            ),
          ),
          // Pourcentage au centre
          Text(
            '${(completionPercentage * 100).toInt()}%',
            style: AppTypography.h3.copyWith(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

