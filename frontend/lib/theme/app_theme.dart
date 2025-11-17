import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// CrewSnow Design System - Main Theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPink,
        primaryContainer: AppColors.primaryPinkDark,
        secondary: AppColors.primaryPinkDark,
        surface: AppColors.cardBackground,
        error: AppColors.error,
        onPrimary: AppColors.textOnPink,
        onSecondary: AppColors.textOnPink,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPink,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundEnd,
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        titleTextStyle: AppTypography.h3,
        centerTitle: true,
      ),
      
      // Elevated Button (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: AppColors.textOnPink,
          elevation: 0,
          shadowColor: AppColors.primaryPink.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // Pill shape
          ),
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.buttonPrimary,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primaryPinkDark;
              }
              if (states.contains(WidgetState.disabled)) {
                return AppColors.textSecondary.withOpacity(0.3);
              }
              return AppColors.primaryPink;
            },
          ),
        ),
      ),
      
      // Outlined Button (Secondary)  
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          backgroundColor: AppColors.cardBackground,
          elevation: 0,
          side: const BorderSide(
            color: AppColors.primaryPink,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTypography.buttonSecondary,
        ),
      ),
      
      // Text Button (Ghost)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          textStyle: AppTypography.buttonGhost,
        ),
      ),
      
      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryPink,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        hintStyle: AppTypography.inputPlaceholder,
        labelStyle: AppTypography.caption,
        errorStyle: AppTypography.small.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shadowColor: AppColors.primaryPink.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedColor: AppColors.primaryPink,
        disabledColor: AppColors.textSecondary.withOpacity(0.1),
        side: const BorderSide(color: AppColors.chipBorder, width: 1),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.chipUnselected,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        checkmarkColor: AppColors.textOnPink,
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        elevation: 8,
      ),
      
      // Dialog  
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.h3,
        contentTextStyle: AppTypography.body,
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.textOnPink,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryPink,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.caption,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primaryPink, width: 2),
        ),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryPink,
        linearTrackColor: AppColors.inputBorder,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        titleTextStyle: AppTypography.bodyBold,
        subtitleTextStyle: AppTypography.caption,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    // Pour l'instant, retourner light theme
    // TODO: implémenter dark mode si nécessaire
    return lightTheme;
  }
  
  // Helper pour overlay background sur dégradé
  static Widget backgroundGradient({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: child,
    );
  }
}
