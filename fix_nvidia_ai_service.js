const fs = require('fs');
const path = 'c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/lib/services/nvidia_ai_service.dart';

let content = fs.readFileSync(path, 'utf8');

// Find the corrupted index
const corruptedMarker = "fatigue', 'ఒళ్ళు నొప్పులు'";
const idx = content.indexOf("fatigue',");
if (idx !== -1) {
  const before = content.substring(0, idx);
  // Find where _buildFallbackResponse starts
  const fallbackIdx = content.indexOf('static NvidiaAiResponse _buildFallbackResponse');
  if (fallbackIdx !== -1) {
    const after = content.substring(fallbackIdx);
    const cleaned = before + '\n\n  ' + after;
    fs.writeFileSync(path, cleaned, 'utf8');
    console.log('Successfully cleaned nvidia_ai_service.dart!');
  } else {
    console.log('Fallback index not found');
  }
} else {
  console.log('Marker not found');
}
