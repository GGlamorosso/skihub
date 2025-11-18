import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// CrewSnow Design System - Boutons

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.icon,
  });
  
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final IconData? icon;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: isEnabled && !isLoading 
            ? AppColors.buttonGradient 
            : null,
          color: !isEnabled || isLoading 
            ? AppColors.textSecondary.withOpacity(0.3) 
            : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isEnabled && !isLoading 
            ? [AppColors.primaryShadow] 
            : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.textOnPink,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.textOnPink, size: 18), // ✅ Réduit de 20 à 18
                    const SizedBox(width: 6), // ✅ Réduit de 8 à 6
                  ],
                  Flexible( // ✅ Permet au texte de se réduire si nécessaire
                    child: Text(
                      text,
                      style: AppTypography.buttonPrimary,
                      overflow: TextOverflow.ellipsis, // ✅ Tronquer si trop long
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.icon,
  });
  
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final IconData? icon;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.primaryPink,
          side: BorderSide(
            color: isEnabled 
              ? AppColors.primaryPink 
              : AppColors.textSecondary.withOpacity(0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primaryPink,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primaryPink, size: 18), // ✅ Réduit de 20 à 18
                  const SizedBox(width: 6), // ✅ Réduit de 8 à 6
                ],
                Flexible( // ✅ Permet au texte de se réduire si nécessaire
                  child: Text(
                    text,
                    style: AppTypography.buttonSecondary,
                    overflow: TextOverflow.ellipsis, // ✅ Tronquer si trop long
                    maxLines: 1,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
  });
  
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryPink,
      ),
      child: Text(
        text,
        style: AppTypography.buttonGhost,
      ),
    );
  }
}

class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.cardBackground,
    this.iconColor = AppColors.primaryPink,
    this.size = 56,
  });
  
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [AppColors.cardShadow],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        iconSize: size * 0.4,
      ),
    );
  }
}

class SwipeActionButton extends StatelessWidget {
  const SwipeActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.type,
  });
  
  final IconData icon;
  final VoidCallback? onPressed;
  final SwipeActionType type;
  
  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    
    switch (type) {
      case SwipeActionType.pass:
        backgroundColor = AppColors.textSecondary.withOpacity(0.1);
        iconColor = AppColors.textSecondary;
        break;
      case SwipeActionType.like:
        backgroundColor = AppColors.success.withOpacity(0.1);
        iconColor = AppColors.success;
        break;
      case SwipeActionType.superLike:
        backgroundColor = AppColors.primaryPink.withOpacity(0.1);
        iconColor = AppColors.primaryPink;
        break;
    }
    
    return CircularIconButton(
      icon: icon,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      size: 64,
    );
  }
}

enum SwipeActionType {
  pass,
  like,
  superLike,
}
