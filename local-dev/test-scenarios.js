#!/usr/bin/env node

/**
 * Test Scenarios Runner
 * Automated testing of email worker functionality
 */

import chalk from 'chalk';
import fetch from 'node-fetch';
import fs from 'fs/promises';

const WORKER_URL = 'http://localhost:3001';
const WEBHOOK_URL = 'http://localhost:3003';

class TestRunner {
  constructor() {
    this.results = [];
  }

  async runTest(name, testFn) {
    console.log(chalk.blue(`\n🧪 Running: ${name}`));
    try {
      const result = await testFn();
      this.results.push({ name, status: 'PASS', result });
      console.log(chalk.green(`✅ PASS: ${name}`));
      return result;
    } catch (error) {
      this.results.push({ name, status: 'FAIL', error: error.message });
      console.log(chalk.red(`❌ FAIL: ${name} - ${error.message}`));
      throw error;
    }
  }

  async loadSampleEmails() {
    try {
      const data = await fs.readFile('./test-data/sample-emails.json', 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.log(chalk.yellow('⚠️  No sample emails found, using defaults'));
      return [
        {
          name: "Test Support Email",
          from: "test@example.com",
          to: "support@bolk.dev",
          subject: "Test support request",
          body: "This is a test support email."
        }
      ];
    }
  }

  async testForwarding() {
    const emails = await this.loadSampleEmails();
    const supportEmail = emails.find(e => e.to === 'support@bolk.dev') || emails[0];
    
    const response = await fetch(`${WORKER_URL}/test-email`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(supportEmail)
    });

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(`Email processing failed: ${result.error}`);
    }

    if (result.action !== 'forward') {
      throw new Error(`Expected forward action, got: ${result.action}`);
    }

    console.log(chalk.gray(`  → Forwarded to: ${result.forwardedTo?.join(', ')}`));
    return result;
  }

  async testWebhook() {
    const emails = await this.loadSampleEmails();
    const apiEmail = emails.find(e => e.to === 'api@bolk.dev') || {
      ...emails[0],
      to: 'api@bolk.dev'
    };

    // Clear webhook logs first
    await fetch(`${WEBHOOK_URL}/logs`, { method: 'DELETE' });

    const response = await fetch(`${WORKER_URL}/test-email`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(apiEmail)
    });

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(`Email processing failed: ${result.error}`);
    }

    if (result.action !== 'webhook') {
      throw new Error(`Expected webhook action, got: ${result.action}`);
    }

    // Verify webhook was called
    await new Promise(resolve => setTimeout(resolve, 500)); // Wait for webhook
    
    const webhookResponse = await fetch(`${WEBHOOK_URL}/logs`);
    const webhookLogs = await webhookResponse.json();
    
    if (webhookLogs.webhooks.length === 0) {
      throw new Error('Webhook was not called');
    }

    console.log(chalk.gray(`  → Webhook called: ${result.webhookUrl}`));
    console.log(chalk.gray(`  → Status: ${result.status}`));
    return result;
  }

  async testStorage() {
    const emails = await this.loadSampleEmails();
    const archiveEmail = emails.find(e => e.to === 'archive@bolk.dev') || {
      ...emails[0],
      to: 'archive@bolk.dev'
    };

    const response = await fetch(`${WORKER_URL}/test-email`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(archiveEmail)
    });

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(`Email processing failed: ${result.error}`);
    }

    if (result.action !== 'store') {
      throw new Error(`Expected store action, got: ${result.action}`);
    }

    console.log(chalk.gray(`  → Email stored in database`));
    return result;
  }

  async testMultipleEmails() {
    const emails = await this.loadSampleEmails();
    const results = [];

    for (const email of emails.slice(0, 3)) {
      const response = await fetch(`${WORKER_URL}/test-email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(email)
      });

      const result = await response.json();
      results.push(result);
      
      console.log(chalk.gray(`  → Processed: ${email.to} (${result.action})`));
      
      // Small delay between emails
      await new Promise(resolve => setTimeout(resolve, 200));
    }

    return results;
  }

  async testApiEndpoints() {
    const endpoints = [
      { path: '/api/config', method: 'GET', name: 'List configurations' },
      { path: '/api/emails', method: 'GET', name: 'List email logs' },
      { path: '/debug', method: 'GET', name: 'Debug information' },
      { path: '/health', method: 'GET', name: 'Health check' }
    ];

    const results = [];

    for (const endpoint of endpoints) {
      const response = await fetch(`${WORKER_URL}${endpoint.path}`, {
        method: endpoint.method
      });

      if (!response.ok) {
        throw new Error(`${endpoint.name} failed: ${response.status}`);
      }

      const data = await response.json();
      results.push({ endpoint: endpoint.path, data });
      
      console.log(chalk.gray(`  → ${endpoint.name}: OK`));
    }

    return results;
  }

  async testWebhookEndpoints() {
    const response = await fetch(`${WEBHOOK_URL}/health`);
    
    if (!response.ok) {
      throw new Error(`Webhook server health check failed: ${response.status}`);
    }

    const health = await response.json();
    console.log(chalk.gray(`  → Webhook server: ${health.status}`));
    console.log(chalk.gray(`  → Total calls: ${health.totalCalls}`));
    
    return health;
  }

  printSummary() {
    console.log(chalk.blue('\n📊 Test Summary:'));
    console.log(chalk.blue('═'.repeat(50)));
    
    const passed = this.results.filter(r => r.status === 'PASS').length;
    const failed = this.results.filter(r => r.status === 'FAIL').length;
    
    console.log(chalk.green(`✅ Passed: ${passed}`));
    console.log(chalk.red(`❌ Failed: ${failed}`));
    console.log(chalk.blue(`📋 Total: ${this.results.length}`));
    
    if (failed > 0) {
      console.log(chalk.red('\n❌ Failed Tests:'));
      this.results
        .filter(r => r.status === 'FAIL')
        .forEach(r => console.log(chalk.red(`  • ${r.name}: ${r.error}`)));
    }
    
    console.log(chalk.blue('\n' + '═'.repeat(50)));
    
    if (failed === 0) {
      console.log(chalk.green('🎉 All tests passed! System is working correctly.'));
    } else {
      console.log(chalk.yellow('⚠️  Some tests failed. Check the errors above.'));
    }
  }
}

// Main execution
async function main() {
  const scenario = process.argv[2] || 'all';
  const runner = new TestRunner();

  console.log(chalk.blue('🚀 Starting Email Worker Test Scenarios'));
  console.log(chalk.gray(`Scenario: ${scenario}`));

  try {
    switch (scenario) {
      case 'forward':
        await runner.runTest('Email Forwarding', () => runner.testForwarding());
        break;
        
      case 'webhook':
        await runner.runTest('Webhook Processing', () => runner.testWebhook());
        break;
        
      case 'store':
        await runner.runTest('Email Storage', () => runner.testStorage());
        break;
        
      case 'all':
      default:
        await runner.runTest('API Endpoints', () => runner.testApiEndpoints());
        await runner.runTest('Webhook Server', () => runner.testWebhookEndpoints());
        await runner.runTest('Email Forwarding', () => runner.testForwarding());
        await runner.runTest('Webhook Processing', () => runner.testWebhook());
        await runner.runTest('Email Storage', () => runner.testStorage());
        await runner.runTest('Multiple Emails', () => runner.testMultipleEmails());
        break;
    }
  } catch (error) {
    // Error already logged by runTest
  }

  runner.printSummary();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { TestRunner };
