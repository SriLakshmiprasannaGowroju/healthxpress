const https = require('https');

const sarvamApiKey = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';
const sarvamFallbackKey = 'sk_hr3tv6ew_UBzXjEc9RqZLGuMpzyctBUQC';
const sarvamChatEndpoint = '/v1/chat/completions';
const sarvamTtsEndpoint = '/text-to-speech';

function callSarvamLLM(messages, maxTokens = 85) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const data = JSON.stringify({
      model: 'sarvam-105b-conversations',
      messages: messages,
      temperature: 0.5,
      max_tokens: maxTokens,
    });

    function tryKey(key) {
      const req = https.request(
        {
          hostname: 'api.sarvam.ai',
          path: sarvamChatEndpoint,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api-subscription-key': key,
            'Content-Length': Buffer.byteLength(data),
          },
        },
        (res) => {
          let body = '';
          res.on('data', (chunk) => (body += chunk));
          res.on('end', () => {
            const duration = Date.now() - start;
            if (res.statusCode === 200) {
              try {
                const parsed = JSON.parse(body);
                const content = parsed.choices[0].message.content.trim();
                resolve({ content, duration, statusCode: 200, keyUsed: key.substring(0, 10) });
              } catch (e) {
                reject(e);
              }
            } else if (key === sarvamApiKey) {
              console.log(`[Primary Key Status ${res.statusCode}] Switching to fallback key...`);
              tryKey(sarvamFallbackKey);
            } else {
              reject(new Error(`Status ${res.statusCode}: ${body}`));
            }
          });
        }
      );
      req.on('error', (err) => {
        if (key === sarvamApiKey) {
          tryKey(sarvamFallbackKey);
        } else {
          reject(err);
        }
      });
      req.write(data);
      req.end();
    }

    tryKey(sarvamApiKey);
  });
}

function callSarvamTTS(text, lang = 'en-IN') {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const speaker = lang.startsWith('te') ? 'kavitha' : (lang.startsWith('hi') ? 'kavya' : 'priya');
    const cleanText = text.substring(0, 250);
    const data = JSON.stringify({
      inputs: [cleanText],
      target_language_code: lang,
      speaker: speaker,
      pitch: 0,
      pace: 1.05,
      loudness: 1.5,
      speech_sample_rate: 22050,
      enable_preprocessing: true,
      model: 'bulbul:v3',
    });

    const req = https.request(
      {
        hostname: 'api.sarvam.ai',
        path: sarvamTtsEndpoint,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': sarvamFallbackKey,
          'Content-Length': Buffer.byteLength(data),
        },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          const duration = Date.now() - start;
          if (res.statusCode === 200) {
            try {
              const parsed = JSON.parse(body);
              const audioBase64 = parsed.audios && parsed.audios[0];
              const audioSizeBytes = audioBase64 ? Buffer.from(audioBase64, 'base64').length : 0;
              resolve({ duration, statusCode: 200, audioSizeBytes });
            } catch (e) {
              reject(e);
            }
          } else {
            reject(new Error(`TTS Status ${res.statusCode}: ${body}`));
          }
        });
      }
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function runMultiTurnQA() {
  console.log('================================================================');
  console.log('🩺 HealthExpress AI Assistant Multi-Turn Latency & QA Benchmark');
  console.log('================================================================\n');

  const conversationHistory = [
    {
      role: 'system',
      content: 'You are HealthExpress AI, an intelligent multilingual doctor assistant for India. Respond concisely, warmly, and naturally in under 2-3 sentences. Never use asterisks or markdown.',
    },
  ];

  const turns = [
    {
      turn: 1,
      user: 'Hi, I am Ramesh, 34 male. I have high fever and severe body pain since yesterday.',
      lang: 'en-IN',
      expected: 'Acknowledge Ramesh, identify fever & body pain, advise rest & hydration.',
    },
    {
      turn: 2,
      user: 'My temperature is 101.5 F and I have mild nausea. Should I take any medicine right now?',
      lang: 'en-IN',
      expected: 'Confirm 101.5 F, recommend standard antipyretic (e.g. Paracetamol 650mg after food) and ask if nausea persists.',
    },
    {
      turn: 3,
      user: 'Thank you doctor. Can I also book a home visit with an RMP or specialist doctor?',
      lang: 'en-IN',
      expected: 'Confirm doctor appointment booking and prompt confirmation.',
    },
    {
      turn: 4,
      user: 'నాకు కొంచెం గొంతు నొప్పి కూడా ఉంది, ఏం చేయాలి?', // Telugu: I also have some sore throat, what to do?
      lang: 'te-IN',
      expected: 'Respond in natural Telugu advising warm salt water gargling and hydration.',
    },
  ];

  const results = [];

  for (const t of turns) {
    console.log(`--- [TURN ${t.turn}] ----------------------------------------------`);
    console.log(`👤 User [${t.lang}]: "${t.user}"`);

    conversationHistory.push({ role: 'user', content: t.user });

    // Measure LLM latency
    const llmRes = await callSarvamLLM(conversationHistory, 85);
    console.log(`🤖 AI Response: "${llmRes.content}"`);
    console.log(`⏱️  LLM Generation Latency: ${llmRes.duration} ms (Key: ${llmRes.keyUsed})`);

    // Measure TTS synthesis latency
    const ttsRes = await callSarvamTTS(llmRes.content, t.lang);
    console.log(`🔊 TTS Voice Synthesis Latency: ${ttsRes.duration} ms (Audio Size: ${(ttsRes.audioSizeBytes / 1024).toFixed(1)} KB)`);

    const totalTurnaround = llmRes.duration + ttsRes.duration;
    console.log(`⚡ Total Voice Response Turnaround: ${totalTurnaround} ms\n`);

    conversationHistory.push({ role: 'assistant', content: llmRes.content });

    results.push({
      turn: t.turn,
      user: t.user,
      ai: llmRes.content,
      llmLatencyMs: llmRes.duration,
      ttsLatencyMs: ttsRes.duration,
      totalLatencyMs: totalTurnaround,
      lang: t.lang,
    });
  }

  console.log('================================================================');
  console.log('📊 MULTI-TURN LATENCY QA SUMMARY REPORT');
  console.log('================================================================');
  console.table(
    results.map((r) => ({
      Turn: r.turn,
      Language: r.lang,
      'LLM Latency': `${r.llmLatencyMs} ms`,
      'TTS Latency': `${r.ttsLatencyMs} ms`,
      'Total Real-Time Latency': `${r.totalLatencyMs} ms`,
      Status: r.totalLatencyMs < 1200 ? '✅ ULTRA FAST' : '⚠️ ACCEPTABLE',
    }))
  );

  const avgLlm = results.reduce((a, b) => a + b.llmLatencyMs, 0) / results.length;
  const avgTts = results.reduce((a, b) => a + b.ttsLatencyMs, 0) / results.length;
  const avgTotal = results.reduce((a, b) => a + b.totalLatencyMs, 0) / results.length;

  console.log(`\n🎯 Average Multi-Turn LLM Latency: ${avgLlm.toFixed(0)} ms`);
  console.log(`🎯 Average Multi-Turn TTS Latency: ${avgTts.toFixed(0)} ms`);
  console.log(`🚀 Average Total Voice Response Turnaround: ${avgTotal.toFixed(0)} ms`);
  console.log('================================================================\n');
}

runMultiTurnQA().catch(console.error);
