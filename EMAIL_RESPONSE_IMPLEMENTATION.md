# Email Response System Implementation Summary

## ✅ Complete Azure Communication Services Integration

### 🏗️ Infrastructure (Bicep)

**New Module: `communication-services.bicep`**
- Creates Email Communication Service in West Europe
- Configures Azure Managed Domain (free subdomain: `DoNotReply@<uuid>.azurecomm.net`)
- Provisions Communication Services resource linked to email domain
- Outputs connection string and sender email for backend use

**Updated: `main.bicep`**
- Adds ACS module deployment
- Passes ACS connection string to Container App as secret
- Exposes sender email and company name as environment variables
- Cost: **$0.00025 per email** (extremely affordable)

**Updated: `app.bicep`**
- Adds secrets for `database-url` and `acs-connection-string`
- Environment variables: `ACS_CONNECTION_STRING`, `ACS_SENDER_EMAIL`, `COMPANY_NAME`, `DATABASE_URL`

---

### 🗄️ Database (PostgreSQL)

**New Table: `ticket_responses`**
```sql
- id (primary key)
- ticket_id (foreign key → tickets.id)
- subject (email subject line)
- response_text (message content)
- sent_to (customer email)
- sent_by (employee name/id)
- created_at (when response was created)
- sent_at (when email was successfully sent)
- email_status (pending/sent/failed/delivered)
- error_message (error details if failed)
- message_id (ACS tracking ID)
```

**Updated: `Ticket` model**
- Added `responses` relationship (one-to-many)
- Cascade delete: deleting ticket deletes all responses

**New: `EmailStatus` enum**
- `PENDING` - Response created, email not sent yet
- `SENT` - Email successfully sent via ACS
- `FAILED` - Email sending failed (error saved)
- `DELIVERED` - Confirmed delivery (future enhancement)

---

### 🔧 Backend (FastAPI)

**New: `config.py`**
- Centralized configuration using Pydantic Settings
- Loads from environment variables or .env file
- Settings: `DATABASE_URL`, `ACS_CONNECTION_STRING`, `ACS_SENDER_EMAIL`, `COMPANY_NAME`

**New: `email_service.py`** (250+ lines)
- `EmailService` class for ACS integration
- `send_ticket_response()` - Main email sending function
- Professional HTML email template with:
  - Gradient header with company branding
  - Case details box (ticket ID and title)
  - Response content in styled container
  - Employee signature
  - Footer with disclaimer
- Plain text fallback for non-HTML clients
- Comprehensive error handling and logging
- Email status tracking and ACS message ID capture

**New: `routes/email.py`**
- **POST /api/tickets/{id}/respond** - Send email response
  - Validates ticket exists
  - Creates TicketResponse record (pending state)
  - Sends email via ACS
  - Updates record with sent status or error
  - Updates ticket's `first_response_at` timestamp
  - Calculates response time in minutes
  - Returns response record with status
  
- **GET /api/tickets/{id}/responses** - Get response history
  - Returns all responses for a ticket
  - Ordered by newest first
  - Includes email status and error messages

**Updated: `requirements.txt`**
- Added `azure-communication-email==1.0.0`

**Updated: `main.py`**
- Imports email routes module
- Includes email router: `/api/tickets/{id}/respond`
- Tags: ["email"]

---

### 🎨 Frontend (React)

**Updated: `api.js`**
- **sendResponse(ticketId, responseData)** - Send email via backend
  - POST request to `/api/tickets/{id}/respond`
  - Passes: response text, customer email/name, ticket title, sent_by
  - Returns response record with email status
  
- **getTicketResponses(ticketId)** - Fetch response history
  - GET request to `/api/tickets/{id}/responses`
  - Returns array of all responses

**Updated: `Dashboard.jsx`**
- Replaced TODO simulation with real API call
- `handleRespond()` now calls `sendResponse()`
- Reloads tickets after sending to update timestamps
- Proper error handling and re-throws for TicketCard

**Existing: `TicketCard.jsx`**
- Already has full UI for sending responses:
  - Customer info display (name, email, phone)
  - Response textarea
  - "Send Email Response" button
  - Loading state during send
  - Success/error alerts
- Calls `onRespond` callback which flows to Dashboard → API

---

## 📧 Email Template Features

### Subject Line
```
Wrangler Tax Services - Response to: [Ticket Title]
```

### HTML Email Includes:
- **Professional gradient header** with company name
- **Case details box** with ticket ID and title
- **Response section** with clean styling
- **Employee signature** (if provided)
- **Footer disclaimer** about automated messages

### Plain Text Version
- All same content in readable text format
- Works with email clients that don't support HTML

---

## 🚀 Deployment Steps

### 1. Deploy Infrastructure (GitHub Actions)
```bash
# Push to trigger workflow
git push origin main

# Or manually deploy via CLI
az deployment group create \
  --resource-group rg-casemanagement-dev \
  --template-file infra/bicep/main.bicep \
  --parameters postgresqlAdminPassword="YourSecurePassword123!"
```

This will:
- Create Azure Communication Services
- Create Email Service with managed domain
- Configure Container App with ACS credentials
- Output sender email address (like `DoNotReply@abc123.azurecomm.net`)

### 2. Database Migration (Automatic)
- Backend will auto-create `ticket_responses` table on startup
- SQLAlchemy handles schema updates via `Base.metadata.create_all()`

### 3. Verify Deployment
```bash
# Check if ACS is configured
curl https://ca-api-casemanagement-dev.agreeablesmoke-8b3eacca.norwayeast.azurecontainerapps.io/health

# Test email endpoint (will need valid ticket ID)
curl -X POST https://ca-api-casemanagement-dev.agreeablesmoke-8b3eacca.norwayeast.azurecontainerapps.io/api/tickets/1/respond \
  -H "Content-Type: application/json" \
  -d '{
    "response": "Thank you for contacting us...",
    "customer_email": "customer@example.com",
    "customer_name": "John Doe",
    "ticket_title": "Tax Question",
    "sent_by": "Sarah Johnson"
  }'
```

