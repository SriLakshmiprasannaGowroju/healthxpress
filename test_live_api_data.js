const https = require('https');

const ENDPOINTS = [
  '/hospitals',
  '/doctors',
  '/pharmacy/medicines',
  '/pharmacy/stores',
  '/emergency/ambulances',
  '/lab-tests'
];

function fetchLive(path) {
  return new Promise((resolve) => {
    https.get(`https://medha.spraksh.com/api${path}`, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ path, status: res.statusCode, data: json });
        } catch (e) {
          resolve({ path, status: res.statusCode, raw: data.slice(0, 150) });
        }
      });
    }).on('error', err => resolve({ path, error: err.message }));
  });
}

async function run() {
  console.log('Testing live API data from https://medha.spraksh.com/api:');
  for (const ep of ENDPOINTS) {
    const res = await fetchLive(ep);
    console.log(`[${res.path}] Status: ${res.status} | Error: ${res.error || 'None'} | Data: ${JSON.stringify(res.data || res.raw || '').slice(0, 100)}`);
  }
}

run();
