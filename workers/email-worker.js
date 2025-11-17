/**
 * Cloudflare Email Worker
 * Handles incoming emails and routes them based on configuration
 */

export default {
  async email(message, env, ctx) {
    try {
      console.log('Processing email:', {
        from: message.from,
        to: message.to,
        subject: message.headers.get('subject')
      });

      // Get email configuration from KV store
      const emailConfig = await getEmailConfig(message.to, env);
      
      if (!emailConfig) {
        console.log('No configuration found for:', message.to);
        message.setReject('Email address not configured');
        return;
      }

      // Log the email to D1 database
      await logEmail(message, env);

      // Process based on configuration
      switch (emailConfig.action) {
        case 'forward':
          await forwardEmail(message, emailConfig, env);
          break;
        case 'webhook':
          await sendWebhook(message, emailConfig, env);
          break;
        case 'store':
          await storeEmail(message, emailConfig, env);
          break;
        default:
          console.log('Unknown action:', emailConfig.action);
          message.setReject('Invalid configuration');
      }

    } catch (error) {
      console.error('Email processing error:', error);
      message.setReject('Internal processing error');
    }
  },

  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Handle API requests
    if (url.pathname.startsWith('/api/')) {
      return handleApiRequest(request, env);
    }

    // Default response
    return new Response('Cloudflare Email Worker is running', {
      headers: { 'Content-Type': 'text/plain' }
    });
  }
};

/**
 * Get email configuration from KV store
 */
async function getEmailConfig(emailAddress, env) {
  try {
    const config = await env.EMAIL_CONFIG.get(emailAddress);
    return config ? JSON.parse(config) : null;
  } catch (error) {
    console.error('Error getting email config:', error);
    return null;
  }
}

/**
 * Log email to D1 database
 */
