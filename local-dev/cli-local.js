#!/usr/bin/env node

/**
 * Local CLI for Testing Email Worker
 * Provides command-line interface for local development
 */

import { program } from 'commander';
import inquirer from 'inquirer';
import chalk from 'chalk';
import Table from 'cli-table3';
import fetch from 'node-fetch';

const WORKER_URL = 'http://localhost:3001';

program
  .name('email-cli-local')
  .description('Local CLI for Cloudflare Email Worker Testing')
  .version('1.0.0');

// Create email configuration
program
  .command('create')
  .description('Create a new email configuration')
  .action(async () => {
    console.log(chalk.blue('🚀 Creating email configuration for local testing\n'));

    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'email',
        message: 'Enter email address (e.g., test@bolk.dev):',
        validate: (input) => {
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          return emailRegex.test(input) || 'Please enter a valid email address';
        }
      },
      {
        type: 'list',
        name: 'action',
        message: 'What should happen to incoming emails?',
        choices: [
          { name: 'Forward to other email addresses', value: 'forward' },
          { name: 'Send to webhook URL', value: 'webhook' },
          { name: 'Store in local database', value: 'store' }
        ]
      }
    ]);

    // Additional prompts based on action
    if (answers.action === 'forward') {
      const forwardAnswers = await inquirer.prompt([
        {
          type: 'input',
          name: 'forwardTo',
          message: 'Enter email addresses to forward to (comma-separated):',
          validate: (input) => {
            if (!input.trim()) return 'Please enter at least one email address';
            return true;
          }
        }
      ]);
      answers.forwardTo = forwardAnswers.forwardTo.split(',').map(e => e.trim());
    }

    if (answers.action === 'webhook') {
      const webhookAnswers = await inquirer.prompt([
        {
          type: 'list',
          name: 'webhookUrl',
          message: 'Choose webhook endpoint:',
          choices: [
            { name: 'Main webhook (http://localhost:3003/webhook)', value: 'http://localhost:3003/webhook' },
            { name: 'Notifications (http://localhost:3003/notifications)', value: 'http://localhost:3003/notifications' },
            { name: 'Custom URL', value: 'custom' }
          ]
        }
      ]);

      if (webhookAnswers.webhookUrl === 'custom') {
        const customAnswers = await inquirer.prompt([
          {
            type: 'input',
            name: 'customUrl',
            message: 'Enter custom webhook URL:',
            validate: (input) => {
              try {
                new URL(input);
                return true;
              } catch {
                return 'Please enter a valid URL';
              }
            }
          }
        ]);
        answers.webhookUrl = customAnswers.customUrl;
      } else {
        answers.webhookUrl = webhookAnswers.webhookUrl;
      }

      const bodyAnswers = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'includeBody',
          message: 'Include email body in webhook payload?',
          default: true
        }
      ]);
      answers.includeBody = bodyAnswers.includeBody;
    }

    try {
      const response = await fetch(`${WORKER_URL}/api/config`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(answers)
      });

      const result = await response.json();

      if (result.success) {
        console.log(chalk.green(`\n✅ Email configuration created successfully!`));
        console.log(chalk.blue('Configuration details:'));
        console.log(JSON.stringify(result.config, null, 2));
      } else {
        console.log(chalk.red(`\n❌ Failed to create configuration: ${result.error}`));
      }
    } catch (error) {
      console.log(chalk.red(`\n❌ Error: ${error.message}`));
    }
  });

