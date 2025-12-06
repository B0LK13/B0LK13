export default async function handler(req, res) {
  if (req.method === 'GET') {
    const config = {
      emailService: process.env.EMAIL_SERVICE || 'gmail',
      checkInterval: process.env.EMAIL_CHECK_INTERVAL || 300000,
      importanceThreshold: parseFloat(process.env.IMPORTANCE_THRESHOLD || 0.7),
      markAsRead: process.env.MARK_EMAILS_AS_READ === 'true',
      githubUsername: process.env.GITHUB_USERNAME,
      projectId: process.env.GITHUB_PROJECT_ID,
    };

    res.status(200).json({ success: true, config });
  } else if (req.method === 'POST') {
    const { importanceThreshold, markAsRead } = req.body;

    if (importanceThreshold && (importanceThreshold < 0 || importanceThreshold > 1)) {
      return res.status(400).json({ 
        success: false, 
        error: 'Importance threshold must be between 0 and 1' 
      });
    }

    res.status(200).json({
      success: true,
      message: 'Configuration updated successfully',
      updated: {
        importanceThreshold,
        markAsRead,
      },
    });
  } else {
    res.status(405).json({ error: 'Method not allowed' });
  }
}
