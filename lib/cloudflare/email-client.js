/**
 * Cloudflare Email Client
 * Handles communication with the Cloudflare Email Worker
 */

import fs from 'fs/promises';
import path from 'path';
import os from 'os';

class CloudflareEmailClient {
  constructor() {
    this.configPath = path.join(os.homedir(), '.cloudflare-email-cli.json');
    this.config = null;
  }

  /**
   * Setup the client with worker URL and API key
   */
  async setup(workerUrl, apiKey) {
    const config = {
      workerUrl: workerUrl.replace(/\/$/, ''), // Remove trailing slash
      apiKey,
      setupAt: new Date().toISOString()
    };

    await fs.writeFile(this.configPath, JSON.stringify(config, null, 2));
    this.config = config;
  }

  /**
   * Load configuration from file
   */
  async loadConfig() {
    if (this.config) return this.config;

    try {
      const configData = await fs.readFile(this.configPath, 'utf8');
      this.config = JSON.parse(configData);
      return this.config;
    } catch (error) {
      throw new Error('Configuration not found. Please run "email-cli setup" first.');
    }
  }

  /**
   * Make API request to the worker
   */
  async makeRequest(endpoint, options = {}) {
    const config = await this.loadConfig();
    
    const url = `${config.workerUrl}${endpoint}`;
    const requestOptions = {
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': config.apiKey,
        ...options.headers
      },
      ...options
    };

    const response = await fetch(url, requestOptions);
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API request failed: ${response.status} ${errorText}`);
    }

    return response.json();
  }

  /**
   * Create email configuration
   */
  async createEmailConfig(config) {
    try {
      const result = await this.makeRequest('/api/config', {
        method: 'POST',
        body: JSON.stringify(config)
      });
      return result;
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get all email configurations
   */
  async getEmailConfigs() {
    try {
      const result = await this.makeRequest('/api/config');
      return result;
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Delete email configuration
   */
  async deleteEmailConfig(email) {
    try {
      const result = await this.makeRequest(`/api/config/${encodeURIComponent(email)}`, {
        method: 'DELETE'
      });
      return result;
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get email logs
   */
  async getEmailLogs(options = {}) {
    try {
      const params = new URLSearchParams();
      if (options.limit) params.append('limit', options.limit);
      if (options.offset) params.append('offset', options.offset);
      
      const endpoint = `/api/emails${params.toString() ? '?' + params.toString() : ''}`;
      const result = await this.makeRequest(endpoint);
      return result;
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Test email configuration
   */
  async testEmailConfig(email) {
    try {
      const configs = await this.getEmailConfigs();
      if (!configs.success) {
        return configs;
      }

      const config = configs.configs.find(c => c.email === email);
      if (!config) {
        return {
          success: false,
          error: 'Email configuration not found'
        };
      }

      // Validate configuration
      const validation = this.validateConfig(config);
      if (!validation.valid) {
        return {
          success: false,
          error: validation.error
        };
      }

      return {
        success: true,
        config,
        message: 'Configuration is valid'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Validate email configuration
   */
  validateConfig(config) {
    if (!config.action) {
      return { valid: false, error: 'Action is required' };
    }

    switch (config.action) {
      case 'forward':
        if (!config.forwardTo || config.forwardTo.length === 0) {
          return { valid: false, error: 'Forward addresses are required' };
        }
        break;
      case 'webhook':
        if (!config.webhookUrl) {
          return { valid: false, error: 'Webhook URL is required' };
        }
        try {
          new URL(config.webhookUrl);
        } catch {
          return { valid: false, error: 'Invalid webhook URL' };
        }
        break;
      case 'store':
        // No additional validation needed for store action
        break;
      default:
        return { valid: false, error: 'Invalid action type' };
    }

    return { valid: true };
  }

  /**
   * Get configuration status
   */
  async getStatus() {
    try {
      const config = await this.loadConfig();
      
      // Test connection to worker
      const response = await fetch(config.workerUrl, {
        headers: {
          'X-API-Key': config.apiKey
        }
      });

      return {
        configured: true,
        workerUrl: config.workerUrl,
        connected: response.ok,
        setupAt: config.setupAt
      };
    } catch (error) {
      return {
        configured: false,
        error: error.message
      };
    }
  }

  /**
   * Update configuration
   */
  async updateConfig(updates) {
    const config = await this.loadConfig();
    const newConfig = { ...config, ...updates };
    
    await fs.writeFile(this.configPath, JSON.stringify(newConfig, null, 2));
    this.config = newConfig;
    
    return newConfig;
  }

  /**
   * Reset configuration
   */
  async resetConfig() {
    try {
      await fs.unlink(this.configPath);
      this.config = null;
      return true;
    } catch (error) {
      return false;
    }
  }
}

export default CloudflareEmailClient;
