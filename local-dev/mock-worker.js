#!/usr/bin/env node

/**
 * Mock Cloudflare Email Worker for Local Development
 * Simulates the email processing logic locally
 */

import express from 'express';
import cors from 'cors';
import chalk from 'chalk';
import { MockDatabase } from './mock-database.js';
import fs from 'fs/promises';
import fetch from 'node-fetch';

const app = express();
const PORT = 3001;
const db = new MockDatabase();

// Middleware
app.use(cors());
app.use(express.json());

// Mock environment variables
const mockEnv = {
  API_KEY: 'local-dev-api-key-123',
  API_BASE_URL: 'http://localhost:3002'
};

console.log(chalk.blue('🚀 Starting Mock Cloudflare Email Worker...'));

// Load sample configurations
async function loadSampleConfigs() {
  try {
    const configData = await fs.readFile('./test-data/sample-configs.json', 'utf8');
    const configs = JSON.parse(configData);
    
    for (const [email, config] of Object.entries(configs)) {
      await db.setEmailConfig(email, config);
    }
    
    console.log(chalk.green('✅ Loaded sample email configurations'));
  } catch (error) {
    console.log(chalk.yellow('⚠️  No sample configs found, starting with empty database'));
  }
}

// Simulate email processing
async function processEmail(emailData) {
  const { to, from, subject, body = '', headers = {} } = emailData;
  
  console.log(chalk.cyan('\n📧 Processing Email:'));
  console.log(chalk.gray(`  From: ${from}`));
  console.log(chalk.gray(`  To: ${to}`));
  console.log(chalk.gray(`  Subject: ${subject}`));
  
  // Get email configuration
  const config = await db.getEmailConfig(to);
  
  if (!config) {
    console.log(chalk.red(`❌ No configuration found for: ${to}`));
    return { success: false, error: 'Email address not configured' };
  }
  
  // Log email
  await db.logEmail({
    messageId: `mock-${Date.now()}`,
    from,
    to,
    subject,
    receivedAt: new Date().toISOString(),
    size: body.length,
    headers: JSON.stringify(headers),
    status: 'received'
  });
  
  // Process based on action
  let result;
  switch (config.action) {
    case 'forward':
      result = await simulateForward(emailData, config);
      break;
    case 'webhook':
      result = await simulateWebhook(emailData, config);
      break;
    case 'store':
      result = await simulateStore(emailData, config);
      break;
    default:
      result = { success: false, error: 'Unknown action' };
  }
  
  // Update email status
  await db.updateEmailStatus(to, result.success ? 'processed' : 'failed');
  
  return result;
}

// Simulate email forwarding
async function simulateForward(emailData, config) {
  const { forwardTo = [] } = config;
  
  console.log(chalk.green('📤 Simulating Forward:'));
  for (const address of forwardTo) {
    console.log(chalk.gray(`  → Forwarding to: ${address}`));
    
    // Log forward action
    await db.logForward({
      emailLogId: Date.now(),
      forwardTo: address,
      status: 'sent',
      sentAt: new Date().toISOString()
    });
  }
  
  return { success: true, action: 'forward', forwardedTo: forwardTo };
}

// Simulate webhook call
async function simulateWebhook(emailData, config) {
  const { webhookUrl, includeBody = false } = config;
  
  console.log(chalk.green('🔗 Calling Webhook:'));
  console.log(chalk.gray(`  URL: ${webhookUrl}`));
  
  const payload = {
    from: emailData.from,
    to: emailData.to,
    subject: emailData.subject,
    timestamp: new Date().toISOString(),
    messageId: `mock-${Date.now()}`,
    headers: emailData.headers || {}
  };
  
  if (includeBody) {
    payload.body = emailData.body || '';
  }
  
  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mock-Cloudflare-Email-Worker/1.0'
      },
      body: JSON.stringify(payload)
    });
    
    const success = response.ok;
    console.log(chalk.gray(`  Response: ${response.status} ${response.statusText}`));
    
    // Log webhook call
    await db.logWebhook({
      emailLogId: Date.now(),
      webhookUrl,
      payload: JSON.stringify(payload),
      responseStatus: response.status,
      responseBody: await response.text(),
      deliveredAt: new Date().toISOString()
    });
    
    return { success, action: 'webhook', webhookUrl, status: response.status };
  } catch (error) {
    console.log(chalk.red(`  Error: ${error.message}`));
    return { success: false, action: 'webhook', error: error.message };
  }
}

// Simulate email storage
async function simulateStore(emailData, config) {
  console.log(chalk.green('📦 Storing Email:'));
  console.log(chalk.gray(`  Storing in local database`));
  
  await db.storeEmail({
    messageId: `mock-${Date.now()}`,
    from: emailData.from,
    to: emailData.to,
    subject: emailData.subject,
    rawContent: JSON.stringify(emailData),
    receivedAt: new Date().toISOString(),
    configId: config.id || null
  });
  
  return { success: true, action: 'store' };
}

// API Routes

// Test email endpoint
app.post('/test-email', async (req, res) => {
  try {
    const result = await processEmail(req.body);
    res.json(result);
  } catch (error) {
    console.error(chalk.red('Error processing email:', error));
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get email configurations
app.get('/api/config', async (req, res) => {
  try {
    const configs = await db.getAllConfigs();
    res.json({ success: true, configs });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create email configuration
app.post('/api/config', async (req, res) => {
  try {
    const { email, action, ...config } = req.body;
    
    if (!email || !action) {
      return res.status(400).json({
        success: false,
        error: 'Email and action are required'
      });
    }
    
    const configData = {
      action,
      ...config,
      createdAt: new Date().toISOString(),
      id: `mock-${Date.now()}`
    };
    
    await db.setEmailConfig(email, configData);
    
    console.log(chalk.green(`✅ Created configuration for: ${email}`));
    res.json({ success: true, message: 'Configuration created', config: configData });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete email configuration
app.delete('/api/config/:email', async (req, res) => {
  try {
    const email = decodeURIComponent(req.params.email);
    await db.deleteEmailConfig(email);
    
    console.log(chalk.yellow(`🗑️  Deleted configuration for: ${email}`));
    res.json({ success: true, message: 'Configuration deleted' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get email logs
app.get('/api/emails', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const logs = await db.getEmailLogs(limit);
    res.json({ success: true, emails: logs });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Debug endpoint
app.get('/debug', async (req, res) => {
  try {
    const state = await db.getDebugState();
    res.json(state);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'Mock Cloudflare Email Worker',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, async () => {
  await loadSampleConfigs();
  console.log(chalk.green(`✅ Mock Worker running at http://localhost:${PORT}`));
  console.log(chalk.blue('📋 Available endpoints:'));
  console.log(chalk.gray('  POST /test-email - Send test email'));
  console.log(chalk.gray('  GET  /api/config - List configurations'));
  console.log(chalk.gray('  POST /api/config - Create configuration'));
  console.log(chalk.gray('  GET  /api/emails - View email logs'));
  console.log(chalk.gray('  GET  /debug - Debug database state'));
  console.log(chalk.gray('  GET  /health - Health check'));
});
