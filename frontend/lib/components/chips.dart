import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// CrewSnow Design System - Chips & Tags

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });
  
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.buttonGradient : null,
          color: isSelected ? null : AppColors.cardBackground,
          border: Border.all(
            color: isSelected 
              ? AppColors.primaryPink 
              : AppColors.chipBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected 
            ? [BoxShadow(
                color: AppColors.primaryShadow.color,
                blurRadius: 6,
                offset: AppColors.primaryShadow.offset,
                spreadRadius: AppColors.primaryShadow.spreadRadius,
              )] 
            : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected 
                  ? AppColors.textOnPink 
                  : AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: isSelected 
                ? AppTypography.chipSelected 
                : AppTypography.chipUnselected,
            ),
          ],
        ),
      ),
    );
  }
}

class MultiSelectChips extends StatefulWidget {
  const MultiSelectChips({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onChanged,
    this.wrap = true,
    this.spacing = 8,
    this.runSpacing = 8,
  });
  
  final List<String> options;
  final Set<String> selectedOptions;
  final ValueChanged<Set<String>> onChanged;
  final bool wrap;
  final double spacing;
  final double runSpacing;
  
  @override
  State<MultiSelectChips> createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<MultiSelectChips> {
  @override
  Widget build(BuildContext context) {
    if (widget.wrap) {
      return Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        children: widget.options.map((option) => AppChip(
          label: option,
          isSelected: widget.selectedOptions.contains(option),
          onTap: () => _toggleOption(option),
        )).toList(),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.options.map((option) => Padding(
          padding: EdgeInsets.only(right: widget.spacing),
          child: AppChip(
            label: option,
            isSelected: widget.selectedOptions.contains(option),
            onTap: () => _toggleOption(option),
          ),
        )).toList(),
      ),
    );
  }
  
  void _toggleOption(String option) {
    final newSelection = Set<String>.from(widget.selectedOptions);
    if (newSelection.contains(option)) {
      newSelection.remove(option);
    } else {
      newSelection.add(option);
    }
    widget.onChanged(newSelection);
  }
}

class SingleSelectChips extends StatelessWidget {
  const SingleSelectChips({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
    this.wrap = true,
    this.spacing = 8,
    this.runSpacing = 8,
  });
  
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onChanged;
  final bool wrap;
  final double spacing;
  final double runSpacing;
  
  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: options.map((option) => AppChip(
          label: option,
          isSelected: selectedOption == option,
          onTap: () => onChanged(option),
        )).toList(),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) => Padding(
          padding: EdgeInsets.only(right: spacing),
          child: AppChip(
            label: option,
            isSelected: selectedOption == option,
            onTap: () => onChanged(option),
          ),
        )).toList(),
      ),
    );
  }
}

class LevelChip extends StatelessWidget {
  const LevelChip({
    super.key,
    required this.level,
    required this.isSelected,
    required this.onTap,
  });
  
  final String level;
  final bool isSelected;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      switch (level.toLowerCase()) {
        case 'débutant':
        case 'beginner':
          return Icons.downhill_skiing;
        case 'intermédiaire':
        case 'intermediate':
          return Icons.sports_motorsports_outlined;
        case 'confirmé':
        case 'advanced':
          return Icons.speed_outlined;
        case 'expert':
          return Icons.emoji_events_outlined;
        default:
          return Icons.person_outline;
      }
    }
    
    return AppChip(
      label: level,
      isSelected: isSelected,
      onTap: onTap,
      icon: getIcon(),
    );
  }
}
