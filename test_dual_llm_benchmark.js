const https = require('https');

const SARVAM_API_KEY = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';
const SARVAM_MODEL = 'sarvam-105b-conversations';
const SARVAM_ENDPOINT = 'api.sarvam.ai';
const SARVAM_PATH = '/v1/chat/completions';

const NVIDIA_API_KEY = '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';
const NVIDIA_MODEL = 'openai/gpt-oss-20b';
const NVIDIA_ENDPOINT = 'integrate.api.nvidia.com';
const NVIDIA_PATH = '/v1/chat/completions';

const SYSTEM_PROMPT = `You are HealthExpress AI conversational voice medical assistant. Keep your response short, empathetic, clinically accurate, and suitable for real-time voice speech (2-3 sentences max). No markdown symbols or bullet points.`;

const TEST_CASES = [
  {
    language: 'English',
    prompt: 'I have had a high fever (102°F) and severe body aches for 2 days. What should I do?'
  },
  {
    language: 'Telugu (తెలుగు)',
    prompt: 'నాకు రెండు రోజులుగా తీవ్రమైన జ్వరం (102°F) మరియు ఒంటి నొప్పులు ఉన్నాయి. నేను ఏమి చేయాలి?'
  },
  {
    language: 'Hindi (हिंदी)',
    prompt: 'मुझे 2 दिनों से तेज बुखार (102°F) और बदन दर्द है। मुझे क्या करना चाहिए?'
  }
];

function callLLM(hostname, path, apiKey, model, userPrompt) {
  return new Promise((resolve) => {
    const payload = JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.3,
      max_tokens: 150
    });

    const startTime = Date.now();
    const req = https.request(
      {
        hostname: hostname,
        path: path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
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
            if (res.statusCode >= 200 && res.statusCode < 300) {
              const reply = data.choices && data.choices[0] && data.choices[0].message ? data.choices[0].message.content : JSON.stringify(data);
              const usage = data.usage || {};
              resolve({
                success: true,
                statusCode: res.statusCode,
                durationMs: duration,
                reply: reply.trim(),
                tokens: usage
              });
            } else {
              resolve({
                success: false,
                statusCode: res.statusCode,
                durationMs: duration,
                error: data.error || data.message || body
              });
            }
          } catch (e) {
            resolve({
              success: false,
              statusCode: res.statusCode,
              durationMs: duration,
              error: `JSON parse error: ${e.message} - Body: ${body}`
            });
          }
        });
      }
    );

    req.on('error', (err) => {
      resolve({
        success: false,
        durationMs: Date.now() - startTime,
        error: err.message
      });
    });

    req.setTimeout(15000, () => {
      req.destroy();
      resolve({
        success: false,
        durationMs: Date.now() - startTime,
        error: 'Timeout (> 15000ms)'
      });
    });

    req.write(payload);
    req.end();
  });
}

async function runBenchmark() {
  console.log('================================================================');
  console.log('🤖 DUAL LLM VOICE ASSISTANT BENCHMARK: SARVAM 105B vs NVIDIA NIM');
  console.log('================================================================\n');

  for (const testCase of TEST_CASES) {
    console.log(`\n----------------------------------------------------------------`);
    console.log(`🌍 TEST CASE: ${testCase.language}`);
    console.log(`🗣️ User Voice Input: "${testCase.prompt}"`);
    console.log(`----------------------------------------------------------------`);

    console.log(`\n▶ [1] Testing Sarvam AI (${SARVAM_MODEL})...`);
    const sarvamRes = await callLLM(SARVAM_ENDPOINT, SARVAM_PATH, SARVAM_API_KEY, SARVAM_MODEL, testCase.prompt);
    
    if (sarvamRes.success) {
      console.log(`✅ Sarvam Status: ${sarvamRes.statusCode} OK | Latency: ${sarvamRes.durationMs} ms`);
      console.log(`💬 Sarvam Response:\n"${sarvamRes.reply}"`);
    } else {
      console.log(`❌ Sarvam Failed (${sarvamRes.durationMs} ms):`, sarvamRes.error);
    }

    console.log(`\n▶ [2] Testing NVIDIA NIM (${NVIDIA_MODEL})...`);
    const nvidiaRes = await callLLM(NVIDIA_ENDPOINT, NVIDIA_PATH, NVIDIA_API_KEY, NVIDIA_MODEL, testCase.prompt);

    if (nvidiaRes.success) {
      console.log(`✅ NVIDIA Status: ${nvidiaRes.statusCode} OK | Latency: ${nvidiaRes.durationMs} ms`);
      console.log(`💬 NVIDIA Response:\n"${nvidiaRes.reply}"`);
    } else {
      console.log(`❌ NVIDIA Failed (${nvidiaRes.durationMs} ms):`, nvidiaRes.error);
    }

    // Comparison summary
    if (sarvamRes.success && nvidiaRes.success) {
      const diff = sarvamRes.durationMs - nvidiaRes.durationMs;
      const faster = diff < 0 ? 'Sarvam' : 'NVIDIA';
      console.log(`\n⚡ Speed Comparison: ${faster} was faster by ${Math.abs(diff)} ms.`);
    }
  }

  console.log('\n================================================================');
  console.log('🏁 BENCHMARK COMPLETE');
  console.log('================================================================');
}

runBenchmark();
