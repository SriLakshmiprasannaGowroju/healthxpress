import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/production_database.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/medicine_model.dart';
import '../models/appointment_model.dart';
import '../models/lab_test_model.dart';
import '../models/business_product_model.dart';
import '../services/nvidia_ai_service.dart';
import '../services/sarvam_live_stt_service.dart';
import '../services/central_data_service.dart';
import '../services/api_service.dart';

class DynamicActionCard {
  final String title;
  final String subtitle;
  final String type; // 'medicine' | 'doctor' | 'test' | 'emergency' | 'product'
  final IconData icon;
  final Color color;
  final dynamic payload;

  DynamicActionCard({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    this.color = const Color(0xFF1E60F6),
    this.payload,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isAudio;
  final List<String>? actionSuggestions;
  final List<String>? detectedSymptoms;
  final List<MedicineModel>? suggestedMedicines;
  final List<BusinessProductModel>? recommendedProducts;
  final List<DoctorModel>? suggestedDoctors;
  final List<LabTestModel>? suggestedLabTests;
  final List<DynamicActionCard>? dynamicCards;
  final bool needsMoreData;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAudio = false,
    this.actionSuggestions,
    this.detectedSymptoms,
    this.suggestedMedicines,
    this.recommendedProducts,
    this.suggestedDoctors,
    this.suggestedLabTests,
    this.dynamicCards,
    this.needsMoreData = false,
  });
}

class AiAssistantProvider extends ChangeNotifier {
  String _selectedLanguage = 'en'; // 'en' | 'te' | 'hi'
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _isLiveVoiceMode = false;
  String _liveTranscription = '';
  Timer? _interimTimer;
  Timer? _callAutoListenTimer;
  Timer? _speechMonitorTimer;

  int? _patientAge;
  String? _patientGender;
  String? _symptomDuration;
  String? _bodyTemperature;
  String? _patientName;
  String? _knownSeverity;
  String? _knownPastHistory;
  String? _knownExistingMeds;
  int _intakeTurnCount = 0;

  String _activeDiagnosis = 'General Health Inquiry';
  String _userInterestSegment = 'Preventive Master Checkups';
  final List<String> _currentSymptoms = [];

  final List<ChatMessage> _messages = [];

  AiAssistantProvider() {
    _initWelcomeMessage();
  }

  @override
  void dispose() {
    _interimTimer?.cancel();
    _callAutoListenTimer?.cancel();
    _speechMonitorTimer?.cancel();
    SarvamLiveSttService.stopSpeaking();
    super.dispose();
  }

  void seedUserContext(UserModel user) {
    if (user.name.isNotEmpty) {
      _patientName = user.name;
    }
    if (user.age > 0) {
      _patientAge = user.age;
    }
    if (user.gender.isNotEmpty) {
      _patientGender = user.gender;
    }
    if (_messages.length <= 1) {
      _initWelcomeMessage();
    }
  }

  void _initWelcomeMessage() {
    _messages.clear();
    _intakeTurnCount = 0;
    _knownSeverity = null;
    _knownPastHistory = null;
    _knownExistingMeds = null;
    final displayName = (_patientName != null && _patientName!.trim().isNotEmpty)
        ? _patientName!.trim().split(' ').first
        : 'there';

    String welcomeText;
    List<String> suggestions;

    if (_selectedLanguage == 'te') {
      welcomeText = 'నమస్కారం $displayName గారు, నేను మీ HealthExpress క్లినికల్ ఏఐ సహాయకుడిని.\n\nమీ ఆరోగ్యం ఎలా ఉంది? మీరు ఎదుర్కొంటున్న సమస్య లేదా లక్షణాలను తెలియజేయండి.';
      suggestions = ['జ్వరం & తలనొప్పి ఉంది', 'కడుపు నొప్పి & గ్యాస్', 'దగ్గు & గొంతు నొప్పి', 'కీళ్ళ & మోకాళ్ళ నొప్పులు'];
    } else if (_selectedLanguage == 'hi') {
      welcomeText = 'नमस्ते $displayName जी, मैं आपका HealthExpress क्लिनिकल एआई सहायक हूँ।\n\nआपकी सेहत कैसी है? कृपया अपनी स्वास्थ्य समस्या या लक्षण बताएं।';
      suggestions = ['बुखार और सिरदर्द', 'पेट दर्द और गैस', 'खांसी और गले में खराश', 'घुटनों में दर्द'];
    } else {
      welcomeText = 'Hello $displayName, I am your HealthExpress Clinical AI Assistant.\n\nHow are you feeling today? Please share what symptoms or health issues you are experiencing.';
      suggestions = ['High fever & headache', 'Stomach pain & acidity', 'Cold & sore throat', 'Joint & knee pain'];
    }

    _messages.add(
      ChatMessage(
        id: 'msg-1',
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
        actionSuggestions: suggestions,
      ),
    );
  }

  // Getters
  String get selectedLanguage => _selectedLanguage;
  bool get isListening => _isListening;
  bool get isThinking => _isThinking;
  bool get isSpeaking => _isSpeaking;
  bool get isLiveVoiceMode => _isLiveVoiceMode;
  String get liveTranscription => _liveTranscription;
  List<ChatMessage> get messages => _messages;
  String get activeDiagnosis => _activeDiagnosis;
  String get userInterestSegment => _userInterestSegment;
  List<String> get currentSymptoms => _currentSymptoms;
  String? get patientName => _patientName;
  int? get patientAge => _patientAge;
  String? get patientGender => _patientGender;
  String? get symptomDuration => _symptomDuration;
  String? get bodyTemperature => _bodyTemperature;

