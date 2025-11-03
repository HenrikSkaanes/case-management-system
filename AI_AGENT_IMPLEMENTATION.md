# AI Agent Ticket Automation - Implementation Plan

**Feature Branch**: `feature/ai-agent-ticket-automation`  
**Start Date**: November 3, 2025  
**Goal**: Add AI-powered ticket drafting with email integration and enhanced UI

---

## 📋 Implementation Phases

### **Phase 1: UI/UX Overhaul** 🎨

#### 1.1 Update Ticket Status Model ✅
**File**: `backend/app/models.py`
- [x] Add new ticket statuses:
  - `AI_DRAFT` - Ticket drafted by AI agent
  - `IN_REVIEW` - Employee reviewing AI draft  
  - `AWAITING_CUSTOMER` - Waiting for customer response
  - `RESOLVED` - Issue resolved, awaiting closure
  - `CLOSED` - Ticket closed
- [x] Add AI-related fields to Ticket model:
  - `ai_generated: bool` - Flag for AI-drafted tickets
  - `ai_draft_content: str` - Original AI-generated content
  - `ai_sources: JSON` - List of source citations
  - `ai_confidence_score: float` - Agent confidence (0-1)
  - `ai_model_version: str` - Model version used
  - `ai_generated_at: DateTime` - When draft was created
- [x] Create database migration

#### 1.2 Update Kanban Board Component ⬜
**File**: `frontend/src/components/Dashboard.jsx`
- [ ] Update `TICKET_STAGES` array with new stages:
  ```javascript
  { id: 'new', label: '📥 New', color: '#ef4444' }
  { id: 'ai_draft', label: '🤖 AI Drafts', color: '#8b5cf6' }
  { id: 'in_review', label: '👁️ Under Review', color: '#3b82f6' }
  { id: 'in_progress', label: '⚙️ In Progress', color: '#f59e0b' }
  { id: 'awaiting_customer', label: '📬 Awaiting Response', color: '#10b981' }
  { id: 'resolved', label: '✅ Resolved', color: '#6366f1' }
  { id: 'closed', label: '🔒 Closed', color: '#6b7280' }
  ```
- [ ] Update column rendering logic
- [ ] Add stage transition tracking

#### 1.3 Enhance Ticket Card with Action Buttons ⬜
**File**: `frontend/src/components/TicketCard.jsx`
- [ ] Add conditional action buttons based on status:
  - `AI_DRAFT`: "Review Draft →"
  - `IN_REVIEW`: "Approve & Send →"
  - `AWAITING_CUSTOMER`: "Mark Resolved →"
  - `RESOLVED`: "Close Ticket →"
- [ ] Add visual indicator for AI-generated tickets (🤖 badge)
- [ ] Style transitions and hover effects

#### 1.4 Create AI Ticket Review Modal ⬜
**New File**: `frontend/src/components/AITicketModal.jsx`
- [ ] Create split-panel layout:
  - **Left Panel**: Editable draft content
  - **Right Panel**: Source citations
- [ ] Add components:
  - Draft editor (textarea with formatting)
  - Confidence score display
  - Source cards with "View Policy" links
- [ ] Add action buttons:
  - "Approve & Send" (moves to next stage)
  - "Edit Draft" (enable editing mode)
  - "Reject & Reassign" (back to manual handling)
- [ ] Add CSS file: `AITicketModal.css`

#### 1.5 Implement Source Citation Highlighting ⬜
**New File**: `frontend/src/components/SourceHighlight.jsx`
- [ ] Create inline citation component
- [ ] Add hover tooltip showing source preview
- [ ] Implement click handler to show full source in modal
- [ ] Style highlighted text (underline, color, icon)

#### 1.6 Create Source Viewer Popup ⬜
**New File**: `frontend/src/components/SourcePopup.jsx`
- [ ] Display full policy text
- [ ] Show section number and title
- [ ] Add "View full policy" link
- [ ] Close button and backdrop

#### 1.7 Update Ticket Modal for Stage Transitions ⬜
**File**: `frontend/src/components/TicketModal.jsx`
- [ ] Add stage transition buttons at bottom
- [ ] Show current stage with progress indicator
- [ ] Add stage history timeline (optional)
- [ ] Update validation for stage transitions

#### 1.8 Add Backend API Endpoints for Stage Transitions ⬜
**New File**: `backend/app/routes/ticket_stages.py`
- [ ] `POST /api/tickets/{id}/transition` - Move ticket to next stage
- [ ] `POST /api/tickets/{id}/approve-draft` - Approve AI draft and send to customer
- [ ] `POST /api/tickets/{id}/reject-draft` - Reject AI draft
- [ ] `GET /api/tickets/{id}/stage-history` - Get stage transition history
- [ ] Add validation logic for allowed transitions

