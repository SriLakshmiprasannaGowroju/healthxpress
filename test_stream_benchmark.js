const https = require('https');

const SARVAM_API_KEY = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';
const SARVAM_MODEL = 'sarvam-105b-conversations';

const NVIDIA_API_KEY = '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';
const NVIDIA_MODEL = 'openai/gpt-oss-20b';

function testStream(name, hostname, apiKey, model, prompt) {
  return new Promise((resolve) => {
    const payload = JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: 'You are HealthExpress AI voice assistant. Respond in 2 short sentences.' },
        { role: 'user', content: prompt }
      ],
      stream: true,
      max_tokens: 100
    });

    const startTime = Date.now();
    let ttft = null;
    let fullText = '';
    let tokenCount = 0;

    const req = https.request(
      {
        hostname: hostname,
        path: '/v1/chat/completions',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
          'Content-Length': Buffer.byteLength(payload)
        }
      },
      (res) => {
        let buffer = '';
        res.on('data', (chunk) => {
          buffer += chunk.toString();
          const lines = buffer.split('\n');
          buffer = lines.pop(); // Keep last incomplete line

          for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed.startsWith('data: ') && trimmed !== 'data: [DONE]') {
              try {
                const parsed = JSON.parse(trimmed.replace('data: ', ''));
                const delta = parsed.choices && parsed.choices[0] && parsed.choices[0].delta && parsed.choices[0].delta.content;
                if (delta) {
                  if (ttft === null) {
                    ttft = Date.now() - startTime;
                  }
                  fullText += delta;
                  tokenCount++;
                }
              } catch (e) {}
            }
          }
        });

        res.on('end', () => {
          const totalDuration = Date.now() - startTime;
          resolve({
            name,
            model,
            statusCode: res.statusCode,
            ttft: ttft || totalDuration,
            totalDuration,
            tokenCount,
            fullText: fullText.trim()
          });
        });
      }
    );

    req.on('error', (err) => resolve({ name, error: err.message }));
    req.setTimeout(12000, () => {
      req.destroy();
      resolve({ name, error: 'Timeout' });
    });
    req.write(payload);
    req.end();
  });
}

async function run() {
  console.log('⚡ STREAMING BENCHMARK: Time To First Token (TTFT) & Total Latency:\n');
  const prompt = 'I have a high fever (102°F) and headache.';

  const sRes = await testStream('Sarvam 105B', 'api.sarvam.ai', SARVAM_API_KEY, SARVAM_MODEL, prompt);
  console.log(`[Sarvam AI 105B]`);
  console.log(`  - TTFT (First Token): ${sRes.ttft} ms`);
  console.log(`  - Total Duration:     ${sRes.totalDuration} ms`);
  console.log(`  - Streamed Response:  "${sRes.fullText}"\n`);

  const nRes = await testStream('NVIDIA NIM', 'integrate.api.nvidia.com', NVIDIA_API_KEY, NVIDIA_MODEL, prompt);
  console.log(`[NVIDIA NIM gpt-oss-20b]`);
  console.log(`  - TTFT (First Token): ${nRes.ttft} ms`);
  console.log(`  - Total Duration:     ${nRes.totalDuration} ms`);
  console.log(`  - Streamed Response:  "${nRes.fullText}"\n`);
}

run();