  List<MedicineModel> get suggestedMedicines => _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, '');
  List<DoctorModel> get suggestedDoctors => _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, '');
  List<LabTestModel> get suggestedLabTests => _getLabTestsForContext(_activeDiagnosis, _currentSymptoms, '');
  List<BusinessProductModel> get suggestedBusinessProducts => _getProductsForContext(_activeDiagnosis, _currentSymptoms, '');

  void selectCondition(String condition) {
    _activeDiagnosis = condition;
    if (condition.contains('Cardiac')) {
      _userInterestSegment = 'Cardiology & Hypertension';
    } else if (condition.contains('Fever') || condition.contains('Cold')) {
      _userInterestSegment = 'Preventive Master Checkups';
    }
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_selectedLanguage == lang) return;
    _selectedLanguage = lang;
    _initWelcomeMessage();
    notifyListeners();
  }

  void toggleLiveVoiceMode([bool? forceState]) async {
    _isLiveVoiceMode = forceState ?? !_isLiveVoiceMode;
    if (_isLiveVoiceMode) {
      // Connect to LiveKit Cloud WebRTC voice session
      SarvamLiveSttService.startLiveKitVoiceSession();
      if (!_isSpeaking && !_isThinking && !SarvamLiveSttService.isSpeakingNow()) {
        // When opening the voice call for the first time, speak the doctor greeting first!
        if (_messages.isNotEmpty && _messages.length == 1 && !_messages.first.isUser) {
          speakText(_messages.first.text);
        } else {
          _startVoiceRecognition();
        }
      }
    } else {
      _callAutoListenTimer?.cancel();
      _speechMonitorTimer?.cancel();
      _stopVoiceRecognition();
      stopSpeaking();
      SarvamLiveSttService.stopLiveKitVoiceSession();
    }
    notifyListeners();
  }

  void updatePatientIntake({int? age, String? gender, String? duration, String? temp, String? name}) {
    if (age != null) _patientAge = age;
    if (gender != null) _patientGender = gender;
    if (duration != null) _symptomDuration = duration;
    if (temp != null) _bodyTemperature = temp;
    if (name != null) _patientName = name;
    notifyListeners();
  }

  void toggleVoiceListening([String? customSpokenText]) {
    if (_isListening) {
      _stopVoiceRecognition();
    } else {
      if (!_isSpeaking && !_isThinking && !SarvamLiveSttService.isSpeakingNow()) {
        _startVoiceRecognition(customSpokenText);
      }
    }
  }

  void stopSpeaking() {
    _speechMonitorTimer?.cancel();
    SarvamLiveSttService.stopSpeaking();
    _isSpeaking = false;
    notifyListeners();
  }

  void speakText(String text) {
    // Immediately stop microphone and recording before playing response
    _callAutoListenTimer?.cancel();
    _interimTimer?.cancel();
    _isListening = false;
    stopSpeaking();
    _isSpeaking = true;
    notifyListeners();
    SarvamLiveSttService.speakText(text, _selectedLanguage);

    // Monitor speech playback completion cleanly with instant event detection
    int elapsedTicks = 0;
    bool hasStartedPlaying = false;
    _speechMonitorTimer?.cancel();
    _speechMonitorTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      elapsedTicks++;
      final isPlaying = SarvamLiveSttService.isSpeakingNow();
      final speechJustEnded = SarvamLiveSttService.isSpeechJustEnded();

      if (isPlaying) {
        hasStartedPlaying = true;
      }

      // Check if TTS has completely finished speaking after it was active, or callback fired, or max timeout (35s) reached
      if (speechJustEnded || (hasStartedPlaying && !isPlaying && elapsedTicks > 2) || elapsedTicks > 350) {
        timer.cancel();
        _isSpeaking = false;
        notifyListeners();

        // Real-time phone call flow: immediately restart listening with ultra-low latency (150ms) buffer
        if (_isLiveVoiceMode) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (_isLiveVoiceMode && !_isSpeaking && !_isListening && !_isThinking) {
              _startVoiceRecognition();
            }
          });
        }
      }
    });
  }

  /// Start Real-time Sarvam Live Voice Recording with VAD silence auto-cut
  void _startVoiceRecognition([String? fallbackText]) async {
    // Strictly prevent microphone listening while AI is speaking or thinking
    if (_isSpeaking || _isThinking || SarvamLiveSttService.isSpeakingNow()) {
      return;
    }

    _speechMonitorTimer?.cancel();
    SarvamLiveSttService.stopSpeaking();
    _isSpeaking = false;
    _isListening = true;
    _liveTranscription = _selectedLanguage == 'te'
        ? 'వినబడుతోంది... మాట్లాడండి'
        : (_selectedLanguage == 'hi' ? 'सुन रहा हूँ... बोलिए' : 'Listening... speak now');
    notifyListeners();

    // Start fast real-time VAD silence auto-cut and interim subtitle polling (every 80ms)
    _interimTimer?.cancel();
    _interimTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_isListening) {
        // Instant VAD Auto-Cut: ONLY when user has spoken and then stopped, cut immediately!
        if (SarvamLiveSttService.isSilenceCutoffTriggered()) {
          _interimTimer?.cancel();
          _stopVoiceRecognition();
          return;
        }

        final interim = SarvamLiveSttService.getLiveInterim();
        if (interim.isNotEmpty && interim != _liveTranscription) {
          _liveTranscription = interim;
          notifyListeners();
        }
      }
    });

    await SarvamLiveSttService.startListening(_selectedLanguage);
  }

  /// Stop Sarvam Live Voice Recording, get real-time server transcription, and process immediately
  void _stopVoiceRecognition() async {
    _callAutoListenTimer?.cancel();
    _interimTimer?.cancel();
    _isListening = false;
    notifyListeners();

    final transcript = await SarvamLiveSttService.stopAndTranscribe(_selectedLanguage);
    _liveTranscription = '';

    if (transcript != null && transcript.trim().isNotEmpty) {
      await addUserMessage(transcript.trim(), isVoice: true);
    } else {
      notifyListeners();
      // If user remained silent during the turn in phone call mode, seamlessly resume listening without looping
      if (_isLiveVoiceMode && !_isSpeaking && !_isThinking) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_isLiveVoiceMode && !_isSpeaking && !_isListening && !_isThinking) {
            _startVoiceRecognition();
          }
        });
      }
    }
  }

  /// Process User Message with Sequential Conversational Intake & NVIDIA/Sarvam LLM
  Future<void> addUserMessage(String text, {String? patientName, bool isVoice = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Entity Extraction - Name
    final nameRegex = RegExp(
      r'\b(?:my\s+name\s+is|i\s+am|im|this\s+is|call\s+me|name\s*:\s*|నా\s*పేరు\s*|నాపేరు\s*|मेरा\s*नाम\s*)\s*([a-zA-Z\u0C00-\u0C7F\u0900-\u097F]+(?:\s+[a-zA-Z\u0C00-\u0C7F\u0900-\u097F]+)?)',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(trimmed);
    if (nameMatch != null) {
      final parsed = nameMatch.group(1)?.trim();
      if (parsed != null && parsed.length >= 2 && !parsed.toLowerCase().contains('fever')) {
        _patientName = parsed;
      }
    } else if (_patientName == null) {
      // If patient name is not set yet, check if the reply is simply a name
      final lower = trimmed.toLowerCase();
      final isGreeting = lower == 'hi' || lower == 'hello' || lower == 'hey' || lower == 'నమస్తే' || lower == 'నమస్కారం' || lower == 'नमस्ते';
      final hasNumbers = RegExp(r'\d').hasMatch(trimmed);
      final hasSymptom = NvidiaAiService.extractSymptoms(trimmed, _selectedLanguage).isNotEmpty;
      final words = trimmed.split(RegExp(r'\s+'));
      if (!isGreeting && !hasNumbers && !hasSymptom && words.isNotEmpty && words.length <= 3) {
        final clean = trimmed.replaceAll(RegExp(r'[^\w\s\u0C00-\u0C7F\u0900-\u097F]'), '').trim();
        if (clean.length >= 2) {
          _patientName = clean;
        }
      }
    }

    // 2. Entity Extraction - Age
    final explicitAgeMatch = RegExp(
      r'\b(?:age|వయస్సు|उम्र)\s*[:=]?\s*(\d{1,2})\b|\b(\d{1,2})\s*(?:years?|yrs?|y/o|year\s*old|साल|वर्ष|సంవత్సరాలు|ఏళ్ళు)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (explicitAgeMatch != null) {
      final ageStr = explicitAgeMatch.group(1) ?? explicitAgeMatch.group(2);
      final parsedAge = int.tryParse(ageStr ?? '');
      if (parsedAge != null && parsedAge > 0 && parsedAge < 115) {
        _patientAge = parsedAge;
      }
    } else if (_patientAge == null) {
      final isDuration = RegExp(r'\b(day|days|week|weeks|hour|hours|month|months|రోజు|రోజులు|दिन|घंटे)\b', caseSensitive: false).hasMatch(trimmed);
      final isTemp = RegExp(r'\b(9\d|10\d)(\.\d)?\s*(°?f|degree)?\b', caseSensitive: false).hasMatch(trimmed);
      final standaloneNumberMatch = RegExp(r'^\s*(\d{1,2})\s*$').firstMatch(trimmed);
      if (!isDuration && !isTemp && standaloneNumberMatch != null) {
        final parsedAge = int.tryParse(standaloneNumberMatch.group(1) ?? '');
        if (parsedAge != null && parsedAge >= 1 && parsedAge <= 110) {
          _patientAge = parsedAge;
        }
      }
    }

    // 3. Entity Extraction - Gender
    final genderMatch = RegExp(
      r'\b(male|female|man|woman|boy|girl|పురుషుడు|మహిళ|స్త్రీ|पुरुष|महिला)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (genderMatch != null) {
      _patientGender = genderMatch.group(0);
    }

    // 4. Entity Extraction - Duration
    final durationMatch = RegExp(
      r'\b(\d+\s*(?:days?|weeks?|months?|hours?|రోజులు|రోజుల|दिन|घंटे)|since\s+(?:yesterday|morning|last\s+night|\d+\s+days?)|నిన్నటి\s*నుండి|నిన్నటినుండి|कल\s*से|आज\s*से|\d+\s*दिनों?\s*సే|\d+\s*రోజులు)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (durationMatch != null) {
      _symptomDuration = durationMatch.group(0);
    }

    // 5. Entity Extraction - Temperature
    final tempMatch = RegExp(
      r'\b((?:9[7-9]|10[0-6])(?:\.\d)?\s*(?:°?[fF]|degrees?|డిగ్రీ|डिग्री)?)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (tempMatch != null) {
      _bodyTemperature = tempMatch.group(1);
    }

    // 6. Entity Extraction - Severity / Pain Character
    final severityMatch = RegExp(
      r'\b(mild|moderate|severe|intense|unbearable|throbbing|burning|cramping|sharp|తక్కువ|మధ్యస్థ|తీవ్రమైన|हल्का|मध्यम|तेज|गंभीर)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (severityMatch != null) {
      _knownSeverity = severityMatch.group(0);
    }

    // 7. Entity Extraction - Past Medical History
    final historyMatch = RegExp(
      r'\b(diabetes|bp|blood\s*pressure|hypertension|asthma|thyroid|sugar|acidity|gerd|cardiac|no\s*disease|no\s*prior|షుగర్|బీపీ|ఆస్తమా|డయాబెటిస్|హైపర్టెన్షన్|मधुमेह|बीपी|अस्थमा|कोई\s*बीमारी\s*नहीं)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (historyMatch != null) {
      _knownPastHistory = historyMatch.group(0);
    }

    // 8. Entity Extraction - Existing Meds Taken
    final medsTakenMatch = RegExp(
      r'\b(paracetamol|dolo|calpol|pan|pantop|antacid|syrup|cetirizine|tablet|medicine|took|taken|పారాసిటమాల్|డోలో|మాత్ర|दवा|पैरासिटामोल|गोली)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (medsTakenMatch != null) {
      _knownExistingMeds = medsTakenMatch.group(0);
    }

    // 9. Entity Extraction - Cumulative Symptoms
    final extracted = NvidiaAiService.extractSymptoms(trimmed, _selectedLanguage);
    for (final s in extracted) {
      if (!_currentSymptoms.contains(s)) {
        _currentSymptoms.add(s);
      }
    }

    _intakeTurnCount++;

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      isAudio: isVoice,
    );
    _messages.add(userMsg);
    _isThinking = true;
    notifyListeners();

    try {
      final lower = trimmed.toLowerCase();
      final isTelugu = _selectedLanguage == 'te';
      final isHindi = _selectedLanguage == 'hi';

      // -------------------------------------------------------------
      // 1. Direct Intent: Book Doctor Appointment
      // -------------------------------------------------------------
      final bool isBookDoctorIntent = lower.contains('book appointment') ||
          lower.contains('book doctor') ||
          lower.contains('schedule appointment') ||
          lower.contains('see doctor') ||
          lower.contains('consult doctor') ||
          lower.contains('అపాయింట్') ||
          lower.contains('డాక్టర్ బుక్') ||
          lower.contains('డాక్టర్ సంప్రదింపు') ||
          lower.contains('अपॉइंटमेंट') ||
          lower.contains('डॉक्टर बुक');

      // -------------------------------------------------------------
      // 2. Direct Intent: Book / Order Medicine
      // -------------------------------------------------------------
      final bool isBookMedicineIntent = lower.contains('book medicine') ||
          lower.contains('order medicine') ||
          lower.contains('order medicines') ||
          lower.contains('buy medicine') ||
          lower.contains('buy tablet') ||
          lower.contains('order tablet') ||
          lower.contains('order dolo') ||
          lower.contains('book dolo') ||
          lower.contains('మందులు ఆర్డర్') ||
          lower.contains('మందులు బుక్') ||
          lower.contains('దవా బుక్') ||
          lower.contains('दवा ऑर्डर') ||
          lower.contains('दवाई बुक');

      // -------------------------------------------------------------
      // 3. Direct Intent: Book Lab Test / Blood Test
      // -------------------------------------------------------------
      final bool isBookTestIntent = lower.contains('book test') ||
          lower.contains('book lab test') ||
          lower.contains('book blood test') ||
          lower.contains('full body checkup') ||
          lower.contains('cbc test') ||
          lower.contains('ల్యాబ్ టెస్ట్ బుక్') ||
          lower.contains('రక్త పరీక్ష బుక్') ||
          lower.contains('टेस्ट बुक') ||
          lower.contains('लैब टेस्ट');

      // -------------------------------------------------------------
      // 4. Direct Intent: Emergency 108 Ambulance Dispatch
      // -------------------------------------------------------------
      final bool isEmergencyIntent = lower.contains('ambulance') ||
          lower.contains('emergency') ||
          lower.contains('108') ||
          lower.contains('అంబులెన్స్') ||
          lower.contains('ఆపత్కాలం') ||
          lower.contains('एम्बुलेंस') ||
          lower.contains('आपातकालीन');

      if (isEmergencyIntent) {
        final dispatch = CentralDataService.instance.triggerEmergencySOS(
          userId: 'USR-101',
          patientName: _patientName ?? 'Verified Patient',
          patientPhone: '9848022338',
          location: 'Live GPS Location (Madhapur, Hyderabad)',
          ambulanceProvider: 'Govt 108 Emergency Service',
          etaMinutes: '6 mins',
          notes: 'Emergency SOS dispatched via HealthExpress AI Assistant',
        );

        final String resText = isTelugu
            ? '108 అత్యవసర అంబులెన్స్ పంపబడింది. అంబులెన్స్ మీ లైవ్ జీపీఎస్ లొకేషన్‌కు 6 నిమిషాల్లో చేరుకుంటుంది. దయచేసి ప్రశాంతంగా ఉండండి, సహాయక బృందం మార్గంలో ఉంది.'
            : (isHindi
                ? '108 आपातकालीन एम्बुलेंस भेज दी गई है। एम्बुलेंस 6 मिनट में आपकी लाइव लोकेशन पर पहुंचेगी। कृपया शांत रहें, मेडिकल टीम रास्ते में है।'
                : '108 Emergency Ambulance Dispatched. Ambulance #EMERG-108 is en-route to your live GPS location with an ETA of 6 minutes. Please stay calm, paramedics are on the way.');

        final dynamicCards = [
          DynamicActionCard(
            title: isTelugu ? '108 అంబులెన్స్ మార్గంలో ఉంది' : (isHindi ? '108 एम्बुलेंस रास्ते में है' : '108 Ambulance En-Route'),
            subtitle: isTelugu ? 'చేరుకునే సమయం: 6 నిమిషాలు (KIMS ఎమర్జెన్సీ)' : (isHindi ? 'आगमन समय: 6 मिनट (KIMS ट्रॉमा)' : 'Live GPS ETA: 6 mins (KIMS Trauma Hospital)'),
            type: 'emergency',
            icon: Icons.emergency_rounded,
            color: const Color(0xFFEF4444),
            payload: dispatch,
          ),
        ];

        final botMsg = ChatMessage(
          id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
          text: resText,
          isUser: false,
          timestamp: DateTime.now(),
          dynamicCards: dynamicCards,
          actionSuggestions: isTelugu
              ? ['లైవ్ అంబులెన్స్ ట్రాక్ చేయండి', 'డాక్టర్‌తో మాట్లాడండి']
              : (isHindi ? ['लाइव एम्बुलेंस ट्रैक करें', 'डॉक्टर से बात करें'] : ['Track 108 Live GPS', 'Call Trauma Doctor']),
        );

        _messages.add(botMsg);
        if (isVoice || _isLiveVoiceMode) speakText(resText);
        return;
      }

      if (isBookDoctorIntent) {
        final doctors = _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, trimmed);
        final doctor = doctors.first;

        final newAppt = AppointmentModel(
          id: '#BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          userId: 'USR-101',
          userName: _patientName ?? 'Venkatesh Murthy',
          userPhone: '9848022338',
          aarogyasriId: 'AROG-TG-44910',
          doctorId: doctor.id,
          doctorName: doctor.name,
          doctorPhoto: doctor.photoUrl,
          doctorSpecialty: doctor.specialty,
          hospitalId: doctor.hospitalId,
          hospitalName: doctor.hospitalName,
          hospitalLocation: doctor.location,
          dateTime: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '10:30 AM',
          type: ConsultationType.videoConsult,
          status: AppointmentStatus.confirmed,
          paymentStatus: PaymentStatus.paid,
          consultationFee: doctor.videoFee > 0 ? doctor.videoFee : 600.0,
          platformFee: 49.0,
          discountAmount: 0.0,
          totalAmount: doctor.videoFee > 0 ? doctor.videoFee + 49.0 : 649.0,
          aarogyasriApplied: true,
          symptomsSummary: _currentSymptoms.isNotEmpty ? _currentSymptoms.join(', ') : 'Clinical Consultation',
          meetingRoomId: 'room-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          createdAt: DateTime.now(),
        );

        CentralDataService.instance.addAppointment(newAppt);

        final String resText = isTelugu
            ? '${doctor.name} (${doctor.specialty}) తో అపాయింట్‌మెంట్ విజయవంతంగా బుక్ చేయబడింది.\n\nసమయం: రేపు ఉదయం 10:30 AM (వీడియో కన్సల్టేషన్). ఆరోగ్యశ్రీ డిజిటల్ పాస్ లింక్ చేయబడింది.'
            : (isHindi
                ? '${doctor.name} (${doctor.specialty}) के साथ अपॉइंटमेंट सफलतापूर्वक बुक हो गया है।\n\nसमय: कल सुबह 10:30 AM (वीडियो परामर्श)। आरोग्यश्री डिजिटल पास लिंक किया गया है।'
                : 'Appointment successfully booked with ${doctor.name} (${doctor.specialty}).\n\nSchedule: Tomorrow at 10:30 AM (Video Consultation). Verified Aarogyasri subsidy pass applied.');

        final dynamicCards = [
          DynamicActionCard(
            title: 'Confirmed Booking: ${doctor.name}',
            subtitle: '${doctor.specialty} • Tomorrow 10:30 AM • Video Consult',
            type: 'doctor',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF10B981),
            payload: newAppt,
          ),
        ];

        final botMsg = ChatMessage(
          id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
          text: resText,
          isUser: false,
          timestamp: DateTime.now(),
          dynamicCards: dynamicCards,
          suggestedDoctors: [doctor],
          actionSuggestions: isTelugu
              ? ['మందులు ఆర్డర్ చేయండి', 'ల్యాబ్ టెస్ట్ బుక్ చేయండి']
              : (isHindi ? ['दवाइयां ऑर्डर करें', 'लैब टेस्ट बुक करें'] : ['Order Suggested Medicines', 'Book Lab Test']),
        );

        _messages.add(botMsg);
        if (isVoice || _isLiveVoiceMode) speakText(resText);
        return;
      }

      if (isBookMedicineIntent) {
        final meds = _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, trimmed);
        final selectedMed = meds.first;

        final newOrder = CentralDataService.instance.placeNewOrder(
          userId: 'USR-101',
          patientName: _patientName ?? 'Venkatesh Murthy',
          patientPhone: '9848022338',
          deliveryAddress: 'Plot 42, Road No 36, Jubilee Hills, Hyderabad',
          items: [CartItemModel(medicine: selectedMed, quantity: 1)],
          subtotal: selectedMed.price,
          deliveryFee: 0.0,
          total: selectedMed.price,
          storeId: 'STORE-01',
          storeName: 'Apollo Pharmacy 24x7',
          storePhone: '+91 40 2360 8888',
          storeAddress: 'Hitech City Main Rd, Hyderabad',
          storeImageUrl: 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400',
          storeLicense: 'TS-HYD-PHARM-2024-8801',
        );

        final String resText = isTelugu
            ? '${selectedMed.name} 15 నిమిషాల ఎక్స్‌ప్రెస్ డెలివరీ ఆర్డర్ చేయబడింది.\n\nరైడర్ రవి కుమార్ అపోలో ఫార్మసీ నుండి మందును ప్యాక్ చేస్తున్నారు. అంచనా సమయం: 15 నిమిషాలు.'
            : (isHindi
                ? '${selectedMed.name} का 15-मिनट एक्सप्रेस डिलीवरी ऑर्डर बुक हो गया है।\n\nराइडर रवि कुमार अपोलो फार्मेसी से दवा ले रहे हैं। अनुमानित समय: 15 मिनट।'
                : 'Express 15-Minute Delivery Order placed for ${selectedMed.name}.\n\nDelivery partner Ravi Kumar is picking up from Apollo Pharmacy 24x7. Estimated arrival: 15 mins.');

        final dynamicCards = [
          DynamicActionCard(
            title: '15-Min Delivery Active: ${selectedMed.name}',
            subtitle: 'Apollo Pharmacy 24x7 • Order ${newOrder.orderId} • ETA 15 mins',
            type: 'medicine',
            icon: Icons.delivery_dining_rounded,
            color: const Color(0xFF0284C7),
            payload: newOrder,
          ),
        ];

        final botMsg = ChatMessage(
          id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
          text: resText,
          isUser: false,
          timestamp: DateTime.now(),
          dynamicCards: dynamicCards,
          suggestedMedicines: meds.take(2).toList(),
          actionSuggestions: isTelugu
              ? ['లైవ్ ఆర్డర్ ట్రాక్ చేయండి', 'డాక్టర్ అపాయింట్‌మెంట్ బుక్ చేయండి']
              : (isHindi ? ['लाइव ऑर्डर ट्रैक करें', 'डॉक्टर अपॉइंटमेंट बुक करें'] : ['Track Live GPS Order', 'Book Doctor Consult']),
        );

        _messages.add(botMsg);
        if (isVoice || _isLiveVoiceMode) speakText(resText);
        return;
      }

      if (isBookTestIntent) {
        final tests = _getLabTestsForContext(_activeDiagnosis, _currentSymptoms, trimmed);
        final test = tests.first;

        final String resText = isTelugu
            ? '${test.name} ల్యాబ్ టెస్ట్ బుక్ చేయబడింది.\n\nఉచిత హోమ్ శాంపిల్ కలెక్షన్ రేపు ఉదయం 8:00 AM కి షెడ్యూల్ చేయబడింది. రిపోర్టులు అదే రోజు సాయంత్రం డిజిటల్‌గా వస్తాయి.'
            : (isHindi
                ? '${test.name} लैब टेस्ट सफलतापूर्वक बुक हो गया है।\n\nनिःशुल्क होम सैंपल कलेक्शन कल सुबह 8:00 AM पर शेड्यूल किया गया है।'
                : 'Diagnostic Lab Test booked for ${test.name}.\n\nFree Home Sample Collection scheduled for Tomorrow at 8:00 AM. Verified digital report delivered within 6 hours.');

        final dynamicCards = [
          DynamicActionCard(
            title: 'Lab Test Booked: ${test.name}',
            subtitle: 'Free Home Collection • Fast 6-Hour Verified Digital Report',
            type: 'test',
            icon: Icons.biotech_rounded,
            color: const Color(0xFF8B5CF6),
            payload: test,
          ),
        ];

        final botMsg = ChatMessage(
          id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
          text: resText,
          isUser: false,
          timestamp: DateTime.now(),
          dynamicCards: dynamicCards,
          suggestedLabTests: tests.take(2).toList(),
          actionSuggestions: isTelugu
              ? ['డాక్టర్‌తో మాట్లాడండి', 'మందులు ఆర్డర్ చేయండి']
              : (isHindi ? ['डॉक्टर से परामर्श लें', 'दवाइयां ऑर्डर करें'] : ['Consult Doctor', 'Order Medicines']),
        );

        _messages.add(botMsg);
        if (isVoice || _isLiveVoiceMode) speakText(resText);
        return;
      }

      // -------------------------------------------------------------
      // 5. Clinical Triage & Comprehensive Recommendation Pipeline
      // -------------------------------------------------------------
      final history = _messages.take(_messages.length - 1).map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      final aiRes = await NvidiaAiService.generateResponse(
        userQuery: trimmed,
        conversationHistory: history,
        lang: _selectedLanguage,
        patientName: patientName ?? _patientName,
        patientAge: _patientAge,
        gender: _patientGender,
        currentSymptoms: _currentSymptoms,
        symptomDuration: _symptomDuration,
        bodyTemperature: _bodyTemperature,
        intakeTurn: _intakeTurnCount,
        knownSeverity: _knownSeverity,
        knownPastHistory: _knownPastHistory,
        knownExistingMeds: _knownExistingMeds,
        isVoiceMode: isVoice || _isLiveVoiceMode,
      );

      _activeDiagnosis = aiRes.triageCategory;

      for (final s in aiRes.detectedSymptoms) {
        if (!_currentSymptoms.contains(s)) {
          _currentSymptoms.add(s);
        }
      }

      // Display rich contextual cards (Medicines, Doctors, Tests) once intake is complete (turn >= 3) or requested
      final bool isIntakeComplete = _intakeTurnCount >= 3 || aiRes.wantsMedicines || _activeDiagnosis.contains('Emergency');

      final matchedMedicines = isIntakeComplete ? _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final matchedDoctors = isIntakeComplete ? _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final matchedTests = isIntakeComplete ? _getLabTestsForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final matchedProducts = isIntakeComplete ? _getProductsForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final dynamicCards = _generateDynamicCards(_activeDiagnosis, trimmed);

      final botMsg = ChatMessage(
        id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: aiRes.content,
        isUser: false,
        timestamp: DateTime.now(),
        detectedSymptoms: _currentSymptoms,
        actionSuggestions: aiRes.actionSuggestions,
        suggestedMedicines: matchedMedicines,
        recommendedProducts: matchedProducts,
        suggestedDoctors: matchedDoctors,
        suggestedLabTests: matchedTests,
        dynamicCards: dynamicCards.isNotEmpty ? dynamicCards : null,
      );

      _messages.add(botMsg);

      if (isVoice || _isLiveVoiceMode) {
        speakText(aiRes.content);
      }

      if (_currentSymptoms.isNotEmpty || _patientName != null) {
        ApiService.runAiTriageWithMemory(
          userId: 'USR-101',
          symptoms: _currentSymptoms.isNotEmpty ? _currentSymptoms.join(', ') : 'Intake: ${_patientName ?? "Patient"}',
          duration: _symptomDuration ?? '1-2 days',
          language: _selectedLanguage,
        );
      }
    } catch (e) {
      debugPrint('Error generating AI response: $e');
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  List<MedicineModel> _getMedicinesForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    // 1. Stomach / Gastric / Acidity / Vomiting
    if (sympText.contains('acidity') || sympText.contains('gastric') || sympText.contains('stomach') || sympText.contains('vomit') || sympText.contains('కడుపు') || sympText.contains('ఎసిడిటీ') || sympText.contains('पेट')) {
      return ProductionDatabase.medicines.where((m) => m.id == 'MED-08' || m.id == 'MED-04' || m.id == 'MED-01').toList();
    }

    // 2. Cold / Cough / Throat / Flu
    if (sympText.contains('cough') || sympText.contains('cold') || sympText.contains('throat') || sympText.contains('గొంతు') || sympText.contains('దగ్గు') || sympText.contains('खांसी')) {
      return ProductionDatabase.medicines.where((m) => m.id == 'MED-02' || m.id == 'MED-03' || m.id == 'MED-06' || m.id == 'MED-05').toList();
    }

    // 3. Headache / Migraine
    if (sympText.contains('headache') || sympText.contains('migraine') || sympText.contains('తలనొప్పి') || sympText.contains('सिरदर्द')) {
      return ProductionDatabase.medicines.where((m) => m.id == 'MED-01' || m.id == 'MED-05' || m.id == 'MED-06').toList();
    }

    // 4. Joint / Knee / Back Pain
    if (sympText.contains('knee') || sympText.contains('joint') || sympText.contains('back') || sympText.contains('orthopedic') || sympText.contains('మోకాలు') || sympText.contains('కీళ్ళ') || sympText.contains('घुटनों')) {
      return ProductionDatabase.medicines.where((m) => m.id == 'MED-01' || m.id == 'MED-06' || m.id == 'MED-05').toList();
    }

    // 5. Fever & Viral Infection
    if (sympText.contains('fever') || sympText.contains('chills') || sympText.contains('viral') || sympText.contains('జ్వరం') || sympText.contains('బుఖార్') || sympText.contains('बुखार')) {
      return ProductionDatabase.medicines.where((m) => m.id == 'MED-01' || m.id == 'MED-04' || m.id == 'MED-05' || m.id == 'MED-02').toList();
    }

    // Default relevant clinical relief
    return [
      ProductionDatabase.medicines[0], // Paracetamol 650mg
      ProductionDatabase.medicines[3], // ORS Electral
      ProductionDatabase.medicines[4], // Vitamin C
      ProductionDatabase.medicines[7], // Pantoprazole
    ];
  }

  List<DoctorModel> _getDoctorsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    // 1. Cardiac / Heart / BP
    if (sympText.contains('cardio') || sympText.contains('chest') || sympText.contains('heart') || sympText.contains('bp') || sympText.contains('రక్తపోటు') || sympText.contains('గుండె')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-01', orElse: () => ProductionDatabase.doctors[0]), // Cardiologist
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-05', orElse: () => ProductionDatabase.doctors[4]), // General Physician
      ];
    }

    // 2. Headache / Migraine / Neurological
    if (sympText.contains('headache') || sympText.contains('migraine') || sympText.contains('neuro') || sympText.contains('తలనొప్పి') || sympText.contains('सिरदर्द')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-02', orElse: () => ProductionDatabase.doctors[1]), // Neurologist
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-06', orElse: () => ProductionDatabase.doctors[5]), // General Physician
      ];
    }

    // 3. Orthopedic / Joint / Knee / Spine
    if (sympText.contains('knee') || sympText.contains('joint') || sympText.contains('back') || sympText.contains('ortho') || sympText.contains('మోకాలు') || sympText.contains('కీళ్ళ') || sympText.contains('घुटनों')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-03', orElse: () => ProductionDatabase.doctors[2]), // Orthopedic Surgeon
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-08', orElse: () => ProductionDatabase.doctors[7]), // Doorstep RMP
      ];
    }

    // 4. Throat / Ear / Sinus / Cold
    if (sympText.contains('throat') || sympText.contains('ear') || sympText.contains('sinus') || sympText.contains('ent') || sympText.contains('గొంతు')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-09', orElse: () => ProductionDatabase.doctors[8]), // ENT Specialist
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-05', orElse: () => ProductionDatabase.doctors[4]), // General Physician
      ];
    }

    // 5. Child / Pediatric
    if (sympText.contains('child') || sympText.contains('baby') || sympText.contains('kid') || sympText.contains('pediatric') || sympText.contains('పిల్లలు')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-10', orElse: () => ProductionDatabase.doctors[9]), // Pediatrician
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-06', orElse: () => ProductionDatabase.doctors[5]), // General Physician
      ];
    }

    // 6. Women / Pregnancy / Gynec
    if (sympText.contains('pregnancy') || sympText.contains('period') || sympText.contains('gynec') || sympText.contains('మహిళ') || sympText.contains('గర్భం')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-04', orElse: () => ProductionDatabase.doctors[3]), // Gynecologist
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-06', orElse: () => ProductionDatabase.doctors[5]), // General Physician
      ];
    }

    // Default General Physicians & Doorstep Care
    return [
      ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-05', orElse: () => ProductionDatabase.doctors[4]), // Dr. Prashant Reddy
      ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-06', orElse: () => ProductionDatabase.doctors[5]), // Dr. Priya Nair
      ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-08', orElse: () => ProductionDatabase.doctors[7]), // Dr. Suresh RMP Doorstep
    ];
  }

  List<LabTestModel> _getLabTestsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    // 1. Fever & Viral Infection
    if (sympText.contains('fever') || sympText.contains('chills') || sympText.contains('viral') || sympText.contains('జ్వరం') || sympText.contains('బుఖార్') || sympText.contains('बुखार')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'CBC' || t.code == 'NS1-ANTIGEN' || t.code == 'MAL-AG').toList();
    }

    // 2. Diabetes & High Blood Sugar
    if (sympText.contains('sugar') || sympText.contains('diabetes') || sympText.contains('glucose') || sympText.contains('షుగర్') || sympText.contains('मधुमेह')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'HBA1C-GLUCOSE' || t.code == 'FULL-BODY-84').toList();
    }

    // 3. Cardiac / BP / Cholesterol
    if (sympText.contains('cardio') || sympText.contains('heart') || sympText.contains('bp') || sympText.contains('pressure') || sympText.contains('chest')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'LIPID-PANEL' || t.code == 'CBC').toList();
    }

    // 4. Stomach / Acidity / Liver / Nausea
    if (sympText.contains('stomach') || sympText.contains('acidity') || sympText.contains('vomit') || sympText.contains('liver') || sympText.contains('కడుపు')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'LFT-KFT' || t.code == 'CBC').toList();
    }

    // 5. Thyroid / Fatigue / Metabolic
    if (sympText.contains('thyroid') || sympText.contains('fatigue') || sympText.contains('weakness') || sympText.contains('weight')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'THYROID-T3T4TSH' || t.code == 'FULL-BODY-84').toList();
    }

    // Default Full Body & Vital Screening
    return ProductionDatabase.labTests.where((t) => t.code == 'FULL-BODY-84' || t.code == 'CBC').toList();
  }

  List<BusinessProductModel> _getProductsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    // 1. Diabetes
    if (sympText.contains('sugar') || sympText.contains('diabetes') || sympText.contains('షుగర్')) {
      return [ProductionDatabase.businessProducts[0], ProductionDatabase.businessProducts[1]]; // Glucometer Kit, Diabetic 360
    }

    // 2. Cardiac & BP
    if (sympText.contains('cardio') || sympText.contains('heart') || sympText.contains('bp') || sympText.contains('pressure')) {
      return [ProductionDatabase.businessProducts[2], ProductionDatabase.businessProducts[3]]; // Digital BP Monitor, Full Body 84
    }

    // 3. Orthopedic & Joint / Knee
    if (sympText.contains('knee') || sympText.contains('joint') || sympText.contains('back') || sympText.contains('ortho') || sympText.contains('మోకాలు')) {
      return [ProductionDatabase.businessProducts[4], ProductionDatabase.businessProducts[3]]; // Orthopedic Heat Knee Wrap, Full Body 84
    }

    // 4. Women Health & Hormonal
    if (sympText.contains('pcos') || sympText.contains('period') || sympText.contains('women') || sympText.contains('hormone')) {
      return [ProductionDatabase.businessProducts[6], ProductionDatabase.businessProducts[5]]; // Women's PCOS Panel, Gold Family Pass
    }

    // Default Full Body Checkup Package & Gold Family Pass
    return [ProductionDatabase.businessProducts[3], ProductionDatabase.businessProducts[5]];
  }

  List<DynamicActionCard> _generateDynamicCards(String category, String query) {
    final lower = query.toLowerCase();
    List<DynamicActionCard> cards = [];

    if (category.contains('Emergency') || lower.contains('chest') || lower.contains('breath') || lower.contains('unconscious') || lower.contains('గుండె నొప్పి')) {
      cards.add(DynamicActionCard(
        title: _selectedLanguage == 'te' ? 'అంబులెన్స్ (108) పంపించండి' : (_selectedLanguage == 'hi' ? '108 एम्बुलेंस बुलाएं' : 'Dispatch 108 Ambulance'),
        subtitle: _selectedLanguage == 'te' ? '6 నిమిషాల్లో చేరుకుంటుంది' : (_selectedLanguage == 'hi' ? '6 मिनट में आपातकालीन सहायता' : 'GPS emergency dispatch in 6 mins'),
        type: 'emergency',
        icon: Icons.emergency_rounded,
        color: const Color(0xFFEF4444),
      ));
    }
    return cards;
  }
}
