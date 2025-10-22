# Database Options

## Current Setup: SQLite (In-Memory)

**⚠️ WARNING:** Your data is currently stored in SQLite **inside the container**. 

**This means:**
- ❌ Data is **lost** when container restarts
- ❌ Can't scale beyond 1 replica (no shared database)
- ✅ Good for: Development, demos, testing

---

## Production Database Options

### Option 1: Azure Database for PostgreSQL (Recommended)

**Pros:**
- ✅ Managed service (backups, updates, monitoring)
- ✅ Data persists across deployments
- ✅ Can scale to multiple container replicas
- ✅ High availability options
- ✅ Automatic backups

**Cons:**
- 💰 Costs ~$25-50/month (Burstable tier)

**Cost Breakdown:**
| Tier | vCores | RAM | Storage | Cost/Month |
|------|--------|-----|---------|------------|
| Burstable (B1ms) | 1 | 2 GB | 32 GB | ~$25 |
| Burstable (B2s) | 2 | 4 GB | 32 GB | ~$50 |
| General Purpose | 2 | 8 GB | 64 GB | ~$150 |

#### How to Enable PostgreSQL:

1. **Uncomment PostgreSQL in main.bicep:**
```bicep
// In infra/bicep/main.bicep, add:

// PostgreSQL Database
module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql-deployment'
  params: {
    serverName: 'psql-${resourceSuffix}'
    location: location
    adminUsername: 'caseadmin'
    adminPassword: 'GENERATE_SECURE_PASSWORD' // Use Key Vault in production!
    databaseName: 'casemanagement'
    postgresqlVersion: '16'
    skuTier: 'Burstable'
    skuName: 'Standard_B1ms'
    storageSizeGB: 32
    tags: tags
  }
}

// Update Container App to use PostgreSQL
module app 'modules/app.bicep' = {
  // ... existing params ...
  environmentVariables: [
    {
      name: 'DATABASE_URL'
      value: postgresql.outputs.connectionString
    }
  ]
}
```

2. **Update Python code to use PostgreSQL:**

```python
# backend/app/database.py
import os

# Change from SQLite to PostgreSQL
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./data/tickets.db"  # Fallback for local dev
)

engine = create_engine(DATABASE_URL)
```

3. **Add PostgreSQL driver:**
```txt
# backend/requirements.txt
psycopg2-binary==2.9.9  # PostgreSQL driver
```

---

### Option 2: SQLite with Azure Files (Persistent Storage)

**Pros:**
- ✅ Cheap (~$2-5/month)
- ✅ Simple setup
- ✅ Data persists

**Cons:**
- ❌ Can't scale beyond 1 replica
- ❌ No managed backups
- ❌ Slower than PostgreSQL

#### How to Enable:

Add storage mount to Container App:
```bicep
// In modules/app.bicep
volumes: [
  {
    name: 'data-volume'
    storageType: 'AzureFile'
    storageName: 'case-management-storage'
  }
]
volumeMounts: [
  {
    volumeName: 'data-volume'
    mountPath: '/app/data'
  }
]
```

---

### Option 3: Keep SQLite (Development Only)

**Good for:**
- ✅ Learning and experimentation
- ✅ Demos and POCs
- ✅ Local development

**Not good for:**
- ❌ Production
- ❌ Multiple users
- ❌ Data you care about

---

## Recommendation for Your Use Case

### For Learning/Testing (Current):
✅ **Keep SQLite** - It's fine for now!

### For Real Company Use:
✅ **Use PostgreSQL** - Worth the cost for data safety

### For Personal Project with Little Traffic:
⚠️ **SQLite + Azure Files** - Cheaper middle ground

---

## Migration Path

**Phase 1 (Now):** SQLite in container ✅ YOU ARE HERE
**Phase 2:** Add PostgreSQL to Bicep, keep SQLite as fallback
**Phase 3:** Switch DATABASE_URL to PostgreSQL
**Phase 4:** Remove SQLite code

---

## Quick Setup: Add PostgreSQL

If you want PostgreSQL now:

1. Create a GitHub Secret for database password:
   - Go to: https://github.com/HenrikSkaanes/case-management-system/settings/secrets/actions
   - Add: `POSTGRES_ADMIN_PASSWORD` = `YourSecurePassword123!`

2. Uncomment PostgreSQL module (I can help with this)

3. Push to GitHub - infrastructure will deploy PostgreSQL

4. Update Python code to use PostgreSQL

**Want me to set this up now?** Let me know! 🚀