---

### **Phase 2: Knowledge Base Setup** 📚

#### 2.1 Create Knowledge Base Structure ⬜
**New Directory**: `docs/knowledge-base/`
- [ ] Create folder structure:
  ```
  docs/knowledge-base/
  ├── policies/
  │   ├── ticket-submission-guidelines.md
  │   ├── response-templates.md
  │   ├── vat-returns-policy.md
  │   ├── income-tax-policy.md
  │   └── corporate-tax-policy.md
  ├── procedures/
  │   ├── ticket-categorization.md
  │   └── escalation-process.md
  └── faq/
      ├── common-vat-questions.md
      └── tax-deadlines.md
  ```

#### 2.2 Create Sample Policy Documents ⬜
**Files**: Various markdown files
- [ ] Write `ticket-submission-guidelines.md` (requirements for tickets)
- [ ] Write `response-templates.md` (standard response templates)
- [ ] Write `vat-returns-policy.md` (VAT filing guidelines)
- [ ] Write `income-tax-policy.md` (income tax procedures)
- [ ] Write `corporate-tax-policy.md` (corporate tax guidelines)
- [ ] Write `ticket-categorization.md` (how to categorize tickets)
- [ ] Write `common-vat-questions.md` (FAQ for VAT)
- [ ] Write `tax-deadlines.md` (important dates)

#### 2.3 Add Metadata to Documents ⬜
- [ ] Add YAML frontmatter to each document:
  ```yaml
  ---
  title: "VAT Returns Policy"
  category: "VAT"
  tags: ["vat", "filing", "deadlines"]
  last_updated: "2025-11-03"
  ---
  ```
- [ ] Ensure consistent formatting across all documents

---

### **Phase 3: Azure AI Infrastructure** ☁️

#### 3.1 Deploy Azure OpenAI Service ⬜
**New File**: `infra/bicep/modules/openai.bicep`
- [ ] Create Bicep module for Azure OpenAI
- [ ] Deploy GPT-4o model (gpt-4o deployment)
- [ ] Set capacity to 10K TPM (tokens per minute)
- [ ] Configure managed identity access
- [ ] Add outputs: endpoint, deployment name

#### 3.2 Deploy Azure AI Search ⬜
**New File**: `infra/bicep/modules/ai-search.bicep`
- [ ] Create Bicep module for AI Search service
- [ ] Set SKU to Basic tier ($75/month)
- [ ] Configure 1 replica, 1 partition
- [ ] Enable semantic search
- [ ] Add outputs: endpoint, admin key

#### 3.3 Update Main Bicep to Include AI Resources ⬜
**File**: `infra/bicep/main.bicep`
- [ ] Add Azure OpenAI module
- [ ] Add AI Search module
- [ ] Create role assignments for Container App managed identity:
  - `Cognitive Services OpenAI User` on OpenAI service
  - `Search Index Data Reader` on AI Search service
- [ ] Add outputs for frontend environment variables

#### 3.4 Deploy Infrastructure ⬜
- [ ] Run infrastructure deployment
- [ ] Verify resources created successfully
- [ ] Test managed identity access
- [ ] Document endpoint URLs

---

### **Phase 4: AI Search Index Setup** 🔍

#### 4.1 Create Search Index Schema ⬜
**New File**: `infra/ai-search/index-schema.json`
- [ ] Define index fields:
  - `id` (Edm.String, key)
  - `title` (Edm.String, searchable)
  - `content` (Edm.String, searchable)
  - `category` (Edm.String, filterable)
  - `tags` (Collection(Edm.String), filterable)
  - `source_file` (Edm.String)
  - `last_updated` (Edm.DateTimeOffset)
- [ ] Enable semantic search configuration
- [ ] Configure vector search (optional, for embeddings)

#### 4.2 Create Indexer Script ⬜
**New File**: `scripts/index-knowledge-base.py`
- [ ] Parse markdown files from `docs/knowledge-base/`
- [ ] Extract frontmatter metadata
- [ ] Split documents into chunks (500 tokens each)
- [ ] Upload to AI Search index
- [ ] Handle updates and deletions

#### 4.3 Run Initial Indexing ⬜
- [ ] Execute indexer script
- [ ] Verify documents in AI Search portal
- [ ] Test search queries
- [ ] Validate semantic ranking

