import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

/// CrewSnow Design System - Layout Components

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });
  
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: padding,
            child: body,
          ),
        ),
      ),
    );
  }
}

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.onNext,
    this.onBack,
    this.progress = 0.0,
    this.nextText = 'Continuer',
    this.isNextEnabled = true,
    this.isLoading = false,
  });
  
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final double progress; // 0.0 to 1.0
  final String nextText;
  final bool isNextEnabled;
  final bool isLoading;
  
  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Column(
        children: [
          // Header avec progress et navigation
          _OnboardingHeader(
            progress: progress,
            onBack: onBack,
          ),
          const SizedBox(height: 32),
          
          // Titre et sous-titre
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h1),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTypography.body),
            ],
          ),
          const SizedBox(height: 32),
          
          // Contenu principal
          Expanded(
            child: content,
          ),
          
          // Bouton suivant
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: PrimaryButton(
              text: nextText,
              onPressed: onNext,
              isEnabled: isNextEnabled,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.progress,
    this.onBack,
  });
  
  final double progress;
  final VoidCallback? onBack;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bouton retour
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          )
        else
          const SizedBox(width: 48),
          
        // Barre de progression
        Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 48), // Balance pour alignement
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.elevation = 0,
  });
  
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double elevation;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: elevation > 0 
          ? [BoxShadow(
              color: AppColors.cardShadow.color,
              blurRadius: elevation * 2,
              offset: AppColors.cardShadow.offset,
              spreadRadius: AppColors.cardShadow.spreadRadius,
            )]
          : [AppColors.cardShadow],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.total,
    required this.current,
  });
  
  final int total;
  final int current;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index <= current;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryPink : AppColors.inputBorder,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
