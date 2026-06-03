import { useState, useEffect, useRef, useCallback } from 'react';

const IMAGE_REGEX = /https?:\/\/[^\s]+\.(?:jpg|jpeg|png|gif|webp|svg|bmp|avif)(?:\?[^\s]*)?/gi;

const parseMessageParts = (text) => {
  const imageUrls = [];
  const remaining = text
    .replace(new RegExp(IMAGE_REGEX.source, 'gi'), (url) => {
      imageUrls.push(url);
      return '';
    })
    .replace(/\s+/g, ' ')
    .trim();
  return { text: remaining, imageUrls };
};

const CopyButton = ({ text }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const el = document.createElement('textarea');
      el.value = text;
      document.body.appendChild(el);
      el.select();
      document.execCommand('copy');
      document.body.removeChild(el);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button className={`copy-btn${copied ? ' copied' : ''}`} onClick={handleCopy}>
      {copied ? 'Copied!' : 'Copy'}
    </button>
  );
};

const ChatImage = ({ src }) => {
  const [orientation, setOrientation] = useState(null);

  return (
    <a href={src} target="_blank" rel="noopener noreferrer">
      <img
        src={src}
        alt="shared image"
        className={`chat-image${orientation ? ` chat-image--${orientation}` : ''}`}
        onLoad={(e) => {
          const { naturalWidth, naturalHeight } = e.target;
          setOrientation(naturalWidth >= naturalHeight ? 'landscape' : 'portrait');
        }}
      />
    </a>
  );
};

function App() {
  const [bots, setBots] = useState([]);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isRunning, setIsRunning] = useState(true);
  const [isTyping, setIsTyping] = useState(false);
  const [typingBot, setTypingBot] = useState(null);
  const [failCount, setFailCount] = useState(0);

  const messagesEndRef = useRef(null);
  const isRunningRef = useRef(isRunning);
  const messagesRef = useRef(messages);
  const failCountRef = useRef(failCount);

  // Keep refs in sync
  useEffect(() => {
    isRunningRef.current = isRunning;
  }, [isRunning]);

  useEffect(() => {
    messagesRef.current = messages;
  }, [messages]);

  useEffect(() => {
    failCountRef.current = failCount;
  }, [failCount]);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isTyping]);

  // Fetch bots on mount
  useEffect(() => {
    fetch('/api/bots')
      .then(res => res.json())
      .then(setBots)
      .catch(console.error);
  }, []);

  const getRandomDelay = () => Math.floor(Math.random() * 2000) + 1500;

  const conversationLoop = useCallback(async () => {
    while (true) {
      await new Promise(resolve => setTimeout(resolve, getRandomDelay()));

      if (!isRunningRef.current) {
        await new Promise(resolve => {
          const check = setInterval(() => {
            if (isRunningRef.current) {
              clearInterval(check);
              resolve();
            }
          }, 100);
        });
      }

      if (failCountRef.current >= 3) {
        console.log('Circuit breaker triggered - stopping loop');
        setIsRunning(false);
        break;
      }

      try {
        const speakerRes = await fetch('/api/chat/next-speaker', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ messages: messagesRef.current })
        });
        const { botId } = await speakerRes.json();

        setIsTyping(true);
        setTypingBot(botId);

        const chatRes = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ messages: messagesRef.current, botId })
        });

        if (!chatRes.ok) throw new Error('Chat request failed');

        const { text } = await chatRes.json();
        const bot = bots.find(b => b.id === botId);

        setMessages(prev => [...prev, {
          id: Date.now(),
          botId,
          botName: bot?.name || botId,
          botColor: bot?.color,
          botAvatar: bot?.avatar,
          text,
          isUser: false
        }]);

        setFailCount(0);
      } catch (error) {
        console.error('Conversation loop error:', error);
        setFailCount(prev => prev + 1);
      } finally {
        setIsTyping(false);
        setTypingBot(null);
      }
    }
  }, [bots]);

  useEffect(() => {
    if (bots.length > 0) {
      conversationLoop();
    }
  }, [bots.length]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!input.trim()) return;
    setMessages(prev => [...prev, {
      id: Date.now(),
      text: input.trim(),
      isUser: true
    }]);
    setInput('');
  };

  const toggleRunning = () => {
    setIsRunning(prev => !prev);
    if (!isRunning) setFailCount(0);
  };

  const currentTypingBot = bots.find(b => b.id === typingBot);

  return (
    <div className="app">
      <header className="header">
        <h1>Bot Group Chat</h1>
        <div className="header-right">
          <div className="bot-badges">
            {bots.map(bot => (
              <span
                key={bot.id}
                className="bot-badge"
                style={{ backgroundColor: bot.color }}
              >
                {bot.avatar} {bot.name}
              </span>
            ))}
          </div>
          <button
            className={`toggle-btn ${isRunning ? 'running' : 'paused'}`}
            onClick={toggleRunning}
          >
            {isRunning ? '⏸ Pause' : '▶ Resume'}
          </button>
        </div>
      </header>

      <main className="messages-container">
        <div className="messages">
          {messages.length === 0 && !isTyping && (
            <div className="empty-state">
              Waiting for bots to start chatting...
            </div>
          )}

          {messages.map(msg => {
            const { text, imageUrls } = parseMessageParts(msg.text);
            return (
              <div
                key={msg.id}
                className={`message ${msg.isUser ? 'user-message' : 'bot-message'}`}
                style={!msg.isUser ? { borderLeftColor: msg.botColor } : {}}
              >
                {!msg.isUser && (
                  <div className="message-header">
                    <span className="bot-avatar">{msg.botAvatar}</span>
                    <span className="bot-name" style={{ color: msg.botColor }}>
                      {msg.botName}
                    </span>
                  </div>
                )}
                {text && <div className="message-text">{text}</div>}
                {imageUrls.length > 0 && (
                  <div className="chat-image-group">
                    {imageUrls.map((url, i) => <ChatImage key={i} src={url} />)}
                  </div>
                )}
                {text && <CopyButton text={text} />}
              </div>
            );
          })}

          {isTyping && currentTypingBot && (
            <div
              className="message bot-message typing"
              style={{ borderLeftColor: currentTypingBot.color }}
            >
              <div className="message-header">
                <span className="bot-avatar">{currentTypingBot.avatar}</span>
                <span className="bot-name" style={{ color: currentTypingBot.color }}>
                  {currentTypingBot.name}
                </span>
              </div>
              <div className="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>
      </main>

      <form className="input-bar" onSubmit={handleSubmit}>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Jump in anytime..."
        />
        <button type="submit">Send</button>
      </form>

      {failCount >= 3 && (
        <div className="error-banner">
          Connection issues detected. Chat paused. Click Resume to try again.
        </div>
      )}
    </div>
  );
}

export default App;
