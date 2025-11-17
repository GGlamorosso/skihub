import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/layout.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/station.dart';
import '../../../services/user_service.dart';
import '../controllers/onboarding_controller.dart';

/// Écran Station & Dates (nouveau pour S2)
class StationDatesScreen extends ConsumerStatefulWidget {
  const StationDatesScreen({super.key});
  
  @override
  ConsumerState<StationDatesScreen> createState() => _StationDatesScreenState();
}

class _StationDatesScreenState extends ConsumerState<StationDatesScreen> {
  final _searchController = TextEditingController();
  List<Station> _stations = [];
  List<Station> _filteredStations = [];
  bool _isLoadingStations = false;
  
  DateTimeRange? _selectedDateRange;
  int _radiusKm = 25;
  
  @override
  void initState() {
    super.initState();
    _loadStations();
    
    // Charger données existantes
    final onboardingData = ref.read(onboardingControllerProvider);
    if (onboardingData.dateFrom != null && onboardingData.dateTo != null) {
      _selectedDateRange = DateTimeRange(
        start: onboardingData.dateFrom!,
        end: onboardingData.dateTo!,
      );
    }
    _radiusKm = onboardingData.radiusKm ?? 25;
    
    _searchController.addListener(_filterStations);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStations() async {
    setState(() => _isLoadingStations = true);
    
    try {
      final stations = await UserService.instance.getStations();
      setState(() {
        _stations = stations;
        _filteredStations = stations;
        _isLoadingStations = false;
      });
    } catch (e) {
      setState(() => _isLoadingStations = false);
      _showError('Erreur de chargement des stations');
    }
  }
  
  void _filterStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStations = _stations.where((station) {
        return station.name.toLowerCase().contains(query) ||
               station.region.toLowerCase().contains(query) ||
               station.countryCode.toLowerCase().contains(query);
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingControllerProvider);
    final selectedStation = onboardingData.station;
    
    final canContinue = selectedStation != null && _selectedDateRange != null;
    
    return OnboardingLayout(
      progress: 0.7, // Ajouté après langues
      title: 'Où et quand tu skies ?',
      subtitle: 'Choisis ta station et tes dates de séjour.',
      onNext: _handleNext,
      onBack: () => context.go('/onboarding/languages'),
      isNextEnabled: canContinue,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Station
          Text(
            'Station de ski',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 16),
          
          // Recherche station
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher une station',
              hintText: 'Val Thorens, Chamonix...',
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
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste stations
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoadingStations
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    final isSelected = selectedStation?.id == station.id;
                    
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.primaryPink.withOpacity(0.1),
                      leading: Text(
                        station.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        station.name,
                        style: AppTypography.bodyBold.copyWith(
                          color: isSelected ? AppColors.primaryPink : null,
                        ),
                      ),
                      subtitle: Text(
                        '${station.region} • ${station.altitudeDisplay}',
                        style: AppTypography.caption,
                      ),
                      trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : null,
                      onTap: () => _selectStation(station),
                    );
                  },
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
                    ref.read(onboardingControllerProvider.notifier)
                        .updateStationInfo(radiusKm: _radiusKm);
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
          
          const Spacer(),
          
          // Résumé sélection
          if (selectedStation != null && _selectedDateRange != null) ...[
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
                    '${selectedStation.flag} ${selectedStation.name}',
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
          ],
        ],
      ),
    );
  }
  
  void _selectStation(Station station) {
    ref.read(onboardingControllerProvider.notifier).updateStationInfo(
      station: station,
    );
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
      
      ref.read(onboardingControllerProvider.notifier).updateStationInfo(
        dateFrom: picked.start,
        dateTo: picked.end,
      );
    }
  }
  
  String _getDateRangeText() {
    if (_selectedDateRange == null) {
      return 'Sélectionner les dates';
    }
    
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  void _handleNext() {
    context.go('/onboarding/gps');
  }
}
