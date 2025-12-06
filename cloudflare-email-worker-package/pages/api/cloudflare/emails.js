/**
 * Next.js API route for Cloudflare email management
 * Provides web interface for email configuration
 */

import CloudflareEmailClient from '../../../lib/cloudflare/email-client.js';

const client = new CloudflareEmailClient();

export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    switch (req.method) {
      case 'GET':
        return await handleGet(req, res);
      case 'POST':
        return await handlePost(req, res);
      case 'DELETE':
        return await handleDelete(req, res);
      default:
        return res.status(405).json({ 
          success: false, 
          error: 'Method not allowed' 
        });
    }
  } catch (error) {
    console.error('API error:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
}

/**
 * Handle GET requests - List email configurations or logs
 */
async function handleGet(req, res) {
  const { type, limit, offset } = req.query;

  if (type === 'logs') {
    const result = await client.getEmailLogs({ 
      limit: parseInt(limit) || 50,
      offset: parseInt(offset) || 0
    });
    return res.status(200).json(result);
  }

  // Default: get email configurations
  const result = await client.getEmailConfigs();
  return res.status(200).json(result);
}

/**
 * Handle POST requests - Create email configuration
 */
async function handlePost(req, res) {
  const { email, action, forwardTo, webhookUrl, includeBody } = req.body;

  if (!email || !action) {
    return res.status(400).json({
      success: false,
      error: 'Email and action are required'
    });
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid email format'
    });
  }

  // Validate action-specific requirements
  const config = { email, action };

  switch (action) {
    case 'forward':
      if (!forwardTo || forwardTo.length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Forward addresses are required'
        });
      }
      config.forwardTo = Array.isArray(forwardTo) ? forwardTo : [forwardTo];
      break;

    case 'webhook':
      if (!webhookUrl) {
        return res.status(400).json({
          success: false,
          error: 'Webhook URL is required'
        });
      }
      try {
        new URL(webhookUrl);
      } catch {
        return res.status(400).json({
          success: false,
          error: 'Invalid webhook URL'
        });
      }
      config.webhookUrl = webhookUrl;
      config.includeBody = includeBody || false;
      break;

    case 'store':
      // No additional validation needed
      break;

    default:
      return res.status(400).json({
        success: false,
        error: 'Invalid action type'
      });
  }

  const result = await client.createEmailConfig(config);
  
  if (result.success) {
    return res.status(201).json(result);
  } else {
    return res.status(400).json(result);
  }
}

/**
 * Handle DELETE requests - Delete email configuration
 */
async function handleDelete(req, res) {
  const { email } = req.query;

  if (!email) {
    return res.status(400).json({
      success: false,
      error: 'Email parameter is required'
    });
  }

  const result = await client.deleteEmailConfig(email);
  
  if (result.success) {
    return res.status(200).json(result);
  } else {
    return res.status(400).json(result);
  }
}
