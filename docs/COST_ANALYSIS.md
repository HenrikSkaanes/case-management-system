# Cost Analysis & Budget Options for POC

## 📊 Current Deployment Cost (Basic Architecture)
Monthly estimate: ~$50-75/month

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| Container Registry | Basic | ~$5 |
| Container Apps | Pay-per-use | ~$5-15 |
| PostgreSQL Flexible | Standard_B1ms | ~$25 |
| Log Analytics | Pay-per-GB | ~$5-10 |
| Static Web App | Free | $0 |
| **Total** | | **~$50-75/month** |

## 💎 New Architecture Cost (Full Production Features)
Monthly estimate: ~$350-450/month

| Resource | SKU | Monthly Cost | Purpose |
|----------|-----|--------------|---------|
| VNet | Standard | $0 | Network isolation |
| NAT Gateway | Standard | ~$30 | Fixed egress IP |
| Key Vault | Standard | ~$1 | Secrets management |
| Container Apps (VNet) | Pay-per-use | ~$10-20 | App hosting |
| PostgreSQL Private | Standard_B1ms | ~$25 | Database |
| **API Management** | **Developer** | **~$50** | **API gateway** |
| **Front Door Premium** | **Premium + WAF** | **~$200-300** | **CDN + Security** |
| Log Analytics | Pay-per-GB | ~$10 | Monitoring |
| Static Web App | Free | $0 | Frontend CDN |
| **Total** | | **~$350-450/month** |

---

## 💰 BUDGET-FRIENDLY OPTIONS FOR POC

### Option 1: Essential Security (~$80-100/month) ⭐ RECOMMENDED
**What you get:**
- ✅ VNet isolation (private PostgreSQL)
- ✅ NAT Gateway (fixed IP for outbound calls)
- ✅ Key Vault (secure secrets)
- ✅ Container Apps with managed identity
- ❌ Skip API Management (use Container App directly)
- ❌ Skip Front Door (use Static Web App directly)

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| VNet + Subnets | Standard | $0 |
| NAT Gateway | Standard | ~$30 |
| Key Vault | Standard | ~$1 |
| Container Apps (VNet) | Pay-per-use | ~$10-20 |
| PostgreSQL Private | Standard_B1ms | ~$25 |
| Log Analytics | Pay-per-GB | ~$10 |
| Static Web App | Free | $0 |
| ACR | Basic | ~$5 |
| **Total** | | **~$80-100/month** |

**Tradeoffs:**
- No rate limiting (rely on Container Apps built-in)
- No WAF (Web Application Firewall)
- No global CDN for API (frontend still has CDN via Static Web App)

---

### Option 2: Minimal Security (~$60-75/month)
**What you get:**
- ✅ Private PostgreSQL (VNet isolation)
- ✅ Key Vault (secure secrets)
- ❌ Skip NAT Gateway (dynamic egress IP)
- ❌ Skip API Management
- ❌ Skip Front Door

| Resource | Monthly Cost |
|----------|--------------|
| VNet + Subnets | $0 |
| Key Vault | ~$1 |
| Container Apps (VNet) | ~$10-20 |
| PostgreSQL Private | ~$25 |
| Log Analytics | ~$10 |
| Static Web App | $0 |
| ACR | ~$5 |
| **Total** | **~$60-75/month** |

**Tradeoffs:**
- Egress IP changes (issue for IP allowlisting)
- No rate limiting
- No WAF

---

### Option 3: Keep Current + Add Essentials (~$55-80/month)
**What you get:**
- Keep current public PostgreSQL
- Add Key Vault only
- No networking changes

**Not recommended** - Misses core security benefits

---

## 🎯 Recommended Approach for POC

### Phase 1: Essential Security (Option 1) - Deploy Now
- Cost: ~$80-100/month
- Duration: POC period (1-3 months)
- Benefits: Core security, manageable cost

### Phase 2: Add APIM (Optional) - After POC Success
- Additional cost: +$50/month (Developer SKU)
- When: If you need rate limiting, API versioning, or analytics

### Phase 3: Add Front Door (Optional) - Before Production
- Additional cost: +$200-300/month (Premium with WAF)
- When: Need global CDN, DDoS protection, or compliance requirements

---

## 🔧 How to Deploy Budget Version

### Option A: Remove Expensive Components (Recommended)
Comment out APIM and Front Door modules in `main.bicep`:

1. Keep: Networking, Key Vault, Private PostgreSQL, Container Apps
2. Skip: API Management, Front Door
3. Static Web App points directly to Container App

### Option B: Use Cheaper SKUs
- APIM: Use "Consumption" tier (~$3/month + pay-per-use)
  - Tradeoff: Less features, cold starts
- Front Door: Use "Standard" without WAF (~$30/month)
  - Tradeoff: No advanced security rules

---

## 💡 Additional Cost Savings

### PostgreSQL
- Current: Standard_B1ms (~$25/month)
- Alternative: Standard_B1s (~$12/month)
  - 1 vCore instead of 2, sufficient for POC

### NAT Gateway
- Consider skipping if:
  - Don't need fixed egress IP
  - Not integrating with IP-restricted external APIs
  - Saves ~$30/month

### Container Apps
- Set aggressive scale-down rules:
  ```bicep
  minReplicas: 0  // Scale to zero when idle
  maxReplicas: 2  // Limit maximum replicas
  ```

---

## 📝 Summary

| Architecture | Monthly Cost | Use Case |
|--------------|--------------|----------|
| **Current (Basic)** | $50-75 | Basic POC, no security |
| **Essential Security** ⭐ | $80-100 | POC with best practices |
| **With APIM** | $130-150 | Need API management |
| **Full Production** | $350-450 | Production ready |

**My Recommendation:** Start with Essential Security (~$80-100/month)
- Keeps core security best practices
- Manageable POC costs
- Easy to add APIM/Front Door later
