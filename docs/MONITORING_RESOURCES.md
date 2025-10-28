# Monitoring Resources & References

## 📚 Official Documentation

### Azure Monitor Baseline Alerts (AMBA)
- **Homepage**: https://azure.github.io/azure-monitor-baseline-alerts/
- **GitHub**: https://github.com/Azure/azure-monitor-baseline-alerts
- **Service-Specific Alerts**: https://azure.github.io/azure-monitor-baseline-alerts/services/
- **Survey (Feedback)**: https://aka.ms/ambaSurvey

### Azure Verified Modules (AVM)
- **Homepage**: https://azure.github.io/Azure-Verified-Modules/
- **Bicep Registry**: https://aka.ms/AVM
- **GitHub**: https://github.com/Azure/bicep-registry-modules
- **Contribution Guide**: https://azure.github.io/Azure-Verified-Modules/contributing/

### Azure Monitor
- **Overview**: https://learn.microsoft.com/azure/azure-monitor/overview
- **Best Practices**: https://learn.microsoft.com/azure/azure-monitor/best-practices
- **Pricing**: https://azure.microsoft.com/pricing/details/monitor/
- **Limits**: https://learn.microsoft.com/azure/azure-monitor/service-limits

### KQL (Kusto Query Language)
- **Quick Reference**: https://learn.microsoft.com/azure/data-explorer/kql-quick-reference
- **Tutorial**: https://learn.microsoft.com/azure/data-explorer/kusto/query/tutorial
- **Best Practices**: https://learn.microsoft.com/azure/data-explorer/kusto/query/best-practices

## 🎓 Learning Paths

