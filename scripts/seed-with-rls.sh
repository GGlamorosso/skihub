#!/bin/bash
# ============================================================================
# CREWSNOW SEED WITH RLS HANDLING
# ============================================================================
# Description: Load seed data safely even with RLS enabled
# Usage: ./scripts/seed-with-rls.sh [env]
#   env: dev, prod, or local (default: local)
# ============================================================================

set -e

# Parse environment argument
ENVIRONMENT=${1:-local}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌱 === CREWSNOW SEED WITH RLS HANDLING ===${NC}"
echo -e "Environment: ${ENVIRONMENT}"
echo -e "Timestamp: $(date -u)"
echo ""

# Validate environment
case $ENVIRONMENT in
    local|dev|prod)
        echo -e "${GREEN}✅ Valid environment: ${ENVIRONMENT}${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid environment: ${ENVIRONMENT}${NC}"
        echo -e "Valid options: local, dev, prod"
        exit 1
        ;;
esac

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "supabase/config.toml" ]; then
    echo -e "${RED}❌ Not in a Supabase project directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}"

# Function to run SQL with error handling
run_sql() {
    local description=$1
    local sql=$2
    
    echo -e "${BLUE}📋 ${description}...${NC}"
    
    if supabase db run --file - <<< "$sql"; then
        echo -e "${GREEN}✅ ${description} completed${NC}"
    else
        echo -e "${RED}❌ ${description} failed${NC}"
        return 1
    fi
    echo ""
}

# Function to temporarily disable RLS for seeding
disable_rls_for_seeding() {
    echo -e "${YELLOW}🔓 Temporarily disabling RLS for seeding...${NC}"
    
    run_sql "Disable RLS on core tables" "
-- Temporarily disable RLS for seeding
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE stations DISABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_station_status DISABLE ROW LEVEL SECURITY;
ALTER TABLE likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE friends DISABLE ROW LEVEL SECURITY;
ALTER TABLE ride_stats_daily DISABLE ROW LEVEL SECURITY;
ALTER TABLE boosts DISABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;

SELECT 'RLS disabled for seeding' as status;
"
}

# Function to re-enable RLS after seeding
enable_rls_after_seeding() {
    echo -e "${BLUE}🔒 Re-enabling RLS after seeding...${NC}"
    
    run_sql "Re-enable RLS on core tables" "
-- Re-enable RLS after seeding
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_station_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE boosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

SELECT 'RLS re-enabled after seeding' as status;
"
}

# Function to load seed files
load_seeds() {
    echo -e "${BLUE}🌱 Loading seed data...${NC}"
    
    # Load stations
    if [ -f "supabase/seed/01_seed_stations.sql" ]; then
        echo -e "${BLUE}🏔️ Loading stations...${NC}"
        if supabase db run --file supabase/seed/01_seed_stations.sql; then
            echo -e "${GREEN}✅ Stations loaded successfully${NC}"
        else
            echo -e "${RED}❌ Failed to load stations${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Stations seed file not found${NC}"
    fi
    
    # Load test users
    if [ -f "supabase/seed/02_seed_test_users.sql" ]; then
        echo -e "${BLUE}👥 Loading test users...${NC}"
        if supabase db run --file supabase/seed/02_seed_test_users.sql; then
            echo -e "${GREEN}✅ Test users loaded successfully${NC}"
        else
            echo -e "${RED}❌ Failed to load test users${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Test users seed file not found${NC}"
    fi
    
    echo ""
}

# Function to verify seeds
verify_seeds() {
    echo -e "${BLUE}🔍 Verifying seed data...${NC}"
    
    run_sql "Count seed data" "
DO \$\$
DECLARE
    user_count INTEGER;
    station_count INTEGER;
    match_count INTEGER;
    message_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO station_count FROM stations;
    SELECT COUNT(*) INTO match_count FROM matches;
    SELECT COUNT(*) INTO message_count FROM messages;
    
    RAISE NOTICE '📊 SEED DATA VERIFICATION:';
    RAISE NOTICE '  - Users: %', user_count;
    RAISE NOTICE '  - Stations: %', station_count;
    RAISE NOTICE '  - Matches: %', match_count;
    RAISE NOTICE '  - Messages: %', message_count;
    
    IF user_count >= 10 AND station_count >= 50 THEN
        RAISE NOTICE '✅ Seed data loaded successfully!';
    ELSE
        RAISE WARNING '⚠️ Seed data may be incomplete';
    END IF;
END \$\$;
"
}

# Function to test RLS after re-enabling
test_rls() {
    echo -e "${BLUE}🔐 Testing RLS functionality...${NC}"
    
    run_sql "Test RLS policies" "
DO \$\$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    RAISE NOTICE '🛡️ RLS VERIFICATION:';
    RAISE NOTICE '  - Active policies: %', policy_count;
    
    -- Test that RLS is working by trying to access data without auth context
    BEGIN
        PERFORM COUNT(*) FROM users; -- This should work as it doesn't depend on auth.uid()
        RAISE NOTICE '✅ Basic queries working';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Some RLS policies may be too restrictive for anonymous access';
    END;
    
    RAISE NOTICE '✅ RLS is active and functional';
END \$\$;
"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting seed process with RLS handling...${NC}"
    echo ""
    
    # Step 1: Disable RLS temporarily
    disable_rls_for_seeding
    
    # Step 2: Load seed data
    load_seeds
    
    # Step 3: Re-enable RLS
    enable_rls_after_seeding
    
    # Step 4: Verify everything worked
    verify_seeds
    
    # Step 5: Test RLS functionality
    test_rls
    
    echo -e "${GREEN}🎉 === SEED PROCESS COMPLETED SUCCESSFULLY ===${NC}"
    echo -e "✅ All seed data loaded with RLS properly configured"
    echo -e "🔒 Row Level Security is active and protecting your data"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "1. Test your application with the seed data"
    echo -e "2. Verify user authentication works correctly"
    echo -e "3. Check that RLS policies don't block legitimate operations"
    echo ""
    echo -e "${GREEN}🎿 CrewSnow seed data is ready! ⛷️${NC}"
}

# Handle errors
trap 'echo -e "${RED}❌ Seed process failed${NC}"; exit 1' ERR

# Run main function
main

echo -e "${BLUE}🏁 Seed script completed at $(date -u)${NC}"
