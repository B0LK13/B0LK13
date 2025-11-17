#!/usr/bin/env node

/**
 * Cloudflare Email CLI Tool
 * Create and manage email addresses from the terminal
 */

import { program } from 'commander';
import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import Table from 'cli-table3';
import CloudflareEmailClient from '../lib/cloudflare/email-client.js';

const client = new CloudflareEmailClient();

program
  .name('email-cli')
  .description('Cloudflare Email Management CLI')
  .version('1.0.0');

// Create email address command
program
  .command('create')
  .description('Create a new email address')
  .option('-e, --email <email>', 'Email address to create')
  .option('-a, --action <action>', 'Action: forward, webhook, store')
  .option('-f, --forward <addresses>', 'Forward to addresses (comma-separated)')
  .option('-w, --webhook <url>', 'Webhook URL')
  .option('-i, --interactive', 'Interactive mode')
  .action(async (options) => {
    try {
      let config = {};

      if (options.interactive || (!options.email || !options.action)) {
        config = await interactiveCreate();
      } else {
        config = {
          email: options.email,
          action: options.action,
          forwardTo: options.forward ? options.forward.split(',') : [],
          webhookUrl: options.webhook
        };
      }

      const spinner = ora('Creating email configuration...').start();
      
      const result = await client.createEmailConfig(config);
      
      if (result.success) {
        spinner.succeed(chalk.green(`Email address ${config.email} created successfully!`));
        console.log(chalk.blue('Configuration:'));
        console.log(JSON.stringify(result.config, null, 2));
      } else {
        spinner.fail(chalk.red(`Failed to create email: ${result.error}`));
      }
    } catch (error) {
      console.error(chalk.red('Error:', error.message));
    }
  });

// List email addresses command
program
  .command('list')
  .description('List all configured email addresses')
  .action(async () => {
    try {
      const spinner = ora('Fetching email configurations...').start();
      
      const result = await client.getEmailConfigs();
      
      if (result.success) {
        spinner.succeed(chalk.green('Email configurations retrieved'));
        
        if (result.configs.length === 0) {
          console.log(chalk.yellow('No email addresses configured'));
          return;
        }

        const table = new Table({
          head: ['Email', 'Action', 'Details', 'Created'],
          colWidths: [30, 15, 40, 20]
        });

        result.configs.forEach(config => {
          let details = '';
          switch (config.action) {
            case 'forward':
              details = `Forward to: ${config.forwardTo?.join(', ') || 'None'}`;
              break;
            case 'webhook':
              details = `Webhook: ${config.webhookUrl || 'Not set'}`;
              break;
            case 'store':
              details = 'Store in database';
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
        spinner.fail(chalk.red(`Failed to fetch configurations: ${result.error}`));
      }
    } catch (error) {
      console.error(chalk.red('Error:', error.message));
    }
  });

// Delete email address command
program
  .command('delete <email>')
  .description('Delete an email address configuration')
  .action(async (email) => {
    try {
      const confirm = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'confirmed',
          message: `Are you sure you want to delete ${email}?`,
          default: false
        }
      ]);

      if (!confirm.confirmed) {
        console.log(chalk.yellow('Operation cancelled'));
        return;
      }

      const spinner = ora('Deleting email configuration...').start();
      
      const result = await client.deleteEmailConfig(email);
      
      if (result.success) {
        spinner.succeed(chalk.green(`Email address ${email} deleted successfully!`));
      } else {
        spinner.fail(chalk.red(`Failed to delete email: ${result.error}`));
      }
    } catch (error) {
      console.error(chalk.red('Error:', error.message));
    }
  });

// Show email logs command
program
  .command('logs')
  .description('Show recent email logs')
  .option('-l, --limit <number>', 'Number of logs to show', '20')
  .action(async (options) => {
    try {
      const spinner = ora('Fetching email logs...').start();
      
      const result = await client.getEmailLogs({ limit: parseInt(options.limit) });
      
      if (result.success) {
        spinner.succeed(chalk.green('Email logs retrieved'));
        
        if (result.emails.length === 0) {
          console.log(chalk.yellow('No email logs found'));
          return;
        }

        const table = new Table({
          head: ['From', 'To', 'Subject', 'Received'],
          colWidths: [25, 25, 40, 20]
        });

        result.emails.forEach(email => {
          table.push([
            email.from_address,
            email.to_address,
            email.subject || '(no subject)',
            new Date(email.received_at).toLocaleString()
          ]);
        });

        console.log(table.toString());
      } else {
        spinner.fail(chalk.red(`Failed to fetch logs: ${result.error}`));
      }
    } catch (error) {
      console.error(chalk.red('Error:', error.message));
    }
  });

// Test email configuration command
program
  .command('test <email>')
  .description('Test an email configuration')
  .action(async (email) => {
    try {
      const spinner = ora('Testing email configuration...').start();
      
      const result = await client.testEmailConfig(email);
      
      if (result.success) {
        spinner.succeed(chalk.green(`Email configuration for ${email} is valid`));
        console.log(chalk.blue('Configuration details:'));
        console.log(JSON.stringify(result.config, null, 2));
      } else {
        spinner.fail(chalk.red(`Email configuration test failed: ${result.error}`));
      }
    } catch (error) {
      console.error(chalk.red('Error:', error.message));
    }
  });

// Interactive create function
async function interactiveCreate() {
  console.log(chalk.blue('🚀 Creating a new email address configuration\n'));

  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'email',
      message: 'Enter the email address (e.g., support@bolk.dev):',
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
        { name: 'Store in database', value: 'store' }
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
          const emails = input.split(',').map(e => e.trim());
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          const invalid = emails.find(email => !emailRegex.test(email));
          return invalid ? `Invalid email address: ${invalid}` : true;
        }
      }
    ]);
    answers.forwardTo = forwardAnswers.forwardTo.split(',').map(e => e.trim());
  }

  if (answers.action === 'webhook') {
    const webhookAnswers = await inquirer.prompt([
      {
        type: 'input',
        name: 'webhookUrl',
        message: 'Enter webhook URL:',
        validate: (input) => {
          try {
            new URL(input);
            return true;
          } catch {
            return 'Please enter a valid URL';
          }
        }
      },
      {
        type: 'confirm',
        name: 'includeBody',
        message: 'Include email body in webhook payload?',
        default: false
      }
    ]);
    answers.webhookUrl = webhookAnswers.webhookUrl;
    answers.includeBody = webhookAnswers.includeBody;
  }

  return answers;
}

// Setup command for initial configuration
program
  .command('setup')
  .description('Setup Cloudflare Email CLI')
  .action(async () => {
    console.log(chalk.blue('🔧 Setting up Cloudflare Email CLI\n'));

    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'workerUrl',
        message: 'Enter your Cloudflare Worker URL:',
        validate: (input) => {
          try {
            new URL(input);
            return true;
          } catch {
            return 'Please enter a valid URL';
          }
        }
      },
      {
        type: 'password',
        name: 'apiKey',
        message: 'Enter your API key:',
        mask: '*'
      }
    ]);

    try {
      await client.setup(answers.workerUrl, answers.apiKey);
      console.log(chalk.green('✅ Setup completed successfully!'));
    } catch (error) {
      console.error(chalk.red('Setup failed:', error.message));
    }
  });

program.parse();
