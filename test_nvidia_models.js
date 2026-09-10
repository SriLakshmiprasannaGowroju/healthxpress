const https = require('https');

const NVIDIA_API_KEY = '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';
const NVIDIA_ENDPOINT = 'integrate.api.nvidia.com';

const MODELS_TO_TEST = [
  'openai/gpt-oss-20b',
  'meta/llama-3.1-8b-instruct',
  'meta/llama-3.1-70b-instruct',
  'nvidia/llama-3.1-nemotron-70b-instruct'
];

async function testModel(model) {
  return new Promise((resolve) => {
    const payload = JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: 'You are a concise voice doctor assistant. Respond in 2 short sentences.' },
        { role: 'user', content: 'I have a high fever of 102F and body aches.' }
      ],
      temperature: 0.2,
      max_tokens: 100
    });

    const startTime = Date.now();
    const req = https.request(
      {
        hostname: NVIDIA_ENDPOINT,
        path: '/v1/chat/completions',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${NVIDIA_API_KEY}`,
          'Content-Length': Buffer.byteLength(payload)
        }
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          const duration = Date.now() - startTime;
          try {
            const data = JSON.parse(body);
            if (res.statusCode === 200) {
              const reply = data.choices && data.choices[0] && data.choices[0].message ? data.choices[0].message.content : '';
              resolve({ model, success: true, latency: duration, reply });
            } else {
              resolve({ model, success: false, latency: duration, error: data.error ? data.error.message : body });
            }
          } catch (e) {
            resolve({ model, success: false, latency: duration, error: e.message });
          }
        });
      }
    );
    req.on('error', (e) => resolve({ model, success: false, latency: Date.now() - startTime, error: e.message }));
    req.setTimeout(10000, () => {
      req.destroy();
      resolve({ model, success: false, latency: Date.now() - startTime, error: 'Timeout' });
    });
    req.write(payload);
    req.end();
  });
}

async function run() {
  console.log('Testing NVIDIA Models for latency & response:');
  for (const m of MODELS_TO_TEST) {
    const res = await testModel(m);
    if (res.success) {
      console.log(`[${res.model}] Latency: ${res.latency}ms -> "${res.reply.trim().slice(0, 100)}..."`);
    } else {
      console.log(`[${res.model}] Failed (${res.latency}ms): ${res.error}`);
    }
  }
}

run();
