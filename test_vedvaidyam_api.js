const https = require('https');

const BASE_URL = 'https://vedvaidyam.com/healthexpress/api';
const ENDPOINTS = [
  '/hospitals',
  '/doctors',
  '/pharmacy/medicines',
  '/pharmacy/stores',
  '/emergency/ambulances',
  '/health'
];

function fetchLive(path) {
  return new Promise((resolve) => {
    https.get(`${BASE_URL}${path}`, (res) => {
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
  console.log(`Testing live API data from ${BASE_URL}:`);
  for (const ep of ENDPOINTS) {
    const res = await fetchLive(ep);
    if (res.status === 200 && res.data) {
      const isArr = Array.isArray(res.data);
      const isDataArr = res.data.data && Array.isArray(res.data.data);
      const count = isArr ? res.data.length : (isDataArr ? res.data.data.length : Object.keys(res.data).length);
      console.log(`✅ [${res.path}] Status 200 | Count: ${count}`);
    } else {
      console.log(`❌ [${res.path}] Status: ${res.status} | Err: ${res.error || res.raw || ''}`);
    }
  }
}

run();
