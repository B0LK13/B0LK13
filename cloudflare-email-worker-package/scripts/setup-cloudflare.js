#!/usr/bin/env node

/**
 * Cloudflare Setup Script
 * Automates the creation of required Cloudflare resources
 */

import { execSync } from 'child_process';
import fs from 'fs';
import chalk from 'chalk';

console.log(chalk.blue('🚀 Cloudflare Email Worker Setup\n'));

function runCommand(command, description) {
  console.log(chalk.yellow(`⚡ ${description}...`));
  try {
    const output = execSync(command, { encoding: 'utf8', stdio: 'pipe' });
    console.log(chalk.green(`✅ ${description} completed`));
    return output;
  } catch (error) {
    console.log(chalk.red(`❌ ${description} failed:`));
    console.log(error.message);
    return null;
  }
}

function extractId(output, pattern) {
  const match = output.match(pattern);
  return match ? match[1] : null;
}

async function main() {
  console.log(chalk.blue('This script will help you set up the required Cloudflare resources.\n'));
  
  // Check if wrangler is available
  console.log(chalk.yellow('🔍 Checking Wrangler installation...'));
  try {
    execSync('npx wrangler --version', { stdio: 'pipe' });
    console.log(chalk.green('✅ Wrangler is available\n'));
  } catch (error) {
    console.log(chalk.red('❌ Wrangler not found. Please run: npm install'));
    process.exit(1);
  }

  // Check authentication
  console.log(chalk.yellow('🔐 Checking Cloudflare authentication...'));
  try {
    const whoami = execSync('npx wrangler whoami', { encoding: 'utf8', stdio: 'pipe' });
    console.log(chalk.green('✅ Already authenticated with Cloudflare'));
    console.log(chalk.gray(`   ${whoami.trim()}\n`));
  } catch (error) {
    console.log(chalk.red('❌ Not authenticated with Cloudflare'));
    console.log(chalk.yellow('Please run: npx wrangler login\n'));
    process.exit(1);
  }

  let kvId = null;
  let kvPreviewId = null;
  let d1Id = null;

  // Create KV Namespace
  const kvOutput = runCommand(
    'npx wrangler kv namespace create "EMAIL_CONFIG"',
    'Creating KV namespace'
  );
  if (kvOutput) {
    kvId = extractId(kvOutput, /id = "([^"]+)"/);
    console.log(chalk.gray(`   KV ID: ${kvId}\n`));
  }

  // Create KV Preview Namespace
  const kvPreviewOutput = runCommand(
    'npx wrangler kv namespace create "EMAIL_CONFIG" --preview',
    'Creating KV preview namespace'
  );
  if (kvPreviewOutput) {
    kvPreviewId = extractId(kvPreviewOutput, /id = "([^"]+)"/);
    console.log(chalk.gray(`   KV Preview ID: ${kvPreviewId}\n`));
  }

  // Create D1 Database
  const d1Output = runCommand(
    'npx wrangler d1 create email-routing-db',
    'Creating D1 database'
  );
  if (d1Output) {
    d1Id = extractId(d1Output, /database_id = "([^"]+)"/);
    console.log(chalk.gray(`   D1 ID: ${d1Id}\n`));
  }

  // Update wrangler.toml
  if (kvId && kvPreviewId && d1Id) {
    console.log(chalk.yellow('📝 Updating wrangler.toml...'));
    
    try {
      let wranglerConfig = fs.readFileSync('wrangler.toml', 'utf8');
      
      // Update KV namespace IDs
      wranglerConfig = wranglerConfig.replace(
        /id = "your-kv-namespace-id"/,
        `id = "${kvId}"`
      );
      wranglerConfig = wranglerConfig.replace(
        /preview_id = "your-preview-kv-namespace-id"/,
        `preview_id = "${kvPreviewId}"`
      );
      
      // Update D1 database ID
      wranglerConfig = wranglerConfig.replace(
        /database_id = "your-d1-database-id"/,
        `database_id = "${d1Id}"`
      );
      
      fs.writeFileSync('wrangler.toml', wranglerConfig);
      console.log(chalk.green('✅ wrangler.toml updated successfully\n'));
    } catch (error) {
      console.log(chalk.red('❌ Failed to update wrangler.toml:'), error.message);
    }
  }

  // Run database migration
  runCommand(
    'npx wrangler d1 execute email-routing-db --file=workers/schema.sql',
    'Running database migration'
  );

  console.log(chalk.green('\n🎉 Cloudflare setup completed!\n'));
  
  console.log(chalk.blue('📋 Next steps:'));
  console.log(chalk.white('1. Set your API key:'));
  console.log(chalk.gray('   npx wrangler secret put API_KEY\n'));
  
  console.log(chalk.white('2. Set your app URL:'));
  console.log(chalk.gray('   npx wrangler secret put API_BASE_URL\n'));
  
  console.log(chalk.white('3. Deploy the worker:'));
  console.log(chalk.gray('   npm run worker:deploy\n'));
  
  console.log(chalk.white('4. Setup the CLI:'));
  console.log(chalk.gray('   npm run email:setup\n'));
  
  console.log(chalk.yellow('💡 Your worker will be available at:'));
  console.log(chalk.gray('   https://email-worker.your-username.workers.dev'));
}

main().catch(console.error);
