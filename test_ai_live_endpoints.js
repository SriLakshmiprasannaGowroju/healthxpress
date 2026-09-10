// test_ai_live_endpoints.js
const https = require('https');

const sarvamApiKey = 'sk_02gq1a59_3J4xI3kYw14mC813t38X2T';
const nvidiaApiKey = 'nvapi-rR_eI5aHj2U6pL7j_XqGvM3n2V1k4L8p9Q';

async function testSarvamChat() {
  console.log('Testing Sarvam Chat API...');
  const payload = JSON.stringify({
    model: 'sarvam-2b',
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
        'api-subscription-key': sarvamApiKey,
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`Sarvam Chat Status: ${res.statusCode}`);
        console.log(`Sarvam Chat Response: ${data.substring(0, 300)}`);
        resolve({ status: res.statusCode, body: data });
      });
    });

    req.on('error', (e) => {
      console.error('Sarvam Chat Error:', e.message);
      resolve({ error: e.message });
    });

    req.write(payload);
    req.end();
  });
}

async function testHostingerAiTriage() {
  console.log('\nTesting Hostinger AI Triage Live Backend API...');
  const payload = JSON.stringify({
    user_id: 'USR-101',
    symptoms: 'fever and headache',
    duration: '2 days',
    language: 'en'
  });

  return new Promise((resolve) => {
    const req = https.request('https://vedvaidyam.com/healthexpress/api/ai_triage.php', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`Hostinger AI Triage Status: ${res.statusCode}`);
        console.log(`Hostinger AI Triage Response: ${data.substring(0, 300)}`);
        resolve({ status: res.statusCode, body: data });
      });
    });

    req.on('error', (e) => {
      console.error('Hostinger AI Triage Error:', e.message);
      resolve({ error: e.message });
    });

    req.write(payload);
    req.end();
  });
}

async function main() {
  await testSarvamChat();
  await testHostingerAiTriage();
}

main();
