import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../components/layout.dart';
import '../../../components/buttons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/ride_stats.dart';
import '../controllers/stats_controller.dart';
import '../../profile/controllers/profile_controller.dart';

/// Écran statistiques ski
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsControllerProvider);
    final profile = ref.watch(currentProfileProvider);
    
    return GradientScaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Tabs
          _buildTabBar(),
          
          // Contenu tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(statsState, profile?.isPremium ?? false),
                _buildChartsTab(statsState, profile?.isPremium ?? false),
                _buildHistoryTab(statsState, profile?.isPremium ?? false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.tracker);
              }
            },
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            'Mes Statistiques',
            style: AppTypography.h3,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ref.read(statsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: AppColors.primaryPink),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.cardShadow],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Résumé'),
          Tab(text: 'Graphiques'),
          Tab(text: 'Historique'),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab(StatsState statsState, bool isPremium) {
    if (statsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }
    
    if (statsState.hasError) {
      return _buildErrorState(statsState.error!);
    }
    
    if (statsState.totalStats == null) {
      return _buildNoStatsState();
    }
    
    final total = statsState.totalStats!;
    final recent = statsState.recentStats;
    
    return RefreshIndicator(
      onRefresh: () => ref.read(statsControllerProvider.notifier).refresh(),
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats totales
            Text('Statistiques totales', style: AppTypography.h3),
            const SizedBox(height: 16),
            
            _buildStatsGrid([
              _StatItem('Distance totale', '${total.totalDistanceKm.toStringAsFixed(1)} km', Icons.straighten),
              _StatItem('Vitesse max', '${total.maxSpeedKmh.toStringAsFixed(1)} km/h', Icons.speed),
              _StatItem('Dénivelé total', '${total.totalElevationM} m', Icons.terrain),
              _StatItem('Sessions', '${total.sessionsCount}', Icons.downhill_skiing),
            ]),
            
            const SizedBox(height: 32),
            
            // Stats récentes (7 jours)
            if (recent.isNotEmpty) ...[
              Text('7 derniers jours', style: AppTypography.h3),
              const SizedBox(height: 16),
              
              _buildRecentStatsCard(recent),
              
              const SizedBox(height: 24),
            ],
            
            // Premium gating
            if (!isPremium) _buildPremiumTeaser(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartsTab(StatsState statsState, bool isPremium) {
    if (!isPremium) {
      return _buildPremiumGatedContent('graphiques avancés');
    }
    
    if (statsState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }
    
    if (statsState.recentStats.length < 2) {
      return _buildNotEnoughDataState();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphique distance
          Text('Distance par jour', style: AppTypography.h3),
          const SizedBox(height: 16),
          _buildDistanceChart(statsState.recentStats),
          
          const SizedBox(height: 32),
          
          // Graphique vitesse
          Text('Vitesse max par jour', style: AppTypography.h3),
          const SizedBox(height: 16),
          _buildSpeedChart(statsState.recentStats),
          
          const SizedBox(height: 32),
          
          // Répartition par station
          if (statsState.stationStats.isNotEmpty) ...[
            Text('Répartition par station', style: AppTypography.h3),
            const SizedBox(height: 16),
            _buildStationChart(statsState.stationStats),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab(StatsState statsState, bool isPremium) {
    if (statsState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }
    
    final stats = isPremium 
      ? statsState.allStats 
      : statsState.recentStats.take(7).toList();
    
    if (stats.isEmpty) {
      return _buildNoStatsState();
    }
    
    return Column(
      children: [
        // Header historique
        if (!isPremium) ...[
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Historique limité aux 7 derniers jours. Passez Premium pour l\'historique complet !',
                    style: AppTypography.small.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Liste sessions
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(statsControllerProvider.notifier).refresh(),
            color: AppColors.primaryPink,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _buildHistoryItem(stat);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppColors.primaryPink, size: 32),
            const SizedBox(height: 8),
            Text(
              item.value,
              style: AppTypography.h3.copyWith(color: AppColors.primaryPink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )).toList(),
    );
  }
  
  Widget _buildRecentStatsCard(List<RideStats> recentStats) {
    final totalDistance = recentStats.fold<double>(0, (sum, stat) => sum + stat.distanceKm);
    final maxSpeed = recentStats.fold<double>(0, (max, stat) => math.max(max, stat.vmaxKmh));
    final totalElevation = recentStats.fold<int>(0, (sum, stat) => sum + stat.elevationGainM);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.primaryShadow],
      ),
      child: Column(
        children: [
          Text(
            'Performance cette semaine',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRecentStatItem(
                '${totalDistance.toStringAsFixed(1)} km',
                'Distance',
                Icons.straighten,
              ),
              _buildRecentStatItem(
                '${maxSpeed.toStringAsFixed(1)} km/h',
                'Vitesse max',
                Icons.speed,
              ),
              _buildRecentStatItem(
                '$totalElevation m',
                'Dénivelé',
                Icons.terrain,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.bodyBold.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTypography.small.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
  
  Widget _buildDistanceChart(List<RideStats> stats) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: stats.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.distanceKm);
              }).toList(),
              isCurved: true,
              gradient: AppColors.buttonGradient,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withOpacity(0.3),
                    AppColors.primaryPink.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpeedChart(List<RideStats> stats) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: stats.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.vmaxKmh);
              }).toList(),
              isCurved: true,
              color: AppColors.success,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStationChart(Map<String, double> stationStats) {
    final sections = stationStats.entries.map((entry) {
      final colors = [
        AppColors.primaryPink,
        AppColors.success,
        AppColors.warning,
        Colors.blue,
        Colors.purple,
      ];
      
      final index = stationStats.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];
      
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}km',
        color: color,
        radius: 60,
        titleStyle: AppTypography.small.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
  
  Widget _buildHistoryItem(RideStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${stat.date.day}',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
                Text(
                  _getMonthName(stat.date.month),
                  style: AppTypography.small.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Stats principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stat.stationName != null) ...[
                  Text(
                    stat.stationName!,
                    style: AppTypography.bodyBold,
                  ),
                  const SizedBox(height: 4),
                ],
                
                Row(
                  children: [
                    _buildMiniStat(stat.distanceDisplay, Icons.straighten),
                    const SizedBox(width: 16),
                    _buildMiniStat(stat.speedDisplay, Icons.speed),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    _buildMiniStat(stat.elevationDisplay, Icons.terrain),
                    const SizedBox(width: 16),
                    _buildMiniStat(stat.timeDisplay, Icons.timer),
                  ],
                ),
              ],
            ),
          ),
          
          // Score performance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${stat.performanceScore.toInt()}',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniStat(String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.small),
      ],
    );
  }
  
  Widget _buildPremiumTeaser() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withOpacity(0.1), AppColors.warning.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: AppColors.warning, size: 48),
          const SizedBox(height: 16),
          Text(
            'Débloquez toutes vos stats',
            style: AppTypography.h3.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: 8),
          Text(
            'Historique complet, graphiques avancés, comparaisons et export de données.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Devenir Premium',
            onPressed: () {
              // TODO S7: Navigation premium
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium S7')),
              );
            },
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPremiumGatedContent(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 64, color: AppColors.warning),
          const SizedBox(height: 16),
          Text(
            'Fonctionnalité Premium',
            style: AppTypography.h3.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: 8),
          Text(
            'Accédez aux $feature avec Premium.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Devenir Premium',
            onPressed: () {
              // TODO S7: Navigation premium
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium S7')),
              );
            },
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoStatsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 24),
          Text('Aucune statistique', style: AppTypography.h3),
          const SizedBox(height: 12),
          Text(
            'Commencez à tracker vos sessions pour voir vos stats !',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Démarrer le tracking',
            icon: Icons.play_arrow,
            onPressed: () {
              if (context.canPop()) {
                context.pop(); // Retour tracker
              } else {
                context.go(AppRoutes.tracker);
              }
            },
            width: 250,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotEnoughDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Pas assez de données', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(
            'Trackez au moins 2 sessions pour voir les graphiques.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Réessayer',
            onPressed: () => ref.read(statsControllerProvider.notifier).refresh(),
            width: 200,
          ),
        ],
      ),
    );
  }
  
  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month];
  }
}

/// Item statistique pour grid
class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  
  const _StatItem(this.title, this.value, this.icon);
}