---

### **Phase 5: Backend AI Agent Service** 🤖

#### 5.1 Add Azure OpenAI Dependencies ⬜
**File**: `backend/requirements.txt`
- [ ] Add `openai>=1.0.0`
- [ ] Add `azure-search-documents>=11.4.0`
- [ ] Add `tiktoken>=0.5.0` (token counting)
- [ ] Update requirements and rebuild container

#### 5.2 Add AI Configuration ⬜
**File**: `backend/app/config.py`
- [ ] Add environment variables:
  - `AZURE_OPENAI_ENDPOINT`
  - `AZURE_OPENAI_DEPLOYMENT` (gpt-4o)
  - `AI_SEARCH_ENDPOINT`
  - `AI_SEARCH_INDEX_NAME` (policies)
- [ ] Add validation for AI configuration

#### 5.3 Create AI Agent Service ⬜
**New File**: `backend/app/services/ai_agent_service.py`
- [ ] Initialize Azure OpenAI client with managed identity
- [ ] Initialize AI Search client
- [ ] Implement `search_knowledge_base(query: str)` method
- [ ] Implement `generate_ticket_draft(email_content: str)` method
- [ ] Implement function calling for structured output
- [ ] Add error handling and logging

#### 5.4 Define Agent System Prompt ⬜
**New File**: `backend/app/services/prompts.py`
- [ ] Write detailed system prompt for ticket drafting
- [ ] Include instructions for:
  - Email parsing (extract customer info)
  - Category classification
  - Priority assessment
  - Professional tone
  - Citation formatting
- [ ] Add few-shot examples

#### 5.5 Create AI Ticket API Endpoints ⬜
**New File**: `backend/app/routes/ai_tickets.py`
- [ ] `POST /api/ai-tickets/draft-from-email` - Generate draft from email
- [ ] `GET /api/ai-tickets/{id}/sources` - Get source citations
- [ ] `POST /api/ai-tickets/{id}/regenerate` - Regenerate draft
- [ ] Add request/response schemas
- [ ] Add authentication/authorization

#### 5.6 Add Tests for AI Service ⬜
**New File**: `backend/tests/test_ai_agent_service.py`
- [ ] Test knowledge base search
- [ ] Test ticket draft generation
- [ ] Test function calling
- [ ] Mock Azure OpenAI responses
- [ ] Test error handling

---

### **Phase 6: Email Integration** 📧

#### 6.1 Configure Azure Communication Services for Inbound Email ⬜
- [ ] Set up email domain with MX records
- [ ] Configure inbound email routing
- [ ] Test email receiving
- [ ] Document email address (e.g., `cases@yourdomain.com`)

#### 6.2 Create Email Processing Logic App ⬜
**New File**: `infra/bicep/modules/logic-app-inbound-email.bicep`
- [ ] Create Logic App with email trigger
- [ ] Parse email content (body, subject, sender)
- [ ] Extract attachments (if any)
- [ ] Call Azure Function for processing
- [ ] Handle errors and retries

#### 6.3 Create Email Processing Azure Function ⬜
**New File**: `backend/functions/process_inbound_email.py`
- [ ] Receive email content from Logic App
- [ ] Call AI agent service to generate draft
- [ ] Create ticket in database with `ai_draft` status
- [ ] Send confirmation email to customer
- [ ] Log processing results

#### 6.4 Update Container App Environment Variables ⬜
- [ ] Add email processing function URL
- [ ] Add shared secret for authentication
- [ ] Update Bicep deployment

#### 6.5 Test End-to-End Email Flow ⬜
- [ ] Send test email to configured address
- [ ] Verify Logic App triggers
- [ ] Check ticket created in database
- [ ] Verify AI draft generated
- [ ] Test customer confirmation email

---

### **Phase 7: Frontend Integration** 🔗

#### 7.1 Add API Service Methods ⬜
**File**: `frontend/src/services/api.js`
- [ ] `getAITickets()` - Fetch AI-drafted tickets
- [ ] `getTicketSources(ticketId)` - Get source citations
- [ ] `transitionTicketStage(ticketId, newStage)` - Move to next stage
- [ ] `approveDraft(ticketId, editedContent)` - Approve and send
- [ ] `rejectDraft(ticketId, reason)` - Reject draft
- [ ] `regenerateDraft(ticketId)` - Request new draft

#### 7.2 Update Dashboard to Fetch AI Tickets ⬜
**File**: `frontend/src/components/Dashboard.jsx`
- [ ] Update `useEffect` to fetch all ticket types
- [ ] Group tickets by stage
- [ ] Add filter for AI-generated tickets
- [ ] Update loading states

