// Server-side proxy for Groq chat completions, so the Groq key stays on the server instead of
// shipping in the web build. Callers must present a Canvas token that Canvas accepts.
const crypto = require('crypto');

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const CANVAS_URL = 'https://hau.instructure.com/api/v1/users/self';
const MODEL = 'openai/gpt-oss-120b';
const VERIFIED_TTL_MS = 10 * 60 * 1000;

// Tokens Canvas has already accepted, stored hashed, so a chat does not re-check on every turn.
const verified = new Map();

async function isCanvasUser(token) {
  const key = crypto.createHash('sha256').update(token).digest('hex');
  const until = verified.get(key);
  if (until && until > Date.now()) return true;

  const response = await fetch(CANVAS_URL, {
    headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
  });
  if (response.status !== 200) return false;

  verified.set(key, Date.now() + VERIFIED_TTL_MS);
  return true;
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'AI proxy is not configured' });

  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return res.status(401).json({ error: 'Not signed in to Canvas' });

  try {
    if (!(await isCanvasUser(token))) {
      return res.status(401).json({ error: 'Not signed in to Canvas' });
    }
  } catch (_) {
    return res.status(502).json({ error: 'Could not reach Canvas' });
  }

  const body = req.body || {};
  if (!Array.isArray(body.messages)) {
    return res.status(400).json({ error: 'messages is required' });
  }

  // The model is fixed here so the key cannot be used for anything else.
  const payload = { model: MODEL, messages: body.messages };
  if (Array.isArray(body.tools)) {
    payload.tools = body.tools;
    payload.tool_choice = 'auto';
  }
  if (typeof body.temperature === 'number') payload.temperature = body.temperature;

  try {
    const upstream = await fetch(GROQ_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const text = await upstream.text();
    res.setHeader('Content-Type', 'application/json');
    return res.status(upstream.status).send(text);
  } catch (_) {
    return res.status(502).json({ error: 'Could not reach the AI provider' });
  }
};
