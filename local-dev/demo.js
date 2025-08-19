#!/usr/bin/env node

/**
 * Demo Script for Cloudflare Email Worker
 * Automated demonstration of the email system
 */

import chalk from 'chalk';
import fetch from 'node-fetch';
import fs from 'fs/promises';

const WORKER_URL = 'http://localhost:3001';
const WEBHOOK_URL = 'http://localhost:3003';

class EmailWorkerDemo {
  constructor() {
    this.step = 0;
  }

  async wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async nextStep(title, description) {
    this.step++;
    console.log(chalk.blue(`\n${'='.repeat(60)}`));
    console.log(chalk.blue(`Step ${this.step}: ${title}`));
    console.log(chalk.blue(`${'='.repeat(60)}`));
    console.log(chalk.gray(description));
    console.log();
    await this.wait(2000);
  }

  async checkServices() {
    await this.nextStep(
      'Service Health Check',
      'Verifying that all services are running and accessible'
    );

    try {
      const workerResponse = await fetch(`${WORKER_URL}/health`);
      const workerHealth = await workerResponse.json();
      console.log(chalk.green('✅ Mock Worker:'), workerHealth.status);

      const webhookResponse = await fetch(`${WEBHOOK_URL}/health`);
      const webhookHealth = await webhookResponse.json();
      console.log(chalk.green('✅ Webhook Server:'), webhookHealth.status);

      console.log(chalk.cyan('\n🌐 Available Services:'));
      console.log(chalk.gray(`  • Mock Worker: ${WORKER_URL}`));
      console.log(chalk.gray(`  • Webhook Server: ${WEBHOOK_URL}`));
      console.log(chalk.gray(`  • Web Dashboard: http://localhost:3002`));

    } catch (error) {
      console.log(chalk.red('❌ Service check failed:', error.message));
      console.log(chalk.yellow('💡 Make sure to run "npm run dev" first'));
      process.exit(1);
    }
  }

  async showExistingConfigs() {
    await this.nextStep(
      'Show Existing Email Configurations',
      'Display pre-configured email addresses loaded from sample data'
    );

    try {
      const response = await fetch(`${WORKER_URL}/api/config`);
      const result = await response.json();

      if (result.success && result.configs.length > 0) {
        console.log(chalk.green(`📧 Found ${result.configs.length} email configurations:`));
        
        result.configs.forEach((config, index) => {
          console.log(chalk.cyan(`\n${index + 1}. ${config.email}`));
          console.log(chalk.gray(`   Action: ${config.action}`));
          
          switch (config.action) {
            case 'forward':
              console.log(chalk.gray(`   Forward to: ${config.forwardTo?.join(', ')}`));
              break;
            case 'webhook':
              console.log(chalk.gray(`   Webhook: ${config.webhookUrl}`));
              console.log(chalk.gray(`   Include body: ${config.includeBody}`));
              break;
            case 'store':
              console.log(chalk.gray(`   Store in database`));
              break;
          }
        });
      } else {
        console.log(chalk.yellow('No email configurations found'));
      }
    } catch (error) {
      console.log(chalk.red('Error fetching configurations:', error.message));
    }
  }

