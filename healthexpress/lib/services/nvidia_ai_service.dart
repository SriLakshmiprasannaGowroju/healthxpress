import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class NvidiaAiResponse {
  final String content;
  final List<String> detectedSymptoms;
  final bool wantsMedicines;
  final List<String> actionSuggestions;
  final String triageCategory;

  NvidiaAiResponse({
    required this.content,
    this.detectedSymptoms = const [],
    this.wantsMedicines = false,
    this.actionSuggestions = const [],
    this.triageCategory = 'General Inquiry',
  });
}

class NvidiaAiService {
  static const String _nvidiaEndpoint = '${AppConfig.nvidiaApiBaseUrl}/chat/completions';
  static const String _nvidiaApiKey = AppConfig.nvidiaApiKey;
  static const String _nvidiaModel = AppConfig.nvidiaModel;

  static const String _sarvamEndpoint = AppConfig.sarvamChatEndpoint;
  static const String _sarvamModel = AppConfig.sarvamChatModel;

  /// Generate intelligent clinical response using Sarvam AI (CORS-compliant for Web)
  /// and NVIDIA NIM API (for native/mobile platforms)
  static Future<NvidiaAiResponse> generateResponse({
    required String userQuery,
    List<Map<String, String>> conversationHistory = const [],
    String lang = 'en',
    String? patientName,
    int? patientAge,
    String? gender,
    List<String>? currentSymptoms,
    String? symptomDuration,
    String? bodyTemperature,
    int intakeTurn = 1,
    String? knownSeverity,
    String? knownPastHistory,
    String? knownExistingMeds,
    bool isVoiceMode = false,
  }) async {
    final trimmedQuery = userQuery.trim();
    final isGreeting = _isGreeting(trimmedQuery);
    final userWantsMedicines = _wantsMedicines(trimmedQuery);
    final isShortQuery = trimmedQuery.split(RegExp(r'\s+')).length <= 6;
    final extracted = extractSymptoms(trimmedQuery, lang);
    final allSymptoms = <String>{...?currentSymptoms, ...extracted}.toList();
    final category = _categorizeQuery(trimmedQuery);

    // Determine conversational intake stage:
    final String intakeStage;
    if (isVoiceMode) {
      intakeStage = 'STAGE_VOICE_CALL_CONVERSATION';
    } else if (intakeTurn >= 4 || (intakeTurn >= 3 && symptomDuration != null && knownPastHistory != null)) {
      intakeStage = 'STAGE_4_RECOMMENDATIONS_AND_MEDS';
    } else if (intakeTurn <= 1) {
      intakeStage = 'STAGE_1_CHIEF_COMPLAINT';
    } else if (intakeTurn == 2) {
      intakeStage = 'STAGE_2_SYMPTOM_DETAILS';
    } else {
      intakeStage = 'STAGE_3_HISTORY_MEDS';
    }

    // Dynamic Max Tokens: ultra-compact (85 tokens) for voice call mode to achieve < 250ms latency,
    // compact for fast question turns, rich for final triage & meds
    final maxTokens = isVoiceMode ? 85 : ((intakeStage != 'STAGE_4_RECOMMENDATIONS_AND_MEDS') ? 160 : 450);

    final systemPrompt = _buildSystemPrompt(
      lang: lang,
      intakeStage: intakeStage,
      isGreeting: isGreeting,
      isShortQuery: isShortQuery,
      patientName: patientName,
      patientAge: patientAge,
      gender: gender,
      symptoms: allSymptoms,
      symptomDuration: symptomDuration,
      bodyTemperature: bodyTemperature,
      intakeTurn: intakeTurn,
      knownSeverity: knownSeverity,
      knownPastHistory: knownPastHistory,
      knownExistingMeds: knownExistingMeds,
      isVoiceMode: isVoiceMode,
    );

    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add recent conversation history for context retention (last 8 messages)
    final recentHistory = conversationHistory.length > 8
        ? conversationHistory.sublist(conversationHistory.length - 8)
        : conversationHistory;
    for (final msg in recentHistory) {
      if (msg['role'] != null && msg['content'] != null) {
        messages.add({
          'role': msg['role']!,
          'content': msg['content']!,
        });
      }
    }

    // Add current user turn
    messages.add({
      'role': 'user',
      'content': trimmedQuery,
    });

    // 1. On Web (kIsWeb), browsers enforce CORS. Sarvam AI supports CORS natively.
    if (kIsWeb) {
      final sarvamContent = await _callSarvam(messages, maxTokens);
      if (sarvamContent != null && sarvamContent.isNotEmpty) {
        final cleaned = _cleanLlmContent(sarvamContent, lang, allSymptoms);
        return NvidiaAiResponse(
          content: cleaned,
          detectedSymptoms: allSymptoms,
          wantsMedicines: userWantsMedicines,
          actionSuggestions: _generateSuggestions(
            intakeStage: intakeStage,
            lang: lang,
            query: trimmedQuery,
            patientName: patientName,
            symptoms: allSymptoms,
          ),
          triageCategory: category,
        );
      }
    } else {
      // 2. On Mobile / Desktop (non-web), try NVIDIA NIM first with Sarvam fallback
      final nvidiaContent = await _callNvidia(messages, maxTokens);
      if (nvidiaContent != null && nvidiaContent.isNotEmpty) {
        final cleaned = _cleanLlmContent(nvidiaContent, lang, allSymptoms);
        return NvidiaAiResponse(
          content: cleaned,
          detectedSymptoms: allSymptoms,
          wantsMedicines: userWantsMedicines,
          actionSuggestions: _generateSuggestions(
            intakeStage: intakeStage,
            lang: lang,
            query: trimmedQuery,
            patientName: patientName,
            symptoms: allSymptoms,
          ),
          triageCategory: category,
        );
      }

      final sarvamContent = await _callSarvam(messages, maxTokens);
      if (sarvamContent != null && sarvamContent.isNotEmpty) {
        final cleaned = _cleanLlmContent(sarvamContent, lang, allSymptoms);
        return NvidiaAiResponse(
          content: cleaned,
          detectedSymptoms: allSymptoms,
          wantsMedicines: userWantsMedicines,
          actionSuggestions: _generateSuggestions(
            intakeStage: intakeStage,
            lang: lang,
            query: trimmedQuery,
            patientName: patientName,
            symptoms: allSymptoms,
          ),
          triageCategory: category,
        );
      }
    }

    // Dynamic offline clinical fallback if network is unreachable
    return _buildFallbackResponse(
      userQuery: trimmedQuery,
      lang: lang,
      intakeStage: intakeStage,
      isGreeting: isGreeting,
      isShortQuery: isShortQuery,
      userWantsMedicines: userWantsMedicines,
      patientName: patientName,
      patientAge: patientAge,
      symptoms: allSymptoms,
      symptomDuration: symptomDuration,
      knownSeverity: knownSeverity,
      knownPastHistory: knownPastHistory,
      knownExistingMeds: knownExistingMeds,
    );
  }

