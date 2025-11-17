import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../constants/app_spacing.dart';
import '../constants/app_colors.dart';

// Accessible card swipe widget
class AccessibleSwipeCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final String semanticLabel;
  final String? likeLabel;
  final String? passLabel;

  const AccessibleSwipeCard({
    super.key,
    required this.child,
    this.onLike,
    this.onPass,
    required this.semanticLabel,
    this.likeLabel = 'Liker ce profil',
    this.passLabel = 'Passer ce profil',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        children: [
          Expanded(child: child),
          
          // Accessible action buttons for screen readers
          Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Semantics(
                    button: true,
                    label: passLabel,
                    child: FloatingActionButton(
                      heroTag: 'pass',
                      onPressed: onPass,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: likeLabel,
                    child: FloatingActionButton(
                      heroTag: 'like',
                      onPressed: onLike,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.favorite, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// High contrast mode support
class HighContrastText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool forceHighContrast;

  const HighContrastText(
    this.text, {
    super.key,
    this.style,
    this.forceHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.of(context).highContrast || forceHighContrast;
    
    TextStyle effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium!;
    
    if (highContrast) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      effectiveStyle = effectiveStyle.copyWith(
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
        shadows: isDark 
            ? [const Shadow(color: Colors.black, blurRadius: 2)]
            : [const Shadow(color: Colors.white, blurRadius: 2)],
      );
    }

    return Text(text, style: effectiveStyle);
  }
}

// Focus-aware navigation
class AccessibleBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const AccessibleBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<AccessibleBottomNavigation> createState() => _AccessibleBottomNavigationState();
}

class _AccessibleBottomNavigationState extends State<AccessibleBottomNavigation> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        items: widget.items.map((item) {
          return BottomNavigationBarItem(
            icon: Semantics(
              button: true,
              label: item.label,
              child: item.icon,
            ),
            activeIcon: Semantics(
              button: true,
              label: '${item.label} - actuel',
              child: item.activeIcon ?? item.icon,
            ),
            label: item.label,
          );
        }).toList(),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }
}

// Screen reader announcements
class AccessibilityAnnouncer {
  static void announce(String message, {bool assertive = false}) {
    SemanticsService.announce(
      message,
      assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }

  static void announceMatch(String username) {
    announce('Nouveau match avec $username !', assertive: true);
  }

  static void announceMessage(String senderName) {
    announce('Nouveau message de $senderName');
  }

  static void announceError(String error) {
    announce('Erreur: $error', assertive: true);
  }

  static void announceSuccess(String message) {
    announce(message, assertive: false);
  }

  static void announceQuotaLimit(String type) {
    announce('Limite quotidienne atteinte pour $type', assertive: true);
  }
}

// Large tap targets for accessibility
class LargeTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double minSize;

  const LargeTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.minSize = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Accessibility-aware animations
class ReducedMotionWidget extends StatelessWidget {
  final Widget child;
  final Widget reducedMotionChild;

  const ReducedMotionWidget({
    super.key,
    required this.child,
    required this.reducedMotionChild,
  });

  @override
  Widget build(BuildContext context) {
    final reduceAnimations = MediaQuery.of(context).disableAnimations;
    return reduceAnimations ? reducedMotionChild : child;
  }
}

// Color blind friendly indicators
class ColorBlindFriendlyIndicator extends StatelessWidget {
  final bool isActive;
  final String label;
  final Color? activeColor;
  final Color? inactiveColor;

  const ColorBlindFriendlyIndicator({
    super.key,
    required this.isActive,
    required this.label,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive 
            ? (activeColor ?? Colors.green[100])
            : (inactiveColor ?? Colors.grey[100]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive 
              ? (activeColor ?? Colors.green)
              : (inactiveColor ?? Colors.grey),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isActive 
                ? (activeColor ?? Colors.green[700])
                : (inactiveColor ?? Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive 
                  ? (activeColor ?? Colors.green[700])
                  : (inactiveColor ?? Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

// Text scaling support
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double maxScaleFactor;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxScaleFactor = 1.4,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.8, maxScaleFactor);
    
    return Text(
      text,
      style: style?.copyWith(fontSize: (style?.fontSize ?? 14) * scaleFactor),
      textAlign: textAlign,
      textScaleFactor: 1.0, // Prevent double scaling
    );
  }
}

// Focus management for forms
class AccessibleForm extends StatefulWidget {
  final List<Widget> children;
  final VoidCallback? onSubmit;

  const AccessibleForm({
    super.key,
    required this.children,
    this.onSubmit,
  });

  @override
  State<AccessibleForm> createState() => _AccessibleFormState();
}

class _AccessibleFormState extends State<AccessibleForm> {
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.children.length; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextFocus(int currentIndex) {
    if (currentIndex < _focusNodes.length - 1) {
      _focusNodes[currentIndex + 1].requestFocus();
    } else {
      // Last field - trigger submit if available
      widget.onSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        if (child is TextField) {
          return Focus(
            focusNode: _focusNodes[index],
            child: TextField(
              focusNode: _focusNodes[index],
              textInputAction: index < widget.children.length - 1 
                  ? TextInputAction.next 
                  : TextInputAction.done,
              onSubmitted: (_) => _nextFocus(index),
              // Copy other properties from original TextField
            ),
          );
        }
        
        return child;
      }).toList(),
    );
  }
}
