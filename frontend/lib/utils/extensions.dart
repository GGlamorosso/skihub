import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extensions utiles pour CrewSnow

extension StringExtensions on String {
  /// Capitalise la première lettre
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Vérifie si l'email est valide
  bool get isValidEmail {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(this);
  }
  
  /// Tronque le texte avec ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension DateTimeExtensions on DateTime {
  /// Format date pour affichage (ex: "15 Jan 2024")
  String get displayDate => DateFormat('d MMM yyyy', 'fr_FR').format(this);
  
  /// Format date courte (ex: "15/01")
  String get shortDate => DateFormat('dd/MM', 'fr_FR').format(this);
  
  /// Format heure (ex: "14:30")
  String get timeOnly => DateFormat('HH:mm', 'fr_FR').format(this);
  
  /// Temps relatif (ex: "il y a 2h")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 7) {
      return displayDate;
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'à l\'instant';
    }
  }
  
  /// Vérifie si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Vérifie si c'est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

extension IntExtensions on int {
  /// Format avec séparateurs (ex: 1000 -> "1 000")
  String get formatted => NumberFormat('#,###', 'fr_FR').format(this);
  
  /// Calcul âge depuis année de naissance
  int get ageFromBirthYear {
    final now = DateTime.now();
    return now.year - this;
  }
}

extension DoubleExtensions on double {
  /// Format distance (ex: 1.2 -> "1,2 km")
  String get distanceDisplay {
    if (this < 1) {
      return '${(this * 1000).toInt()}m';
    }
    return '${toStringAsFixed(1)} km';
  }
  
  /// Format vitesse (ex: 45.6 -> "45,6 km/h")
  String get speedDisplay => '${toStringAsFixed(1)} km/h';
  
  /// Format altitude (ex: 2300.0 -> "2 300m")
  String get altitudeDisplay => '${toInt().formatted}m';
}

extension ListExtensions<T> on List<T> {
  /// Récupère élément à index ou null si hors limites
  T? get(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Divise la liste en chunks
  List<List<T>> chunk(int size) {
    List<List<T>> chunks = [];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

extension BuildContextExtensions on BuildContext {
  /// Taille de l'écran
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Hauteur de l'écran
  double get screenHeight => screenSize.height;
  
  /// Largeur de l'écran
  double get screenWidth => screenSize.width;
  
  /// Padding système (status bar, etc.)
  EdgeInsets get systemPadding => MediaQuery.of(this).padding;
  
  /// Hauteur du clavier
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  
  /// Vérifie si le clavier est ouvert
  bool get isKeyboardOpen => keyboardHeight > 0;
  
  /// ThemeData actuel
  ThemeData get theme => Theme.of(this);
  
  /// TextTheme actuel
  TextTheme get textTheme => theme.textTheme;
  
  /// ColorScheme actuel
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Affiche un snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Affiche un snackbar de succès
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }
  
  /// Affiche un snackbar d'erreur
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }
}
