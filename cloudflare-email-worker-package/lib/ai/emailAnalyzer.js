import OpenAI from 'openai';

class EmailAnalyzer {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }

  async analyzeImportance(email) {
    const { subject, from, body } = email;
    const prompt = `Analyze this email and rate its importance on a scale of 0.0 to 1.0. From: ${from}, Subject: ${subject}, Body: ${body.substring(0, 500)}. Respond with only a number between 0.0 and 1.0.`;

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 10,
        temperature: 0.1,
      });
      const importance = parseFloat(response.choices[0].message.content.trim());
      return isNaN(importance) ? 0.5 : Math.max(0, Math.min(1, importance));
    } catch (error) {
      console.error('Error analyzing email importance:', error);
      return 0.5;
    }
  }

  async extractTasks(email) {
    const { subject, body } = email;
    const prompt = `Extract actionable tasks from this email. Return only the tasks as a JSON array of strings. Email Subject: ${subject}, Email Body: ${body}. Return format: ["task 1", "task 2"]`;

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 200,
        temperature: 0.2,
      });
      const content = response.choices[0].message.content.trim();
      const tasks = JSON.parse(content);
      return Array.isArray(tasks) ? tasks : [];
    } catch (error) {
      console.error('Error extracting tasks:', error);
      return [`Review and respond to email: ${subject}`];
    }
  }

  async analyzeEmail(email) {
    const [importance, extractedTasks] = await Promise.all([
      this.analyzeImportance(email),
      this.extractTasks(email),
    ]);

    return {
      ...email,
      importance,
      extractedTasks,
      isImportant: importance >= (process.env.IMPORTANCE_THRESHOLD || 0.7),
    };
  }
}

export default EmailAnalyzer;
