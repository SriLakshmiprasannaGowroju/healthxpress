const https = require('https');

const BASE_URL = 'https://vedvaidyam.com/healthexpress/api';

function fetchLive(path) {
  return new Promise((resolve) => {
    https.get(`${BASE_URL}${path}`, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ error: data.slice(0, 100) });
        }
      });
    });
  });
}

async function run() {
  const doctors = await fetchLive('/doctors');
  console.log('--- REAL DOCTORS FROM HOSTINGER MYSQL ---');
  console.log(JSON.stringify(doctors, null, 2));

  const hospitals = await fetchLive('/hospitals');
  console.log('\n--- REAL HOSPITALS FROM HOSTINGER MYSQL ---');
  console.log(JSON.stringify(hospitals, null, 2));

  const medicines = await fetchLive('/pharmacy/medicines');
  console.log('\n--- REAL MEDICINES FROM HOSTINGER MYSQL ---');
  console.log(JSON.stringify(medicines, null, 2));
}

run();
