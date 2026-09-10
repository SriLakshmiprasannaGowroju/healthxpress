// test_keys_live.js
const https = require('https');

const sarvamKey = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';
const nvidiaKey = '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';

async function testSarvamKey(model) {
  console.log(`Testing Sarvam Chat with key sk_n4tzuy3c... model=${model}`);
  const payload = JSON.stringify({
    model: model,
    messages: [
      { role: 'system', content: 'You are HealthExpress AI assistant.' },
      { role: 'user', content: 'Hello, I have headache and fever.' }
    ],
    temperature: 0.6,
    max_tokens: 150
  });

  return new Promise((resolve) => {
    const req = https.request('https://api.sarvam.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-subscription-key': sarvamKey,
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`[Sarvam ${model}] Status: ${res.statusCode}`);
        console.log(`[Sarvam ${model}] Response: ${data.substring(0, 300)}\n`);
        resolve({ status: res.statusCode, body: data });
      });
    });

    req.on('error', (e) => {
      console.error('Sarvam Error:', e.message);
      resolve({ error: e.message });
    });

    req.write(payload);
    req.end();
  });
}

async function testNvidiaKey(model) {
  console.log(`Testing NVIDIA NIM with key nvapi-8hbjHM1... model=${model}`);
  const payload = JSON.stringify({
    model: model,
    messages: [
      { role: 'system', content: 'You are HealthExpress AI assistant.' },
      { role: 'user', content: 'Hello, I have headache and fever.' }
    ],
    temperature: 0.6,
    max_tokens: 150
  });

  return new Promise((resolve) => {
    const req = https.request('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${nvidiaKey}`,
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`[NVIDIA ${model}] Status: ${res.statusCode}`);
        console.log(`[NVIDIA ${model}] Response: ${data.substring(0, 300)}\n`);
        resolve({ status: res.statusCode, body: data });
      });
    });

    req.on('error', (e) => {
      console.error('NVIDIA Error:', e.message);
      resolve({ error: e.message });
    });

    req.write(payload);
    req.end();
  });
}

async function run() {
  await testSarvamKey('sarvam-105b-conversations');
  await testSarvamKey('sarvam-2b');
  await testNvidiaKey('openai/gpt-oss-20b');
  await testNvidiaKey('meta/llama-3.1-8b-instruct');
  await testNvidiaKey('google/gemma-2-9b-it');
}

run();
