import 'package:flutter/material.dart';

/// CrewSnow Design System - Colors
/// Ligne directrice : fond rose + dégradés blanc, pas l'inverse
/// Ambiance Tinder / ski / bubble-gum
class AppColors {
  // Couleurs principales
  static const Color primaryPink = Color(0xFFFF4B8A);
  static const Color primaryPinkDark = Color(0xFFE03676);
  
  // Fond & surfaces
  static const Color backgroundStart = Color(0xFFFF4B8A); // Haut dégradé
  static const Color backgroundEnd = Color(0xFFFFFFFF);   // Bas dégradé
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color overlayBlur = Color(0x99FFFFFF);     // 60% opacité
  
  // Texte
  static const Color textPrimary = Color(0xFF1F1F2B);     // Quasi noir
  static const Color textSecondary = Color(0xFF6C6C80);
  static const Color textOnPink = Color(0xFFFFFFFF);
  
  // États / feedback
  static const Color success = Color(0xFF3CCB7A);
  static const Color warning = Color(0xFFFFB547);
  static const Color error = Color(0xFFFF4B4B);
  
  // Couleurs spéciales
  static const Color chipBorder = Color(0xFFFFD2E3);
  static const Color inputBorder = Color(0xFFFFE0EC);
  
  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryPink, Color(0xFFFFE5F1)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryPink, Color(0xFFFF82B1)],
  );
  
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x80000000)],
  );
  
  // Helper methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  static BoxShadow get primaryShadow => BoxShadow(
    color: primaryPink.withOpacity(0.25),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow get cardShadow => BoxShadow(
    color: primaryPink.withOpacity(0.15),
    blurRadius: 12,
    offset: const Offset(0, 6),
  );
}
