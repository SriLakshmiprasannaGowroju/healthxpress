const https = require('https');
const { performance } = require('perf_hooks');
const { AccessToken } = require('./livekit_voice_agent/node_modules/livekit-server-sdk');

const LIVEKIT_API_KEY = 'API5veVBN62icXT';
const LIVEKIT_API_SECRET = '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA';
const SARVAM_API_KEY = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';

console.log('====================================================');
console.log('⚡ HEALTHEXPRESS AI - REAL-TIME LATENCY BENCHMARK');
console.log('====================================================\n');

async function benchmarkTokenGeneration() {
  const start = performance.now();
  const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
    identity: 'patient-bench-01',
    ttl: '1h',
  });
  at.addGrant({ roomJoin: true, room: 'bench-room', canPublish: true, canSubscribe: true });
  await at.toJwt();
  const duration = (performance.now() - start).toFixed(2);
  console.log(`⏱️  1. LiveKit Token Generation:    ${duration} ms`);
  return parseFloat(duration);
}

function benchmarkSarvamLLM() {
  return new Promise((resolve) => {
    const postData = JSON.stringify({
      model: 'sarvam-105b-conversations',
      messages: [
        { role: 'system', content: 'You are HealthExpress AI. Keep response short.' },
        { role: 'user', content: 'What is the dosage for paracetamol 500mg for fever?' }
      ],
      temperature: 0.2,
      max_tokens: 60
    });

    const start = performance.now();
    const req = https.request({
      hostname: 'api.sarvam.ai',
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-subscription-key': SARVAM_API_KEY,
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 10000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const duration = (performance.now() - start).toFixed(2);
        console.log(`⏱️  2. Sarvam 105B LLM Inference:   ${duration} ms`);
        resolve(parseFloat(duration));
      });
    });

    req.on('error', () => resolve(0));
    req.write(postData);
    req.end();
  });
}

function benchmarkSarvamTTS() {
  return new Promise((resolve) => {
    const postData = JSON.stringify({
      inputs: ['Take one tablet after food every six hours if fever persists.'],
      target_language_code: 'en-IN',
      speaker: 'shubh',
      pitch: 0,
      pace: 1.1,
      loudness: 1.5,
      speech_sample_rate: 8000,
      enable_preprocessing: true,
      model: 'bulbul:v3'
    });

    const start = performance.now();
    const req = https.request({
      hostname: 'api.sarvam.ai',
      path: '/text-to-speech',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-subscription-key': SARVAM_API_KEY,
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 10000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const duration = (performance.now() - start).toFixed(2);
        console.log(`⏱️  3. Sarvam Bulbul v3 TTS Audio:  ${duration} ms`);
        resolve(parseFloat(duration));
      });
    });

    req.on('error', () => resolve(0));
    req.write(postData);
    req.end();
  });
}

async function runBenchmark() {
  const tToken = await benchmarkTokenGeneration();
  const tLLM = await benchmarkSarvamLLM();
  const tTTS = await benchmarkSarvamTTS();

  const totalRoundtrip = (tLLM + tTTS).toFixed(2);
  const endpointingDelay = 70; // 0.07s min_endpointing_delay
  const webrtcTransit = 35; // typical LiveKit Cloud transit

  console.log('\n----------------------------------------------------');
  console.log('📊 REAL-TIME PIPELINE BREAKDOWN:');
  console.log(` • User Speech Endpointing Detection : ~${endpointingDelay} ms (0.07s)`);
  console.log(` • WebRTC Ingress Transit (LiveKit)  : ~${webrtcTransit} ms`);
  console.log(` • Sarvam Saaras v4 STT (Streamed)   : Real-time (flush_signal=True)`);
  console.log(` • Sarvam 105B Conversational LLM    : ${tLLM} ms`);
  console.log(` • Sarvam Bulbul v3 TTS Audio Gen    : ${tTTS} ms`);
  console.log(` • WebRTC Egress Audio Playback      : ~${webrtcTransit} ms`);
  console.log('----------------------------------------------------');
  console.log(`🚀 Total User Voice-to-Ear Turnaround: ~${(parseFloat(totalRoundtrip) + endpointingDelay + (webrtcTransit * 2)).toFixed(0)} ms`);
  console.log('====================================================\n');
}

runBenchmark();