async function logEmail(message, env) {
  try {
    const stmt = env.EMAIL_DB.prepare(`
      INSERT INTO email_logs (
        message_id, from_address, to_address, subject, 
        received_at, size, headers
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    
    await stmt.bind(
      message.headers.get('message-id') || crypto.randomUUID(),
      message.from,
      message.to,
      message.headers.get('subject') || '',
      new Date().toISOString(),
      message.rawSize || 0,
      JSON.stringify(Object.fromEntries(message.headers))
    ).run();
  } catch (error) {
    console.error('Error logging email:', error);
  }
}

/**
 * Forward email to configured addresses
 */
async function forwardEmail(message, config, env) {
  try {
    const forwardAddresses = config.forwardTo || [];
    
    for (const address of forwardAddresses) {
      await message.forward(address);
      console.log('Forwarded email to:', address);
    }
  } catch (error) {
    console.error('Error forwarding email:', error);
    throw error;
  }
}

/**
 * Send webhook notification
 */
async function sendWebhook(message, config, env) {
  try {
    const webhookUrl = config.webhookUrl;
    if (!webhookUrl) {
      throw new Error('Webhook URL not configured');
    }

    const emailData = {
      from: message.from,
      to: message.to,
      subject: message.headers.get('subject'),
      timestamp: new Date().toISOString(),
      messageId: message.headers.get('message-id'),
      headers: Object.fromEntries(message.headers)
    };

    // Get email body if needed
    if (config.includeBody) {
      const reader = message.raw.getReader();
      const chunks = [];
      let done = false;
      
      while (!done) {
        const { value, done: readerDone } = await reader.read();
        done = readerDone;
        if (value) chunks.push(value);
      }
      
      const rawEmail = new TextDecoder().decode(
        new Uint8Array(chunks.reduce((acc, chunk) => [...acc, ...chunk], []))
      );
      emailData.body = rawEmail;
    }

    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Cloudflare-Email-Worker/1.0'
      },
      body: JSON.stringify(emailData)
    });

    if (!response.ok) {
      throw new Error(`Webhook failed: ${response.status}`);
    }

    console.log('Webhook sent successfully to:', webhookUrl);
  } catch (error) {
    console.error('Error sending webhook:', error);
    throw error;
  }
}

/**
 * Store email in database
 */
async function storeEmail(message, config, env) {
  try {
    // Read the email content
    const reader = message.raw.getReader();
    const chunks = [];
    let done = false;
    
    while (!done) {
      const { value, done: readerDone } = await reader.read();
      done = readerDone;
      if (value) chunks.push(value);
    }
    
    const rawEmail = new TextDecoder().decode(
      new Uint8Array(chunks.reduce((acc, chunk) => [...acc, ...chunk], []))
    );

    const stmt = env.EMAIL_DB.prepare(`
      INSERT INTO stored_emails (
        message_id, from_address, to_address, subject,
        raw_content, received_at, config_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    
    await stmt.bind(
      message.headers.get('message-id') || crypto.randomUUID(),
      message.from,
      message.to,
      message.headers.get('subject') || '',
      rawEmail,
      new Date().toISOString(),
      config.id || null
    ).run();

    console.log('Email stored successfully');
  } catch (error) {
    console.error('Error storing email:', error);
    throw error;
  }
}

/**
 * Handle API requests
 */
async function handleApiRequest(request, env) {
  const url = new URL(request.url);
  const path = url.pathname;

  try {
    // Verify API key
    const apiKey = request.headers.get('X-API-Key');
    if (!apiKey || apiKey !== env.API_KEY) {
      return new Response('Unauthorized', { status: 401 });
    }

    if (path === '/api/emails' && request.method === 'GET') {
      return getEmails(request, env);
    }

    if (path === '/api/config' && request.method === 'GET') {
      return getConfigs(request, env);
    }

    if (path === '/api/config' && request.method === 'POST') {
      return createConfig(request, env);
    }

    if (path.startsWith('/api/config/') && request.method === 'DELETE') {
      return deleteConfig(request, env);
    }

    return new Response('Not Found', { status: 404 });
  } catch (error) {
    console.error('API error:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
}

/**
 * Get stored emails
 */
async function getEmails(request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit')) || 50;
  const offset = parseInt(url.searchParams.get('offset')) || 0;

  const stmt = env.EMAIL_DB.prepare(`
    SELECT * FROM email_logs
    ORDER BY received_at DESC
    LIMIT ? OFFSET ?
  `);

  const result = await stmt.bind(limit, offset).all();

  return new Response(JSON.stringify({
    success: true,
    emails: result.results,
    total: result.results.length
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Get email configurations
 */
async function getConfigs(request, env) {
  const configs = await env.EMAIL_CONFIG.list();
  const configData = [];

  for (const key of configs.keys) {
    const config = await env.EMAIL_CONFIG.get(key.name);
    configData.push({
      email: key.name,
      ...JSON.parse(config)
    });
  }

  return new Response(JSON.stringify({
    success: true,
    configs: configData
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Create email configuration
 */
async function createConfig(request, env) {
  const data = await request.json();
  const { email, action, ...config } = data;

  if (!email || !action) {
    return new Response(JSON.stringify({
      success: false,
      error: 'Email and action are required'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  const configData = {
    action,
    ...config,
    createdAt: new Date().toISOString(),
    id: crypto.randomUUID()
  };

  await env.EMAIL_CONFIG.put(email, JSON.stringify(configData));

  return new Response(JSON.stringify({
    success: true,
    message: 'Configuration created',
    config: configData
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Delete email configuration
 */
async function deleteConfig(request, env) {
  const url = new URL(request.url);
  const email = decodeURIComponent(url.pathname.split('/').pop());

  await env.EMAIL_CONFIG.delete(email);

  return new Response(JSON.stringify({
    success: true,
    message: 'Configuration deleted'
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Get stored emails
 */
async function getEmails(request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit')) || 50;
  const offset = parseInt(url.searchParams.get('offset')) || 0;

  const stmt = env.EMAIL_DB.prepare(`
    SELECT * FROM email_logs 
    ORDER BY received_at DESC 
    LIMIT ? OFFSET ?
  `);
  
  const result = await stmt.bind(limit, offset).all();
  
  return new Response(JSON.stringify({
    success: true,
    emails: result.results,
    total: result.results.length
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Get email configurations
 */
async function getConfigs(request, env) {
  const configs = await env.EMAIL_CONFIG.list();
  const configData = [];
  
  for (const key of configs.keys) {
    const config = await env.EMAIL_CONFIG.get(key.name);
    configData.push({
      email: key.name,
      ...JSON.parse(config)
    });
  }
  
  return new Response(JSON.stringify({
    success: true,
    configs: configData
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Create email configuration
 */
async function createConfig(request, env) {
  const data = await request.json();
  const { email, action, ...config } = data;
  
  if (!email || !action) {
    return new Response(JSON.stringify({
      success: false,
      error: 'Email and action are required'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  const configData = {
    action,
    ...config,
    createdAt: new Date().toISOString(),
    id: crypto.randomUUID()
  };
  
  await env.EMAIL_CONFIG.put(email, JSON.stringify(configData));
  
  return new Response(JSON.stringify({
    success: true,
    message: 'Configuration created',
    config: configData
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}

/**
 * Delete email configuration
 */
async function deleteConfig(request, env) {
  const url = new URL(request.url);
  const email = decodeURIComponent(url.pathname.split('/').pop());
  
  await env.EMAIL_CONFIG.delete(email);
  
  return new Response(JSON.stringify({
    success: true,
    message: 'Configuration deleted'
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}