---

## 💰 Cost Analysis

### Azure Communication Services Email
- **$0.00025 per email** (25 cents per 1,000 emails)
- **Example costs:**
  - 100 emails/month: $0.025 (~2.5 cents)
  - 1,000 emails/month: $0.25 (25 cents)
  - 10,000 emails/month: $2.50

### Total Monthly Cost (with existing infrastructure)
- Static Web App: **Free tier**
- Container App: **~$23/month** (0.25 CPU, 0.5Gi RAM)
- PostgreSQL: **~$25/month** (B1ms tier)
- Communication Services: **~$0.25-$5/month** (depending on volume)
- **Total: ~$48-53/month**

---

## 🔐 Security Features

### Secrets Management
- ACS connection string stored as Container App secret
- Database URL stored as Container App secret
- Not exposed in logs or environment variable listings

### Email Domain
- Uses Azure Managed Domain (Microsoft handles DNS, SPF, DKIM)
- Cannot be spoofed or used for phishing
- Domain format: `DoNotReply@<uuid>.azurecomm.net`

### Data Privacy
- Communication Services data location: **Norway** (GDPR compliant)
- User engagement tracking: **Disabled** (privacy-friendly)

---

## 📊 Audit Trail

### Every email response is tracked:
- Who sent it (`sent_by`)
- When it was sent (`sent_at`)
- Email delivery status (`email_status`)
- ACS message ID for tracking
- Error messages if sending failed
- Complete message content

### Query response history:
```python
# Get all responses for a ticket
responses = db.query(TicketResponse).filter(
    TicketResponse.ticket_id == ticket_id
).all()
```

---

## 🎯 How It Works (End-to-End Flow)

1. **Customer submits case** via landing page
   - Case stored in PostgreSQL with customer email

2. **Employee opens case** in dashboard
   - Sees customer info (name, email, phone)
   - Clicks to expand ticket card

3. **Employee writes response**
   - Types message in textarea
   - Clicks "Send Email Response"

4. **Frontend calls API**
   - POST to `/api/tickets/{id}/respond`
   - Sends response text, customer details, employee name

5. **Backend creates response record**
   - Saves to `ticket_responses` table
   - Status: `PENDING`

6. **Backend sends email via ACS**
   - Builds professional HTML email
   - Calls Azure Communication Services API
   - Gets message ID if successful

7. **Backend updates records**
   - Status changes to `SENT` or `FAILED`
   - Saves ACS message ID
   - Updates ticket's `first_response_at` timestamp
   - Calculates response time

8. **Frontend shows success**
   - Alert: "Response sent successfully!"
   - Clears textarea
   - Reloads ticket with updated timestamp

9. **Customer receives email**
   - Professional branded email
   - Can see case details and response
   - Cannot reply (DoNotReply address)

---

## 🧪 Testing Locally (Before Deployment)

### 1. Set environment variables:
```bash
# backend/.env
DATABASE_URL=postgresql://caseadmin:password@localhost:5432/casemanagement
ACS_CONNECTION_STRING=endpoint=https://...;accesskey=...
ACS_SENDER_EMAIL=DoNotReply@abc123.azurecomm.net
COMPANY_NAME=Wrangler Tax Services
```

### 2. Install dependencies:
```bash
cd backend
pip install -r requirements.txt
```

### 3. Run backend:
```bash
cd backend
uvicorn app.main:app --reload
```

### 4. Test with Swagger UI:
- Go to http://localhost:8000/docs
- Find POST /api/tickets/{ticket_id}/respond
- Try sending a test email

### 5. Check logs:
```bash
# Look for email service logs
# ✅ Email sent successfully: ...
# ❌ Failed to send email: ...
```

---

## 🐛 Troubleshooting

### Email not sending?
1. Check ACS connection string is configured
2. Verify sender email format (must be from managed domain)
3. Check Container App logs for errors
4. Verify customer email is valid

### Database errors?
1. Run migrations: `Base.metadata.create_all(bind=engine)`
2. Check PostgreSQL connection string
3. Verify ticket exists before sending response

### Frontend not calling API?
1. Check VITE_API_URL environment variable
2. Verify CORS is configured for Static Web App URL
3. Check browser console for errors

---

## 📝 Next Steps / Future Enhancements

### Short Term:
- [ ] Add employee authentication (identify who sent response)
- [ ] Add response templates for common questions
- [ ] Show response history in ticket details
- [ ] Add "Reply" functionality (customers can respond)

### Medium Term:
- [ ] Email delivery confirmation (track "delivered" status)
- [ ] Rich text editor for formatted responses
- [ ] File attachments support
- [ ] Automated response suggestions using AI

### Long Term:
- [ ] Custom email domain (instead of azurecomm.net)
- [ ] Two-way email (receive customer replies)
- [ ] SMS notifications via ACS
- [ ] Email analytics dashboard

---

## ✅ Summary

**What was implemented:**
1. ✅ Azure Communication Services infrastructure (Bicep)
2. ✅ TicketResponse database table for audit trail
3. ✅ Email service with professional HTML templates
4. ✅ API endpoints for sending and retrieving responses
5. ✅ Frontend integration with real backend API
6. ✅ Configuration management for secrets
7. ✅ Error handling and status tracking
8. ✅ First response time calculation

**Ready to deploy:** Yes! Push to GitHub and workflow will deploy everything.

**Cost:** ~$48-53/month total (email adds <$5/month)

**User experience:** Employees can respond to customers via email with professional branding, all tracked in database.
