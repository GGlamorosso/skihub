import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/subscription.dart';
import '../controllers/premium_controller.dart';
import '../../../components/buttons.dart';
import '../../../core/config/app_config.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  final bool fromQuotaLimit;
  final QuotaType? limitType;
  
  const PremiumScreen({
    Key? key,
    this.fromQuotaLimit = false,
    this.limitType,
  }) : super(key: key);

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<PremiumPlan> _premiumPlans = [];
  List<PremiumPlan> _boostPlans = [];
  bool _isAnnual = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final premiumRepository = ref.read(premiumRepositoryProvider);
    final premiumPlans = await premiumRepository.getPremiumPlans();
    final boostPlans = await premiumRepository.getBoostPlans();
    
    setState(() {
      _premiumPlans = premiumPlans;
      _boostPlans = boostPlans;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si Stripe est désactivé
    if (!AppConfig.stripeEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Premium'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Premium bientôt disponible',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Les fonctionnalités premium seront disponibles prochainement. '
                  'Merci de votre patience!',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final premiumState = ref.watch(premiumControllerProvider);
    final premiumController = ref.read(premiumControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!premiumState.isPremium)
            TextButton(
              onPressed: () => premiumController.restorePurchases(),
              child: const Text(
                'Restaurer',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Premium'),
            Tab(text: 'Boosts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPremiumTab(context, premiumState, premiumController),
          _buildBoostsTab(context, premiumState, premiumController),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(
    BuildContext context,
    PremiumState premiumState,
    PremiumController premiumController,
  ) {
    if (premiumState.isPremium) {
      return _buildPremiumActiveView(context, premiumState, premiumController);
    }
    
    return _buildPremiumPaywallView(context, premiumState, premiumController);
  }

  Widget _buildPremiumActiveView(
    BuildContext context,
    PremiumState premiumState,
    PremiumController premiumController,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.diamond, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Premium Actif',
                      style: AppTypography.h2.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (premiumState.subscription != null) ...[
                  Text(
                    'Plan: ${_getPlanDisplayName(premiumState.subscription!)}',
                    style: AppTypography.body1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Renouvellement: ${premiumState.subscription!.currentPeriodEnd.toLocaleDateString()}',
                    style: AppTypography.body2.copyWith(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Premium features status
          _buildFeatureStatusList(),
          
          const SizedBox(height: 32),
          
          // Quota info
          if (premiumState.quotaInfo != null)
            _buildQuotaInfoCard(premiumState.quotaInfo!),
          
          const SizedBox(height: 32),
          
          // Subscription management
          _buildSubscriptionManagement(context, premiumController),
        ],
      ),
    );
  }

  Widget _buildPremiumPaywallView(
    BuildContext context,
    PremiumState premiumState,
    PremiumController premiumController,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero section
          _buildHeroSection(context),
          
          const SizedBox(height: 32),
          
          // Features section
          _buildFeaturesSection(),
          
          const SizedBox(height: 32),
          
          // Plans section
          _buildPlansSection(context, premiumController),
          
          const SizedBox(height: 32),
          
          // Free vs Premium comparison
          _buildComparisonSection(),
          
          const SizedBox(height: 32),
          
          // FAQ section
          _buildFAQSection(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBoostsTab(
    BuildContext context,
    PremiumState premiumState,
    PremiumController premiumController,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active boosts
          if (premiumState.activeBoosts.isNotEmpty) ...[
            Text('Boosts Actifs', style: AppTypography.h3),
            const SizedBox(height: 16),
            ...premiumState.activeBoosts.map((boost) => _buildActiveBoostCard(boost)),
            const SizedBox(height: 32),
          ],
          
          // Boost plans
          Text('Booster Votre Profil', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(
            'Augmentez votre visibilité et apparaissez en premier sur votre station',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          
          ..._boostPlans.map((plan) => _buildBoostPlanCard(context, plan, premiumController)),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    String title = 'Débloquez Votre Potentiel';
    String subtitle = 'Accédez à toutes les fonctionnalités premium de CrewSnow';
    
    if (widget.fromQuotaLimit && widget.limitType != null) {
      switch (widget.limitType!) {
        case QuotaType.swipe:
          title = 'Limite de Likes Atteinte';
          subtitle = 'Passez premium pour des likes illimités';
          break;
        case QuotaType.message:
          title = 'Limite de Messages Atteinte';
          subtitle = 'Passez premium pour des messages illimités';
          break;
        case QuotaType.none:
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.diamond, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.h1.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.body1.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      const _FeatureItem(
        icon: Icons.favorite,
        title: 'Likes Illimités',
        description: 'Likez autant de profils que vous voulez',
        color: AppColors.error,
      ),
      _FeatureItem(
        icon: Icons.visibility_off,
        title: 'Mode Invisible',
        description: 'Naviguez sans être vu par les autres',
        color: AppColors.primary,
      ),
      const _FeatureItem(
        icon: Icons.analytics,
        title: 'Stats Complètes',
        description: 'Analyses détaillées de votre activité',
        color: AppColors.success,
      ),
      const _FeatureItem(
        icon: Icons.flash_on,
        title: 'Super Likes',
        description: '5 super likes par jour pour vous démarquer',
        color: AppColors.warning,
      ),
      _FeatureItem(
        icon: Icons.filter_list,
        title: 'Filtres Avancés',
        description: 'Filtres par niveau, style, et plus encore',
        color: AppColors.info,
      ),
      _FeatureItem(
        icon: Icons.support_agent,
        title: 'Support Prioritaire',
        description: 'Assistance rapide et personnalisée',
        color: AppColors.primary,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fonctionnalités Premium', style: AppTypography.h2),
          const SizedBox(height: 16),
          ...features.map((feature) => _buildFeatureCard(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(feature.icon, color: feature.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: AppTypography.subtitle1),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(
    BuildContext context,
    PremiumController premiumController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Choisissez Votre Plan', style: AppTypography.h2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Mensuel', !_isAnnual),
                    _buildToggleButton('Annuel', _isAnnual),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Plans
          ..._premiumPlans
              .where((plan) => 
                  (_isAnnual && plan.interval == 'year') || 
                  (!_isAnnual && plan.interval == 'month'))
              .map((plan) => _buildPlanCard(context, plan, premiumController)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = text == 'Annuel'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: AppTypography.body2.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    PremiumPlan plan,
    PremiumController premiumController,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: plan.isPopular 
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.border),
        boxShadow: plan.isPopular 
            ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )]
            : [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: AppTypography.h3),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'POPULAIRE',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.priceText,
                style: AppTypography.h2.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              if (plan.savingsText.isNotEmpty)
                Text(
                  plan.savingsText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Features
          ...plan.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: AppTypography.body2,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 20),
          
          // CTA Button
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Choisir ce Plan',
              onPressed: () => _purchasePlan(context, plan, premiumController),
              isLoading: ref.watch(premiumControllerProvider).isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostsTab(
    BuildContext context,
    PremiumState premiumState,
    PremiumController premiumController,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active boosts
          if (premiumState.activeBoosts.isNotEmpty) ...[
            Text('Boosts Actifs', style: AppTypography.h3),
            const SizedBox(height: 16),
            ...premiumState.activeBoosts.map((boost) => _buildActiveBoostCard(boost)),
            const SizedBox(height: 32),
          ],
          
          // Boost plans
          Text('Booster Votre Profil', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(
            'Augmentez votre visibilité et apparaissez en premier dans les résultats de votre station',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          
          ..._boostPlans.map((plan) => _buildBoostPlanCard(context, plan, premiumController)),
        ],
      ),
    );
  }

  Widget _buildActiveBoostCard(Boost boost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Boost x${boost.boostMultiplier.toStringAsFixed(1)}',
                          style: AppTypography.subtitle1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      boost.stationName ?? 'Station inconnue',
                      style: AppTypography.body2.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  boost.timeRemainingText,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoostPlanCard(
    BuildContext context,
    PremiumPlan plan,
    PremiumController premiumController,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: plan.isPopular 
            ? Border.all(color: AppColors.warning, width: 2)
            : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: AppTypography.h4),
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'POPULAIRE',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          Text(
            plan.priceText,
            style: AppTypography.h3.copyWith(color: AppColors.warning),
          ),
          
          const SizedBox(height: 16),
          
          // Features
          ...plan.features.take(3).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: AppTypography.body2,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Activer le Boost',
              onPressed: () => _purchaseBoost(context, plan, premiumController),
              backgroundColor: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Free vs Premium', style: AppTypography.h3),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildComparisonRow('Likes par jour', '20', 'Illimités', true),
                _buildComparisonRow('Messages par jour', '50', 'Illimités', false),
                _buildComparisonRow('Super likes', '0', '5/jour', true),
                _buildComparisonRow('Voir qui vous a liké', '❌', '✅', false),
                _buildComparisonRow('Mode invisible', '❌', '✅', true),
                _buildComparisonRow('Stats détaillées', '❌', '✅', false),
                _buildComparisonRow('Filtres avancés', '❌', '✅', true),
                _buildComparisonRow('Support', 'Standard', 'Prioritaire', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String freeValue,
    String premiumValue,
    bool isAlternate,
  ) {
    return Container(
      color: isAlternate ? AppColors.surface : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature, style: AppTypography.body2),
          ),
          Expanded(
            child: Text(
              freeValue,
              style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              premiumValue,
              style: AppTypography.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      const _FAQItem(
        question: 'Comment annuler mon abonnement ?',
        answer: 'Vous pouvez annuler à tout moment dans les paramètres de votre compte. L\'abonnement reste actif jusqu\'à la fin de la période payée.',
      ),
      const _FAQItem(
        question: 'Puis-je changer de plan ?',
        answer: 'Oui, vous pouvez passer du plan mensuel à annuel ou vice versa. La différence est calculée au prorata.',
      ),
      const _FAQItem(
        question: 'Que se passe-t-il si j\'annule ?',
        answer: 'Vous gardez l\'accès premium jusqu\'à la fin de votre période de facturation, puis revenez au plan gratuit.',
      ),
      const _FAQItem(
        question: 'Les boosts sont-ils remboursables ?',
        answer: 'Les boosts ne sont pas remboursables une fois activés, mais vous pouvez les annuler avant qu\'ils ne commencent.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Questions Fréquentes', style: AppTypography.h3),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(_FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: AppTypography.subtitle2,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq.answer,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureStatusList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fonctionnalités Actives', style: AppTypography.h3),
        const SizedBox(height: 16),
        _buildFeatureStatus('Likes illimités', true),
        _buildFeatureStatus('Messages illimités', true),
        _buildFeatureStatus('Super likes quotidiens', true),
        _buildFeatureStatus('Voir qui vous a liké', true),
        _buildFeatureStatus('Mode invisible', true),
        _buildFeatureStatus('Stats détaillées', true),
        _buildFeatureStatus('Filtres avancés', true),
        _buildFeatureStatus('Support prioritaire', true),
      ],
    );
  }

  Widget _buildFeatureStatus(String feature, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            feature,
            style: AppTypography.body2.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaInfoCard(QuotaInfo quotaInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Text('Utilisation Premium', style: AppTypography.subtitle1),
            ],
          ),
          const SizedBox(height: 16),
          Text('Likes: Illimités ✅', style: AppTypography.body2),
          const SizedBox(height: 8),
          Text('Messages: Illimités ✅', style: AppTypography.body2),
          const SizedBox(height: 8),
          Text('Reset: Aucune limite', style: AppTypography.body2),
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagement(
    BuildContext context,
    PremiumController premiumController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestion de l\'Abonnement', style: AppTypography.h3),
        const SizedBox(height: 16),
        
        OutlinedButton.icon(
          onPressed: () => premiumController.cancelSubscription(),
          icon: const Icon(Icons.settings),
          label: const Text('Gérer l\'Abonnement'),
        ),
        
        const SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: () => premiumController.restorePurchases(),
          icon: const Icon(Icons.refresh),
          label: const Text('Restaurer les Achats'),
        ),
      ],
    );
  }

  Future<void> _purchasePlan(
    BuildContext context,
    PremiumPlan plan,
    PremiumController premiumController,
  ) async {
    if (plan.stripePriceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan non disponible')),
      );
      return;
    }

    final success = await premiumController.purchasePremium(plan.stripePriceId!);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'achat')),
      );
    }
  }

  Future<void> _purchaseBoost(
    BuildContext context,
    PremiumPlan plan,
    PremiumController premiumController,
  ) async {
    // Get current user's station
    // This would typically come from the user's current location or selected station
    const stationId = 'current-station-id'; // TODO: Get from location service
    
    final success = await premiumController.purchaseBoost(
      boostType: plan.id,
      stationId: stationId,
      durationHours: _getBoostDurationHours(plan.id),
      multiplier: 2.0,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'achat du boost')),
      );
    }
  }

  int _getBoostDurationHours(String boostType) {
    switch (boostType) {
      case 'boost_1h': return 1;
      case 'boost_24h': return 24;
      case 'boost_week': return 168;
      default: return 24;
    }
  }

  String _getPlanDisplayName(Subscription subscription) {
    if (subscription.interval == 'year') {
      return 'Premium Annuel';
    } else {
      return 'Premium Mensuel';
    }
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _FAQItem {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });
}
