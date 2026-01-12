import { google } from 'googleapis';

class GmailClient {
  constructor() {
    this.gmail = null;
    this.initializeClient();
  }

  initializeClient() {
    if (process.env.GMAIL_CLIENT_ID && process.env.GMAIL_CLIENT_SECRET) {
      const oauth2Client = new google.auth.OAuth2(
        process.env.GMAIL_CLIENT_ID,
        process.env.GMAIL_CLIENT_SECRET,
        process.env.GMAIL_REDIRECT_URI
      );
      oauth2Client.setCredentials({
        refresh_token: process.env.GMAIL_REFRESH_TOKEN,
      });
      this.gmail = google.gmail({ version: 'v1', auth: oauth2Client });
    }
  }

  async getUnreadEmails() {
    if (!this.gmail) {
      throw new Error('Gmail client not configured');
    }

    try {
      const response = await this.gmail.users.messages.list({
        userId: 'me',
        q: 'is:unread',
        maxResults: 10,
      });

      const messages = response.data.messages || [];
      const emails = [];

      for (const message of messages) {
        const email = await this.gmail.users.messages.get({
          userId: 'me',
          id: message.id,
        });

        const headers = email.data.payload.headers;
        const subject = headers.find(h => h.name === 'Subject')?.value || '';
        const from = headers.find(h => h.name === 'From')?.value || '';
        const date = headers.find(h => h.name === 'Date')?.value || '';

        let body = '';
        if (email.data.payload.body.data) {
          body = Buffer.from(email.data.payload.body.data, 'base64').toString();
        } else if (email.data.payload.parts) {
          const textPart = email.data.payload.parts.find(
            part => part.mimeType === 'text/plain'
          );
          if (textPart && textPart.body.data) {
            body = Buffer.from(textPart.body.data, 'base64').toString();
          }
        }

        emails.push({
          id: message.id,
          subject,
          from,
          date: new Date(date),
          body: body.replace(/\r?\n/g, ' ').trim(),
        });
      }

      return emails;
    } catch (error) {
      console.error('Error fetching emails:', error);
      throw error;
    }
  }

  async markAsRead(emailId) {
    if (this.gmail) {
      await this.gmail.users.messages.modify({
        userId: 'me',
        id: emailId,
        resource: {
          removeLabelIds: ['UNREAD'],
        },
      });
    }
  }
}

export default GmailClient;
