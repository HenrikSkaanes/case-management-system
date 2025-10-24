# Cost-Optimized Architecture for Learning

## 💰 Final Cost Breakdown

### Monthly Costs (Optimized for POC + Learning)

| Resource | SKU | Monthly Cost | Annual Cost |
|----------|-----|--------------|-------------|
| **VNet + Subnets** | Standard | $0 | $0 |
| **NAT Gateway** | Standard | ~$33 | ~$396 |
| **Key Vault** | Standard | ~$1 | ~$12 |
| **Container Apps** | Pay-per-use (scale to 0) | ~$10-20 | ~$120-240 |
| **PostgreSQL Private** | Burstable B1ms | ~$25 | ~$300 |
| **Log Analytics** | Pay-per-GB | ~$10 | ~$120 |
| **Static Web App** | Free | $0 | $0 |
| **ACR** | Basic | ~$5 | ~$60 |
| **API Management** | **Consumption** | **~$3 + usage** | **~$36** |
| **Front Door** | **Standard** | **~$35** | **~$420** |
| | | | |
| **TOTAL** | | **~$120-150/month** | **~$1,500-1,800/year** |

---

## 📊 Comparison with Other Options

| Architecture | Monthly | Annual | What You Get |
|--------------|---------|---------|--------------|
| **Current (Basic)** | $50-75 | $600-900 | No security features |
| **Budget POC** | $80-100 | $960-1,200 | VNet + Key Vault only |
| **Optimized (This)** ⭐ | $120-150 | $1,500-1,800 | All features, cost-optimized |
| **Full Production** | $350-450 | $4,200-5,400 | Enterprise-grade |

---

## 🎓 What You Learn with This Setup

### API Management (Consumption Tier ~$3/month)
**What it does:**
- Acts as a gateway between your frontend and backend
- Handles CORS, rate limiting, authentication
- Provides analytics and monitoring
- Enables API versioning

**Key concepts you'll learn:**
- ✅ Policies (inbound/outbound/backend)
- ✅ Rate limiting & throttling
- ✅ CORS configuration
- ✅ API products & subscriptions
- ✅ Backend service URLs
- ✅ Response caching
- ✅ Request/response transformation

**Consumption vs Developer:**
| Feature | Consumption (~$3/mo) | Developer (~$50/mo) |
|---------|---------------------|---------------------|
| Rate limit | ✅ Yes | ✅ Yes |
| CORS | ✅ Yes | ✅ Yes |
| Analytics | ✅ Basic | ✅ Advanced |
| Dev portal | ❌ No | ✅ Yes |
| VNet integration | ❌ No | ✅ Yes |
| SLA | ❌ None | ✅ 99.95% |
| Cold starts | ⚠️ Yes (~10s) | ✅ None |

**Perfect for POC:** The $47/month savings is worth the occasional cold start for learning!

---

### Azure Front Door (Standard ~$35/month)
**What it does:**
- Global CDN (Content Delivery Network)
- SSL/TLS termination
- URL routing and rewrites
- Caching strategies
- DDoS protection (basic)

**Key concepts you'll learn:**
- ✅ Origin groups & health probes
- ✅ Routing rules & path patterns
- ✅ Cache configuration
- ✅ Compression settings
- ✅ Custom domains & SSL
- ✅ HTTP to HTTPS redirects

**Standard vs Premium:**
| Feature | Standard (~$35/mo) | Premium (~$330/mo) |
|---------|-------------------|-------------------|
| CDN | ✅ Yes | ✅ Yes |
| SSL/TLS | ✅ Yes | ✅ Yes |
| Routing | ✅ Yes | ✅ Yes |
| Caching | ✅ Yes | ✅ Yes |
| Basic DDoS | ✅ Yes | ✅ Yes |
| WAF (firewall) | ❌ No | ✅ Yes |
| Private Link | ❌ No | ✅ Yes |
| Advanced rules | ❌ Limited | ✅ Extensive |

**Perfect for POC:** You get 90% of the value at 10% of the cost!

---

## 🔍 What's Different from Budget Version?

### You're Adding:

**API Management (~$3/month extra)**
- Learn about API gateways
- Understand rate limiting
- Practice policy configuration
- See API analytics

**Front Door (~$35/month extra)**
- Global CDN experience
- SSL/TLS management
- Routing strategies
- Caching patterns

**Total difference:** ~$40/month more than budget version

---

## 💡 Cost Optimization Tips

### If You Want to Save More:

1. **Skip NAT Gateway** (saves ~$33/month)
   ```json
   "deployNatGateway": { "value": false }
   ```
   - Tradeoff: Dynamic egress IP (changes on restart)
   - Fine if you don't need IP allowlisting

2. **Use Smaller PostgreSQL** (saves ~$13/month)
   - Change `Standard_B1ms` → `Standard_B1s`
   - 1 vCore instead of 2
   - Sufficient for POC testing

3. **Aggressive Container Apps Scaling** (saves ~$5-10/month)
   ```bicep
   minReplicas: 0  // Already configured
   maxReplicas: 2  // Limit maximum instances
   ```

**Total possible savings:** ~$50/month → Brings cost to ~$70-100/month

---

## 🚀 Upgrade Path

### When to Upgrade Each Component:

**APIM: Consumption → Developer ($50/month)**
- When: Need dev portal, advanced analytics, or VNet integration
- Benefit: No cold starts, 99.95% SLA

**APIM: Developer → Standard/Premium ($250-700/month)**
- When: Production with high traffic
- Benefit: Multi-region, better performance, higher limits

**Front Door: Standard → Premium ($330/month)**
- When: Need WAF, DDoS protection, compliance
- Benefit: OWASP rules, bot protection, private link

**PostgreSQL: B1ms → General Purpose ($100-300/month)**
- When: Performance issues or high concurrent connections
- Benefit: Better IOPS, more connections, point-in-time restore

---

## 📈 Expected Usage Costs

### API Management (Consumption)
- Base: $3.50/month (1M calls included)
- Additional: $0.035 per 10K calls
- Example: 5M calls/month = $3.50 + $1.40 = $4.90

### Front Door (Standard)
- Base: $35/month
- Outbound data: $0.081/GB (first 10TB)
- Example: 100GB/month = $35 + $8.10 = $43.10

### Container Apps
- vCPU-second: $0.000024
- GB-second: $0.000002375
- HTTP requests: Free (first 2M)
- Example: 10 hours/day at 0.5 vCPU, 1GB = ~$15/month

**Typical POC total:** ~$120-150/month

---

## ✅ Recommendation

**Deploy with these settings:**
- APIM: Consumption ✅
- Front Door: Standard ✅
- NAT Gateway: Enabled ✅
- PostgreSQL: B1ms ✅
- Container Apps: Scale to 0 ✅

**Cost:** ~$120-150/month
**Value:** Full production architecture for learning
**Upgrade:** Easy when you need it

This gives you hands-on experience with:
- API Management concepts
- Global CDN architecture
- Networking best practices
- Security patterns
- Infrastructure as Code

**All for less than the cost of 2-3 Udemy courses! 🎓**