#### 7.3 Connect AI Ticket Modal to Backend ⬜
**File**: `frontend/src/components/AITicketModal.jsx`
- [ ] Fetch sources on modal open
- [ ] Handle draft approval (call API + move stage)
- [ ] Handle draft editing (save changes)
- [ ] Handle draft rejection (update status)
- [ ] Show loading/error states

#### 7.4 Add Notification System ⬜
**New File**: `frontend/src/components/Notification.jsx`
- [ ] Create toast notification component
- [ ] Show success message on draft approval
- [ ] Show error message on failures
- [ ] Auto-dismiss after 5 seconds

#### 7.5 Update Environment Variables ⬜
**File**: `.github/workflows/deploy-frontend.yml`
- [ ] Add `VITE_AI_FEATURES_ENABLED=true`
- [ ] Update Static Web App settings

---

### **Phase 8: Testing & Polish** ✨

#### 8.1 End-to-End Testing ⬜
- [ ] Test email-to-ticket flow with real emails
- [ ] Test all stage transitions manually
- [ ] Test AI draft approval and sending
- [ ] Test source citation display
- [ ] Test error scenarios (AI failure, email parsing errors)

#### 8.2 Performance Optimization ⬜
- [ ] Add caching for knowledge base searches
- [ ] Optimize AI Search queries
- [ ] Add request timeouts
- [ ] Test with high volume (100+ tickets)

#### 8.3 Monitoring & Logging ⬜
- [ ] Add Application Insights logging for AI calls
- [ ] Track token usage and costs
- [ ] Monitor AI Search query performance
- [ ] Set up alerts for failures

#### 8.4 Documentation ⬜
- [ ] Update `README.md` with AI features
- [ ] Create `docs/AI_AGENT_GUIDE.md` with usage instructions
- [ ] Document knowledge base maintenance process
- [ ] Add troubleshooting guide

#### 8.5 Security Review ⬜
- [ ] Validate managed identity permissions
- [ ] Review prompt injection risks
- [ ] Test input validation for emails
- [ ] Ensure customer data privacy

---

### **Phase 9: Deployment** 🚀

#### 9.1 Merge Feature Branch ⬜
- [ ] Create pull request from `feature/ai-agent-ticket-automation` to `main`
- [ ] Code review
- [ ] Run all tests
- [ ] Merge PR

#### 9.2 Deploy to Production ⬜
- [ ] Deploy infrastructure changes
- [ ] Deploy backend changes
- [ ] Deploy frontend changes
- [ ] Verify all services running

#### 9.3 Post-Deployment Validation ⬜
- [ ] Send test email and verify ticket creation
- [ ] Test UI in production
- [ ] Monitor logs for errors
- [ ] Gather initial user feedback

---

## 📊 Progress Tracking

**Overall Progress**: 1/73 tasks completed (1.4%)

### Phase Completion:
- **Phase 1 (UI/UX)**: 1/8 ✅⬜⬜⬜⬜⬜⬜⬜
- **Phase 2 (Knowledge Base)**: 0/3 ⬜
- **Phase 3 (Azure AI Infra)**: 0/4 ⬜
- **Phase 4 (AI Search Index)**: 0/3 ⬜
- **Phase 5 (AI Agent Service)**: 0/6 ⬜
- **Phase 6 (Email Integration)**: 0/5 ⬜
- **Phase 7 (Frontend Integration)**: 0/5 ⬜
- **Phase 8 (Testing & Polish)**: 0/5 ⬜
- **Phase 9 (Deployment)**: 0/3 ⬜

---

## 🎯 Current Focus

**Active Phase**: Phase 1 - UI/UX Overhaul  
**Current Task**: 1.2 - Update Kanban Board Component  
**Last Completed**: 1.1 - Update Ticket Status Model ✅

---

## 📝 Notes & Decisions

- **Language**: Documents will be in English initially, can add Norwegian later
- **Model**: Using GPT-4o (not fine-tuning initially)
- **Search**: Azure AI Search Basic tier ($75/month)
- **Email**: `cases@yourdomain.com` (configure your domain)
- **Cost Estimate**: ~$80-100/month additional for AI features

---

## 🔗 References

- [Azure OpenAI Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Azure AI Search RAG Pattern](https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview)
- [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling)
- [Azure Communication Services](https://learn.microsoft.com/en-us/azure/communication-services/concepts/email/email-overview)

---

**Last Updated**: November 3, 2025
