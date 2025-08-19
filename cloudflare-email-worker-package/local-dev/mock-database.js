/**
 * Mock Database for Local Development
 * Simulates Cloudflare D1 and KV storage locally
 */

import fs from 'fs/promises';
import path from 'path';

export class MockDatabase {
  constructor() {
    this.dataDir = './local-data';
    this.configFile = path.join(this.dataDir, 'email-configs.json');
    this.logsFile = path.join(this.dataDir, 'email-logs.json');
    this.storedEmailsFile = path.join(this.dataDir, 'stored-emails.json');
    this.webhookLogsFile = path.join(this.dataDir, 'webhook-logs.json');
    this.forwardLogsFile = path.join(this.dataDir, 'forward-logs.json');
    
    this.init();
  }

  async init() {
    try {
      await fs.mkdir(this.dataDir, { recursive: true });
      
      // Initialize files if they don't exist
      const files = [
        { file: this.configFile, data: {} },
        { file: this.logsFile, data: [] },
        { file: this.storedEmailsFile, data: [] },
        { file: this.webhookLogsFile, data: [] },
        { file: this.forwardLogsFile, data: [] }
      ];

      for (const { file, data } of files) {
        try {
          await fs.access(file);
        } catch {
          await fs.writeFile(file, JSON.stringify(data, null, 2));
        }
      }
    } catch (error) {
      console.error('Error initializing mock database:', error);
    }
  }

  async readFile(filePath) {
    try {
      const data = await fs.readFile(filePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error(`Error reading ${filePath}:`, error);
      return null;
    }
  }

  async writeFile(filePath, data) {
    try {
      await fs.writeFile(filePath, JSON.stringify(data, null, 2));
    } catch (error) {
      console.error(`Error writing ${filePath}:`, error);
    }
  }

  // Email Configuration Methods (simulates KV storage)
  async setEmailConfig(email, config) {
    const configs = await this.readFile(this.configFile) || {};
    configs[email] = config;
    await this.writeFile(this.configFile, configs);
  }

  async getEmailConfig(email) {
    const configs = await this.readFile(this.configFile) || {};
    return configs[email] || null;
  }

  async deleteEmailConfig(email) {
    const configs = await this.readFile(this.configFile) || {};
    delete configs[email];
    await this.writeFile(this.configFile, configs);
  }

  async getAllConfigs() {
    const configs = await this.readFile(this.configFile) || {};
    return Object.entries(configs).map(([email, config]) => ({
      email,
      ...config
    }));
  }

  // Email Logging Methods (simulates D1 database)
  async logEmail(emailData) {
    const logs = await this.readFile(this.logsFile) || [];
    const logEntry = {
      id: logs.length + 1,
      ...emailData,
      createdAt: new Date().toISOString()
    };
    logs.push(logEntry);
    await this.writeFile(this.logsFile, logs);
    return logEntry;
  }

  async getEmailLogs(limit = 50) {
    const logs = await this.readFile(this.logsFile) || [];
    return logs
      .sort((a, b) => new Date(b.receivedAt) - new Date(a.receivedAt))
      .slice(0, limit);
  }

  async updateEmailStatus(email, status) {
    const logs = await this.readFile(this.logsFile) || [];
    const latestLog = logs
      .filter(log => log.to === email)
      .sort((a, b) => new Date(b.receivedAt) - new Date(a.receivedAt))[0];
    
    if (latestLog) {
      latestLog.status = status;
      latestLog.processedAt = new Date().toISOString();
      await this.writeFile(this.logsFile, logs);
    }
  }

  // Stored Emails Methods
  async storeEmail(emailData) {
    const emails = await this.readFile(this.storedEmailsFile) || [];
    const storedEmail = {
      id: emails.length + 1,
      ...emailData,
      createdAt: new Date().toISOString()
    };
    emails.push(storedEmail);
    await this.writeFile(this.storedEmailsFile, emails);
    return storedEmail;
  }

  async getStoredEmails(limit = 50) {
    const emails = await this.readFile(this.storedEmailsFile) || [];
    return emails
      .sort((a, b) => new Date(b.receivedAt) - new Date(a.receivedAt))
      .slice(0, limit);
  }

  // Webhook Logging Methods
  async logWebhook(webhookData) {
    const logs = await this.readFile(this.webhookLogsFile) || [];
    const logEntry = {
      id: logs.length + 1,
      ...webhookData,
      createdAt: new Date().toISOString()
    };
    logs.push(logEntry);
    await this.writeFile(this.webhookLogsFile, logs);
    return logEntry;
  }

  async getWebhookLogs(limit = 50) {
    const logs = await this.readFile(this.webhookLogsFile) || [];
    return logs
      .sort((a, b) => new Date(b.deliveredAt) - new Date(a.deliveredAt))
      .slice(0, limit);
  }

  // Forward Logging Methods
  async logForward(forwardData) {
    const logs = await this.readFile(this.forwardLogsFile) || [];
    const logEntry = {
      id: logs.length + 1,
      ...forwardData,
      createdAt: new Date().toISOString()
    };
    logs.push(logEntry);
    await this.writeFile(this.forwardLogsFile, logs);
    return logEntry;
  }

  async getForwardLogs(limit = 50) {
    const logs = await this.readFile(this.forwardLogsFile) || [];
    return logs
      .sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt))
      .slice(0, limit);
  }

  // Debug and Statistics
  async getDebugState() {
    const configs = await this.getAllConfigs();
    const emailLogs = await this.getEmailLogs();
    const storedEmails = await this.getStoredEmails();
    const webhookLogs = await this.getWebhookLogs();
    const forwardLogs = await this.getForwardLogs();

    return {
      summary: {
        totalConfigs: configs.length,
        totalEmailLogs: emailLogs.length,
        totalStoredEmails: storedEmails.length,
        totalWebhookCalls: webhookLogs.length,
        totalForwards: forwardLogs.length
      },
      configs,
      recentLogs: emailLogs.slice(0, 10),
      recentWebhooks: webhookLogs.slice(0, 5),
      recentForwards: forwardLogs.slice(0, 5)
    };
  }

  async getStats() {
    const configs = await this.getAllConfigs();
    const logs = await this.getEmailLogs();
    
    const stats = {
      totalConfigs: configs.length,
      totalEmails: logs.length,
      emailsByAction: {},
      emailsByStatus: {},
      recentActivity: logs.slice(0, 5)
    };

    // Count by action
    configs.forEach(config => {
      stats.emailsByAction[config.action] = (stats.emailsByAction[config.action] || 0) + 1;
    });

    // Count by status
    logs.forEach(log => {
      stats.emailsByStatus[log.status] = (stats.emailsByStatus[log.status] || 0) + 1;
    });

    return stats;
  }

  // Reset all data
  async reset() {
    await this.writeFile(this.configFile, {});
    await this.writeFile(this.logsFile, []);
    await this.writeFile(this.storedEmailsFile, []);
    await this.writeFile(this.webhookLogsFile, []);
    await this.writeFile(this.forwardLogsFile, []);
  }
}
