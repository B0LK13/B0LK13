const fs = require('fs');

/**
 * Save an array of conversations as a Markdown file.
 * Each conversation is rendered with a level 1 heading for the title
 * followed by level 2 headings for each message author and the message text.
 *
 * @param {string} filename - The path where the Markdown file will be saved.
 * @param {Array<Object>} conversations - The conversations to save.
 *        Each object should have a `title` and a `messages` array with
 *        items of the form `{ author: string, text: string }`.
 */
function saveConversations(filename, conversations) {
  let mdContent = '';

  conversations.forEach((conversation) => {
    mdContent += `# ${conversation.title}\n\n`;

    conversation.messages.forEach((msg) => {
      mdContent += `## ${msg.author}\n`;
      mdContent += `${msg.text}\n\n`;
    });
  });

  fs.writeFileSync(filename, mdContent, 'utf8');
}

// Example usage
if (require.main === module) {
  const data = [
    {
      title: 'Demo-Gesprek 1',
      messages: [
        { author: 'Gebruiker', text: 'Hallo!' },
        { author: 'Bot', text: 'Hi, hoe kan ik je helpen?' }
      ]
    },
    {
      title: 'Demo-Gesprek 2',
      messages: [
        { author: 'Gebruiker', text: 'Wat is het weer vandaag?' },
        { author: 'Bot', text: 'Het wordt zonnig met 23°C.' }
      ]
    }
  ];

  saveConversations('gesprekken.md', data);
  console.log('Conversaties opgeslagen in gesprekken.md');
}

module.exports = saveConversations;
