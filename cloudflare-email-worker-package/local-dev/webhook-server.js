#!/usr/bin/env node

/**
 * Webhook Test Server
 * Simulates webhook endpoints for testing email worker
 */

import express from 'express';
import cors from 'cors';
import chalk from 'chalk';
import fs from 'fs/promises';

const app = express();
const PORT = 3003;

// Store webhook calls in memory for testing
let webhookCalls = [];
let notificationCalls = [];

// Middleware
app.use(cors());
app.use(express.json());

console.log(chalk.blue('🔗 Starting Webhook Test Server...'));

// Main webhook endpoint
app.post('/webhook', (req, res) => {
  const timestamp = new Date().toISOString();
  const call = {
    id: webhookCalls.length + 1,
    timestamp,
    headers: req.headers,
    body: req.body,
    endpoint: '/webhook'
  };
  
  webhookCalls.push(call);
  
  console.log(chalk.green('\n🔗 Webhook Called:'));
  console.log(chalk.gray(`  From: ${req.body.from}`));
  console.log(chalk.gray(`  To: ${req.body.to}`));
  console.log(chalk.gray(`  Subject: ${req.body.subject}`));
  console.log(chalk.gray(`  Timestamp: ${timestamp}`));
  
  if (req.body.body) {
    console.log(chalk.gray(`  Body: ${req.body.body.substring(0, 100)}...`));
  }
  
  // Simulate processing
  setTimeout(() => {
    console.log(chalk.cyan('  ✅ Webhook processed successfully'));
  }, 100);
  
  res.json({
    success: true,
    message: 'Webhook received and processed',
    id: call.id,
    timestamp
  });
});

// Notifications webhook endpoint
app.post('/notifications', (req, res) => {
  const timestamp = new Date().toISOString();
  const call = {
    id: notificationCalls.length + 1,
    timestamp,
    headers: req.headers,
    body: req.body,
    endpoint: '/notifications'
  };
  
  notificationCalls.push(call);
  
  console.log(chalk.yellow('\n🔔 Notification Webhook:'));
  console.log(chalk.gray(`  From: ${req.body.from}`));
  console.log(chalk.gray(`  Subject: ${req.body.subject}`));
  console.log(chalk.gray(`  Alert Level: ${req.body.headers?.['X-Alert-Level'] || 'Normal'}`));
  
  res.json({
    success: true,
    message: 'Notification received',
    id: call.id,
    timestamp
  });
});

// Get webhook logs
app.get('/logs', (req, res) => {
  res.json({
    webhooks: webhookCalls.slice(-20), // Last 20 calls
    notifications: notificationCalls.slice(-20),
    total: webhookCalls.length + notificationCalls.length
  });
});

// Get specific webhook call
app.get('/webhook/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const call = webhookCalls.find(c => c.id === id) || notificationCalls.find(c => c.id === id);
  
  if (call) {
    res.json(call);
  } else {
    res.status(404).json({ error: 'Webhook call not found' });
  }
});

// Webhook dashboard
app.get('/dashboard', (req, res) => {
  const html = `
<!DOCTYPE html>
<html>
<head>
    <title>Webhook Test Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; }
        .stats { display: flex; gap: 20px; margin: 20px 0; }
        .stat { flex: 1; text-align: center; padding: 20px; background: #e3f2fd; border-radius: 8px; }
        .stat h3 { margin: 0; color: #1976d2; }
        .stat p { margin: 5px 0 0 0; font-size: 24px; font-weight: bold; }
        .log { border-left: 4px solid #4caf50; padding: 10px; margin: 10px 0; background: #f9f9f9; }
        .log.notification { border-left-color: #ff9800; }
        .timestamp { color: #666; font-size: 12px; }
        .refresh { background: #2196f3; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
    </style>
    <script>
        function refreshData() {
            fetch('/logs')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('webhook-count').textContent = data.webhooks.length;
                    document.getElementById('notification-count').textContent = data.notifications.length;
                    document.getElementById('total-count').textContent = data.total;
                    
                    const logsDiv = document.getElementById('logs');
                    logsDiv.innerHTML = '';
                    
                    [...data.webhooks, ...data.notifications]
                        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
                        .slice(0, 10)
                        .forEach(call => {
                            const div = document.createElement('div');
                            div.className = 'log' + (call.endpoint === '/notifications' ? ' notification' : '');
                            div.innerHTML = \`
                                <strong>\${call.body.subject}</strong><br>
                                From: \${call.body.from} → To: \${call.body.to}<br>
                                Endpoint: \${call.endpoint}<br>
                                <span class="timestamp">\${new Date(call.timestamp).toLocaleString()}</span>
                            \`;
                            logsDiv.appendChild(div);
                        });
                });
        }
        
        setInterval(refreshData, 2000);
        window.onload = refreshData;
    </script>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1 class="header">🔗 Webhook Test Dashboard</h1>
            <p style="text-align: center; color: #666;">Real-time webhook monitoring for email worker testing</p>
        </div>
        
        <div class="stats">
            <div class="stat">
                <h3>Webhooks</h3>
                <p id="webhook-count">0</p>
            </div>
            <div class="stat">
                <h3>Notifications</h3>
                <p id="notification-count">0</p>
            </div>
            <div class="stat">
                <h3>Total Calls</h3>
                <p id="total-count">0</p>
            </div>
        </div>
        
        <div class="card">
            <h2>Recent Webhook Calls</h2>
            <button class="refresh" onclick="refreshData()">🔄 Refresh</button>
            <div id="logs"></div>
        </div>
    </div>
</body>
</html>`;
  
  res.send(html);
});

// Clear logs
app.delete('/logs', (req, res) => {
  webhookCalls = [];
  notificationCalls = [];
  console.log(chalk.yellow('🗑️  Cleared all webhook logs'));
  res.json({ success: true, message: 'Logs cleared' });
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Webhook Test Server',
    endpoints: ['/webhook', '/notifications'],
    totalCalls: webhookCalls.length + notificationCalls.length,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(chalk.green(`✅ Webhook Server running at http://localhost:${PORT}`));
  console.log(chalk.blue('📋 Available endpoints:'));
  console.log(chalk.gray('  POST /webhook - Main webhook endpoint'));
  console.log(chalk.gray('  POST /notifications - Notifications webhook'));
  console.log(chalk.gray('  GET  /logs - View webhook logs'));
  console.log(chalk.gray('  GET  /dashboard - Webhook dashboard'));
  console.log(chalk.gray('  GET  /health - Health check'));
  console.log(chalk.cyan('\n🌐 Open dashboard: http://localhost:3003/dashboard'));
});
