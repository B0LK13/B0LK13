#!/usr/bin/env node

/**
 * Setup Script for Local Development Environment
 * Creates the local-dev directory and all necessary files
 */

import fs from 'fs/promises';
import path from 'path';
import chalk from 'chalk';

async function createDirectory(dirPath) {
  try {
    await fs.mkdir(dirPath, { recursive: true });
    console.log(chalk.green(`✅ Created directory: ${dirPath}`));
  } catch (error) {
    console.log(chalk.yellow(`⚠️  Directory already exists: ${dirPath}`));
  }
}

async function copyFile(source, destination) {
  try {
    const content = await fs.readFile(source, 'utf8');
    await fs.writeFile(destination, content);
    console.log(chalk.green(`✅ Created file: ${destination}`));
  } catch (error) {
    console.log(chalk.red(`❌ Failed to copy ${source}: ${error.message}`));
  }
}

async function main() {
  console.log(chalk.blue('🚀 Setting up Local Development Environment\n'));

  // Create directories
  await createDirectory('local-dev');
  await createDirectory('local-dev/test-data');
  await createDirectory('local-dev/web-dashboard');
  await createDirectory('local-dev/local-data');

  // Check if source files exist and copy them
  const filesToCopy = [
    { src: 'local-dev/package.json', dest: 'local-dev/package.json' },
    { src: 'local-dev/README.md', dest: 'local-dev/README.md' },
    { src: 'local-dev/mock-worker.js', dest: 'local-dev/mock-worker.js' },
    { src: 'local-dev/mock-database.js', dest: 'local-dev/mock-database.js' },
    { src: 'local-dev/webhook-server.js', dest: 'local-dev/webhook-server.js' },
    { src: 'local-dev/server.js', dest: 'local-dev/server.js' },
    { src: 'local-dev/cli-local.js', dest: 'local-dev/cli-local.js' },
    { src: 'local-dev/test-scenarios.js', dest: 'local-dev/test-scenarios.js' },
    { src: 'local-dev/demo.js', dest: 'local-dev/demo.js' }
  ];

  for (const file of filesToCopy) {
    try {
      await fs.access(file.src);
      await copyFile(file.src, file.dest);
    } catch (error) {
      console.log(chalk.yellow(`⚠️  Source file not found: ${file.src}`));
    }
  }

  console.log(chalk.blue('\n📋 Next Steps:'));
  console.log(chalk.gray('1. cd local-dev'));
  console.log(chalk.gray('2. npm install'));
  console.log(chalk.gray('3. npm run dev'));
  console.log(chalk.green('\n🎉 Local development environment setup complete!'));
}

main().catch(console.error);