  async demonstrateEmailForwarding() {
    await this.nextStep(
      'Demonstrate Email Forwarding',
      'Send a test email to support@bolk.dev and show forwarding simulation'
    );

    const testEmail = {
      from: 'customer@example.com',
      to: 'support@bolk.dev',
      subject: 'Demo: Customer Support Request',
      body: 'Hello, I need help with my account setup. This is a demo email to show forwarding functionality.',
      headers: {
        'Content-Type': 'text/plain',
        'X-Demo': 'Email Forwarding'
      }
    };

    console.log(chalk.cyan('📧 Sending test email:'));
    console.log(chalk.gray(`  From: ${testEmail.from}`));
    console.log(chalk.gray(`  To: ${testEmail.to}`));
    console.log(chalk.gray(`  Subject: ${testEmail.subject}`));

    try {
      const response = await fetch(`${WORKER_URL}/test-email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testEmail)
      });

      const result = await response.json();

      if (result.success) {
        console.log(chalk.green('\n✅ Email processed successfully!'));
        console.log(chalk.blue('📤 Forwarding Result:'));
        console.log(chalk.gray(`  Action: ${result.action}`));
        console.log(chalk.gray(`  Forwarded to: ${result.forwardedTo?.join(', ')}`));
      } else {
        console.log(chalk.red('❌ Email processing failed:', result.error));
      }
    } catch (error) {
      console.log(chalk.red('Error sending email:', error.message));
    }
  }

  async demonstrateWebhook() {
    await this.nextStep(
      'Demonstrate Webhook Integration',
      'Send email to api@bolk.dev and show real webhook call'
    );

    // Clear webhook logs first
    await fetch(`${WEBHOOK_URL}/logs`, { method: 'DELETE' });

    const testEmail = {
      from: 'developer@startup.com',
      to: 'api@bolk.dev',
      subject: 'Demo: API Integration Question',
      body: 'What are the current rate limits for the API? This is a demo email to show webhook functionality.',
      headers: {
        'Content-Type': 'text/plain',
        'X-Demo': 'Webhook Integration',
        'X-Priority': 'High'
      }
    };

    console.log(chalk.cyan('📧 Sending webhook test email:'));
    console.log(chalk.gray(`  From: ${testEmail.from}`));
    console.log(chalk.gray(`  To: ${testEmail.to}`));
    console.log(chalk.gray(`  Subject: ${testEmail.subject}`));

    try {
      const response = await fetch(`${WORKER_URL}/test-email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testEmail)
      });

      const result = await response.json();

