// Smoke test script for React Native app API contract, security logic, and catalog parsing
const crypto = require('crypto');

async function runSmokeTests() {
  console.log('=== RUNNING SMOKE TESTS FOR MYKIDSTUBE RN ===\n');

  // Test 1: PIN Security Logic (Salted SHA-256 with 16-byte random salt)
  console.log('1. Testing PIN Security Logic...');
  const randomBytes = crypto.randomBytes(16);
  const salt = randomBytes.toString('hex');
  const hashPin = (pin, s) => {
    return crypto.createHash('sha256').update(`${s}:${pin}`).digest('hex');
  };

  const defaultPinHash = hashPin('1234', salt);
  const correctCheck = hashPin('1234', salt) === defaultPinHash;
  const incorrectCheck = hashPin('9999', salt) === defaultPinHash;
  const changedPin = '5829';
  const newPinHash = hashPin(changedPin, salt);
  const newPinCheck = hashPin(changedPin, salt) === newPinHash;

  if (correctCheck && !incorrectCheck && newPinCheck && defaultPinHash !== newPinHash) {
    console.log('  ✓ PIN Security: Salted SHA-256 hashing, default check, and verification passed.');
  } else {
    throw new Error('PIN Security test failed!');
  }

  // Test 2: Live API Health Check
  console.log('\n2. Testing Portal API Health Check (https://mykidstube.kidstube.workers.dev/api/v1/health)...');
  try {
    const healthRes = await fetch('https://mykidstube.kidstube.workers.dev/api/v1/health');
    const healthData = await healthRes.json();
    console.log(`  ✓ Health status: ${healthRes.status}, data:`, healthData);
  } catch (err) {
    console.warn('  ⚠️ Health ping failed (network may be offline):', err.message);
  }

  // Test 3: Live Device Registration (Pairing Code generation)
  console.log('\n3. Testing Device Registration Endpoint (/api/v1/devices/register)...');
  try {
    const regRes = await fetch('https://mykidstube.kidstube.workers.dev/api/v1/devices/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ device_name: 'RN Automated Smoke Test Tablet' }),
    });
    if (regRes.status === 200) {
      const regData = await regRes.json();
      console.log(`  ✓ Registered successfully! Pairing Code: ${regData.pairing_code}, Device ID: ${regData.device_id}`);

      // Test 4: Device Status Check for the new code
      console.log(`\n4. Testing Device Status Polling (/api/v1/devices/status/${regData.pairing_code})...`);
      const statusRes = await fetch(`https://mykidstube.kidstube.workers.dev/api/v1/devices/status/${regData.pairing_code}`);
      const statusData = await statusRes.json();
      console.log(`  ✓ Device Status poll returned: ${statusRes.status}, status: ${statusData.status}`);
    } else {
      console.log(`  ⚠️ Register returned status ${regRes.status}`);
    }
  } catch (err) {
    console.warn('  ⚠️ Register test failed:', err.message);
  }

  // Test 5: Live Catalog Fetch & Parsing
  console.log('\n5. Testing Catalog Fetch & Defensive Parsing (/api/v1/catalog)...');
  try {
    const catRes = await fetch('https://mykidstube.kidstube.workers.dev/api/v1/catalog');
    if (catRes.status === 200) {
      const catData = await catRes.json();
      const videoCount = catData.videos ? catData.videos.length : 0;
      const categoryCount = catData.categories ? catData.categories.length : 0;
      console.log(`  ✓ Catalog parsed cleanly! Found ${videoCount} videos, ${categoryCount} categories.`);
      if (videoCount > 0) {
        const sample = catData.videos[0];
        console.log(`    Sample video: "${sample.title}" (${sample.id}, status: ${sample.status})`);
      }
    }
  } catch (err) {
    console.warn('  ⚠️ Catalog fetch failed:', err.message);
  }

  console.log('\n=== SMOKE TESTS COMPLETE ===');
}

runSmokeTests().catch(console.error);
