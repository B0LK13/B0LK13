#!/usr/bin/env node

/**
 * Cloudflare Email Worker Examples
 * Demonstrates how to use the email system programmatically
 */

import CloudflareEmailClient from '../lib/cloudflare/email-client.js';

const client = new CloudflareEmailClient();

async function runExamples() {
  console.log('🚀 Cloudflare Email Worker Examples\n');

  try {
    // Example 1: Create a forward email
    console.log('📧 Example 1: Creating a forward email...');
    const forwardResult = await client.createEmailConfig({
      email: 'support@yourdomain.com',
      action: 'forward',
      forwardTo: ['admin@company.com', 'team@company.com']
    });
    
    if (forwardResult.success) {
      console.log('✅ Forward email created successfully');
      console.log('   Email:', forwardResult.config.email);
      console.log('   Forwards to:', forwardResult.config.forwardTo.join(', '));
    } else {
      console.log('❌ Failed to create forward email:', forwardResult.error);
    }
    console.log();

    // Example 2: Create a webhook email
    console.log('🔗 Example 2: Creating a webhook email...');
    const webhookResult = await client.createEmailConfig({
      email: 'api@yourdomain.com',
      action: 'webhook',
      webhookUrl: 'https://your-app.com/webhook/email',
      includeBody: true
    });
    
    if (webhookResult.success) {
      console.log('✅ Webhook email created successfully');
      console.log('   Email:', webhookResult.config.email);
      console.log('   Webhook URL:', webhookResult.config.webhookUrl);
      console.log('   Include body:', webhookResult.config.includeBody);
    } else {
      console.log('❌ Failed to create webhook email:', webhookResult.error);
    }
    console.log();

    // Example 3: Create a storage email
    console.log('📦 Example 3: Creating a storage email...');
    const storeResult = await client.createEmailConfig({
      email: 'archive@yourdomain.com',
      action: 'store'
    });
    
    if (storeResult.success) {
      console.log('✅ Storage email created successfully');
      console.log('   Email:', storeResult.config.email);
      console.log('   Action: Store in database');
    } else {
      console.log('❌ Failed to create storage email:', storeResult.error);
    }
    console.log();

    // Example 4: List all configurations
    console.log('📋 Example 4: Listing all email configurations...');
    const listResult = await client.getEmailConfigs();
    
    if (listResult.success) {
      console.log('✅ Email configurations retrieved');
      console.log(`   Total configurations: ${listResult.configs.length}`);
      
      listResult.configs.forEach((config, index) => {
        console.log(`   ${index + 1}. ${config.email} (${config.action})`);
      });
    } else {
      console.log('❌ Failed to list configurations:', listResult.error);
    }
    console.log();

    // Example 5: Get email logs
    console.log('📊 Example 5: Getting recent email logs...');
    const logsResult = await client.getEmailLogs({ limit: 10 });
    
    if (logsResult.success) {
      console.log('✅ Email logs retrieved');
      console.log(`   Recent emails: ${logsResult.emails.length}`);
      
      logsResult.emails.slice(0, 3).forEach((email, index) => {
        console.log(`   ${index + 1}. From: ${email.from_address}`);
        console.log(`      To: ${email.to_address}`);
        console.log(`      Subject: ${email.subject || '(no subject)'}`);
        console.log(`      Received: ${new Date(email.received_at).toLocaleString()}`);
      });
    } else {
      console.log('❌ Failed to get logs:', logsResult.error);
    }
    console.log();

    // Example 6: Test email configuration
    console.log('🧪 Example 6: Testing email configuration...');
    const testResult = await client.testEmailConfig('support@yourdomain.com');
    
    if (testResult.success) {
      console.log('✅ Email configuration is valid');
      console.log('   Configuration details:');
      console.log('   ', JSON.stringify(testResult.config, null, 4));
    } else {
      console.log('❌ Email configuration test failed:', testResult.error);
    }
    console.log();

    console.log('🎉 Examples completed successfully!');
    console.log('\n💡 Tips:');
    console.log('   - Use the CLI for interactive management: npm run email');
    console.log('   - Access the web interface at /cloudflare-email');
    console.log('   - Check logs regularly to monitor email processing');
    console.log('   - Test configurations before going live');

  } catch (error) {
    console.error('❌ Error running examples:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Make sure you have run "npm run email:setup"');
    console.log('   2. Verify your Cloudflare Worker is deployed');
    console.log('   3. Check your API key and worker URL');
    console.log('   4. Ensure your domain has Email Routing enabled');
  }
}

// Utility function to demonstrate webhook payload
function exampleWebhookPayload() {
  return {
    from: 'user@example.com',
    to: 'api@yourdomain.com',
    subject: 'API Request via Email',
    timestamp: new Date().toISOString(),
    messageId: '<example-message-id@example.com>',
    headers: {
      'Content-Type': 'text/plain',
      'User-Agent': 'Example Email Client',
      'X-Custom-Header': 'Custom Value'
    },
    body: 'This is an example email body that would be sent to your webhook endpoint.'
  };
}

// Utility function to demonstrate email routing logic
function demonstrateRouting() {
  console.log('\n📋 Email Routing Examples:');
  console.log('\n1. Support Email (Forward):');
  console.log('   support@yourdomain.com → admin@company.com, team@company.com');
  
  console.log('\n2. API Email (Webhook):');
  console.log('   api@yourdomain.com → POST https://your-app.com/webhook/email');
  console.log('   Payload:', JSON.stringify(exampleWebhookPayload(), null, 2));
  
  console.log('\n3. Archive Email (Store):');
  console.log('   archive@yourdomain.com → Stored in D1 database');
  console.log('   Available via API: GET /api/emails?type=stored');
  
  console.log('\n4. Catch-all (Custom Logic):');
  console.log('   *@yourdomain.com → Processed by worker logic');
}

// Run examples if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const command = process.argv[2];
  
  if (command === 'routing') {
    demonstrateRouting();
  } else {
    runExamples();
  }
}

export { runExamples, demonstrateRouting, exampleWebhookPayload };
