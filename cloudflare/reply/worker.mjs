const MAX_BODY = 32 * 1024;
const MAX_TEXT = 3500;

async function readText(request) {
  if (!request.body) return null;
  const reader = request.body.getReader();
  const decoder = new TextDecoder();
  let size = 0;
  let body = '';
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > MAX_BODY) {
      await reader.cancel();
      return null;
    }
    body += decoder.decode(value, { stream: true });
  }
  const form = new URLSearchParams(body + decoder.decode());
  const text = form.get('text')?.trim();
  return text && text.length <= MAX_TEXT && [...form.keys()].length === 1 ? text : null;
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin');
    const headers = { 'Cache-Control': 'no-store', 'Vary': 'Origin' };
    if (origin === env.GAME_ORIGIN) headers['Access-Control-Allow-Origin'] = origin;
    const reply = (status) => Response.json({ ok: status === 200 }, { status, headers });

    if (new URL(request.url).pathname !== '/send') return reply(404);
    if (!origin || origin !== env.GAME_ORIGIN) return reply(403);
    if (request.method === 'OPTIONS') {
      headers['Access-Control-Allow-Methods'] = 'POST';
      headers['Access-Control-Allow-Headers'] = 'Content-Type';
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== 'POST') return reply(405);
    if (request.headers.get('Content-Type')?.split(';')[0] !== 'application/x-www-form-urlencoded') return reply(415);
    if (!env.TELEGRAM_BOT_TOKEN || !env.TELEGRAM_CHAT_ID) return reply(503);

    let stage = 'client_limit';
    try {
      const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
      if (!(await env.REPLY_PER_CLIENT.limit({ key: ip })).success) return reply(429);
      stage = 'request_body';
      const text = await readText(request);
      if (!text) return reply(400);
      stage = 'total_limit';
      if (!(await env.REPLY_TOTAL.limit({ key: 'reply' })).success) return reply(429);
      stage = 'telegram_request';
      if (!/^\d+:[A-Za-z0-9_-]+$/.test(env.TELEGRAM_BOT_TOKEN)) {
        console.warn('Telegram bot secret has invalid format');
        return reply(503);
      }
      const result = await fetch(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: env.TELEGRAM_CHAT_ID, text }),
        signal: AbortSignal.timeout(12000),
        redirect: 'manual',
      });
      if (!result.ok) {
        console.warn('Telegram delivery rejected', { status: result.status });
        return reply(502);
      }
      if ((await result.json()).ok !== true) return reply(502);
      return reply(200);
    } catch (error) {
      console.warn('Reply delivery failed', { stage, kind: error?.name });
      return reply(502);
    }
  },
};
