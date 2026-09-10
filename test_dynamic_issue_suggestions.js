const https = require('https');

const SARVAM_API_KEY = 'sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh';
const SARVAM_MODEL = 'sarvam-105b-conversations';

const TEST_ISSUES = [
  {
    condition: 'Stomach Ache & Severe Acidity',
    userPrompt: 'I have severe burning in my stomach and acid reflux after eating.',
    expectedDoctor: 'Gastroenterologist / General Physician',
    expectedMed: 'Pantoprazole / Antacid'
  },
  {
    condition: 'Knee Joint Pain & Stiffness',
    userPrompt: 'My right knee has severe swelling and pain when climbing stairs for 3 days.',
    expectedDoctor: 'Orthopedic Surgeon (Dr. Naveen)',
    expectedMed: 'Pain Relief / Heat wrap'
  },
  {
    condition: 'Throat Irritation & Dry Cough',
    userPrompt: 'తీవ్రమైన గొంతు నొప్పి మరియు పొడి దగ్గు ఉంది, మింగలేకపోతున్నాను.', // Telugu
    expectedDoctor: 'ENT Specialist (Dr. Vikram)',
    expectedMed: 'Cough Syrup / Salt gargles'
  },
  {
    condition: 'High Sugar & Diabetes Concern',
    userPrompt: 'मुझे बहुत ज्यादा प्यास लग रही है और बार-बार पेशाब आ रहा है, शुगर 240 है।', // Hindi
    expectedDoctor: 'Diabetologist / Physician',
    expectedMed: 'Glucometer Kit / HbA1c test'
  }
];

function callSarvam(prompt) {
  return new Promise((resolve) => {
    const payload = JSON.stringify({
      model: SARVAM_MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are HealthExpress AI conversational clinical assistant. Formulate personalized, non-generic medical guidance directly tailored to whatever specific health issue the patient describes in 2-3 sentences. No markdown formatting.'
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 150
    });

    const start = Date.now();
    const req = https.request(
      {
        hostname: 'api.sarvam.ai',
        path: '/v1/chat/completions',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${SARVAM_API_KEY}`,
          'Content-Length': Buffer.byteLength(payload)
        }
      },
      (res) => {
        let body = '';
        res.on('data', (c) => (body += c));
        res.on('end', () => {
          try {
            const data = JSON.parse(body);
            const reply = data.choices && data.choices[0] && data.choices[0].message ? data.choices[0].message.content : '';
            resolve({ success: true, latency: Date.now() - start, reply });
          } catch (e) {
            resolve({ success: false, error: e.message });
          }
        });
      }
    );
    req.on('error', (e) => resolve({ success: false, error: e.message }));
    req.write(payload);
    req.end();
  });
}

async function run() {
  console.log('================================================================');
  console.log('🩺 DYNAMIC ISSUE-SPECIFIC CLINICAL ADVICE VERIFICATION');
  console.log('================================================================\n');

  for (const issue of TEST_ISSUES) {
    console.log(`\n📌 Condition: ${issue.condition}`);
    console.log(`🗣️ Patient Input: "${issue.userPrompt}"`);
    console.log(`🎯 Expected Alignment: Doctor [${issue.expectedDoctor}], Care [${issue.expectedMed}]`);
    
    const res = await callSarvam(issue.userPrompt);
    if (res.success) {
      console.log(`⚡ Response (${res.latency}ms):`);
      console.log(`"${res.reply.trim()}"`);
    } else {
      console.log(`❌ Error:`, res.error);
    }
  }
}

run();