### Microsoft Learn
1. **[Monitor and backup Azure resources](https://learn.microsoft.com/training/paths/az-104-monitor-backup-resources/)**
   - Duration: ~4 hours
   - Level: Intermediate
   - Free

2. **[Design and implement logging and monitoring solutions](https://learn.microsoft.com/training/paths/design-monitoring-strategy-azure/)**
   - Duration: ~6 hours
   - Level: Advanced
   - Free

3. **[Azure Monitor fundamentals](https://learn.microsoft.com/training/modules/intro-to-azure-monitor/)**
   - Duration: 45 minutes
   - Level: Beginner
   - Free

### Video Courses

1. **Pluralsight**: [Azure Monitor Deep Dive](https://www.pluralsight.com/courses/microsoft-azure-monitor)
   - Comprehensive course covering all aspects
   - Requires Pluralsight subscription

2. **YouTube - Azure Friday**: [Azure Monitor Series](https://www.youtube.com/playlist?list=PLLasX02E8BPDT2Z2pdCHNCkENpcQWy5n6)
   - Free video series
   - Weekly updates

## 🛠️ Tools & Utilities

### Monitoring Tools
- **Azure Monitor**: https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade
- **Azure Workbooks**: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Insights%2Fworkbooks
- **Log Analytics**: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.OperationalInsights%2Fworkspaces

### Development Tools
- **VS Code Extension**: [Azure Monitor](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azuremonitor)
- **KQL Extension**: [Kusto Language Server](https://marketplace.visualstudio.com/items?itemName=rosshamish.kuskus-kusto-language-server)
- **Bicep Extension**: [Bicep Language Support](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

### CLI Tools
```powershell
# Azure CLI (with monitor extension)
az extension add --name monitor

# KQL Query Tool
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AzureDiagnostics | take 10"

# Bicep CLI
az bicep version
```

## 📊 Sample Queries & Templates

### GitHub Repositories

1. **Azure Monitor Community**
   - URL: https://github.com/Azure/azure-monitor-community
   - Contains: Sample queries, dashboards, alert rules

2. **Azure Workbooks Gallery**
   - URL: https://github.com/microsoft/Application-Insights-Workbooks
   - Contains: Pre-built workbooks for various scenarios

3. **KQL Queries**
   - URL: https://github.com/rod-trent/MustLearnKQL
   - Contains: KQL learning resources and examples

4. **AMBA Templates**
   - URL: https://github.com/Azure/azure-monitor-baseline-alerts/tree/main/patterns
   - Contains: Ready-to-deploy alert templates

## 🎯 Service-Specific AMBA Guidelines

### Container Apps
- **Alerts**: https://azure.github.io/azure-monitor-baseline-alerts/services/App/containerApps/
- **Recommended Thresholds**:
  - CPU: >90%
  - Memory: >90%
  - Restarts: >3 in 15min

### PostgreSQL Flexible Server
- **Alerts**: https://azure.github.io/azure-monitor-baseline-alerts/services/DBforPostgreSQL/flexibleServers/
- **Recommended Thresholds**:
  - CPU: >90%
  - Memory: >90%
  - Storage: >85%
  - Connections: Monitor failed connections

### API Management
- **Alerts**: https://azure.github.io/azure-monitor-baseline-alerts/services/ApiManagement/service/
- **Recommended Thresholds**:
  - Failed requests: >10 in 15min
  - Latency P95: >5 seconds
  - Capacity: >80%

### Static Web Apps
- **Alerts**: https://azure.github.io/azure-monitor-baseline-alerts/services/Web/staticSites/
- **Recommended Metrics**:
  - HTTP errors (4xx, 5xx)
  - Request count
  - Bandwidth usage

## 🔗 AVM Modules for Monitoring

### Core Monitoring Modules

```bicep
// Action Groups
'br/public:avm/res/insights/action-group:0.8.0'

// Metric Alerts
'br/public:avm/res/insights/metric-alert:0.4.1'

// Log Alerts (Scheduled Query Rules)
'br/public:avm/res/insights/scheduled-query-rule:0.5.2'

// Activity Log Alerts
'br/public:avm/res/insights/activity-log-alert:0.4.1'

// Application Insights
'br/public:avm/res/insights/component:0.6.1'

// Log Analytics Workspace
'br/public:avm/res/operational-insights/workspace:0.12.0'

// Complete Monitoring Pattern
'br/public:avm/ptn/azd/monitoring:0.2.1'
```

### Module Documentation
- **AVM Hub**: https://azure.github.io/Azure-Verified-Modules/
- **Module Index**: https://azure.github.io/Azure-Verified-Modules/indexes/bicep/
- **GitHub**: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/insights

## 💬 Community & Support

### Forums & Discussion
- **Microsoft Q&A**: https://learn.microsoft.com/answers/tags/143/azure-monitor
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/azure-monitor
- **Reddit**: https://www.reddit.com/r/AZURE/
- **Azure Tech Community**: https://techcommunity.microsoft.com/t5/azure-monitor/bd-p/AzureMonitor

### Azure Support
- **Support Portal**: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- **Service Health**: https://status.azure.com/
- **Product Feedback**: https://feedback.azure.com/d365community/forum/79b1327d-d925-ec11-b6e6-000d3a4f06a4

### Social Media
- **Twitter/X**: [@AzureMonitor](https://twitter.com/search?q=%23AzureMonitor)
- **LinkedIn**: [Azure Monitor Group](https://www.linkedin.com/groups/4407177/)
- **YouTube**: [Microsoft Azure](https://www.youtube.com/@MicrosoftAzure)

## 📰 Blogs & Articles

### Microsoft Blogs
- **Azure Monitor Blog**: https://techcommunity.microsoft.com/t5/azure-monitor-blog/bg-p/AzureMonitorBlog
- **Azure Updates**: https://azure.microsoft.com/updates/?category=monitoring-management
- **Azure Architecture Blog**: https://techcommunity.microsoft.com/t5/azure-architecture-blog/bg-p/AzureArchitectureBlog

### Community Blogs
- **John Savill's Technical Training**: https://www.youtube.com/@NTFAQGuy
- **Scott Hanselman**: https://www.hanselman.com/blog/CategoryView.aspx?category=Azure
- **Thomas Maurer**: https://www.thomasmaurer.ch/category/azure/

## 🎮 Interactive Learning

### Hands-On Labs
1. **Microsoft Learn Sandbox**
   - Free Azure subscription for learning
   - https://learn.microsoft.com/training/

2. **Azure Citadel**
   - Community labs and workshops
   - https://azurecitadel.com/

3. **KQL Detective Agency**
   - Gamified KQL learning
   - https://detective.kusto.io/

### Practice Environments
- **Azure Free Account**: https://azure.microsoft.com/free/
- **Azure for Students**: https://azure.microsoft.com/free/students/
- **Visual Studio Subscription**: https://my.visualstudio.com/

## 📖 Books

### Recommended Reading

1. **"Azure for Architects" by Ritesh Modi**
   - Comprehensive guide to Azure architecture
   - Includes monitoring best practices

2. **"Monitoring and Observability" by Cindy Sridharan**
   - Theory and practices (not Azure-specific but excellent)
   - Available free online: https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/

3. **"The Site Reliability Workbook" by Google**
   - SRE practices including monitoring
   - Free: https://sre.google/workbook/table-of-contents/

## 🔧 Configuration Examples

### Sample Alert Rules (JSON)
- **GitHub Gist**: https://gist.github.com/search?q=azure+monitor+alert
- **Azure Quickstart Templates**: https://github.com/Azure/azure-quickstart-templates

### Workbook Templates
- **Community Gallery**: https://github.com/microsoft/Application-Insights-Workbooks/tree/master/Workbooks
- **Azure Portal**: Monitor → Workbooks → Public Templates

### Log Analytics Queries
- **Query Samples**: https://learn.microsoft.com/azure/azure-monitor/logs/queries
- **Schema Reference**: https://learn.microsoft.com/azure/azure-monitor/reference/tables/tables-category

## 🎯 Related Technologies

### Complementary Services
- **Application Insights**: https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview
- **Azure Managed Grafana**: https://azure.microsoft.com/services/managed-grafana/
- **Azure Chaos Studio**: https://azure.microsoft.com/services/chaos-studio/
- **Azure Load Testing**: https://azure.microsoft.com/services/load-testing/

### Third-Party Integrations
- **Datadog**: https://docs.datadoghq.com/integrations/azure/
- **Splunk**: https://docs.splunk.com/Documentation/AddOns/latest/Azure/
- **Elastic**: https://www.elastic.co/guide/en/cloud/current/ec-azure-marketplace.html
- **PagerDuty**: https://support.pagerduty.com/docs/azure-integration-guide

## 🚀 Advanced Topics

### Infrastructure as Code
- **Bicep Documentation**: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest
- **Pulumi Azure**: https://www.pulumi.com/docs/clouds/azure/

### DevOps Integration
- **Azure DevOps Monitoring**: https://learn.microsoft.com/azure/devops/project/navigation/preview-features
- **GitHub Actions**: https://github.com/marketplace/actions/azure-monitor
- **Jenkins Integration**: https://plugins.jenkins.io/azure-monitor/

### Cost Optimization
- **Azure Cost Management**: https://learn.microsoft.com/azure/cost-management-billing/
- **Advisor Recommendations**: https://portal.azure.com/#blade/Microsoft_Azure_Expert/AdvisorMenuBlade/overview
- **Cost Alerts**: https://learn.microsoft.com/azure/cost-management-billing/costs/cost-mgt-alerts-monitor-usage-spending

## 📱 Mobile Apps

### Azure Mobile App
- **iOS**: https://apps.apple.com/app/microsoft-azure/id1219013620
- **Android**: https://play.google.com/store/apps/details?id=com.microsoft.azure

Features:
- View alerts on the go
- Run diagnostics
- Manage resources
- Execute common actions

## 🔐 Security & Compliance

### Security Monitoring
- **Microsoft Defender for Cloud**: https://learn.microsoft.com/azure/defender-for-cloud/
- **Microsoft Sentinel**: https://learn.microsoft.com/azure/sentinel/
- **Azure Policy**: https://learn.microsoft.com/azure/governance/policy/

### Compliance
- **Trust Center**: https://www.microsoft.com/trust-center
- **Compliance Documentation**: https://learn.microsoft.com/azure/compliance/
- **Service Trust Portal**: https://servicetrust.microsoft.com/

## 🆕 What's New

### Stay Updated
- **Azure Updates RSS**: https://azure.microsoft.com/updates/feed/
- **What's New in Azure Monitor**: https://learn.microsoft.com/azure/azure-monitor/whats-new
- **Roadmap**: https://azure.microsoft.com/updates/?category=monitoring-management

### Preview Features
- **Azure Preview Portal**: https://preview.portal.azure.com/
- **Feature Previews**: https://azure.microsoft.com/updates/?status=inpreview

---

## 📝 Quick Reference Card

| Need | Resource |
|------|----------|
| **Learn AMBA** | https://azure.github.io/azure-monitor-baseline-alerts/ |
| **Use AVM** | https://aka.ms/AVM |
| **Write KQL** | https://learn.microsoft.com/azure/data-explorer/kql-quick-reference |
| **Check Pricing** | https://azure.microsoft.com/pricing/details/monitor/ |
| **Get Help** | https://learn.microsoft.com/answers/tags/143/azure-monitor |
| **Report Issues** | https://github.com/Azure/azure-monitor-baseline-alerts/issues |
| **View Updates** | https://azure.microsoft.com/updates/?category=monitoring-management |

---

**Last Updated**: October 2025
**Maintained By**: Case Management System Team
**License**: MIT
