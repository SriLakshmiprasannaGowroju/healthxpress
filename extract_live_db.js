const https = require('https');
const fs = require('fs');

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
          resolve(null);
        }
      });
    }).on('error', () => resolve(null));
  });
}

async function dump() {
  const doctorsRes = await fetchLive('/doctors');
  const hospitalsRes = await fetchLive('/hospitals');
  const medicinesRes = await fetchLive('/pharmacy/medicines');
  const storesRes = await fetchLive('/pharmacy/stores');

  const doctors = doctorsRes && doctorsRes.data ? doctorsRes.data : [];
  const hospitals = hospitalsRes && hospitalsRes.data ? hospitalsRes.data : [];
  const medicines = medicinesRes && medicinesRes.data && medicinesRes.data.medicines ? medicinesRes.data.medicines : [];
  const stores = storesRes && storesRes.data ? storesRes.data : [];

  console.log(`Live Data Fetched: ${hospitals.length} Hospitals, ${doctors.length} Doctors, ${medicines.length} Medicines, ${stores.length} Stores`);

  fs.writeFileSync('c:/Users/shese/Desktop/healthyxpress_medha/live_db_dump.json', JSON.stringify({
    hospitals,
    doctors,
    medicines,
    stores
  }, null, 2));
}

dump();
