import EmailProcessor from '../../../lib/email/processor.js';

const processor = new EmailProcessor();

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const stats = await processor.getProcessingStats();
    res.status(200).json({
      success: true,
      status: 'running',
      ...stats,
    });
  } catch (error) {
    console.error('Status check error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
}
