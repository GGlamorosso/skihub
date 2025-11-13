# CrewSnow Seed Data

## 📋 Overview

This directory contains seed data for the CrewSnow application, designed to work safely with Row Level Security (RLS) enabled.

## 📁 Files

### Seed Data Files
- **`01_seed_stations.sql`** - European ski stations (60+ stations)
- **`02_seed_test_users.sql`** - Test users with diverse profiles (10 users)
- **`03_test_queries.sql`** - Validation and performance test queries
- **`stations_source.csv`** - Raw CSV source for station data

### Documentation
- **`README.md`** - This file

## 🚀 Usage

### Option 1: RLS-Safe Seeding (Recommended)

Use the RLS-safe seeding script that handles RLS activation/deactivation automatically:

```bash
# Local development
./scripts/seed-with-rls.sh local

# DEV environment  
./scripts/seed-with-rls.sh dev

# PROD environment (use with caution)
./scripts/seed-with-rls.sh prod
```

### Option 2: Manual Seeding

If you need to run seed files manually:

```bash
# Load stations
supabase db run --file supabase/seed/01_seed_stations.sql

# Load test users
supabase db run --file supabase/seed/02_seed_test_users.sql

# Run validation queries
supabase db run --file supabase/seed/03_test_queries.sql
```

**⚠️ Note**: Manual seeding may fail with RLS enabled. Use Option 1 for reliability.

### Option 3: Database Reset with Seeds

For a complete fresh start:

```bash
# Reset database and reload with seeds
./scripts/db-reset-with-rls.sh local
```

## 🔒 RLS Compatibility

### The Challenge

With Row Level Security (RLS) enabled, seed data insertion can fail because:
- RLS policies require `auth.uid()` context
- Seed scripts run without authenticated user context
- Some policies may block legitimate seed operations

### The Solution

Our RLS-safe seeding process:

1. **Temporarily disable RLS** on core tables
2. **Load seed data** without RLS interference
3. **Re-enable RLS** to restore security
4. **Verify** that RLS is working correctly
5. **Test** that seed data is accessible

### Process Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   RLS Enabled   │ → │  RLS Disabled   │ → │   Load Seeds    │
│   (Secure)      │    │  (Temporary)    │    │   (Safe)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Verify RLS    │ ← │   RLS Enabled   │ ← │  Verify Seeds   │
│   (Test)        │    │   (Secure)      │    │   (Count)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📊 Seed Data Contents

### Stations (60+ European Ski Resorts)
- **Countries**: France, Switzerland, Austria, Italy, Germany
- **Data**: Name, coordinates, elevation, season info, official websites
- **Examples**: Val Thorens, Chamonix, Zermatt, St. Anton, Cortina d'Ampezzo

### Test Users (10 Diverse Profiles)
- **Levels**: Beginner to Expert
- **Ride Styles**: Alpine, Freestyle, Freeride, Powder, etc.
- **Languages**: English, French, German, Italian combinations
- **Premium Status**: Mix of free and premium users
- **Locations**: Distributed across different stations

### Sample Data Relationships
- **User Station Status**: Users at different resorts with date ranges
- **Likes**: Mutual likes between users (creates matches)
- **Matches**: 3 sample matches from mutual likes
- **Messages**: Sample chat conversations
- **Ride Stats**: Daily activity tracking for users

## 🧪 Validation

After seeding, the system automatically validates:

### Data Counts
- ✅ Users: 10 test accounts
- ✅ Stations: 60+ ski resorts  
- ✅ Matches: 3 sample matches
- ✅ Messages: Sample conversations
- ✅ User Station Status: Location assignments
- ✅ Ride Stats: Activity data

### RLS Functionality
- ✅ Policies are active (40+ policies)
- ✅ Anonymous access blocked to sensitive tables
- ✅ Public view accessible
- ✅ Cross-user isolation working

### Performance
- ✅ Index usage verified
- ✅ Query performance within targets
- ✅ No sequential scans on large tables

## 🔧 Troubleshooting

### Common Issues

**1. RLS Blocks Seed Insertion**
```
Error: new row violates row-level security policy
```
**Solution**: Use `./scripts/seed-with-rls.sh` which handles RLS automatically.

**2. Duplicate Key Violations**
```
Error: duplicate key value violates unique constraint
```
**Solution**: Reset database first with `./scripts/db-reset-with-rls.sh`.

**3. Function Not Found**
```
Error: function auth.uid() does not exist
```
**Solution**: This happens when RLS policies reference `auth.uid()` but no auth context exists. The RLS-safe script handles this.

**4. Permission Denied**
```
Error: permission denied for table users
```
**Solution**: Ensure you're connected to the correct Supabase project and have appropriate permissions.

### Manual RLS Management

If you need to manually manage RLS (advanced users only):

```sql
-- Disable RLS temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ... load data ...
-- Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

**⚠️ Warning**: Manual RLS management is error-prone. Use scripts instead.

## 📋 Environment-Specific Notes

### Local Development
- Uses `supabase start` local instance
- Safe to reset frequently
- No authentication required for CLI

### DEV Environment
- Requires Supabase project linking
- Needs SUPABASE_ACCESS_TOKEN
- Safe for testing and experimentation

### PROD Environment
- **⚠️ EXTREME CAUTION REQUIRED**
- Requires explicit confirmation
- Creates backups before operations
- Should only be seeded on initial deployment

## 🎯 Best Practices

1. **Always use RLS-safe scripts** for seeding
2. **Test in DEV** before applying to PROD
3. **Backup before seeding** in production
4. **Validate after seeding** with test suite
5. **Document any custom seed data** additions

## 🔄 CI/CD Integration

The seeding process is integrated into the CI/CD pipeline:

- **PR validation**: Checks seed file syntax
- **DEV deployment**: Automatically seeds on `[seed]` commit message
- **PROD deployment**: Manual seeding with confirmation required

See `.github/workflows/supabase-ci.yml` for implementation details.

## 📚 Related Documentation

- [Database Schema](../docs/schema.dbml) - Complete ERD
- [RLS Implementation](../RLS_IMPLEMENTATION_REPORT.md) - Security details
- [Operations Guide](../docs/ops-README.md) - Database management
- [Testing Guide](../S2_TESTING_REPORT.md) - Validation procedures
