# ✅ Week 7 Deployment Checklist - Stripe & Quotas

## 📋 Pre-Deployment

### ✅ **Stripe Setup**
- [ ] Stripe account configured (test/live)
- [ ] Run `cd stripe && node products-setup.js`
- [ ] Note price IDs from output
- [ ] Configure webhook URL in Stripe Dashboard
- [ ] Copy stripe.env.example to .env and fill keys

### ✅ **Database Migration**
- [ ] Apply quotas migration: `supabase migration apply 20250110_usage_limits_quotas`
- [ ] Verify tables created: `\d+ daily_usage` `\d+ usage_limits_config`
- [ ] Test functions: `SELECT * FROM get_user_usage_status(user_id);`

### ✅ **Edge Functions**
- [ ] Deploy: `supabase functions deploy create-stripe-customer`
- [ ] Deploy: `supabase functions deploy stripe-webhook-enhanced` 
- [ ] Deploy: `supabase functions deploy swipe-enhanced`
- [ ] Deploy: `supabase functions deploy send-message-enhanced`

### ✅ **Environment Variables**
- [ ] Supabase: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET
- [ ] Client: STRIPE_PUBLISHABLE_KEY, price IDs
- [ ] Verify: Edge Functions have access to all vars

## 🧪 Testing

### ✅ **Quota System**
- [ ] Test: `SELECT can_user_perform_action(user_id, 'like');`
- [ ] Test: `SELECT * FROM check_and_increment_like_quota(user_id);`
- [ ] Verify: Free user hits limit at 20 likes
- [ ] Verify: Premium user unlimited

### ✅ **Stripe Integration**
- [ ] Test customer creation Edge Function
- [ ] Test webhook with Stripe CLI: `stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook-enhanced`
- [ ] Simulate events: checkout.session.completed, subscription.deleted
- [ ] Verify: user premium status updates

### ✅ **API Integration**
- [ ] Test swipe with quota: curl swipe-enhanced endpoint
- [ ] Test messaging with quota: curl send-message-enhanced  
- [ ] Verify: 429 errors when quota exceeded
- [ ] Verify: quota_info in responses

## 🚀 Production Deployment

### ✅ **Stripe Production**
- [ ] Switch to live Stripe keys
- [ ] Configure live webhook endpoint
- [ ] Test with real payment (small amount)
- [ ] Verify webhook receives live events

### ✅ **Monitoring Setup**  
- [ ] Dashboard for usage analytics
- [ ] Alerts for quota system health
- [ ] Stripe webhook monitoring
- [ ] Error tracking for Edge Functions

### ✅ **Performance Validation**
- [ ] Quota checks < 50ms
- [ ] Stripe webhook processing < 1s
- [ ] Enhanced functions < 200ms
- [ ] Database queries using indexes

## 📊 Post-Deployment

### ✅ **User Experience**
- [ ] Test upgrade flow (free → premium)
- [ ] Test quota warnings in app
- [ ] Test boost purchase and activation
- [ ] Test subscription cancellation

### ✅ **Business Metrics**
- [ ] Track conversion rates
- [ ] Monitor quota hit rates  
- [ ] Analyze upgrade triggers
- [ ] Revenue tracking

## 🔧 Troubleshooting

### ❌ **Common Issues**
- **Quota not enforced**: Check trigger enabled
- **Webhook fails**: Verify signature + endpoint URL
- **Premium not activated**: Check subscription status sync
- **Performance slow**: Verify index usage

### 📞 **Support Commands**
```bash
# Check quota health
psql -c "SELECT * FROM usage_analytics;"

# Check Stripe sync
psql -c "SELECT * FROM user_has_active_premium_enhanced(user_id);"

# View webhook logs  
supabase functions logs stripe-webhook-enhanced --follow

# Test complete system
./scripts/test-week7-stripe-quotas.sh
```

**WEEK 7 READY FOR PRODUCTION** ✅💳
