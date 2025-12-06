#!/usr/bin/env node

/**
 * Deployment Verification Script
 * Verifies that the Cloudflare Email Worker package is working correctly
 */

import chalk from 'chalk';
import { spawn } from 'child_process';
import fetch from 'node-fetch';

class DeploymentVerifier {
  constructor() {
    this.results = [];
    this.services = {
      worker: 'http://localhost:3001',
      dashboard: 'http://localhost:3002', 
      webhook: 'http://localhost:3003'
    };
  }

  async wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async checkService(name, url) {
    try {
      console.log(chalk.blue(`🔍 Checking ${name}...`));
      const response = await fetch(`${url}/health`, { timeout: 5000 });
      
      if (response.ok) {
        const data = await response.json();
        console.log(chalk.green(`✅ ${name}: ${data.status || 'healthy'}`));
        return true;
      } else {
        console.log(chalk.red(`❌ ${name}: HTTP ${response.status}`));
        return false;
      }
    } catch (error) {
      console.log(chalk.red(`❌ ${name}: ${error.message}`));
      return false;
    }
  }

  async testEmailCreation() {
    try {
      console.log(chalk.blue('🔍 Testing email creation...'));
      
      const testConfig = {
        email: 'verify@bolk.dev',
        action: 'forward',
        forwardTo: ['test@example.com']
      };

      const response = await fetch(`${this.services.worker}/api/config`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testConfig)
      });

      const result = await response.json();
      
      if (result.success) {
        console.log(chalk.green('✅ Email creation: Working'));
        return true;
      } else {
        console.log(chalk.red(`❌ Email creation: ${result.error}`));
        return false;
      }
    } catch (error) {
      console.log(chalk.red(`❌ Email creation: ${error.message}`));
      return false;
    }
  }

  async testEmailProcessing() {
    try {
      console.log(chalk.blue('🔍 Testing email processing...'));
      
      const testEmail = {
        from: 'test@example.com',
        to: 'verify@bolk.dev',
        subject: 'Verification Test',
        body: 'This is a deployment verification test.'
      };

      const response = await fetch(`${this.services.worker}/test-email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testEmail)
      });

      const result = await response.json();
      
      if (result.success) {
        console.log(chalk.green(`✅ Email processing: ${result.action} successful`));
        return true;
      } else {
        console.log(chalk.red(`❌ Email processing: ${result.error}`));
        return false;
      }
    } catch (error) {
      console.log(chalk.red(`❌ Email processing: ${error.message}`));
      return false;
    }
  }

  async testWebhookEndpoint() {
    try {
      console.log(chalk.blue('🔍 Testing webhook endpoint...'));
      
      const response = await fetch(`${this.services.webhook}/logs`);
      const data = await response.json();
      
      console.log(chalk.green(`✅ Webhook endpoint: ${data.total || 0} total calls`));
      return true;
    } catch (error) {
      console.log(chalk.red(`❌ Webhook endpoint: ${error.message}`));
      return false;
    }
  }

  async checkFileStructure() {
    console.log(chalk.blue('🔍 Checking file structure...'));
    
    const requiredFiles = [
      'wrangler.toml',
      'workers/email-worker.js',
      'workers/schema.sql',
      'scripts/email-cli.js',
      'local-dev/package.json',
      'local-dev/mock-worker.js',
      'DEPLOYMENT_README.md'
    ];

    let allFilesExist = true;
    
    for (const file of requiredFiles) {
      try {
        await import('fs').then(fs => fs.promises.access(file));
        console.log(chalk.gray(`  ✓ ${file}`));
      } catch (error) {
        console.log(chalk.red(`  ✗ ${file} - Missing`));
        allFilesExist = false;
      }
    }

    if (allFilesExist) {
      console.log(chalk.green('✅ File structure: Complete'));
    } else {
      console.log(chalk.red('❌ File structure: Missing files'));
    }
    
    return allFilesExist;
  }

  async runVerification() {
    console.log(chalk.blue('🚀 Cloudflare Email Worker - Deployment Verification'));
    console.log(chalk.blue('=' .repeat(60)));
    console.log();

    // Check file structure
    const filesOk = await this.checkFileStructure();
    console.log();

    // Check services
    console.log(chalk.blue('📡 Checking Services...'));
    const workerOk = await this.checkService('Mock Worker', this.services.worker);
    const dashboardOk = await this.checkService('Web Dashboard', this.services.dashboard);
    const webhookOk = await this.checkService('Webhook Server', this.services.webhook);
    console.log();

    // Test functionality if services are running
    let functionalityOk = false;
    if (workerOk && dashboardOk && webhookOk) {
      console.log(chalk.blue('🧪 Testing Functionality...'));
      const createOk = await this.testEmailCreation();
      const processOk = await this.testEmailProcessing();
      const webhookTestOk = await this.testWebhookEndpoint();
      functionalityOk = createOk && processOk && webhookTestOk;
      console.log();
    }

    // Summary
    console.log(chalk.blue('📊 Verification Summary'));
    console.log(chalk.blue('=' .repeat(30)));
    
    const results = [
      { name: 'File Structure', status: filesOk },
      { name: 'Mock Worker', status: workerOk },
      { name: 'Web Dashboard', status: dashboardOk },
      { name: 'Webhook Server', status: webhookOk },
      { name: 'Email Functionality', status: functionalityOk }
    ];

    results.forEach(result => {
      const icon = result.status ? '✅' : '❌';
      const color = result.status ? chalk.green : chalk.red;
      console.log(color(`${icon} ${result.name}`));
    });

    const allPassed = results.every(r => r.status);
    
    console.log();
    if (allPassed) {
      console.log(chalk.green('🎉 VERIFICATION PASSED!'));
      console.log(chalk.green('The Cloudflare Email Worker system is working correctly.'));
      console.log();
      console.log(chalk.blue('🌐 Access Points:'));
      console.log(chalk.gray(`  • Web Dashboard: ${this.services.dashboard}`));
      console.log(chalk.gray(`  • Webhook Monitor: ${this.services.webhook}/dashboard`));
      console.log(chalk.gray(`  • API Endpoint: ${this.services.worker}/debug`));
    } else {
      console.log(chalk.red('❌ VERIFICATION FAILED!'));
      console.log(chalk.yellow('Please check the issues above and ensure:'));
      console.log(chalk.gray('  1. You are in the correct directory'));
      console.log(chalk.gray('  2. Dependencies are installed (npm install)'));
      console.log(chalk.gray('  3. Services are running (npm run dev)'));
    }

    return allPassed;
  }
}

// Run verification
const verifier = new DeploymentVerifier();
verifier.runVerification().catch(console.error);
