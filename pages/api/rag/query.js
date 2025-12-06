import OpenAI from 'openai';

const EMBEDDING_MODEL = 'text-embedding-3-small';
const CHAT_MODEL = 'gpt-4.1-mini';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

function cosineSimilarity(a, b) {
  const minLength = Math.min(a.length, b.length);
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let index = 0; index < minLength; index += 1) {
    dotProduct += a[index] * b[index];
    normA += a[index] * a[index];
    normB += b[index] * b[index];
  }

  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB) || 1);
}

function parseFollowUps(text) {
  const match = text.match(/Follow-up questions:\s*([\s\S]*?)(?:\n\s*Sources:|$)/i);
  if (!match) {
    return [];
  }

  return match[1]
    .split('\n')
    .map((line) => line.replace(/^[-*\d.\s]+/, '').trim())
    .filter(Boolean);
}

function parseSources(text, fallback) {
  const match = text.match(/Sources:\s*([\s\S]*)$/i);
  if (!match) {
    return fallback;
  }

  const lines = match[1]
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);

  if (!lines.length) {
    return fallback;
  }

  const parsed = lines.map((line) => {
    const cleaned = line.replace(/^[-*\d.\s]+/, '').trim();
    const linkMatch = cleaned.match(/\[([^\]]+)\]\(([^)]+)\)/);
    if (linkMatch) {
      return { title: linkMatch[1], path: linkMatch[2] };
    }

    const fallbackMatch = fallback.find((source) =>
      source.title === cleaned || cleaned.includes(source.title)
    );
    if (fallbackMatch) {
      return fallbackMatch;
    }

    return { title: cleaned };
  });

  return parsed.length ? parsed : fallback;
}

function cleanAnswer(text) {
  const withoutFollowUps = text.replace(/Follow-up questions:[\s\S]*/i, '').trim();
  const withoutSources = withoutFollowUps.replace(/Sources:[\s\S]*/i, '').trim();
  return withoutSources.replace(/^Answer:\s*/i, '').trim();
}

export default async function handler(request, response) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'POST');
    return response.status(405).json({ error: 'Method not allowed.' });
  }

  if (!process.env.OPENAI_API_KEY) {
    return response.status(500).json({ error: 'OPENAI_API_KEY is not configured.' });
  }

  const { question, chunks } = request.body || {};

  if (!question || !chunks?.length) {
    return response.status(400).json({ error: 'Question and knowledge chunks are required.' });
  }

  try {
    const limitedChunks = chunks.slice(0, 50);

    const questionEmbeddingResult = await openai.embeddings.create({
      model: EMBEDDING_MODEL,
      input: question,
    });
    const questionEmbedding = questionEmbeddingResult.data[0].embedding;

    const chunkEmbeddings = [];
    for (const chunk of limitedChunks) {
      const embeddingResult = await openai.embeddings.create({
        model: EMBEDDING_MODEL,
        input: chunk.content.slice(0, 2000),
      });
      chunkEmbeddings.push({
        ...chunk,
        embedding: embeddingResult.data[0].embedding,
      });
    }

    const rankedChunks = chunkEmbeddings
      .map((chunk) => ({
        ...chunk,
        similarity: cosineSimilarity(chunk.embedding, questionEmbedding),
      }))
      .sort((a, b) => b.similarity - a.similarity);

    const topChunks = rankedChunks.slice(0, 5);

    const context = topChunks
      .map(
        (chunk, index) =>
          `Source ${index + 1}: ${chunk.docTitle} (${chunk.docPath})\n${chunk.content}`
      )
      .join('\n\n');

    const completion = await openai.chat.completions.create({
      model: CHAT_MODEL,
      temperature: 0.3,
      messages: [
        {
          role: 'system',
          content:
            'You are a meticulous retrieval-augmented research assistant. Use only the supplied source material to answer the question. Provide detailed synthesis, note any gaps, and always recommend at least two thoughtful follow-up questions. Reference sources by name. Format the response using the requested sections.',
        },
        {
          role: 'user',
          content: `Question: ${question}\n\nAvailable sources:\n${context}\n\nRespond using the following structure:\nAnswer:\n<detailed response>\n\nFollow-up questions:\n- question one\n- question two\n\nSources:\n- [Source title](source path)`,
        },
      ],
      max_tokens: 800,
    });

    const answerText = completion.choices?.[0]?.message?.content?.trim();

    if (!answerText) {
      throw new Error('The assistant returned an empty response.');
    }

    const fallbackSources = topChunks.map((chunk) => ({
      title: chunk.docTitle,
      path: chunk.docPath,
      preview: chunk.content.slice(0, 240),
      similarity: chunk.similarity,
    }));

    const structuredResponse = {
      answer: cleanAnswer(answerText),
      followUps: parseFollowUps(answerText),
      sources: parseSources(answerText, fallbackSources),
      documents: fallbackSources,
    };

    return response.status(200).json(structuredResponse);
  } catch (error) {
    console.error('RAG query failed:', error);
    return response.status(500).json({
      error: error.message || 'Failed to process the RAG query.',
    });
  }
}
