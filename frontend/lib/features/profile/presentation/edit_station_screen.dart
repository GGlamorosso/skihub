import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/station.dart';
import '../../../services/user_service.dart';
import '../controllers/profile_controller.dart';

/// Écran pour modifier la station active de l'utilisateur
class EditStationScreen extends ConsumerStatefulWidget {
  const EditStationScreen({super.key});
  
  @override
  ConsumerState<EditStationScreen> createState() => _EditStationScreenState();
}

class _EditStationScreenState extends ConsumerState<EditStationScreen> {
  final _searchController = TextEditingController();
  List<Station> _stations = [];
  List<Station> _filteredStations = [];
  bool _isLoadingStations = false;
  bool _isSaving = false;
  
  Station? _selectedStation;
  DateTimeRange? _selectedDateRange;
  int _radiusKm = 25;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStations);
    
    // ✅ Corrigé : Décale les appels qui modifient des providers après la construction du widget
    // Utiliser Future.microtask pour exécuter après la fin du build
    Future.microtask(() {
      _loadStations();
      _loadCurrentStation();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  /// Charger la station actuelle de l'utilisateur
  Future<void> _loadCurrentStation() async {
    // Attendre que le profil soit chargé
    await ref.read(profileControllerProvider.notifier).loadProfile();
    
    final profileState = ref.read(profileControllerProvider);
    final currentStation = profileState.currentStation;
    
    // ✅ Corrigé : Gérer les nulls dans currentStation
    if (currentStation != null && currentStation.isValid && mounted) {
      setState(() {
        _selectedStation = currentStation.station;
        // Utiliser les dates directement depuis le modèle UserStationStatus (avec vérification null)
        if (currentStation.dateFrom != null && currentStation.dateTo != null) {
          _selectedDateRange = DateTimeRange(
            start: currentStation.dateFrom!,
            end: currentStation.dateTo!,
          );
        }
        _radiusKm = currentStation.radiusKm ?? 25;
      });
    } else {
      // Pas de station active, valeurs par défaut
      if (mounted) {
        setState(() {
          _selectedDateRange = DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 7)),
          );
          _radiusKm = 25;
        });
      }
    }
  }
  
  Future<void> _loadStations() async {
    setState(() => _isLoadingStations = true);
    
    try {
      debugPrint('🔍 Loading stations...');
      final stations = await UserService.instance.getStations();
      debugPrint('✅ Loaded ${stations.length} stations');
      
      setState(() {
        _stations = stations;
        // ✅ Afficher toutes les stations au démarrage (pas de filtre)
        _filteredStations = stations;
        _isLoadingStations = false;
      });
      
      if (stations.isEmpty) {
        debugPrint('⚠️ No stations loaded - check database');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading stations: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoadingStations = false);
      _showError('Erreur de chargement des stations: $e');
    }
  }
  
  void _filterStations() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        // Si pas de recherche, afficher toutes les stations
        _filteredStations = _stations;
      } else {
        // Filtrer par nom, région ou pays
        _filteredStations = _stations.where((station) {
          return station.name.toLowerCase().contains(query) ||
                 station.region.toLowerCase().contains(query) ||
                 station.countryCode.toLowerCase().contains(query);
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final canSave = _selectedStation != null && _selectedDateRange != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier ma station'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Où et quand tu skies ?',
                  style: AppTypography.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisis ta station et tes dates de séjour.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Section Station
                Text(
                  'Station de ski',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 16),
                
                // Recherche station avec suggestions
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher une station',
                    hintText: 'Tapez pour voir les suggestions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterStations();
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                    helperText: _isLoadingStations
                      ? 'Chargement des stations...'
                      : _stations.isEmpty
                        ? 'Aucune station disponible'
                        : _searchController.text.isEmpty
                          ? 'Tapez pour rechercher parmi ${_stations.length} stations disponibles'
                          : _filteredStations.isEmpty
                            ? 'Aucune station trouvée. Essayez un autre nom.'
                            : '${_filteredStations.length} station${_filteredStations.length > 1 ? 's' : ''} trouvée${_filteredStations.length > 1 ? 's' : ''} - Cliquez pour sélectionner',
                    helperMaxLines: 2,
                  ),
                  onChanged: (_) => _filterStations(),
                ),
                
                const SizedBox(height: 16),
                
                // Liste stations avec suggestions
                if (_isLoadingStations)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredStations.isEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardBackground,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                              ? 'Commencez à taper pour rechercher'
                              : 'Aucune station trouvée',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Essayez un autre nom de station',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardBackground,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec nombre de résultats
                        if (_searchController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.primaryPink,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Suggestions (${_filteredStations.length})',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryPink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Liste scrollable
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredStations.length,
                            itemBuilder: (context, index) {
                              final station = _filteredStations[index];
                              final isSelected = _selectedStation?.id == station.id;
                              
                              return InkWell(
                                onTap: () {
                                  _selectStation(station);
                                  // Optionnel : fermer le clavier après sélection
                                  FocusScope.of(context).unfocus();
                                },
                                child: Container(
                                  color: isSelected
                                    ? AppColors.primaryPink.withOpacity(0.1)
                                    : Colors.transparent,
                                  child: ListTile(
                                    selected: isSelected,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPink.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          station.flag,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      station.name,
                                      style: AppTypography.bodyBold.copyWith(
                                        color: isSelected ? AppColors.primaryPink : AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${station.region}, ${station.countryCode} • ${station.altitudeDisplay}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    trailing: isSelected
                                      ? Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Section Dates
                Text(
                  'Dates de séjour',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedDateRange != null 
                          ? AppColors.primaryPink 
                          : AppColors.inputBorder,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardBackground,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          color: _selectedDateRange != null 
                            ? AppColors.primaryPink 
                            : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getDateRangeText(),
                            style: AppTypography.body.copyWith(
                              color: _selectedDateRange != null 
                                ? AppColors.textPrimary 
                                : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Section Rayon
                Text(
                  'Rayon de recherche',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _radiusKm.toDouble(),
                        min: 5,
                        max: 100,
                        divisions: 19,
                        activeColor: AppColors.primaryPink,
                        label: '$_radiusKm km',
                        onChanged: (value) {
                          setState(() => _radiusKm = value.round());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_radiusKm km',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Résumé sélection
                if (_selectedStation != null && _selectedDateRange != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(
                              'Ton séjour',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedStation!.flag} ${_selectedStation!.name}',
                          style: AppTypography.bodyBold.copyWith(color: AppColors.success),
                        ),
                        Text(
                          _getDateRangeText(),
                          style: AppTypography.caption.copyWith(color: AppColors.success),
                        ),
                        Text(
                          'Rayon: $_radiusKm km',
                          style: AppTypography.caption.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Bouton sauvegarder
                PrimaryButton(
                  text: _isSaving ? 'Enregistrement...' : 'Enregistrer',
                  onPressed: canSave && !_isSaving ? _saveStation : null,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _selectStation(Station station) {
    setState(() {
      _selectedStation = station;
    });
  }
  
  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialRange = _selectedDateRange ?? DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 7)),
    );
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialRange,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryPink,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }
  
  String _getDateRangeText() {
    if (_selectedDateRange == null) {
      return 'Sélectionner les dates';
    }
    
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
  
  Future<void> _saveStation() async {
    if (_selectedStation == null || _selectedDateRange == null) {
      _showError('Veuillez sélectionner une station et des dates');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final success = await ref.read(profileControllerProvider.notifier).updateStationStatus(
        stationId: _selectedStation!.id,
        dateFrom: _selectedDateRange!.start,
        dateTo: _selectedDateRange!.end,
        radiusKm: _radiusKm,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Station mise à jour avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        _showError('Erreur lors de la mise à jour de la station');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

