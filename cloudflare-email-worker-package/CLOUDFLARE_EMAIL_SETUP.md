# Cloudflare Email Worker Setup Guide

This guide will help you set up a custom Cloudflare Email Worker that allows users to create and manage email addresses from the terminal and web interface.

## 🚀 Features

- **Terminal CLI**: Create email addresses from command line
- **Web Interface**: Manage emails through Next.js dashboard
- **Multiple Actions**: Forward, webhook, or store emails
- **Real-time Logs**: Monitor email processing
- **Database Storage**: Track all email activity

## 📋 Prerequisites

1. **Cloudflare Account** with Email Routing enabled
2. **Domain** configured with Cloudflare
3. **Node.js** 18+ installed
4. **Wrangler CLI** installed globally

## 🛠️ Installation

### 1. Install Dependencies

```bash
npm install
```

### 2. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 3. Authenticate with Cloudflare

```bash
wrangler login
```

## ⚙️ Configuration

### 1. Update wrangler.toml

Edit `wrangler.toml` and replace the placeholder values:

```toml
# Replace with your actual values
[[email]]
destination_addresses = ["*@yourdomain.com"]

[[kv_namespaces]]
id = "your-kv-namespace-id"
preview_id = "your-preview-kv-namespace-id"

[[d1_databases]]
database_id = "your-d1-database-id"
```

### 2. Create Cloudflare Resources

#### Create KV Namespace
```bash
wrangler kv:namespace create "EMAIL_CONFIG"
wrangler kv:namespace create "EMAIL_CONFIG" --preview
```

#### Create D1 Database
```bash
wrangler d1 create email-routing-db
```

#### Run Database Migration
```bash
npm run db:migrate
```

### 3. Set Environment Variables

```bash
# Set API key for worker authentication
wrangler secret put API_KEY

# Set your Next.js app URL
wrangler secret put API_BASE_URL
```

### 4. Configure Email Routing

In Cloudflare Dashboard:
1. Go to Email → Email Routing
2. Enable Email Routing for your domain
3. Add catch-all route pointing to your worker

## 🚀 Deployment

### 1. Deploy the Worker

```bash
npm run worker:deploy
```

### 2. Test the Worker

```bash
npm run worker:dev
```

### 3. Deploy Next.js App

Deploy your Next.js app to Vercel, Netlify, or your preferred platform.

## 📱 Usage

### Terminal CLI

#### Setup CLI
```bash
npm run email:setup
# Follow prompts to enter worker URL and API key
```

#### Create Email Address
```bash
# Interactive mode
npm run email:create

# Direct command
npm run email create --email user@yourdomain.com --action forward --forward recipient@example.com
```

#### List Email Addresses
```bash
npm run email:list
```

#### View Email Logs
```bash
npm run email:logs
```

#### Delete Email Address
```bash
npm run email delete user@yourdomain.com
```

### Web Interface

1. Navigate to `/cloudflare-email` in your Next.js app
2. Use the web interface to:
   - Create new email addresses
   - Manage existing configurations
   - View email logs
   - Monitor statistics

## 📧 Email Actions

### 1. Forward
Forwards incoming emails to specified addresses.

```bash
npm run email create --email support@yourdomain.com --action forward --forward admin@company.com,team@company.com
```

### 2. Webhook
Sends email data to a webhook URL.

```bash
npm run email create --email api@yourdomain.com --action webhook --webhook https://your-app.com/webhook/email
```

### 3. Store
Stores emails in the database for later retrieval.

```bash
npm run email create --email archive@yourdomain.com --action store
```

## 🔧 API Endpoints

### Worker API

- `GET /api/emails` - Get email logs
- `GET /api/config` - Get email configurations
- `POST /api/config` - Create email configuration
- `DELETE /api/config/{email}` - Delete email configuration

### Next.js API

- `GET /api/cloudflare/emails` - Get configurations or logs
- `POST /api/cloudflare/emails` - Create email configuration
- `DELETE /api/cloudflare/emails?email={email}` - Delete configuration

## 📊 Database Schema

The system uses Cloudflare D1 with the following tables:

- `email_logs` - All incoming email logs
- `stored_emails` - Complete email content (when action is 'store')
- `email_routes` - Email routing configurations (backup)
- `webhook_logs` - Webhook delivery logs
- `forward_logs` - Email forwarding logs

## 🔒 Security

- API key authentication for all worker endpoints
- Input validation for email addresses and URLs
- Rate limiting (configure in worker if needed)
- CORS headers for web interface

## 🐛 Troubleshooting

### Common Issues

1. **Worker not receiving emails**
   - Check Email Routing configuration in Cloudflare Dashboard
   - Verify catch-all route points to your worker
   - Check worker logs: `wrangler tail`

2. **CLI setup fails**
   - Ensure worker is deployed and accessible
   - Verify API key is set correctly
   - Check worker URL format

3. **Database errors**
   - Run migration: `npm run db:migrate`
   - Check D1 database configuration in wrangler.toml

### Debug Commands

```bash
# View worker logs
wrangler tail

# Test worker locally
npm run worker:dev

# Check CLI configuration
cat ~/.cloudflare-email-cli.json
```

## 📝 Environment Variables

### Worker Environment Variables
- `API_KEY` - Authentication key for API access
- `API_BASE_URL` - Your Next.js application URL
- `ENVIRONMENT` - deployment environment

### Next.js Environment Variables
- `CLOUDFLARE_WORKER_URL` - URL of your deployed worker
- `CLOUDFLARE_API_KEY` - API key for worker access

## 🔄 Updates

To update the worker:

```bash
# Pull latest changes
git pull

# Deploy updated worker
npm run worker:deploy

# Update CLI if needed
npm run email:setup
```

## 📚 Additional Resources

- [Cloudflare Email Routing Docs](https://developers.cloudflare.com/email-routing/)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler/)

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Cloudflare Workers logs
3. Verify all configuration steps
4. Check API endpoints are accessible
