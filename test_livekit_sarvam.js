const https = require('https');
const { AccessToken } = require('./livekit_voice_agent/node_modules/livekit-server-sdk');

const LIVEKIT_URL = 'wss://luca-vsv9whhr.livekit.cloud';
const LIVEKIT_API_KEY = 'API5veVBN62icXT';
const LIVEKIT_API_SECRET = '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA';
const SARVAM_API_KEY = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';

console.log('====================================================');
console.log('🧪 HEALTHEXPRESS AI - LIVEKIT + SARVAM TEST HARNESS');
console.log('====================================================\n');

async function testLiveKitToken() {
  console.log('1️⃣ Testing LiveKit Token Generation...');
  try {
    const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: 'test-patient-001',
      ttl: '1h',
    });
    at.addGrant({
      roomJoin: true,
      room: 'test-clinical-room',
      canPublish: true,
      canSubscribe: true,
    });
    const token = await at.toJwt();
    console.log('   ✅ LiveKit JWT Token Generated Successfully!');
    console.log('   🔑 Token preview:', token.substring(0, 40) + '...');
    return true;
  } catch (e) {
    console.error('   ❌ LiveKit Token Error:', e.message);
    return false;
  }
}

function testSarvamLLM() {
  console.log('\n2️⃣ Testing Sarvam 105B Conversations LLM API...');
  return new Promise((resolve) => {
    const postData = JSON.stringify({
      model: 'sarvam-105b-conversations',
      messages: [
        {
          role: 'system',
          content: 'You are HealthExpress AI voice triage assistant. Respond concisely in Telugu or English.'
        },
        {
          role: 'user',
          content: 'నాకు రెండు రోజులుగా జ్వరం మరియు తలనొప్పిగా ఉంది. ఏమి చేయాలి?'
        }
      ],
      temperature: 0.3,
      max_tokens: 150
    });

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
        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(data);
            const reply = parsed.choices?.[0]?.message?.content || data;
            console.log('   ✅ Sarvam 105B Response (Status: 200 OK):');
            console.log('   💬 "' + reply.trim() + '"');
            resolve(true);
          } catch (e) {
            console.log('   ✅ Response received:', data.substring(0, 150));
            resolve(true);
          }
        } else {
          console.log(`   ⚠️ Sarvam LLM HTTP Status: ${res.statusCode}:`, data);
          resolve(false);
        }
      });
    });

    req.on('error', (e) => {
      console.error('   ❌ Sarvam LLM Request Error:', e.message);
      resolve(false);
    });

    req.write(postData);
    req.end();
  });
}

function testSarvamTTS() {
  console.log('\n3️⃣ Testing Sarvam Bulbul v3 TTS API (Voice Synthesis)...');
  return new Promise((resolve) => {
    const postData = JSON.stringify({
      inputs: ['నమస్కారం! హెల్త్ ఎక్స్‌ప్రెస్ క్లినికల్ వాయిస్ అసిస్టెంట్‌కి స్వాగతం.'],
      target_language_code: 'te-IN',
      speaker: 'shubh',
      pitch: 0,
      pace: 1.05,
      loudness: 1.5,
      speech_sample_rate: 8000,
      enable_preprocessing: true,
      model: 'bulbul:v3'
    });

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
        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(data);
            const audioData = parsed.audios?.[0] || '';
            console.log('   ✅ Sarvam Bulbul v3 TTS Audio Generated Successfully (Status: 200 OK)!');
            console.log('   🎵 Base64 Audio length:', audioData.length, 'bytes');
            resolve(true);
          } catch (e) {
            console.log('   ✅ TTS Response received:', data.substring(0, 100));
            resolve(true);
          }
        } else {
          console.log(`   ⚠️ Sarvam TTS HTTP Status: ${res.statusCode}:`, data);
          resolve(false);
        }
      });
    });

    req.on('error', (e) => {
      console.error('   ❌ Sarvam TTS Request Error:', e.message);
      resolve(false);
    });

    req.write(postData);
    req.end();
  });
}

async function runAllTests() {
  const t1 = await testLiveKitToken();
  const t2 = await testSarvamLLM();
  const t3 = await testSarvamTTS();

  console.log('\n====================================================');
  if (t1 && t2 && t3) {
    console.log('🎉 ALL TESTS PASSED! LiveKit + Sarvam pipeline is 100% OPERATIONAL!');
  } else {
    console.log('ℹ️ Tests completed. Check individual statuses above.');
  }
  console.log('====================================================');
}

runAllTests();
