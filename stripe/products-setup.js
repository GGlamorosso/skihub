// CrewSnow Stripe Products and Prices Setup - Week 7
// 1.1 Création des produits et prix

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

async function createCrewSnowProducts() {
  console.log('🎯 Creating CrewSnow Stripe Products and Prices...');
  
  try {
    // ============================================================================
    // ABONNEMENTS PREMIUM
    // ============================================================================
    
    // Premium Monthly
    const premiumProduct = await stripe.products.create({
      name: 'CrewSnow Premium',
      description: 'Access premium features: unlimited likes, advanced filters, priority matching',
      metadata: {
        feature_unlimited_likes: 'true',
        feature_advanced_filters: 'true', 
        feature_priority_matching: 'true',
        feature_read_receipts: 'true'
      }
    });
    
    const monthlyPrice = await stripe.prices.create({
      product: premiumProduct.id,
      unit_amount: 999, // €9.99
      currency: 'eur',
      recurring: {
        interval: 'month'
      },
      metadata: {
        plan_type: 'premium_monthly',
        daily_likes_limit: 'unlimited',
        daily_messages_limit: 'unlimited'
      }
    });
    
    const seasonalPrice = await stripe.prices.create({
      product: premiumProduct.id,
      unit_amount: 2999, // €29.99 for season
      currency: 'eur',
      recurring: {
        interval: 'month',
        interval_count: 5 // 5 months season
      },
      metadata: {
        plan_type: 'premium_seasonal',
        daily_likes_limit: 'unlimited',
        daily_messages_limit: 'unlimited'
      }
    });
    
    // ============================================================================
    // BOOSTS (ONE-TIME PAYMENTS)
    // ============================================================================
    
    // Daily Boost
    const dailyBoostProduct = await stripe.products.create({
      name: 'CrewSnow Daily Boost',
      description: 'Boost your profile visibility for 24 hours in selected stations',
      metadata: {
        boost_duration: '24',
        boost_multiplier: '2.0'
      }
    });
    
    const dailyBoostPrice = await stripe.prices.create({
      product: dailyBoostProduct.id,
      unit_amount: 299, // €2.99
      currency: 'eur',
      metadata: {
        boost_type: 'daily',
        boost_duration_hours: '24',
        boost_multiplier: '2.0'
      }
    });
    
    // Weekly Boost
    const weeklyBoostPrice = await stripe.prices.create({
      product: dailyBoostProduct.id,
      unit_amount: 999, // €9.99
      currency: 'eur', 
      metadata: {
        boost_type: 'weekly',
        boost_duration_hours: '168', // 7 days
        boost_multiplier: '3.0'
      }
    });
    
    // Multi-Station Boost
    const multiStationBoostProduct = await stripe.products.create({
      name: 'CrewSnow Multi-Station Boost',
      description: 'Boost your profile across multiple connected ski stations',
      metadata: {
        boost_type: 'multi_station',
        max_stations: '5'
      }
    });
    
    const multiStationPrice = await stripe.prices.create({
      product: multiStationBoostProduct.id,
      unit_amount: 1999, // €19.99
      currency: 'eur',
      metadata: {
        boost_type: 'multi_station',
        boost_duration_hours: '72', // 3 days
        boost_multiplier: '2.5',
        max_stations: '5'
      }
    });
    
    // ============================================================================
    // PACK DE SWIPES SUPPLÉMENTAIRES
    // ============================================================================
    
    const swipePackProduct = await stripe.products.create({
      name: 'CrewSnow Extra Swipes Pack',
      description: 'Additional daily swipes for non-premium users',
      metadata: {
        pack_type: 'extra_swipes'
      }
    });
    
    const smallSwipePackPrice = await stripe.prices.create({
      product: swipePackProduct.id,
      unit_amount: 199, // €1.99
      currency: 'eur',
      metadata: {
        pack_type: 'small_swipe_pack',
        extra_likes_count: '20',
        validity_days: '30'
      }
    });
    
    const largeSwipePackPrice = await stripe.prices.create({
      product: swipePackProduct.id,
      unit_amount: 499, // €4.99  
      currency: 'eur',
      metadata: {
        pack_type: 'large_swipe_pack',
        extra_likes_count: '100',
        validity_days: '30'
      }
    });
    
    // ============================================================================
    // OUTPUT CONFIGURATION
    // ============================================================================
    
    console.log('✅ Products and Prices created successfully!');
    console.log('\n📋 Configuration for your .env:');
    console.log('# Premium Subscription');
    console.log(`STRIPE_PRICE_PREMIUM_MONTHLY=${monthlyPrice.id}`);
    console.log(`STRIPE_PRICE_PREMIUM_SEASONAL=${seasonalPrice.id}`);
    console.log('\n# Boosts');
    console.log(`STRIPE_PRICE_DAILY_BOOST=${dailyBoostPrice.id}`);
    console.log(`STRIPE_PRICE_WEEKLY_BOOST=${weeklyBoostPrice.id}`);
    console.log(`STRIPE_PRICE_MULTI_STATION_BOOST=${multiStationPrice.id}`);
    console.log('\n# Extra Swipes');
    console.log(`STRIPE_PRICE_SMALL_SWIPE_PACK=${smallSwipePackPrice.id}`);
    console.log(`STRIPE_PRICE_LARGE_SWIPE_PACK=${largeSwipePackPrice.id}`);
    console.log('\n# Product IDs');
    console.log(`STRIPE_PRODUCT_PREMIUM=${premiumProduct.id}`);
    console.log(`STRIPE_PRODUCT_DAILY_BOOST=${dailyBoostProduct.id}`);
    console.log(`STRIPE_PRODUCT_MULTI_STATION_BOOST=${multiStationBoostProduct.id}`);
    console.log(`STRIPE_PRODUCT_SWIPE_PACK=${swipePackProduct.id}`);
    
    // Save to file for reference
    const config = {
      products: {
        premium: premiumProduct.id,
        daily_boost: dailyBoostProduct.id,
        multi_station_boost: multiStationBoostProduct.id,
        swipe_pack: swipePackProduct.id
      },
      prices: {
        premium_monthly: monthlyPrice.id,
        premium_seasonal: seasonalPrice.id,
        daily_boost: dailyBoostPrice.id,
        weekly_boost: weeklyBoostPrice.id,
        multi_station_boost: multiStationPrice.id,
        small_swipe_pack: smallSwipePackPrice.id,
        large_swipe_pack: largeSwipePackPrice.id
      }
    };
    
    require('fs').writeFileSync('stripe-config.json', JSON.stringify(config, null, 2));
    console.log('\n💾 Configuration saved to stripe-config.json');
    
  } catch (error) {
    console.error('❌ Error creating products:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  createCrewSnowProducts();
}

module.exports = { createCrewSnowProducts };
