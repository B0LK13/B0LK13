# 🧪 Cloudflare Email Worker - Local Development Environment

This directory contains a complete local development environment for testing the Cloudflare Email Worker system before production deployment.

## 🎯 **What This Demonstrates**

- **Email Worker Logic**: Test email processing locally
- **CLI Tools**: Create and manage email configurations
- **Web Dashboard**: Monitor emails and configurations
- **Database Operations**: Simulate D1 database locally
- **Webhook Testing**: Test webhook endpoints
- **End-to-End Flow**: Complete email routing simulation

## 📁 **Local Development Structure**

```
local-dev/
├── README.md                    # This file
├── package.json                 # Local dev dependencies
├── server.js                    # Local development server
├── mock-worker.js               # Simulated Cloudflare Worker
├── mock-database.js             # In-memory database simulation
├── webhook-server.js            # Test webhook endpoints
├── test-data/                   # Sample configurations and emails
│   ├── sample-configs.json      # Pre-configured email addresses
│   ├── sample-emails.json       # Test email scenarios
│   └── mock-responses.json      # Expected responses
├── cli-local.js                 # Local CLI for testing
└── web-dashboard/               # Local web interface
    ├── index.html               # Dashboard UI
    ├── app.js                   # Dashboard logic
    └── styles.css               # Dashboard styling
```

## 🚀 **Quick Start**

### **1. Install Dependencies**
```bash
cd local-dev
npm install
```

### **2. Start Local Development Server**
```bash
npm run dev
```

This starts:
- **Mock Worker**: http://localhost:3001 (simulates Cloudflare Worker)
- **Web Dashboard**: http://localhost:3002 (email management interface)
- **Webhook Server**: http://localhost:3003 (test webhook endpoints)

### **3. Test CLI Tools**
```bash
# Create email configurations
npm run cli:create

# List configurations
npm run cli:list

# Test email processing
npm run cli:test
```

### **4. Test Email Scenarios**
```bash
# Test forwarding
npm run test:forward

# Test webhooks
npm run test:webhook

# Test storage
npm run test:store
```

## 🧪 **Testing Scenarios**

### **Pre-configured Test Emails**
- `support@bolk.dev` → Forward to admin@company.com
- `api@bolk.dev` → Webhook to http://localhost:3003/webhook
- `archive@bolk.dev` → Store in local database

### **Test Commands**
```bash
# Send test email to support
curl -X POST http://localhost:3001/test-email \
  -H "Content-Type: application/json" \
  -d '{"to": "support@bolk.dev", "from": "user@example.com", "subject": "Test Support Email"}'

# Check webhook logs
curl http://localhost:3003/logs

# View stored emails
curl http://localhost:3001/api/emails
```

## 📊 **Monitoring**

- **Worker Logs**: Console output from mock worker
- **Database State**: View at http://localhost:3001/debug
- **Webhook Activity**: View at http://localhost:3003/dashboard
- **Email Processing**: Real-time logs in terminal

## 🔧 **Configuration**

Edit `test-data/sample-configs.json` to modify email configurations:

```json
{
  "support@bolk.dev": {
    "action": "forward",
    "forwardTo": ["admin@company.com", "team@company.com"]
  },
  "api@bolk.dev": {
    "action": "webhook",
    "webhookUrl": "http://localhost:3003/webhook",
    "includeBody": true
  }
}
```

## 🎯 **What You'll See**

1. **Email Creation**: CLI creates configurations in local storage
2. **Email Processing**: Mock worker processes test emails
3. **Forwarding Simulation**: Logs show where emails would be forwarded
4. **Webhook Calls**: Real HTTP requests to local webhook server
5. **Database Storage**: Emails stored in local JSON database
6. **Web Dashboard**: Real-time view of all activity

## 🚀 **Next Steps**

Once local testing is complete:
1. Deploy to Cloudflare using the main worker files
2. Update configurations with real domains and webhooks
3. Enable Email Routing in Cloudflare Dashboard
4. Test with real email addresses

---

**This local environment proves the concept works end-to-end before production deployment!** 🎉
