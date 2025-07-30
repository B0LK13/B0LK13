import GmailClient from './gmailClient.js';
import EmailAnalyzer from '../ai/emailAnalyzer.js';
import GitHubClient from '../github/client.js';

class EmailProcessor {
  constructor() {
    this.emailClient = new GmailClient();
    this.analyzer = new EmailAnalyzer();
    this.githubClient = new GitHubClient();
    this.processedEmails = new Set();
  }

  async processEmails() {
    try {
      console.log('Checking for new emails...');
      const emails = await this.emailClient.getUnreadEmails();
      
      if (emails.length === 0) {
        console.log('No new emails found.');
        return { processed: 0, tasksCreated: 0 };
      }

      console.log(`Found ${emails.length} unread emails.`);
      
      let processed = 0;
      let tasksCreated = 0;

      for (const email of emails) {
        if (this.processedEmails.has(email.id)) {
          continue;
        }

        console.log(`Processing email: ${email.subject}`);
        
        const analyzedEmail = await this.analyzer.analyzeEmail(email);
        
        console.log(`Email importance: ${analyzedEmail.importance}`);
        
        if (analyzedEmail.isImportant) {
          console.log('Creating GitHub task for important email...');
          
          try {
            const task = await this.githubClient.createTaskFromEmail(analyzedEmail);
            console.log(`Created GitHub issue: ${task.html_url}`);
            tasksCreated++;
          } catch (error) {
            console.error('Error creating GitHub task:', error);
          }
        }

        this.processedEmails.add(email.id);
        processed++;

        if (process.env.MARK_EMAILS_AS_READ === 'true') {
          try {
            await this.emailClient.markAsRead(email.id);
          } catch (error) {
            console.error('Error marking email as read:', error);
          }
        }
      }

      console.log(`Processed ${processed} emails, created ${tasksCreated} tasks.`);
      
      return { processed, tasksCreated };
    } catch (error) {
      console.error('Error processing emails:', error);
      throw error;
    }
  }

  async getProcessingStats() {
    return {
      processedCount: this.processedEmails.size,
      lastProcessed: new Date().toISOString(),
    };
  }
}

export default EmailProcessor;
