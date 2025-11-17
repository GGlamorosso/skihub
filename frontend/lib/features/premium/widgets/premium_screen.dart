import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/subscription.dart';
import '../services/stripe_service.dart';
import '../services/quota_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stripeService = StripeService(PremiumRepository());
    final premiumPlans = stripeService.getPremiumPlans();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CrewSnow Premium'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Premium header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.star,
                  size: 64,
                  color: Colors.amber[400],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Débloquez tout votre potentiel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Connectez-vous avec plus de skieurs et vivez des expériences inoubliables',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Premium'),
              Tab(text: 'Boosts'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPremiumTab(premiumPlans, stripeService),
                _buildBoostsTab(stripeService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(List<PremiumPlan> plans, StripeService stripeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Benefits section
          _buildBenefitsSection(),
          const SizedBox(height: AppSpacing.xl),
          
          // Pricing plans
          _buildPricingPlans(plans, stripeService),
          const SizedBox(height: AppSpacing.xl),
          
          // Free vs Premium comparison
          _buildComparisonTable(),
          const SizedBox(height: AppSpacing.xl),
          
          // FAQ section
          _buildFAQSection(),
          const SizedBox(height: AppSpacing.xl),
          
          // Restore purchases
          _buildRestorePurchases(),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'icon': Icons.favorite_border,
        'title': 'Swipes illimités',
        'description': 'Likez autant de profils que vous voulez',
        'color': Colors.red,
      },
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Messages illimités',
        'description': 'Discutez sans limite avec vos matchs',
        'color': Colors.blue,
      },
      {
        'icon': Icons.visibility,
        'title': 'Voir qui vous a liké',
        'description': 'Découvrez qui s\'intéresse à vous',
        'color': Colors.purple,
      },
      {
        'icon': Icons.flash_on,
        'title': 'Mode boost',
        'description': 'Augmentez votre visibilité dans les stations',
        'color': Colors.orange,
      },
      {
        'icon': Icons.filter_list,
        'title': 'Filtres avancés',
        'description': 'Affinez votre recherche par niveau et style',
        'color': Colors.green,
      },
      {
        'icon': Icons.analytics,
        'title': 'Statistiques détaillées',
        'description': 'Suivez vos performances et progrès',
        'color': Colors.indigo,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avantages Premium',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: ListTile(
              leading: Icon(
                benefit['icon'] as IconData,
                color: benefit['color'] as Color,
                size: 28,
              ),
              title: Text(
                benefit['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(benefit['description'] as String),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPricingPlans(List<PremiumPlan> plans, StripeService stripeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez votre plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...plans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildPlanCard(plan, stripeService),
        )),
      ],
    );
  }

  Widget _buildPlanCard(PremiumPlan plan, StripeService stripeService) {
    return AppCard(
      child: Container(
        decoration: plan.isPopular
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              )
            : null,
        child: Stack(
          children: [
            if (plan.isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'POPULAIRE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Pricing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.id == 'premium_seasonal' 
                            ? '€${plan.displayPriceYearly.toStringAsFixed(2)}'
                            : '€${plan.displayPriceMonthly.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        plan.id == 'premium_seasonal' ? '/saison' : '/mois',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (plan.id == 'premium_seasonal') ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Économie ${plan.yearlySavingsPercent}%',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Features
                  ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Choisir ce plan',
                      onPressed: _isLoading ? null : () => _purchasePlan(plan, stripeService),
                      variant: plan.isPopular ? AppButtonVariant.primary : AppButtonVariant.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final features = [
      {'name': 'Swipes par jour', 'free': '20', 'premium': 'Illimité'},
      {'name': 'Messages par jour', 'free': '10', 'premium': 'Illimité'},
      {'name': 'Voir qui vous a liké', 'free': '❌', 'premium': '✅'},
      {'name': 'Mode invisible', 'free': '❌', 'premium': '✅'},
      {'name': 'Filtres avancés', 'free': '❌', 'premium': '✅'},
      {'name': 'Statistiques détaillées', 'free': 'Basic', 'premium': 'Complètes'},
      {'name': 'Support client', 'free': 'Standard', 'premium': 'Prioritaire'},
      {'name': 'Boosts inclus', 'free': '0', 'premium': '1/mois'},
    ];

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparaison Free vs Premium',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Table(
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(
                        'Fonctionnalité',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(
                        'Free',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(
                        'Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                ...features.map((feature) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(feature['name']!),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(
                        feature['free']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: feature['free'] == '❌' ? Colors.grey : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(
                        feature['premium']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostsTab(StripeService stripeService) {
    final boostTypes = stripeService.getBoostOptions();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boostez votre visibilité',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Apparaissez en priorité dans les résultats de recherche de votre station',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          ...boostTypes.map((boostType) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildBoostCard(boostType, stripeService),
          )),
          
          const SizedBox(height: AppSpacing.xl),
          _buildBoostInfo(),
        ],
      ),
    );
  }

  Widget _buildBoostCard(BoostType boostType, StripeService stripeService) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Boost ${boostType.displayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${boostType.multiplier}x',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              boostType.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  '€${boostType.displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                AppButton(
                  text: 'Acheter',
                  onPressed: _isLoading ? null : () => _purchaseBoost(boostType, stripeService),
                  variant: AppButtonVariant.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostInfo() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Comment fonctionnent les boosts ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '• Votre profil apparaît en priorité dans les recherches\n'
              '• Multiplicateur de visibilité selon la durée\n'
              '• Actif uniquement dans la station sélectionnée\n'
              '• Peut être cumulé avec le statut Premium',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'Comment puis-je annuler mon abonnement ?',
        'answer': 'Vous pouvez annuler à tout moment dans les paramètres de votre compte ou via le portail Stripe.',
      },
      {
        'question': 'Puis-je changer de plan ?',
        'answer': 'Oui, vous pouvez passer au plan annuel ou revenir au plan mensuel à tout moment.',
      },
      {
        'question': 'Les boosts sont-ils remboursables ?',
        'answer': 'Les boosts peuvent être annulés dans les 24h suivant l\'achat pour un remboursement complet.',
      },
      {
        'question': 'Que se passe-t-il si j\'annule ?',
        'answer': 'Vous gardez l\'accès Premium jusqu\'à la fin de votre période de facturation.',
      },
    ];

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions fréquentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...faqs.map((faq) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq['question']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    faq['answer']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRestorePurchases() {
    return Column(
      children: [
        TextButton(
          onPressed: _restorePurchases,
          child: const Text('Restaurer mes achats'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _openCustomerPortal,
          child: const Text('Gérer mon abonnement'),
        ),
      ],
    );
  }

  Future<void> _purchasePlan(PremiumPlan plan, StripeService stripeService) async {
    setState(() => _isLoading = true);

    try {
      const userId = 'current-user-id'; // Get from auth
      final priceId = plan.id == 'premium_seasonal' 
          ? plan.stripePriceIdYearly 
          : plan.stripePriceIdMonthly;

      if (priceId == null) {
        throw Exception('Price ID not configured for plan');
      }

      await stripeService.purchasePremium(
        userId: userId,
        priceId: priceId,
        successUrl: 'https://app.crewsnow.com/premium/success',
        cancelUrl: 'https://app.crewsnow.com/premium/cancel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'achat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseBoost(BoostType boostType, StripeService stripeService) async {
    setState(() => _isLoading = true);

    try {
      const userId = 'current-user-id'; // Get from auth  
      const stationId = 'current-station-id'; // Get from user location

      await stripeService.purchaseBoost(
        userId: userId,
        stationId: stationId,
        boostType: boostType,
        successUrl: 'https://app.crewsnow.com/boost/success',
        cancelUrl: 'https://app.crewsnow.com/boost/cancel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'achat du boost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    // This would typically integrate with in_app_purchase plugin
    // For now, just show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérification des achats en cours...'),
        ),
      );
    }
  }

  Future<void> _openCustomerPortal() async {
    try {
      final stripeService = StripeService(PremiumRepository());
      const userId = 'current-user-id'; // Get from auth
      
      await stripeService.openCustomerPortal(
        userId: userId,
        returnUrl: 'https://app.crewsnow.com/profile',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