  /// Clean tool calls, thoughts, technical XML tags, and ALL emojis from LLM responses
  static String _cleanLlmContent(String raw, String lang, List<String> symptoms) {
    var text = raw;
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    text = text.replaceAll(RegExp(r'<tool_call>[\s\S]*?</tool_call>'), '');
    text = text.replaceAll(RegExp(r'<tool_response>[\s\S]*?</tool_response>'), '');
    text = text.replaceAll(RegExp(r'\[/?TOOL_CALLS?\]'), '');
    text = text.replaceAll(RegExp(r'```json[\s\S]*?```'), '');
    // Strictly strip all Unicode emojis and pictographs
    text = text.replaceAll(
      RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}\u{200D}\u{FE0F}]', unicode: true),
      '',
    );
    text = text.trim();
    return text;
  }

  /// Call Sarvam AI conversational LLM (CORS-friendly on Web) with automatic fallback key support
  static Future<String?> _callSarvam(List<Map<String, String>> messages, int maxTokens) async {
    for (final key in AppConfig.sarvamApiKeys) {
      try {
        final response = await http
            .post(
              Uri.parse(_sarvamEndpoint),
              headers: {
                'api-subscription-key': key,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': _sarvamModel,
                'messages': messages,
                'temperature': 0.5,
                'max_tokens': maxTokens,
              }),
            )
            .timeout(const Duration(seconds: 14));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content']?.toString().trim() ?? '';
            if (content.isNotEmpty) {
              return content;
            }
          }
        } else {
          debugPrint('Sarvam AI API status ${response.statusCode} for key: ${response.body}');
        }
      } catch (e) {
        debugPrint('Sarvam AI request notice for key: $e');
      }
    }
    return null;
  }

  /// Call NVIDIA NIM API (for native/mobile environments)
  static Future<String?> _callNvidia(List<Map<String, String>> messages, int maxTokens) async {
    try {
      final response = await http
          .post(
            Uri.parse(_nvidiaEndpoint),
            headers: {
              'Authorization': 'Bearer $_nvidiaApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _nvidiaModel,
              'messages': messages,
              'temperature': 0.5,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(const Duration(seconds: 14));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content']?.toString().trim() ?? '';
          if (content.isNotEmpty) {
            return content;
          }
        }
      } else {
        debugPrint('NVIDIA API status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('NVIDIA API notice: $e');
    }
    return null;
  }

  static bool _isGreeting(String text) {
    final lower = text.toLowerCase().trim();
    return lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'namaste' ||
        lower == 'నమస్కారం' ||
        lower == 'నమస్తే' ||
        lower == 'नमस्ते' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ');
  }


  static bool _wantsMedicines(String text) {
    final lower = text.toLowerCase();
    return lower.contains('medicine') ||
        lower.contains('tablet') ||
        lower.contains('drug') ||
        lower.contains('capsule') ||
        lower.contains('syrup') ||
        lower.contains('dosage') ||
        lower.contains('what should i take') ||
        lower.contains('suggest medicine') ||
        lower.contains('prescribe') ||
        lower.contains('prescription') ||
        lower.contains('what should i do') ||
        lower.contains('what to do') ||
        lower.contains('suggest medicine') ||
        lower.contains('మందులు') ||
        lower.contains('దవా') ||
        lower.contains('दवा');
  }

  static String _buildSystemPrompt({
    required String lang,
    required String intakeStage,
    required bool isGreeting,
    required bool isShortQuery,
    String? patientName,
    int? patientAge,
    String? gender,
    List<String> symptoms = const [],
    String? symptomDuration,
    String? bodyTemperature,
    int intakeTurn = 1,
    String? knownSeverity,
    String? knownPastHistory,
    String? knownExistingMeds,
    bool isVoiceMode = false,
  }) {
    final languageDirective = lang == 'te'
        ? 'Strictly reply in fluent, respectful, natural Telugu (తెలుగు).'
        : (lang == 'hi'
            ? 'Strictly reply in fluent, natural, caring Hindi (हिंदी).'
            : 'Reply in clear, professional, warm and conversational English.');

    if (isVoiceMode) {
      return '''
You are HealthExpress AI, a caring, expert clinical voice assistant on a live real-time voice call.
$languageDirective

VOICE CALL RULES:
1. Speak naturally like a real doctor speaking to a patient on the phone.
2. Be warm, empathetic, clear, and very concise (1 to 2 short sentences max).
3. Do NOT use emojis, bullet points, asterisks, bold formatting, markdown, or numbered lists.
4. STRICT QUESTION LIMIT: Ask at most 1 to 2 short questions per turn. NEVER ask multiple or long lists of questions at once.
5. In early turns, ask 1-2 quick questions about duration or severity. Once symptoms and duration are clear, give direct advice and recommended medicines.
''';
    }

    final knownProfile = '''
Patient Profile Known So Far:
- Name: ${patientName ?? "Unknown"}
- Age: ${patientAge != null ? "$patientAge years" : "Unknown"}
- Reported Symptoms: ${symptoms.isNotEmpty ? symptoms.join(', ') : "None reported yet"}
- Duration: ${symptomDuration ?? "Unknown"}
- Severity / Progression: ${knownSeverity ?? "Unknown"}
- Past Medical History: ${knownPastHistory ?? "Unknown"}
- Current Medications Taken: ${knownExistingMeds ?? "None mentioned yet"}
- Current Intake Turn: $intakeTurn
''';

    return '''
You are HealthExpress AI, a caring, empathetic, and knowledgeable clinical doctor assistant.
$languageDirective

STRICT RULES:
1. NO EMOJIS: Do NOT use any emojis whatsoever in your responses. Emojis are strictly banned.
2. CONVERSATIONAL TONE: Speak naturally, warmly, and compassionately like an experienced doctor talking to a patient. Avoid rigid or robotic formulas.
3. STRICT 2 QUESTIONS PER TURN (NO QUESTION DUMPING):
   - In any questioning round, ask EXACTLY 2 short, focused clinical questions.
   - NEVER ask more than 2 questions in a single response. Never list 3, 4, or 5 questions at once.
   - Collect clinical understanding progressively across multiple rounds.
4. MULTI-ROUND INTAKE BEFORE MEDICINE RECOMMENDATIONS:
   - For Turn 1, Turn 2, and Turn 3, do NOT prescribe medicines yet. Gather information through 2 questions per round.
   - In Stage 4 (after having gathered proper knowledge of symptoms, duration, and severity), synthesize your assessment and provide specific medicine recommendations.

$knownProfile

STAGE-BY-STAGE GUIDELINES:
- **STAGE 1 (Chief Complaint & Duration - EXACTLY 2 QUESTIONS)**:
  * Acknowledge the user's reported discomfort warmly and empathetically.
  * Ask EXACTLY 2 questions:
    1. How many days or hours have you been experiencing this?
    2. Have you noticed any fever, chills, or headache along with this?
  * Do NOT prescribe medicines in Stage 1.

- **STAGE 2 (Severity & Associated Symptoms - EXACTLY 2 QUESTIONS)**:
  * Acknowledge their reported duration and symptoms (${symptoms.isNotEmpty ? symptoms.join(', ') : "stated issue"}).
  * Ask EXACTLY 2 questions:
    1. How severe is the discomfort (mild, moderate, or severe)?
    2. Are you experiencing any nausea, vomiting, cough, or stomach disturbance?
  * Do NOT prescribe medicines in Stage 2.

- **STAGE 3 (Medical History & Current Medications - EXACTLY 2 QUESTIONS)**:
  * Acknowledge their severity and symptoms.
  * Ask EXACTLY 2 questions:
    1. Have you already taken any tablet or home remedy today?
    2. Do you have any chronic conditions (like Diabetes, Blood Pressure, Acidity, or Asthma) or drug allergies?
  * Do NOT prescribe medicines in Stage 3.

- **STAGE 4 (Conversational Care Plan & Medicine Recommendations)**:
  * Now that you have complete knowledge of the patient's condition, deliver the comprehensive care guidance:
    * Clinical Assessment: A concise, reassuring explanation of what the symptoms indicate.
    * Recommended Medications and Dosage: Specific first-line OTC remedies (e.g., Paracetamol 650mg, Pantoprazole 40mg, ORS) with exact dosage, timing (after food / before food), and duration.
    * Home Care and Nutrition: 2-3 practical tips (warm fluids, rest, light diet).
    * Red Flags: When to consult a physician or visit a hospital.
    * Do NOT ask further questions in Stage 4.
''';
  }

  static List<String> _generateSuggestions({
    required String intakeStage,
    required String lang,
    required String query,
    String? patientName,
    List<String> symptoms = const [],
  }) {
    if (intakeStage == 'STAGE_1_CHIEF_COMPLAINT') {
      if (lang == 'te') {
        return ['తీవ్రమైన జ్వరం & తలనొప్పి', 'కడుపు నొప్పి & ఎసిడిటీ', 'దగ్గు & గొంతు నొప్పి', 'కీళ్ళ & మోకాళ్ళ నొప్పులు'];
      } else if (lang == 'hi') {
        return ['तेज बुखार और सिरदर्द', 'पेट दर्द और एसिडिटी', 'खांसी और गले में दर्द', 'घुटनों और जोड़ों में दर्द'];
      }
      return ['High fever & headache', 'Stomach ache & acidity', 'Throat pain & cough', 'Joint & knee pain'];
    }

    if (intakeStage == 'STAGE_2_SYMPTOM_DETAILS') {
      if (lang == 'te') {
        return ['నిన్నటి నుండి (మధ్యస్థంగా)', '2-3 రోజుల నుండి (తీవ్రంగా)', 'జ్వరం 102°F & చలి ఉంది', 'వాంతులు & వికారం ఉన్నాయి'];
      } else if (lang == 'hi') {
        return ['कल से (मध्यम दर्द)', '2-3 दिनों से (गंभीर)', 'बुखार 102°F और कंपकंपी', 'उल्टी और जी मिचलाना'];
      }
      return ['Since yesterday (moderate)', '2 - 3 days (severe)', 'Fever is 102°F with chills', 'Having nausea & vomiting'];
    }

    if (intakeStage == 'STAGE_3_HISTORY_MEDS') {
      if (lang == 'te') {
        return ['ఎటువంటి ఇతర వ్యాధులు లేవు', 'షుగర్ & బీపీ ఉన్నాయి', 'పారాసిటమాల్ వేసుకున్నాను', 'ఎటువంటి అలర్జీలు లేవు'];
      } else if (lang == 'hi') {
        return ['कोई पुरानी बीमारी नहीं है', 'शुगर और बीपी है', 'पैरासिटामोल लिया है', 'कोई एलर्जी नहीं है'];
      }
      return ['No prior chronic conditions', 'Have Diabetes & High BP', 'Took 1 Paracetamol already', 'No known drug allergies'];
    }

    // Dynamic Stage 4 Clinical Triage / Follow-up suggestions based on user issue
    final lower = '${query.toLowerCase()} ${symptoms.join(' ').toLowerCase()}';

    // 1. Stomach Ache / Gastric / Acidity
    if (lower.contains('stomach') || lower.contains('gastric') || lower.contains('acidity') || lower.contains('కడుపు') || lower.contains('గ్యాస్') || lower.contains('पेट') || lower.contains('एसिडिटी') || lower.contains('vomit') || lower.contains('వాంతులు') || lower.contains('उल्टी')) {
      if (lang == 'te') {
        return ['Pantoprazole మందు ఆర్డర్ (15 నిమి)', 'ఎసిడిటీ ఇంటి చిట్కాలు', 'గ్యాస్ట్రోఎంటరాలజిస్ట్ అపాయింట్‌మెంట్', 'LFT లివర్ టెస్ట్'];
      } else if (lang == 'hi') {
        return ['Pantoprazole दवा ऑर्डर करें', 'एसिडिटी के घरेलू उपाय', 'पेट रोग विशेषज्ञ से परामर्श', 'LFT लिवर टेस्ट बुक करें'];
      }
      return ['Order Pantoprazole (15 mins)', 'Safe home relief for acidity', 'Consult Gastroenterologist', 'Liver & Kidney Profile (LFT+KFT)'];
    }

    // 2. Headache / Migraine
    if (lower.contains('headache') || lower.contains('migraine') || lower.contains('head pain') || lower.contains('తలనొప్పి') || lower.contains('తల నొప్పి') || lower.contains('सिरदर्द') || lower.contains('माइग्रेन')) {
      if (lang == 'te') {
        return ['పారాసిటమాల్ ఆర్డర్ చేయండి (15 నిమి)', 'మైగ్రేన్ ఉపశమన చిట్కాలు', 'న్యూరాలజిస్ట్ డాక్టర్‌ని సంప్రదించండి', 'రక్తపోటు తనిఖీ'];
      } else if (lang == 'hi') {
        return ['पैरासिटामोल दवा मंगाएं', 'सिरदर्द में तुरंत राहत उपाय', 'न्यूरोलॉजिस्ट डॉक्टर से परामर्श', 'बीपी जांच कराएं'];
      }
      return ['Order Pain Relief Medicine (15 mins)', 'Migraine relief techniques', 'Book Neurologist (Dr. Sunil Kumar)', 'Check Blood Pressure'];
    }

    // 3. Cold, Cough & Sore Throat
    if (lower.contains('cough') || lower.contains('cold') || lower.contains('throat') || lower.contains('దగ్గు') || lower.contains('జలుబు') || lower.contains('గొంతు') || lower.contains('खांसी') || lower.contains('जुकाम') || lower.contains('गला')) {
      if (lang == 'te') {
        return ['కాఫ్ సిరప్ & సెట్రిజిన్ ఆర్డర్', 'గొంతు నొప్పికి గార్గల్ చిట్కాలు', 'ENT స్పెషలిస్ట్‌ని సంప్రదించండి', 'స్టీమ్ ఇన్హేలేషన్ గైడ్'];
      } else if (lang == 'hi') {
        return ['कफ सिरप व सिट्रीजिन ऑर्डर करें', 'गले के दर्द के लिए गरारे के उपाय', 'ईएनटी विशेषज्ञ से परामर्श', 'भाप लेने की विधि'];
      }
      return ['Order Cough Syrup & Cetirizine', 'Throat soothing steam & gargles', 'Book ENT Specialist (Dr. Vikram)', 'Viral Infection Panel'];
    }

    // 4. Joint, Knee & Back Pain
    if (lower.contains('knee') || lower.contains('joint') || lower.contains('back') || lower.contains('spine') || lower.contains('arthritis') || lower.contains('మోకాలు') || lower.contains('కీళ్ళ') || lower.contains('నడుము') || lower.contains('घुटनों') || lower.contains('कमर') || lower.contains('जोड़ों')) {
      if (lang == 'te') {
        return ['హీట్ థెరపీ ర్యాప్ ఆర్డర్', 'కీళ్ళ నొప్పుల వ్యాయామాలు', 'ఆర్థోపెడిక్ డాక్టర్ కన్సల్టేషన్', 'బోన్ డెన్సిటీ & కాల్షియం టెస్ట్'];
      } else if (lang == 'hi') {
        return ['हीट थेरेपी नी-रैप मंगाएं', 'जोड़ों के दर्द के सरल व्यायाम', 'ऑर्थोपेडिक डॉक्टर से परामर्श', 'कैल्शियम व विटामिन डी टेस्ट'];
      }
      return ['Order Heat Therapy Knee Wrap', 'Safe knee joint exercises', 'Consult Orthopedic Surgeon (Dr. Naveen)', 'Calcium & Vitamin D Lab Panel'];
    }

    // 5. Fever & Infection
    if (lower.contains('fever') || lower.contains('temp') || lower.contains('జ్వరం') || lower.contains('బుఖార్') || lower.contains('बुखार')) {
      if (lang == 'te') {
        return ['పారాసిటమాల్ 650mg ఆర్డర్ (15 నిమి)', 'జ్వరం తగ్గించే ఇంటి చిట్కాలు', 'CBC & డెంగ్యూ టెస్ట్ బుక్ చేయండి', 'వైద్యుడిని సంప్రదించండి'];
      } else if (lang == 'hi') {
        return ['पैरासिटामोल 650mg ऑर्डर करें', 'बुखार कम करने के घरेलू उपाय', 'सीबीसी और डेंगू टेस्ट बुक करें', 'डॉक्टर से वीडियो परामर्श'];
      }
      return ['Order Paracetamol 650mg (15 mins)', 'Safe fever home care & hydration', 'Book CBC & Dengue Antigen Test', 'Consult Telehealth Doctor'];
    }

    if (lang == 'te') {
      return ['సిఫార్సు చేసిన మందులు ఆర్డర్', 'ఇంటి చిట్కాలు', 'డాక్టర్‌ని సంప్రదించండి', 'ల్యాబ్ టెస్ట్‌లు'];
    } else if (lang == 'hi') {
      return ['सुझाई गई दवाएं ऑर्डर करें', 'घरेलू उपाय', 'डॉक्टर से परामर्श', 'लैब टेस्ट बुक करें'];
    }
    return ['Order prescribed medicines', 'Personalized home care tips', 'Book specialist doctor', 'Recommended diagnostic tests'];
  }

  /// Extract clinical symptoms from text across English, Telugu, and Hindi
  static List<String> extractSymptoms(String text, String lang) {
    final lower = text.toLowerCase();
    final List<String> detected = [];

    final map = {
      'Fever & Chills': ['fever', 'temperature', 'chills', 'shivering', '100', '101', '102', '103', '104', 'జ్వరం', 'చలి', 'బుఖార్', 'तापमान', 'बुखार', 'कपकपी'],
      'Headache & Migraine': ['headache', 'head pain', 'migraine', 'throbbing head', 'తలనొప్పి', 'తల నొప్పి', 'మైగ్రేన్', 'सिरदर्द', 'सिर दर्द', 'माइग्रेन'],
      'Cold, Cough & Throat': ['throat', 'cough', 'cold', 'sore throat', 'congestion', 'runny nose', 'pharyngitis', 'గొంతు', 'దగ్గు', 'జలుబు', 'ముక్కు కారడం', 'खांसी', 'जुकाम', 'गले में खराश', 'गला दर्द'],
      'Body Ache & Fatigue': ['body pain', 'body ache', 'muscle pain', 'fatigue', 'weakness', 'tiredness', 'ఒంటి నొప్పులు', 'ఒళ్ళు నొప్పులు', 'నీరసం', 'బలహీనత', 'बदन दर्द', 'कमजोरी', 'थकान'],
      'Acidity & Gastric': ['acidity', 'acid reflux', 'heartburn', 'gas', 'bloating', 'belching', 'gerd', 'ఎసిడిటీ', 'గ్యాస్', 'మంట', 'छाती में जलन', 'गैस', 'एसिडिटी'],
      'Stomach Ache & Nausea': ['stomach', 'abdomen', 'cramps', 'vomit', 'nausea', 'loose motions', 'diarrhea', 'కడుపు నొప్పి', 'వాంతులు', 'విరేచనాలు', 'జీర్ణసమస్య', 'पेट दर्द', 'उल्टी', 'दस्त'],
      'Joint & Knee Pain': ['joint', 'knee', 'backache', 'back pain', 'spine', 'arthritis', 'sciatica', 'మోకాలు', 'కీళ్ళ', 'నడుము నొప్పి', 'వెన్ను నొప్పి', 'घुटनों में दर्द', 'जोड़ों का दर्द', 'कमर दर्द'],
      'Hypertension & Cardiac': ['bp', 'blood pressure', 'chest pain', 'chest tightness', 'palpitations', 'heart rate', 'రక్తపోటు', 'బ్లడ్ ప్రెషర్', 'ఛాతీ నొప్పి', 'గుండె దడ', 'बीपी', 'रक्तचाप'],
      'Diabetes & High Sugar': ['sugar', 'diabetes', 'glucose', 'frequent thirst', 'frequent urination', 'షుగర్', 'మధుమేహం', 'డయాబెటిస్', 'शुगर', 'मधुमेह'],
      'Skin Allergy & Rash': ['rash', 'itching', 'allergy', 'redness', 'hive', 'దురద', 'అలర్జీ', 'దద్దుర్లు', 'खुजली', 'एलर्जी'],
      'Eye Irritation': ['eye pain', 'eye redness', 'burning eyes', 'కంటి నొప్పి', 'కళ్ళు ఎర్రబడటం', 'आंख में दर्द'],
    };

    map.forEach((symptom, keywords) {
      for (final kw in keywords) {
        if (lower.contains(kw)) {
          if (!detected.contains(symptom)) detected.add(symptom);
          break;
        }
      }
    });

    return detected;
  }

  static String _categorizeQuery(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('chest pain') || lower.contains('unconscious') || lower.contains('severe breath') || lower.contains('heart attack') || lower.contains('గుండె నొప్పి')) {
      return 'Emergency Urgent';
    }
    if (lower.contains('fever') || lower.contains('chills') || lower.contains('101') || lower.contains('102') || lower.contains('జ్వరం') || lower.contains('बुखार')) {
      return 'Fever & Viral Infection';
    }
    if (lower.contains('throat') || lower.contains('cough') || lower.contains('cold') || lower.contains('congestion') || lower.contains('గొంతు') || lower.contains('దగ్గు') || lower.contains('खांसी')) {
      return 'Upper Respiratory & ENT';
    }
    if (lower.contains('headache') || lower.contains('migraine') || lower.contains('తలనొప్పి') || lower.contains('सिरदर्द')) {
      return 'Headache & Neurological';
    }
    if (lower.contains('stomach') || lower.contains('acidity') || lower.contains('gas') || lower.contains('vomit') || lower.contains('loose motions') || lower.contains('కడుపు') || lower.contains('ఎసిడిటీ') || lower.contains('पेट')) {
      return 'Gastroenterology & Acidity';
    }
    if (lower.contains('knee') || lower.contains('joint') || lower.contains('back') || lower.contains('arthritis') || lower.contains('మోకాలు') || lower.contains('కీళ్ళ') || lower.contains('घुटनों') || lower.contains('जोड़ों')) {
      return 'Orthopedic & Joint Care';
    }
    if (lower.contains('sugar') || lower.contains('diabetes') || lower.contains('షుగర్') || lower.contains('मधुमेह')) {
      return 'Diabetes & Metabolic Care';
    }
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('palpitations') || lower.contains('రక్తపోటు') || lower.contains('रक्तचाप')) {
      return 'Cardiology & Hypertension';
    }
    if (lower.contains('rash') || lower.contains('itching') || lower.contains('allergy') || lower.contains('దురద') || lower.contains('खुजली')) {
      return 'Dermatology & Allergy';
    }
    return 'General Clinical Inquiry';
  }

  static NvidiaAiResponse _buildFallbackResponse({
    required String userQuery,
    required String lang,
    required String intakeStage,
    required bool isGreeting,
    required bool isShortQuery,
    required bool userWantsMedicines,
    String? patientName,
    int? patientAge,
    List<String> symptoms = const [],
    String? symptomDuration,
    String? knownSeverity,
    String? knownPastHistory,
    String? knownExistingMeds,
  }) {
    String reply;
    final name = patientName ?? 'there';
    final sympStr = symptoms.isNotEmpty ? symptoms.join(', ') : 'your symptoms';

    switch (intakeStage) {
      case 'STAGE_1_CHIEF_COMPLAINT':
        if (lang == 'te') {
          reply = 'నమస్కారం $name గారు. నేను మీ HealthExpress క్లినికల్ సహాయకుడిని.\n\nమీ సమస్యను సరిగ్గా అర్థం చేసుకోవడానికి, మీరు ప్రస్తుతం ఎదుర్కొంటున్న సమస్య లేదా లక్షణాలు ఏమిటో మరియు ఈ సమస్య ఎన్ని రోజుల నుండి ఉందో దయచేసి చెప్పగలరా?';
        } else if (lang == 'hi') {
          reply = 'नमस्ते $name जी। मैं आपका HealthExpress क्लिनिकल सहायक हूँ।\n\nआपकी सही मदद करने के लिए, क्या आप बता सकते हैं कि आपको मुख्य रूप से क्या तकलीफ है और यह परेशानी कितने दिनों से हो रही है?';
        } else {
          reply = 'Hello $name, I am your HealthExpress Clinical AI assistant.\n\nTo understand your condition properly, could you tell me what specific symptoms you are experiencing, and how many days or hours you have been having this discomfort?';
        }
        break;

      case 'STAGE_2_SYMPTOM_DETAILS':
        if (lang == 'te') {
          reply = '$name గారు, మీకు $sympStr ఉన్నట్లు అర్థమైంది.\n\nఈ సమస్య ఎంత తీవ్రంగా ఉంది (తక్కువగానా లేక తీవ్రంగానా)? అలాగే దీనితో పాటు చలి, వాంతులు, తలనొప్పి లేదా గొంతు నొప్పి లాంటి ఇతర లక్షణాలు ఏమైనా ఉన్నాయా?';
        } else if (lang == 'hi') {
          reply = '$name जी, मैं समझ गया कि आपको $sympStr की शिकायत है।\n\nयह दर्द या परेशानी कितनी तेज है? क्या इसके साथ आपको बुखार, उल्टी, ठंड लगना या गले में दर्द जैसे अन्य लक्षण भी महसूस हो रहे हैं?';
        } else {
          reply = 'I understand you are dealing with $sympStr, $name.\n\nCould you tell me how severe the discomfort feels, and whether you are noticing any other symptoms such as chills, nausea, headache, or sore throat?';
        }
        break;

      case 'STAGE_3_HISTORY_MEDS':
        if (lang == 'te') {
          reply = 'వివరాలు తెలిపినందుకు ధన్యవాదాలు $name గారు. సరైన మందులు సూచించే ముందు:\n\nమీకు షుగర్, బీపీ, ఆస్తమా లేదా గ్యాస్ వంటి దీర్ఘకాలిక సమస్యలు ఏమైనా ఉన్నాయా? అలాగే ఈ రోజు ఇప్పటికే ఏదైనా టాబ్లెట్ తీసుకున్నారా, లేదా ఏదైనా మందుల అలర్జీ ఉందా?';
        } else if (lang == 'hi') {
          reply = 'जानकारी के लिए धन्यवाद $name जी। सही सलाह देने के लिए बस यह बता दीजिए:\n\nक्या आपको पहले से कोई पुरानी बीमारी (जैसे शुगर, बीपी, अस्थमा या एसिडिटी) है? क्या आज आपने पहले से कोई दवा ली है, या किसी दवा से एलर्जी है?';
        } else {
          reply = 'Thank you for sharing that, $name. Before I provide tailored recommendations:\n\nDo you have any existing health conditions (such as Diabetes, High BP, Acidity, or Asthma)? Also, have you taken any medicines today, or do you have any known drug allergies?';
        }
        break;

      case 'STAGE_4_RECOMMENDATIONS_AND_MEDS':
      default:
        if (lang == 'te') {
          reply = 'నమస్కారం $name గారు, మీరు తెలిపిన లక్షణాల ($sympStr) ఆధారంగా మీ కేర్ ప్లాన్ మరియు సలహాలు:\n\n'
              'క్లినికల్ విశ్లేషణ:\n'
              'మీరు తెలిపిన లక్షణాలు మరియు వ్యవధి ఆధారంగా, ఇది సాధారణ సీజనల్ ఇన్ఫెక్షన్ లేదా అక్యూట్ గ్యాస్ట్రిక్ సమస్య కావచ్చు.\n\n'
              'సిఫార్సు చేసిన మందులు & మోతాదు:\n'
              '• పారాసిటమాల్ 650mg (Dolo / Calpol): జ్వరం లేదా ఒంటి నొప్పులు ఉంటే ఆహారం తర్వాత 1 మాత్ర (అవసరమైతే రోజుకు 2 సార్లు).\n'
              '• పాంటోప్రజోల్ 40mg (Pan-40): ఎసిడిటీ / కడుపు మంట నివారణకు ఉదయం అల్పాహారానికి 30 నిమిషాల ముందు 1 మాత్ర.\n'
              '• ORS ఎలక్ట్రాల్ పౌడర్: డీహైడ్రేషన్ నివారణకు 1 లీటరు తాగునీటిలో కలిపి రోజంతా కొద్దికొద్దిగా త్రాగండి.\n\n'
              'ఇంటి చిట్కాలు & ఆహార నియమాలు:\n'
              '• పుష్కలంగా గోరువెచ్చని నీరు, కొబ్బరి నీళ్ళు లేదా సూప్స్ త్రాగండి.\n'
              '• తేలికగా జీర్ణమయ్యే ఆహారం (ఖిచ్డీ, ఇడ్లీ) తీసుకోండి; కారం, వేపుళ్ళు మానుకోండి.\n'
              '• పూర్తి శారీరక విశ్రాంతి తీసుకోండి.\n\n'
              'వైద్యుడిని ఎప్పుడు సంప్రదించాలి:\n'
              'తీవ్రమైన జ్వరం లేదా నొప్పి 48 గంటల కంటే ఎక్కువ కొనసాగితే జనరల్ ఫిజీషియన్ ని సంప్రదించండి.\n\n'
              'సిఫార్సు చేసిన మందులు, డాక్టర్ కన్సల్టేషన్ మరియు ల్యాబ్ టెస్ట్‌లు క్రింద అందుబాటులో ఉన్నాయి:';
        } else if (lang == 'hi') {
          reply = 'नमस्ते $name जी, आपके बताए गए लक्षणों ($sympStr) के आधार पर आपकी स्वास्थ्य सलाह और देखभाल योजना:\n\n'
              'क्लिनिकल मूल्यांकन:\n'
              'आपके लक्षणों और समय के अनुसार यह मौसमी तीव्र संक्रमण या सामान्य पाचन संबंधी समस्या प्रतीत होती है।\n\n'
              'सुझाई गई दवाएं और खुराक:\n'
              '• पैरासिटामोल 650mg (Dolo): बुखार या बदन दर्द के लिए भोजन के बाद 1 गोली (दिन में अधिकतम 2 बार आवश्यकतानुसार)।\n'
              '• पैंटोप्राजोल 40mg (Pan-40): एसिडिटी व पेट जलन के लिए सुबह खाली पेट नाश्ते से 30 मिनट पहले 1 गोली।\n'
              '• ओआरएस इलेक्ट्राल: शरीर में पानी की कमी न होने पाए इसलिए 1 लीटर पानी में घोलकर दिनभर पिएं।\n\n'
              'घरेलू उपाय और खान-पान:\n'
              '• पर्याप्त गुनगुना पानी पिएं और खुद को हाइड्रेटेड रखें।\n'
              '• सुपाच्य और हल्का भोजन (खिचड़ी, दलिया) लें; तीखा-तला भोजन न खाएं।\n'
              '• पर्याप्त आराम और नींद लें।\n\n'
              'डॉक्टर से कब मिलें:\n'
              'यदि लक्षण 48 घंटे के बाद भी बने रहें तो तुरंत विशेषज्ञ डॉक्टर से परामर्श लें।\n\n'
              'सुझाई गई दवाएं, डॉक्टर अपॉइंटमेंट और आवश्यक टेस्ट नीचे उपलब्ध हैं:';
        } else {
          reply = 'Hello $name, based on your symptoms ($sympStr) and duration, here is your clinical care guidance:\n\n'
              'Clinical Assessment:\n'
              'Based on your reported progression, this is indicative of a mild seasonal or acute condition.\n\n'
              'Recommended First-Line Medications & Dosage:\n'
              '• Tab Paracetamol 650mg (Dolo / Calpol): 1 tablet after meals twice daily as needed for fever or body ache.\n'
              '• Tab Pantoprazole 40mg (Pan-40): 1 tablet once daily in the morning, 30 minutes before breakfast for gastric comfort.\n'
              '• ORS Electral Sachet: Dissolve in 1 Litre of clean water and sip throughout the day for hydration.\n\n'
              'Home Care & Supportive Advice:\n'
              '• Hydration: Drink plenty of warm water, clear soups, and fluids.\n'
              '• Nutrition: Eat light, easily digestible meals such as porridge or soup. Avoid spicy or fried food.\n'
              '• Rest: Ensure adequate sleep and physical rest for proper recovery.\n\n'
              'When to Seek Immediate Care:\n'
              'If high fever, persistent vomiting, or severe pain continues beyond 48 hours, please consult a physician immediately.\n\n'
              'Suggested medicines, doctor consultation, and diagnostic tests are available below:';
        }
        break;
    }

    return NvidiaAiResponse(
      content: reply,
      detectedSymptoms: symptoms.isNotEmpty ? symptoms : extractSymptoms(userQuery, lang),
      wantsMedicines: userWantsMedicines,
      actionSuggestions: _generateSuggestions(
        intakeStage: intakeStage,
        lang: lang,
        query: userQuery,
        patientName: patientName,
        symptoms: symptoms,
      ),
      triageCategory: _categorizeQuery(userQuery),
    );
  }
}
