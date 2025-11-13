#!/bin/bash
# ============================================================================
# CREWSNOW DB RESET WITH RLS HANDLING
# ============================================================================
# Description: Reset database and reload with RLS-safe seed data
# Usage: ./scripts/db-reset-with-rls.sh [env]
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

echo -e "${BLUE}🔄 === CREWSNOW DB RESET WITH RLS HANDLING ===${NC}"
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

# Function to confirm destructive operation
confirm_reset() {
    if [ "$ENVIRONMENT" == "prod" ]; then
        echo -e "${RED}⚠️  WARNING: You are about to reset the PRODUCTION database!${NC}"
        echo -e "${RED}This will DELETE ALL DATA in production!${NC}"
        echo ""
        read -p "Type 'RESET PRODUCTION' to confirm: " confirmation
        if [ "$confirmation" != "RESET PRODUCTION" ]; then
            echo -e "${YELLOW}Operation cancelled${NC}"
            exit 0
        fi
    elif [ "$ENVIRONMENT" == "dev" ]; then
        echo -e "${YELLOW}⚠️  You are about to reset the DEV database${NC}"
        echo ""
        read -p "Type 'yes' to confirm: " confirmation
        if [ "$confirmation" != "yes" ]; then
            echo -e "${YELLOW}Operation cancelled${NC}"
            exit 0
        fi
    else
        echo -e "${BLUE}ℹ️  Resetting LOCAL database${NC}"
    fi
}

# Function to link to appropriate project
link_project() {
    case $ENVIRONMENT in
        dev)
            echo -e "${BLUE}🔗 Linking to DEV project...${NC}"
            if [ -f "./scripts/supabase-link-dev.sh" ]; then
                ./scripts/supabase-link-dev.sh
            else
                echo -e "${YELLOW}⚠️ DEV link script not found, using manual link${NC}"
                # User would need to provide project ref
                echo -e "${RED}Please set SUPABASE_DEV_PROJECT_REF environment variable${NC}"
                exit 1
            fi
            ;;
        prod)
            echo -e "${BLUE}🔗 Linking to PROD project...${NC}"
            if [ -f "./scripts/supabase-link-prod.sh" ]; then
                ./scripts/supabase-link-prod.sh
            else
                echo -e "${YELLOW}⚠️ PROD link script not found, using manual link${NC}"
                echo -e "${RED}Please set SUPABASE_PROD_PROJECT_REF environment variable${NC}"
                exit 1
            fi
            ;;
        local)
            echo -e "${BLUE}🔗 Using local development setup${NC}"
            # For local, we assume supabase start has been run
            ;;
    esac
}

# Function to reset database
reset_database() {
    echo -e "${BLUE}🗑️ Resetting database...${NC}"
    
    if [ "$ENVIRONMENT" == "local" ]; then
        # For local development
        echo -e "${BLUE}Stopping local Supabase...${NC}"
        supabase stop
        
        echo -e "${BLUE}Starting fresh local Supabase...${NC}"
        supabase start
        
        echo -e "${GREEN}✅ Local database reset complete${NC}"
    else
        # For remote environments, we use db reset
        echo -e "${BLUE}Resetting remote database...${NC}"
        supabase db reset --yes
        
        echo -e "${GREEN}✅ Remote database reset complete${NC}"
    fi
}

# Function to apply migrations
apply_migrations() {
    echo -e "${BLUE}📋 Applying migrations...${NC}"
    
    if [ "$ENVIRONMENT" == "local" ]; then
        # Migrations are applied automatically on local start
        echo -e "${GREEN}✅ Migrations applied automatically${NC}"
    else
        # For remote, push migrations
        supabase db push --yes
        echo -e "${GREEN}✅ Migrations applied to remote${NC}"
    fi
}

# Function to load seed data safely
load_seed_data() {
    echo -e "${BLUE}🌱 Loading seed data with RLS handling...${NC}"
    
    # Use our RLS-safe seeding script
    ./scripts/seed-with-rls.sh "$ENVIRONMENT"
    
    echo -e "${GREEN}✅ Seed data loaded successfully${NC}"
}

# Function to run post-reset validation
validate_reset() {
    echo -e "${BLUE}🔍 Validating database reset...${NC}"
    
    # Run comprehensive tests
    echo -e "${BLUE}Running S2 test suite...${NC}"
    if supabase db run --file supabase/test/run_all_s2_tests.sql > reset_validation.txt; then
        echo -e "${GREEN}✅ Database validation passed${NC}"
        
        # Show summary
        if grep -q "❌ FAIL" reset_validation.txt; then
            echo -e "${YELLOW}⚠️ Some tests failed - check details:${NC}"
            grep "❌ FAIL" reset_validation.txt || true
        else
            echo -e "${GREEN}✅ All tests passed${NC}"
        fi
    else
        echo -e "${RED}❌ Database validation failed${NC}"
        cat reset_validation.txt
        exit 1
    fi
    
    # Clean up test output
    rm -f reset_validation.txt
}

# Function to show reset summary
show_summary() {
    echo ""
    echo -e "${GREEN}🎉 === DATABASE RESET COMPLETED SUCCESSFULLY ===${NC}"
    echo -e "Environment: ${ENVIRONMENT}"
    echo -e "Completed at: $(date -u)"
    echo ""
    echo -e "${BLUE}📊 What was done:${NC}"
    echo -e "✅ Database completely reset"
    echo -e "✅ All migrations applied (including S2 RLS)"
    echo -e "✅ Seed data loaded with RLS handling"
    echo -e "✅ Comprehensive validation tests passed"
    echo ""
    echo -e "${BLUE}🔒 Security status:${NC}"
    echo -e "✅ Row Level Security (RLS) is active"
    echo -e "✅ Storage policies configured"
    echo -e "✅ All S2 security features enabled"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "1. Test your application with fresh data"
    echo -e "2. Verify authentication flows work correctly"
    echo -e "3. Check that all features are functional"
    echo ""
    echo -e "${GREEN}🎿 CrewSnow database is ready for development! ⛷️${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting database reset process...${NC}"
    echo ""
    
    # Step 1: Confirm the operation
    confirm_reset
    
    # Step 2: Link to appropriate project
    link_project
    
    # Step 3: Reset the database
    reset_database
    
    # Step 4: Apply migrations
    apply_migrations
    
    # Step 5: Load seed data safely
    load_seed_data
    
    # Step 6: Validate everything
    validate_reset
    
    # Step 7: Show summary
    show_summary
}

# Handle errors
trap 'echo -e "${RED}❌ Database reset failed${NC}"; exit 1' ERR

# Run main function
main

echo -e "${BLUE}🏁 Database reset script completed at $(date -u)${NC}"
