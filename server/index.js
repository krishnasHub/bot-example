import express from 'express';
import cors from 'cors';
import Anthropic from '@anthropic-ai/sdk';
import dotenv from 'dotenv';
import { getPublicBotInfo, getBotById, bots } from './bots.js';
import { searchImage } from './imageSearch.js';

dotenv.config();

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

const IMAGE_SEARCH_TOOL = {
  name: 'search_image',
  description: 'Search for a relevant image to share in the chat. When this tool returns a URL, include it verbatim in your response text — it will be automatically displayed as an image.',
  input_schema: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Descriptive search query, e.g. "golden sunset mountains" or "excited jumping person"'
      }
    },
    required: ['query']
  }
};

const imageSearchEnabled = () =>
  process.env.PEXELS_API_KEY && !process.env.PEXELS_API_KEY.startsWith('your_');

// GET /api/bots - returns public bot info
app.get('/api/bots', (req, res) => {
  res.json(getPublicBotInfo());
});

// POST /api/chat - generate a response for a specific bot
app.post('/api/chat', async (req, res) => {
  try {
    const { messages, botId } = req.body;
    const bot = getBotById(botId);

    if (!bot) {
      return res.status(400).json({ error: 'Invalid bot ID' });
    }

    let transcript;
    if (!messages || messages.length === 0) {
      transcript = '(The group chat just started. Say something to kick off the conversation!)';
    } else {
      transcript = messages.map(msg => {
        const speaker = msg.isUser ? 'Human' : msg.botName;
        return `[${speaker}]: ${msg.text}`;
      }).join('\n');
      transcript += `\n\n(Now respond as ${bot.name}.)`;
    }

    const tools = imageSearchEnabled() ? [IMAGE_SEARCH_TOOL] : [];
    const userMessages = [{ role: 'user', content: transcript }];

    const response = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 512,
      system: bot.systemPrompt,
      ...(tools.length && { tools }),
      messages: userMessages
    });

    let text;

    if (response.stop_reason === 'tool_use') {
      const toolUse = response.content.find(b => b.type === 'tool_use');
      const imageUrl = await searchImage(toolUse.input.query);

      const toolResult = imageUrl
        ? `Image found: ${imageUrl} — include this URL verbatim in your response.`
        : 'No image found for that query.';

      const finalResponse = await anthropic.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 512,
        system: bot.systemPrompt,
        tools,
        messages: [
          ...userMessages,
          { role: 'assistant', content: response.content },
          { role: 'user', content: [{ type: 'tool_result', tool_use_id: toolUse.id, content: toolResult }] }
        ]
      });

      text = finalResponse.content.find(b => b.type === 'text')?.text ?? '';
    } else {
      text = response.content.find(b => b.type === 'text')?.text ?? '';
    }

    res.json({ text, botId });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ error: 'Failed to generate response' });
  }
});

// POST /api/chat/next-speaker - pick the next bot to speak
app.post('/api/chat/next-speaker', (req, res) => {
  const { messages } = req.body;

  let lastBotId = null;
  if (messages && messages.length > 0) {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isUser && messages[i].botId) {
        lastBotId = messages[i].botId;
        break;
      }
    }
  }

  const availableBots = bots.filter(bot => bot.id !== lastBotId);
  const nextBot = availableBots[Math.floor(Math.random() * availableBots.length)];

  res.json({ botId: nextBot.id });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  if (imageSearchEnabled()) {
    console.log('Image search enabled (Pexels)');
  }
});
