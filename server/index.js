import express from 'express';
import cors from 'cors';
import Anthropic from '@anthropic-ai/sdk';
import dotenv from 'dotenv';
import { getPublicBotInfo, getBotById, bots } from './bots.js';

dotenv.config();

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
});

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

    // Format conversation history as a transcript
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

    const response = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 256,
      system: bot.systemPrompt,
      messages: [
        { role: 'user', content: transcript }
      ]
    });

    const text = response.content[0].text;
    res.json({ text, botId });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ error: 'Failed to generate response' });
  }
});

// POST /api/chat/next-speaker - pick the next bot to speak
app.post('/api/chat/next-speaker', (req, res) => {
  const { messages } = req.body;

  // Find the last bot that spoke (if any)
  let lastBotId = null;
  if (messages && messages.length > 0) {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isUser && messages[i].botId) {
        lastBotId = messages[i].botId;
        break;
      }
    }
  }

  // Filter out the last speaker and pick randomly
  const availableBots = bots.filter(bot => bot.id !== lastBotId);
  const nextBot = availableBots[Math.floor(Math.random() * availableBots.length)];

  res.json({ botId: nextBot.id });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
