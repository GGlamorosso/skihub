import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Extension helper pour sécuriser les appels context.pop()
extension SafeNavigation on BuildContext {
  /// Pop sécurisé : vérifie si on peut pop avant de le faire
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      // Si on ne peut pas pop, rediriger vers une route safe
      go('/');
    }
  }
  
  /// Pop avec fallback vers une route spécifique
  void safePopOrGo(String fallbackRoute) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackRoute);
    }
  }
}

