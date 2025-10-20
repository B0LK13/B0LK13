import OpenAI from 'openai';

const CHAT_MODEL = 'gpt-4.1-mini';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export default async function handler(request, response) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'POST');
    return response.status(405).json({ error: 'Method not allowed.' });
  }

  if (!process.env.OPENAI_API_KEY) {
    return response.status(500).json({ error: 'OPENAI_API_KEY is not configured.' });
  }

  const { documents } = request.body || {};

  if (!documents?.length) {
    return response.status(400).json({ error: 'Documents are required to build suggestions.' });
  }

  const documentDigest = documents
    .map(
      (doc, index) =>
        `Document ${index + 1}: ${doc.title}\nPath: ${doc.path}\nTags: ${doc.tags?.join(', ') || 'None'}\nSummary: ${doc.summary}`
    )
    .join('\n\n');

  try {
    const completion = await openai.chat.completions.create({
      model: CHAT_MODEL,
      temperature: 0.4,
      messages: [
        {
          role: 'system',
          content:
            'You are an information architect tasked with transforming a Markdown knowledge base into a searchable, insight-rich repository. Suggest metadata, automation, and database enhancements.',
        },
        {
          role: 'user',
          content: `Analyse the following Markdown collection and respond with JSON containing the keys "overview" (string), "autoTaggingIdeas" (array of strings), and "databaseDesignTips" (array of strings).\n\n${documentDigest}`,
        },
      ],
      max_tokens: 600,
    });

    const rawText = completion.choices?.[0]?.message?.content?.trim();
    if (!rawText) {
      throw new Error('Suggestion generation failed.');
    }

    let parsed;
    try {
      parsed = JSON.parse(rawText);
    } catch (parseError) {
      parsed = {
        overview: rawText,
        autoTaggingIdeas: [],
        databaseDesignTips: [],
      };
    }

    return response.status(200).json({
      overview: parsed.overview || 'No overview available.',
      autoTaggingIdeas: Array.isArray(parsed.autoTaggingIdeas)
        ? parsed.autoTaggingIdeas.filter(Boolean)
        : [],
      databaseDesignTips: Array.isArray(parsed.databaseDesignTips)
        ? parsed.databaseDesignTips.filter(Boolean)
        : [],
    });
  } catch (error) {
    console.error('Suggestion generation failed:', error);
    return response.status(500).json({
      error: error.message || 'Unable to create knowledge base suggestions.',
    });
  }
}
