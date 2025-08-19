import { Octokit } from '@octokit/rest';

class GitHubClient {
  constructor() {
    this.octokit = new Octokit({
      auth: process.env.GITHUB_TOKEN,
    });
    this.username = process.env.GITHUB_USERNAME;
    this.projectId = process.env.GITHUB_PROJECT_ID;
  }

  async createIssue(title, body, labels = ['email-task']) {
    try {
      const response = await this.octokit.rest.issues.create({
        owner: this.username,
        repo: 'B0LK13',
        title,
        body,
        labels,
      });
      return response.data;
    } catch (error) {
      console.error('Error creating GitHub issue:', error);
      throw error;
    }
  }

  async createTaskFromEmail(emailData) {
    const { subject, from, body, importance, extractedTasks } = emailData;
    const issueTitle = `Email Task: ${subject}`;
    const issueBody = `
## Email Details
- **From:** ${from}
- **Subject:** ${subject}
- **Importance Score:** ${importance}
- **Received:** ${new Date().toISOString()}

## Extracted Tasks
${extractedTasks.map(task => `- [ ] ${task}`).join('\n')}

## Original Email Content
${body.substring(0, 1000)}${body.length > 1000 ? '...' : ''}

---
*This task was automatically created by the Email Agent*
    `;
    return await this.createIssue(issueTitle, issueBody);
  }
}

export default GitHubClient;