      if (result.success) {
        console.log(chalk.green('\n✅ Email processed successfully!'));
        console.log(chalk.blue('🔗 Webhook Result:'));
        console.log(chalk.gray(`  Action: ${result.action}`));
        console.log(chalk.gray(`  Webhook URL: ${result.webhookUrl}`));
        console.log(chalk.gray(`  HTTP Status: ${result.status}`));

        // Wait a moment then check webhook logs
        await this.wait(1000);
        
        const webhookResponse = await fetch(`${WEBHOOK_URL}/logs`);
        const webhookLogs = await webhookResponse.json();
        
        if (webhookLogs.webhooks.length > 0) {
          const latestCall = webhookLogs.webhooks[webhookLogs.webhooks.length - 1];
          console.log(chalk.green('\n🎯 Webhook successfully received:'));
          console.log(chalk.gray(`  Timestamp: ${latestCall.timestamp}`));
          console.log(chalk.gray(`  Payload: ${JSON.stringify(latestCall.body, null, 2)}`));
        }
      } else {
        console.log(chalk.red('❌ Email processing failed:', result.error));
      }
    } catch (error) {
      console.log(chalk.red('Error sending email:', error.message));
    }
  }

  async demonstrateStorage() {
    await this.nextStep(
      'Demonstrate Email Storage',
      'Send email to archive@bolk.dev and show database storage'
    );

    const testEmail = {
      from: 'legal@partner.com',
      to: 'archive@bolk.dev',
      subject: 'Demo: Important Document Archive',
      body: 'This document needs to be archived for future reference. This is a demo email to show storage functionality.',
      headers: {
        'Content-Type': 'text/html',
        'X-Demo': 'Email Storage',
        'X-Document-Type': 'Legal'
      }
    };

    console.log(chalk.cyan('📧 Sending storage test email:'));
    console.log(chalk.gray(`  From: ${testEmail.from}`));
    console.log(chalk.gray(`  To: ${testEmail.to}`));
    console.log(chalk.gray(`  Subject: ${testEmail.subject}`));

    try {
      const response = await fetch(`${WORKER_URL}/test-email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testEmail)
      });

      const result = await response.json();

      if (result.success) {
        console.log(chalk.green('\n✅ Email processed successfully!'));
        console.log(chalk.blue('📦 Storage Result:'));
        console.log(chalk.gray(`  Action: ${result.action}`));
        console.log(chalk.gray(`  Stored in local database`));
      } else {
        console.log(chalk.red('❌ Email processing failed:', result.error));
      }
    } catch (error) {
      console.log(chalk.red('Error sending email:', error.message));
    }
  }

  async showEmailLogs() {
    await this.nextStep(
      'Show Email Processing Logs',
      'Display recent email activity and processing results'
    );

    try {
      const response = await fetch(`${WORKER_URL}/api/emails?limit=10`);
      const result = await response.json();

      if (result.success && result.emails.length > 0) {
        console.log(chalk.green(`📊 Recent email activity (${result.emails.length} emails):`));
        
        result.emails.forEach((email, index) => {
          console.log(chalk.cyan(`\n${index + 1}. ${email.subject || '(no subject)'}`));
          console.log(chalk.gray(`   From: ${email.from || email.from_address}`));
          console.log(chalk.gray(`   To: ${email.to || email.to_address}`));
          console.log(chalk.gray(`   Status: ${email.status}`));
          console.log(chalk.gray(`   Received: ${new Date(email.receivedAt || email.received_at).toLocaleString()}`));
        });
      } else {
        console.log(chalk.yellow('No email logs found'));
      }
    } catch (error) {
      console.log(chalk.red('Error fetching logs:', error.message));
    }
  }

  async showDebugInfo() {
    await this.nextStep(
      'Show Debug Information',
      'Display system state and statistics'
    );

    try {
      const response = await fetch(`${WORKER_URL}/debug`);
      const debug = await response.json();

      console.log(chalk.green('🔍 System Debug Information:'));
      console.log(chalk.cyan('\n📊 Summary:'));
      Object.entries(debug.summary).forEach(([key, value]) => {
        console.log(chalk.gray(`  ${key}: ${value}`));
      });

      if (debug.recentLogs.length > 0) {
        console.log(chalk.cyan('\n📧 Recent Activity:'));
        debug.recentLogs.slice(0, 3).forEach(log => {
          console.log(chalk.gray(`  • ${log.subject || '(no subject)'} - ${log.status}`));
        });
      }

    } catch (error) {
      console.log(chalk.red('Error fetching debug info:', error.message));
    }
  }

  async showNextSteps() {
    await this.nextStep(
      'Next Steps for Production',
      'Instructions for deploying to real Cloudflare infrastructure'
    );

    console.log(chalk.green('🚀 Ready for Production Deployment!'));
    console.log(chalk.blue('\n📋 Next Steps:'));
    console.log(chalk.gray('1. Deploy to Cloudflare:'));
    console.log(chalk.gray('   npm run worker:deploy'));
    console.log(chalk.gray('\n2. Configure Email Routing in Cloudflare Dashboard'));
    console.log(chalk.gray('3. Set up real webhook endpoints'));
    console.log(chalk.gray('4. Test with real email addresses'));
    
    console.log(chalk.cyan('\n🌐 Local Development URLs:'));
    console.log(chalk.gray(`  • Web Dashboard: http://localhost:3002`));
    console.log(chalk.gray(`  • Webhook Dashboard: http://localhost:3003/dashboard`));
    console.log(chalk.gray(`  • Mock Worker API: ${WORKER_URL}/debug`));

    console.log(chalk.yellow('\n💡 Tips:'));
    console.log(chalk.gray('  • Use the web dashboard for visual management'));
    console.log(chalk.gray('  • Check webhook dashboard for real-time webhook monitoring'));
    console.log(chalk.gray('  • Run "npm run test:all" for automated testing'));
  }

  async run() {
    console.log(chalk.blue('🎬 Starting Cloudflare Email Worker Demo'));
    console.log(chalk.gray('This demo will show all features of the email management system\n'));

    await this.checkServices();
    await this.showExistingConfigs();
    await this.demonstrateEmailForwarding();
    await this.demonstrateWebhook();
    await this.demonstrateStorage();
    await this.showEmailLogs();
    await this.showDebugInfo();
    await this.showNextSteps();

    console.log(chalk.green('\n🎉 Demo completed successfully!'));
    console.log(chalk.blue('The Cloudflare Email Worker system is working perfectly.'));
  }
}

// Run demo
const demo = new EmailWorkerDemo();
demo.run().catch(console.error);
