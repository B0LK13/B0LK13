#!/usr/bin/env node

/**
 * Local Web Dashboard Server
 * Serves the email management dashboard for local testing
 */

import express from 'express';
import cors from 'cors';
import chalk from 'chalk';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3002;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'web-dashboard')));

console.log(chalk.blue('🌐 Starting Local Web Dashboard...'));

// Proxy API requests to mock worker
app.use('/api', async (req, res) => {
  try {
    const workerUrl = `http://localhost:3001${req.path}`;
    const response = await fetch(workerUrl, {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        ...req.headers
      },
      body: req.method !== 'GET' ? JSON.stringify(req.body) : undefined
    });

    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    console.error('Proxy error:', error);
    res.status(500).json({ error: 'Proxy error', message: error.message });
  }
});

// Dashboard route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'web-dashboard', 'index.html'));
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Local Web Dashboard',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(chalk.green(`✅ Web Dashboard running at http://localhost:${PORT}`));
  console.log(chalk.blue('📋 Available routes:'));
  console.log(chalk.gray('  GET  / - Email management dashboard'));
  console.log(chalk.gray('  ALL  /api/* - Proxied to mock worker'));
  console.log(chalk.gray('  GET  /health - Health check'));
  console.log(chalk.cyan('\n🌐 Open dashboard: http://localhost:3002'));
});