// List email configurations
program
  .command('list')
  .description('List all email configurations')
  .action(async () => {
    try {
      const response = await fetch(`${WORKER_URL}/api/config`);
      const result = await response.json();

      if (result.success) {
        console.log(chalk.green('📧 Email Configurations:\n'));

        if (result.configs.length === 0) {
          console.log(chalk.yellow('No email configurations found.'));
          return;
        }

        const table = new Table({
          head: ['Email', 'Action', 'Details', 'Created'],
          colWidths: [25, 12, 40, 20]
        });

        result.configs.forEach(config => {
          let details = '';
          switch (config.action) {
            case 'forward':
              details = `→ ${config.forwardTo?.join(', ') || 'None'}`;
              break;
            case 'webhook':
              details = `🔗 ${config.webhookUrl || 'Not set'}`;
              break;
            case 'store':
              details = '📦 Store in database';
              break;
          }

          table.push([
            config.email,
            config.action,
            details,
            new Date(config.createdAt).toLocaleDateString()
          ]);
        });

        console.log(table.toString());
      } else {
        console.log(chalk.red(`❌ Failed to fetch configurations: ${result.error}`));
      }
    } catch (error) {
      console.log(chalk.red(`❌ Error: ${error.message}`));
    }
  });

// Test email processing
program
  .command('test')
  .description('Send test emails to configured addresses')
  .action(async () => {
    try {
      // Get available configurations
      const configResponse = await fetch(`${WORKER_URL}/api/config`);
      const configResult = await configResponse.json();

      if (!configResult.success || configResult.configs.length === 0) {
        console.log(chalk.yellow('No email configurations found. Create some first with "create" command.'));
        return;
      }

      const answers = await inquirer.prompt([
        {
          type: 'list',
          name: 'email',
          message: 'Select email address to test:',
          choices: configResult.configs.map(config => ({
            name: `${config.email} (${config.action})`,
            value: config.email
          }))
        },
        {
          type: 'input',
          name: 'from',
          message: 'From email address:',
          default: 'test@example.com'
        },
        {
          type: 'input',
          name: 'subject',
          message: 'Email subject:',
          default: 'Test email from local CLI'
        },
        {
          type: 'input',
          name: 'body',
          message: 'Email body:',
          default: 'This is a test email sent from the local development CLI.'
        }
      ]);

      console.log(chalk.blue('\n📧 Sending test email...'));

      const response = await fetch(`${WORKER_URL}/test-email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          to: answers.email,
          from: answers.from,
          subject: answers.subject,
          body: answers.body,
          headers: {
            'Content-Type': 'text/plain',
            'X-Test-Source': 'Local CLI'
          }
        })
      });

      const result = await response.json();

      if (result.success) {
        console.log(chalk.green('✅ Test email processed successfully!'));
        console.log(chalk.blue('Result:'));
        console.log(JSON.stringify(result, null, 2));
      } else {
        console.log(chalk.red(`❌ Test failed: ${result.error}`));
      }
    } catch (error) {
      console.log(chalk.red(`❌ Error: ${error.message}`));
    }
  });

// View email logs
program
  .command('logs')
  .description('View recent email logs')
  .action(async () => {
    try {
      const response = await fetch(`${WORKER_URL}/api/emails?limit=20`);
      const result = await response.json();

      if (result.success) {
        console.log(chalk.green('📊 Recent Email Logs:\n'));

        if (result.emails.length === 0) {
          console.log(chalk.yellow('No email logs found.'));
          return;
        }

        const table = new Table({
          head: ['From', 'To', 'Subject', 'Status', 'Received'],
          colWidths: [20, 20, 30, 12, 20]
        });

        result.emails.forEach(email => {
          table.push([
            email.from || email.from_address,
            email.to || email.to_address,
            (email.subject || '(no subject)').substring(0, 25),
            email.status || 'unknown',
            new Date(email.receivedAt || email.received_at).toLocaleString()
          ]);
        });

        console.log(table.toString());
      } else {
        console.log(chalk.red(`❌ Failed to fetch logs: ${result.error}`));
      }
    } catch (error) {
      console.log(chalk.red(`❌ Error: ${error.message}`));
    }
  });

// Debug command
program
  .command('debug')
  .description('Show debug information')
  .action(async () => {
    try {
      const response = await fetch(`${WORKER_URL}/debug`);
      const result = await response.json();

      console.log(chalk.blue('🔍 Debug Information:\n'));
      console.log(JSON.stringify(result, null, 2));
    } catch (error) {
      console.log(chalk.red(`❌ Error: ${error.message}`));
    }
  });

program.parse();
