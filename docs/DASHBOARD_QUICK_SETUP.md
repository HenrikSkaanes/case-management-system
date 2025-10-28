# 📌 Quick Dashboard Setup (5 Minutes)

**Cost**: $0/month  
**Setup Time**: 5 minutes  
**Skill Level**: Absolute beginner

---

## 🎯 What is an Azure Dashboard?

A simple, pinned collection of tiles showing metrics from your resources. Think of it as a customizable home screen for your infrastructure.

**Comparison**:

| Feature | Dashboard | Workbook |
|---------|-----------|----------|
| **Setup Time** | 5 min | 15 min |
| **Complexity** | Simple | Advanced |
| **Customization** | Basic | Full |
| **Log Queries** | ❌ No | ✅ Yes |
| **Charts** | Pre-defined | Custom |
| **Best For** | Quick glance | Deep analysis |

---

## 🚀 Setup Steps

### Step 1: Create Dashboard

1. Go to [Azure Portal](https://portal.azure.com)
2. Click **Dashboard** in left menu (or search "Dashboard")
3. Click **+ New dashboard** → **Blank dashboard**
4. Name it: **"Case Management System - Monitoring"**
5. Click **Done customizing** (you'll add tiles next)

### Step 2: Pin Container App Metrics

1. Search for your **Container App** resource
2. Click **Metrics** in left menu
3. Configure first metric:
   - Metric: **CPU Usage (nanoCores)**
   - Aggregation: **Avg**
   - Time range: **Last 1 hour**
4. Click **📌 Pin to dashboard** icon (top right)
5. Select your dashboard
6. Click **Pin**

7. Repeat for more metrics:
   - **Working Set Bytes** (Memory) - Avg
   - **Requests** - Sum
   - **Restarts** - Count

### Step 3: Pin PostgreSQL Metrics

1. Search for your **PostgreSQL server** resource
2. Click **Metrics** in left menu
3. Pin these metrics:
   - **CPU percent** - Avg
   - **Memory percent** - Avg
   - **Storage percent** - Avg
   - **Active Connections** - Avg

### Step 4: Pin APIM Metrics

1. Search for your **API Management** resource
2. Click **Metrics** in left menu
3. Pin these metrics:
   - **Total Gateway Requests** - Sum
   - **Failed Gateway Requests** - Sum
   - **Gateway Request Duration** - Avg

### Step 5: Organize Dashboard

1. Go back to **Dashboard**
2. Click **Edit** (top toolbar)
3. Drag tiles to organize:
   ```
   ┌─────────────────────────────────────────┐
   │ [Container CPU] [Container Memory]      │
   │ [Container Requests] [Container Errors] │
   ├─────────────────────────────────────────┤
   │ [DB CPU] [DB Memory] [DB Storage]       │
   │ [DB Connections]                        │
   ├─────────────────────────────────────────┤
   │ [APIM Requests] [APIM Failures]         │
   │ [APIM Latency]                          │
   └─────────────────────────────────────────┘
   ```
4. Resize tiles by dragging corners
5. Click **Done customizing**

### Step 6: Share Dashboard

1. Click **Share** (top toolbar)
2. Choose:
   - **Publish to dashboard** → Select users/groups
   - OR **Copy link** → Send to team
3. Click **Share**

---

## 📊 Recommended Tiles

### Must-Have Metrics (Pin These First)

**Container App** (Backend Health):
- ✅ CPU Usage (nanoCores) - Avg
- ✅ Working Set Bytes - Avg
- ✅ Requests - Sum
- ✅ HTTP 5xx errors - Count

**PostgreSQL** (Database Health):
- ✅ CPU percent - Avg
- ✅ Memory percent - Avg
- ✅ Storage percent - Avg
- ✅ Active Connections - Avg

**API Management** (Gateway Health):
- ✅ Total Requests - Sum
- ✅ Failed Requests - Sum
- ✅ Duration - Avg

### Nice-to-Have Metrics

**Container App**:
- Replica Count
- Response Time
- Network In/Out

**PostgreSQL**:
- Read/Write IOPS
- Network In/Out
- Replication Lag (if using replicas)

**APIM**:
- Backend Duration
- Other Requests (external API calls)
- Capacity

---

## 🎨 Customization Tips

### Change Time Range

1. Click on any tile
2. Click **⚙️ Settings** icon
3. Change **Time range**:
   - Last 30 minutes
   - Last 1 hour (recommended)
   - Last 4 hours
   - Last 24 hours
4. Click **Apply**

### Change Chart Type

1. Click tile → **⚙️ Settings**
2. Change **Chart type**:
   - **Line** (trends over time) - Recommended
   - **Area** (filled line chart)
   - **Bar** (comparisons)
   - **Scatter** (correlation analysis)

### Split by Dimension

Example: Show CPU per replica

1. Edit metric
2. Click **Add filter**
3. Select **replicaName**
4. Chart now shows each replica separately

### Add Alert Status Tile

1. In dashboard edit mode, click **+ Add tile**
2. Search for **Alert summary**
3. Drag onto dashboard
4. Configure:
   - Scope: Your resource group
   - Time range: Last 24 hours
   - Severity: All
5. Click **Apply**

---

## 🔄 Auto-Refresh

Dashboards don't auto-refresh by default. To enable:

1. Open dashboard
2. Click **⟳ Auto refresh** (top toolbar)
3. Select interval:
   - 5 minutes (recommended)
   - 15 minutes
   - 30 minutes
   - 1 hour

**Note**: Too frequent refresh can slow down browser

---

## 📱 Mobile Access

### Azure Mobile App

1. Install **Azure Mobile App** (iOS/Android)
2. Login with your account
3. Go to **Dashboards**
4. View your monitoring dashboard

**Works great for**:
- Quick status checks
- Reviewing alerts on-the-go
- Basic troubleshooting

---

## 🆚 Dashboard vs Workbook - Which to Use?

### Use Dashboard When:
- ✅ You need quick visual overview
- ✅ Management wants simple executive view
- ✅ You're pinning from multiple resources
- ✅ Mobile access is important
- ✅ You want fastest setup

### Use Workbook When:
- ✅ You need log queries (errors, traces)
- ✅ You want advanced visualizations
- ✅ You need interactive parameters
- ✅ You're doing deep troubleshooting
- ✅ You want to combine metrics + logs

### Use Both!
**Recommended Approach**:
1. ✅ Create **Dashboard** for daily monitoring (everyone)
2. ✅ Create **Workbook** for investigations (developers)

---

## 🚨 Common Issues

### "Cannot pin to dashboard"

**Cause**: Dashboard sharing permissions

**Fix**:
1. Ensure dashboard is shared with your user
2. OR create new personal dashboard
3. Try pinning again

### "No data available"

**Cause**: Resource hasn't generated metrics yet

**Fix**:
1. Wait 5-10 minutes after deployment
2. Verify resource is running
3. Try changing time range to "Last 24 hours"

### "Metric not found"

**Cause**: Wrong resource type or metric namespace

**Fix**:
1. Verify resource type (Container App vs Container Instance)
2. Check metric is available for this resource tier
3. Some metrics require specific configurations

### Tiles show wrong data

**Cause**: Aggregation type mismatch

**Fix**:
- **CPU/Memory**: Use Average (not Sum)
- **Requests**: Use Sum (not Average)
- **Errors**: Use Count
- **Latency**: Use Average or P95

---

## 📈 Advanced: Add Custom Markdown Tiles

Add text explanations or status indicators:

1. In edit mode, click **+ Add tile** → **Markdown**
2. Write content:
   ```markdown
   ## 🚦 System Status
   
   **Last Updated**: Nov 28, 2024
   
   | Service | Status |
   |---------|--------|
   | Backend | ✅ Healthy |
   | Database | ✅ Healthy |
   | API Gateway | ✅ Healthy |
   
   **Next Review**: Dec 5, 2024
   ```
3. Click **Apply**
4. Position next to metrics

---

## 🎯 Sample Dashboard Layout

```
┌────────────────────────────────────────────────────────┐
│  Case Management System - Monitoring                   │
│  Last refreshed: 2 minutes ago    [⟳ Auto: 5min]      │
├────────────────────────────────────────────────────────┤
│                                                         │
│  📊 Active Alerts (Last 24h)    🚦 Status Overview     │
│  ┌──────────────────────┐       ┌──────────────────┐  │
│  │ Critical: 0          │       │ Backend:    ✅   │  │
│  │ Warning:  2          │       │ Database:   ✅   │  │
│  │ Info:     5          │       │ Gateway:    ✅   │  │
│  └──────────────────────┘       └──────────────────┘  │
│                                                         │
│  🐳 Container App (Backend)                            │
│  ┌──────────┬──────────┬──────────┬──────────┐        │
│  │   CPU    │  Memory  │ Requests │  Errors  │        │
│  │ [Chart]  │ [Chart]  │ [Chart]  │ [Chart]  │        │
│  └──────────┴──────────┴──────────┴──────────┘        │
│                                                         │
│  🗄️ PostgreSQL Database                                │
│  ┌──────────┬──────────┬──────────┬──────────┐        │
│  │   CPU    │  Memory  │ Storage  │  Conns   │        │
│  │ [Chart]  │ [Chart]  │ [Chart]  │ [Chart]  │        │
│  └──────────┴──────────┴──────────┴──────────┘        │
│                                                         │
│  🌐 API Management                                      │
│  ┌──────────┬──────────┬──────────────────────┐       │
│  │ Requests │ Failures │     Latency          │       │
│  │ [Chart]  │ [Chart]  │     [Chart]          │       │
│  └──────────┴──────────┴──────────────────────┘       │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist

- [ ] Created new dashboard
- [ ] Pinned Container App metrics (4 tiles)
- [ ] Pinned PostgreSQL metrics (4 tiles)
- [ ] Pinned APIM metrics (3 tiles)
- [ ] Added alert summary tile
- [ ] Organized layout
- [ ] Set auto-refresh to 5 minutes
- [ ] Shared with team
- [ ] Tested on mobile app
- [ ] Bookmarked dashboard URL

---

## 📚 Next Steps

### Today
- ✅ Use dashboard for daily monitoring
- ✅ Check 2-3 times per day
- ✅ Respond to visual anomalies

### This Week
- ✅ Create **Workbook** for detailed analysis (see `WORKBOOK_SETUP.md`)
- ✅ Set up alert action groups (email notifications)
- ✅ Document normal baselines

### This Month
- ✅ Fine-tune alert thresholds
- ✅ Add more custom tiles based on needs
- ✅ Create dashboards for different audiences:
  - Management (high-level KPIs)
  - Operations (infrastructure health)
  - Developers (errors, logs)

---

## 💡 Pro Tips

1. **Create Multiple Dashboards**:
   - `Monitoring - Overview` (this guide)
   - `Monitoring - Costs` (spending trends)
   - `Monitoring - Security` (security events)

2. **Use Dashboard as Homepage**:
   - Go to **Settings** (⚙️) → **Appearance**
   - Set **Startup dashboard** to your monitoring dashboard

3. **Keyboard Shortcuts**:
   - `Ctrl + F` - Search dashboards
   - `F11` - Fullscreen (great for wall displays)

4. **Export Dashboard**:
   - Click **Download** → Save JSON
   - Commit to Git for version control
   - Restore easily if deleted

5. **Team Dashboards**:
   - Create shared team dashboard
   - Different team members can add their own tiles
   - Everyone sees same view

---

## 🆘 Need Help?

**Quick Questions**:
- How to add more tiles? → Edit mode → Pin from resource metrics
- How to remove tile? → Edit mode → Click X on tile
- How to resize? → Edit mode → Drag corner of tile

**Resources**:
- [Azure Dashboards Docs](https://learn.microsoft.com/en-us/azure/azure-portal/azure-portal-dashboards)
- [Sharing Dashboards](https://learn.microsoft.com/en-us/azure/azure-portal/azure-portal-dashboard-share-access)

**Still Stuck?**
Share:
1. Screenshot of dashboard
2. What you're trying to add
3. Error message (if any)

I'll help debug!
