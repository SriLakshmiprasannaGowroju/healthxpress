const https = require('https');

// Test Overpass API for Rajahmundry (lat: 16.989, lng: 81.784)
const lat = 16.989;
const lng = 81.784;
const radius = 6000;
const query = `[out:json][timeout:15];
(
  node["amenity"="hospital"](around:${radius},${lat},${lng});
  way["amenity"="hospital"](around:${radius},${lat},${lng});
  node["amenity"="clinic"](around:${radius},${lat},${lng});
  way["amenity"="clinic"](around:${radius},${lat},${lng});
);
out center 30;`;

const url = 'https://overpass-api.de/api/interpreter?data=' + encodeURIComponent(query);

const req = https.get(url, { headers: { 'User-Agent': 'HealthExpress-App/1.0' } }, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Overpass Status:', res.statusCode);
    try {
      const json = JSON.parse(data);
      console.log('Elements found:', json.elements.length);
      json.elements.forEach((el, i) => {
        const name = el.tags?.name || el.tags?.['name:en'] || el.tags?.['name:te'];
        const eLat = el.lat || el.center?.lat;
        const eLon = el.lon || el.center?.lon;
        const type = el.tags?.healthcare || el.tags?.amenity;
        console.log(`${i + 1}. ${name || 'Unnamed Clinic'} [${type}] @ ${eLat}, ${eLon}`);
      });
    } catch (e) {
      console.error(e.message);
    }
  });
});
req.on('error', (e) => console.error('Request error:', e.message));
