import { useCallback, useMemo, useState } from 'react';
import matter from 'gray-matter';

import Layout, { GradientBackground } from '../components/Layout';
import SEO from '../components/SEO';

function renderAssistantBlocks(text = '') {
  const blocks = text.trim().split(/\n{2,}/).filter(Boolean);
  if (!blocks.length) {
    return null;
  }

  return blocks.map((block, index) => {
    const lines = block.split('\n').filter(Boolean);
    const isList =
      lines.length > 1 && lines.every((line) => /^[-*]\s+/.test(line.trim()));

    if (isList) {
      return (
        <ul
          key={`assistant-block-${index}`}
          className="list-disc list-inside space-y-1 text-sm leading-relaxed"
        >
          {lines.map((line, lineIndex) => (
            <li key={`assistant-block-${index}-${lineIndex}`}>
              {line.replace(/^[-*]\s+/, '').trim()}
            </li>
          ))}
        </ul>
      );
    }

    return (
      <p
        key={`assistant-block-${index}`}
        className="text-sm leading-relaxed whitespace-pre-wrap"
      >
        {block.replace(/^[-*]\s+/, '').trim()}
      </p>
    );
  });
}

function extractTitle(content = '', fallback) {
  const headingMatch = content.match(/^#\s+(.*)$/m);
  if (headingMatch) {
    return headingMatch[1].trim();
  }
  return fallback;
}

function summarizeContent(content = '') {
  const cleaned = content.replace(/```[\s\S]*?```/g, '').trim();
  const paragraphs = cleaned.split(/\n{2,}/).filter(Boolean);
  const snippet = paragraphs.slice(0, 2).join(' ').trim();
  return snippet.length > 400 ? `${snippet.slice(0, 400)}…` : snippet;
}

function generateLocalTags(frontMatterTags, content = '') {
  const tags = new Set();
  if (Array.isArray(frontMatterTags)) {
    frontMatterTags.filter(Boolean).forEach((tag) => tags.add(String(tag).trim()));
  }

  const keywordCounts = {};
  const words = content
    .toLowerCase()
    .replace(/[^a-z0-9\s]/gi, ' ')
    .split(/\s+/)
    .filter((word) => word.length > 4);

  words.forEach((word) => {
    keywordCounts[word] = (keywordCounts[word] || 0) + 1;
  });

  const sortedKeywords = Object.entries(keywordCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([word]) => word);

  sortedKeywords.forEach((keyword) => tags.add(keyword));

  return Array.from(tags).slice(0, 12);
}

function createChunks(doc, chunkSize = 1200) {
  const sections = doc.content.split(/\n{2,}/).filter(Boolean);
  const chunks = [];
  let buffer = '';
  let index = 0;

  sections.forEach((section) => {
    if ((buffer + '\n\n' + section).length > chunkSize) {
      if (buffer.trim()) {
        chunks.push({
          id: `${doc.id}-chunk-${index}`,
          content: buffer.trim(),
          docTitle: doc.title,
          docPath: doc.path,
          docSummary: doc.summary,
        });
        index += 1;
      }
      buffer = section;
    } else {
      buffer = buffer ? `${buffer}\n\n${section}` : section;
    }
  });

  if (buffer.trim()) {
    chunks.push({
      id: `${doc.id}-chunk-${index}`,
      content: buffer.trim(),
      docTitle: doc.title,
      docPath: doc.path,
      docSummary: doc.summary,
    });
  }

  return chunks;
}

function formatFileSize(bytes) {
  if (!bytes) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  const size = bytes / Math.pow(1024, index);
  return `${size.toFixed(size >= 10 ? 0 : 1)} ${units[index]}`;
}

export default function RAGWorkbench() {
  const [documents, setDocuments] = useState([]);
  const [chunks, setChunks] = useState([]);
  const [datasetError, setDatasetError] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const [suggestions, setSuggestions] = useState(null);
  const [suggestionsError, setSuggestionsError] = useState('');
  const [loadingSuggestions, setLoadingSuggestions] = useState(false);

  const [messages, setMessages] = useState([]);
  const [question, setQuestion] = useState('');
  const [isAsking, setIsAsking] = useState(false);
  const [chatError, setChatError] = useState('');

  const totalSize = useMemo(
    () => documents.reduce((sum, doc) => sum + (doc.size || 0), 0),
    [documents]
  );

  const tagFrequency = useMemo(() => {
    const frequency = {};
    documents.forEach((doc) => {
      doc.tags.forEach((tag) => {
        frequency[tag] = (frequency[tag] || 0) + 1;
      });
    });

    return Object.entries(frequency)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 12);
  }, [documents]);

  const handleFolderSelection = useCallback(async (event) => {
    const fileList = event.target.files;
    if (!fileList?.length) {
      setDocuments([]);
      setChunks([]);
      return;
    }

    setDatasetError('');
    setSuggestions(null);
    setSuggestionsError('');
    setMessages([]);
    setChatError('');

    setIsProcessing(true);
    try {
      const markdownFiles = Array.from(fileList).filter((file) =>
        /\.mdx?$/i.test(file.name)
      );

      if (!markdownFiles.length) {
        setDocuments([]);
        setChunks([]);
        setDatasetError('No Markdown files were found in the selected folder.');
        return;
      }

      const loadedDocs = await Promise.all(
        markdownFiles.map(async (file, index) => {
          const rawContent = await file.text();
          const parsed = matter(rawContent);
          const cleanContent = parsed.content.trim();
          const path = file.webkitRelativePath || file.name;
          const title = extractTitle(cleanContent, file.name.replace(/\.mdx?$/i, ''));
          const summary = summarizeContent(cleanContent);
          const tags = generateLocalTags(parsed.data?.tags, cleanContent);

          return {
            id: `${index}-${path}`,
            title,
            path,
            summary,
            content: cleanContent,
            tags,
            size: file.size,
          };
        })
      );

      const chunkList = loadedDocs.flatMap((doc) => createChunks(doc));

      setDocuments(loadedDocs);
      setChunks(chunkList);
      event.target.value = '';

      setLoadingSuggestions(true);
      try {
        const response = await fetch('/api/rag/suggestions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            documents: loadedDocs.map((doc) => ({
              title: doc.title,
              path: doc.path,
              summary: doc.summary,
              tags: doc.tags,
            })),
          }),
        });

        if (!response.ok) {
          const message = await response.json().catch(() => ({}));
          throw new Error(message?.error || 'Unable to generate suggestions.');
        }

        const payload = await response.json();
        setSuggestions(payload);
      } catch (error) {
        setSuggestionsError(error.message);
      } finally {
        setLoadingSuggestions(false);
      }
    } catch (error) {
      setDatasetError(error.message || 'Failed to process folder.');
    } finally {
      setIsProcessing(false);
    }
  }, []);

  const handleAskQuestion = useCallback(
    async (event) => {
      event.preventDefault();
      if (!question.trim()) {
        return;
      }
      if (!chunks.length) {
        setChatError('Load a Markdown knowledge set before starting the chat.');
        return;
      }

      const message = question.trim();
      setMessages((prev) => [...prev, { role: 'user', content: message }]);
      setQuestion('');
      setChatError('');
      setIsAsking(true);

      try {
        const response = await fetch('/api/rag/query', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            question: message,
            chunks: chunks.map((chunk) => ({
              id: chunk.id,
              content: chunk.content,
              docTitle: chunk.docTitle,
              docPath: chunk.docPath,
              docSummary: chunk.docSummary,
            })),
          }),
        });

        if (!response.ok) {
          const message = await response.json().catch(() => ({}));
          throw new Error(message?.error || 'The assistant was unable to respond.');
        }

        const payload = await response.json();
        setMessages((prev) => [
          ...prev,
          {
            role: 'assistant',
            content: payload.answer,
            followUps: payload.followUps,
            sources: payload.sources,
            documents: payload.documents,
          },
        ]);
      } catch (error) {
        setChatError(error.message);
      } finally {
        setIsAsking(false);
      }
    },
    [question, chunks]
  );

  const handleFollowUpSeed = useCallback((followUp) => {
    setQuestion(followUp);
  }, []);

  return (
    <Layout>
      <SEO
        title="RAG Knowledge Workbench"
        description="Build an intelligent Markdown knowledge base with autotagging insights and a retrieval-augmented chat assistant."
      />
      <main className="relative w-full px-6 py-16 space-y-12">
        <header className="text-center space-y-4">
          <h1 className="text-4xl font-bold tracking-tight text-gray-900 dark:text-white">
            RAG Knowledge Workbench
          </h1>
          <p className="max-w-2xl mx-auto text-lg text-gray-600 dark:text-gray-200">
            Load a folder of Markdown notes, receive intelligent suggestions for structuring your
            knowledge base, and interrogate the content with a retrieval-augmented chat assistant that
            cites its sources and proposes next steps.
          </p>
        </header>

        <section className="p-6 space-y-4 bg-white/70 dark:bg-black/40 backdrop-blur rounded-2xl shadow-xl border border-white/20">
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
                1. Assemble your dataset
              </h2>
              <p className="text-gray-600 dark:text-gray-200">
                Select a local folder that contains Markdown files. The content never leaves your browser
                except for anonymised snippets sent to the OpenAI API for suggestions and chat responses.
              </p>
            </div>
            <label className="inline-flex items-center px-5 py-3 text-sm font-medium text-white bg-primary rounded-full cursor-pointer hover:opacity-90">
              <input
                type="file"
                webkitdirectory="true"
                directory="true"
                multiple
                accept=".md,.mdx"
                onChange={handleFolderSelection}
                className="hidden"
              />
              Choose folder
            </label>
          </div>
          {isProcessing && (
            <p className="text-sm text-primary">Processing Markdown files…</p>
          )}
          {datasetError && (
            <p className="text-sm text-red-500">{datasetError}</p>
          )}
          {documents.length > 0 && (
            <dl className="grid gap-4 sm:grid-cols-3 text-sm text-gray-700 dark:text-gray-200">
              <div className="p-4 rounded-xl bg-white/60 dark:bg-white/10 border border-white/30">
                <dt className="font-semibold uppercase tracking-wide text-xs opacity-70">Documents</dt>
                <dd className="mt-1 text-xl font-semibold">{documents.length}</dd>
              </div>
              <div className="p-4 rounded-xl bg-white/60 dark:bg-white/10 border border-white/30">
                <dt className="font-semibold uppercase tracking-wide text-xs opacity-70">Knowledge chunks</dt>
                <dd className="mt-1 text-xl font-semibold">{chunks.length}</dd>
              </div>
              <div className="p-4 rounded-xl bg-white/60 dark:bg-white/10 border border-white/30">
                <dt className="font-semibold uppercase tracking-wide text-xs opacity-70">Dataset size</dt>
                <dd className="mt-1 text-xl font-semibold">{formatFileSize(totalSize)}</dd>
              </div>
            </dl>
          )}
        </section>

        {documents.length > 0 && (
          <section className="p-6 space-y-6 bg-white/70 dark:bg-black/40 backdrop-blur rounded-2xl shadow-xl border border-white/20">
            <div className="space-y-2">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
                2. Blueprint smart organisation
              </h2>
              <p className="text-gray-600 dark:text-gray-200">
                The assistant analyses file summaries and suggested tags to surface opportunities for
                better metadata, relationships, and governance.
              </p>
            </div>
            {loadingSuggestions && (
              <p className="text-sm text-primary">Generating structural recommendations…</p>
            )}
            {suggestionsError && (
              <p className="text-sm text-red-500">{suggestionsError}</p>
            )}
            {suggestions && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Knowledge base overview</h3>
                  <p className="mt-2 text-gray-700 dark:text-gray-200 whitespace-pre-line">
                    {suggestions.overview}
                  </p>
                </div>
                {suggestions.autoTaggingIdeas?.length > 0 && (
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Autotagging strategies</h3>
                    <ul className="mt-2 space-y-2 text-gray-700 dark:text-gray-200 list-disc list-inside">
                      {suggestions.autoTaggingIdeas.map((idea, index) => (
                        <li key={index}>{idea}</li>
                      ))}
                    </ul>
                  </div>
                )}
                {suggestions.databaseDesignTips?.length > 0 && (
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Smart database upgrades</h3>
                    <ul className="mt-2 space-y-2 text-gray-700 dark:text-gray-200 list-disc list-inside">
                      {suggestions.databaseDesignTips.map((tip, index) => (
                        <li key={index}>{tip}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            )}
            {tagFrequency.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Tag spotlight</h3>
                <div className="mt-3 flex flex-wrap gap-3">
                  {tagFrequency.map(([tag, count]) => (
                    <span
                      key={tag}
                      className="px-3 py-1 text-sm rounded-full bg-primary/10 text-primary border border-primary/20"
                    >
                      {tag} · {count}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </section>
        )}

        {documents.length > 0 && (
          <section className="p-6 space-y-6 bg-white/70 dark:bg-black/40 backdrop-blur rounded-2xl shadow-xl border border-white/20">
            <div className="space-y-2">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
                3. Explore your Markdown universe
              </h2>
              <p className="text-gray-600 dark:text-gray-200">
                Review extracted summaries and suggested metadata before opening the conversational
                workspace.
              </p>
            </div>
            <div className="space-y-4 max-h-96 overflow-y-auto pr-1">
              {documents.map((doc) => (
                <article
                  key={doc.id}
                  className="p-4 border border-white/30 rounded-xl bg-white/60 dark:bg-white/10"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{doc.title}</h3>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{doc.path}</p>
                    </div>
                    <span className="text-xs px-2 py-1 rounded-full bg-primary/10 text-primary border border-primary/20">
                      {formatFileSize(doc.size)}
                    </span>
                  </div>
                  <p className="mt-3 text-sm text-gray-700 dark:text-gray-200">{doc.summary}</p>
                  {doc.tags.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-3">
                      {doc.tags.map((tag) => (
                        <span
                          key={tag}
                          className="px-2 py-1 text-xs rounded-full bg-gray-900/10 dark:bg-white/10 text-gray-700 dark:text-gray-200"
                        >
                          #{tag}
                        </span>
                      ))}
                    </div>
                  )}
                </article>
              ))}
            </div>
          </section>
        )}

        <section className="p-6 space-y-6 bg-white/80 dark:bg-black/50 backdrop-blur rounded-2xl shadow-xl border border-white/20">
          <div className="space-y-2">
            <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
              4. Interrogate the knowledge graph
            </h2>
            <p className="text-gray-600 dark:text-gray-200">
              Ask detailed questions and receive sourced answers. The assistant proposes thoughtful
              follow-up prompts so you can keep digging.
            </p>
          </div>

          <div className="space-y-4">
            <div className="space-y-3 max-h-96 overflow-y-auto pr-1">
              {messages.length === 0 && (
                <div className="p-6 text-sm text-gray-600 dark:text-gray-300 bg-white/60 dark:bg-white/5 border border-dashed border-white/40 rounded-xl">
                  Load your Markdown notes and ask a question to start the conversation.
                </div>
              )}
              {messages.map((message, index) => (
                <div
                  key={index}
                  className={`rounded-xl p-4 border ${
                    message.role === 'user'
                      ? 'bg-primary text-white border-primary/40'
                      : 'bg-white/70 dark:bg-white/10 border-white/30 text-gray-900 dark:text-gray-100'
                  }`}
                >
                  <div className="text-xs uppercase tracking-wide opacity-70 mb-2">
                    {message.role === 'user' ? 'You' : 'RAG assistant'}
                  </div>
                  {message.role === 'assistant' ? (
                    <div className="space-y-2 text-gray-900 dark:text-gray-100">
                      {renderAssistantBlocks(message.content)}
                    </div>
                  ) : (
                    <p className="text-sm leading-relaxed whitespace-pre-line">{message.content}</p>
                  )}

                  {message.role === 'assistant' && message.followUps?.length > 0 && (
                    <div className="mt-4">
                      <h4 className="text-xs font-semibold uppercase tracking-wide opacity-70">
                        Follow-up ideas
                      </h4>
                      <div className="mt-2 flex flex-wrap gap-2">
                        {message.followUps.map((followUp, followUpIndex) => (
                          <button
                            key={followUpIndex}
                            type="button"
                            onClick={() => handleFollowUpSeed(followUp)}
                            className="px-3 py-1 text-xs font-medium rounded-full bg-primary/10 text-primary border border-primary/20 hover:bg-primary/20"
                          >
                            {followUp}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                  {message.role === 'assistant' && message.documents?.length > 0 && (
                    <div className="mt-4 space-y-2">
                      <h4 className="text-xs font-semibold uppercase tracking-wide opacity-70">
                        High-signal excerpts
                      </h4>
                      <div className="space-y-2">
                        {message.documents.map((document, documentIndex) => (
                          <div
                            key={documentIndex}
                            className="p-3 border border-white/30 rounded-lg bg-white/60 dark:bg-white/5"
                          >
                            <p className="text-xs font-semibold text-primary dark:text-primary/80">
                              {document.title}
                              {document.path ? (
                                <span className="opacity-70"> · {document.path}</span>
                              ) : null}
                            </p>
                            <p className="mt-1 text-xs text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
                              {document.preview}
                            </p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {message.role === 'assistant' && message.sources?.length > 0 && (
                    <div className="mt-4 space-y-1">
                      <h4 className="text-xs font-semibold uppercase tracking-wide opacity-70">
                        Sources consulted
                      </h4>
                      <ul className="text-xs text-gray-700 dark:text-gray-300 space-y-1 list-disc list-inside">
                        {message.sources.map((source, sourceIndex) => (
                          <li key={sourceIndex}>
                            {source.path ? (
                              <span>
                                <span className="font-medium">{source.title}</span>
                                <span className="opacity-70"> · {source.path}</span>
                              </span>
                            ) : (
                              <span>{source.title}</span>
                            )}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              ))}
            </div>

            <form onSubmit={handleAskQuestion} className="space-y-3">
              <textarea
                value={question}
                onChange={(event) => setQuestion(event.target.value)}
                rows={3}
                placeholder="Ask for project history, capture architecture dependencies, or request synthesis across files…"
                className="w-full px-4 py-3 text-sm border border-white/40 rounded-xl bg-white/60 dark:bg-white/10 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/50"
              />
              {chatError && <p className="text-sm text-red-500">{chatError}</p>}
              <div className="flex items-center justify-between gap-4">
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  Responses leverage OpenAI embeddings and a GPT model; set the <code>OPENAI_API_KEY</code>
                  environment variable in your deployment.
                </p>
                <button
                  type="submit"
                  disabled={isAsking}
                  className="inline-flex items-center px-4 py-2 text-sm font-semibold rounded-full bg-primary text-white hover:opacity-90 disabled:opacity-50"
                >
                  {isAsking ? 'Thinking…' : 'Send question'}
                </button>
              </div>
            </form>
          </div>
        </section>
      </main>
      <GradientBackground variant="large" className="fixed top-20 left-1/2 -translate-x-1/2 opacity-40 dark:opacity-60" />
      <GradientBackground variant="small" className="fixed bottom-0 left-0 opacity-20 dark:opacity-10" />
    </Layout>
  );
}
