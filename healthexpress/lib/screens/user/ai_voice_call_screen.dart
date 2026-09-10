import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import 'cart_checkout_screen.dart';
import 'book_appointment_screen.dart';

class AiVoiceCallScreen extends StatefulWidget {
  const AiVoiceCallScreen({super.key});

  @override
  State<AiVoiceCallScreen> createState() => _AiVoiceCallScreenState();
}

class _AiVoiceCallScreenState extends State<AiVoiceCallScreen> {
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  bool _isSpeaker = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    // Start Call Timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDurationSeconds++);
    });

    // Initialize voice session & auto-start listening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final ai = context.read<AiAssistantProvider>();
        ai.seedUserContext(auth.currentUser);
        ai.toggleLiveVoiceMode(true);
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _endCall() {
    final ai = context.read<AiAssistantProvider>();
    ai.stopSpeaking();
    ai.toggleLiveVoiceMode(false);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _toggleMute() {
    final ai = context.read<AiAssistantProvider>();
    setState(() => _isMuted = !_isMuted);
    ai.toggleVoiceListening();
  }

  String _getStatusText(AiAssistantProvider ai, bool isTelugu, bool isHindi) {
    if (ai.isSpeaking) {
      return isTelugu
          ? 'AI మాట్లాడుతోంది (స్పీకర్ ఆన్)...'
          : (isHindi ? 'AI बोल रहा है (स्पीकर सक्रिय)...' : 'AI Speaking (Speaker Active)...');
    } else if (ai.isListening) {
      return isTelugu
          ? 'మైక్రోఫోన్ వింటోంది... మాట్లాడండి'
          : (isHindi ? 'माइक सुन रहा है... बोलिए' : 'Microphone listening... speak now');
    } else if (ai.isThinking) {
      return isTelugu
          ? 'విశ్లేషిస్తోంది...'
          : (isHindi ? 'विश्लेषण जारी है...' : 'Analyzing symptoms...');
    } else {
      return isTelugu
          ? 'మాట్లాడటానికి మైక్ నొక్కండి'
          : (isHindi ? 'बोलने के लिए माइक दबाएं' : 'Tap microphone to speak');
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Consumer<AiAssistantProvider>(
        builder: (context, ai, _) {
          final isTelugu = ai.selectedLanguage == 'te';
          final isHindi = ai.selectedLanguage == 'hi';

          final latestAiMsg = ai.messages.reversed.firstWhere(
            (m) => !m.isUser,
            orElse: () => ai.messages.first,
          );

          return SafeArea(
            child: Column(
              children: [
                // 1. Top Call Header & Language Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                        onPressed: _endCall,
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTelugu
                                    ? 'ప్రత్యక్ష AI వైద్య సహాయకుడు'
                                    : (isHindi ? 'लाइव AI स्वास्थ्य सहायक' : 'Live AI Clinical Assistant'),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDuration(_callDurationSeconds),
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 10, color: Color(0xFF34D399)),
                                    SizedBox(width: 2),
                                    Text(
                                      'LiveKit Ultra-Low Latency',
                                      style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Language dropdown menu
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ai.selectedLanguage,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'te', child: Text('తెలుగు (TE)')),
                              DropdownMenuItem(value: 'hi', child: Text('हिन्दी (HI)')),
                            ],
                            onChanged: (lang) {
                              if (lang != null) ai.setLanguage(lang);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Real-Time Status & Clean Stationary Orb (Non-Animated)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Clean Stationary Orb (No Animations)
                        GestureDetector(
                          onTap: () => ai.toggleVoiceListening(),
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: ai.isSpeaking
                                  ? const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : (ai.isListening
                                      ? const LinearGradient(
                                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )),
                              boxShadow: [
                                BoxShadow(
                                  color: (ai.isSpeaking
                                          ? const Color(0xFF10B981)
                                          : (ai.isListening ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6)))
                                      .withValues(alpha: 0.5),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                ai.isSpeaking
                                    ? Icons.volume_up_rounded
                                    : (ai.isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
                                color: Colors.white,
                                size: 68,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Speaking / Listening Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            _getStatusText(ai, isTelugu, isHindi),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Clinical Action Cards & Real-Time Service Booking
                if (latestAiMsg.dynamicCards != null && latestAiMsg.dynamicCards!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: latestAiMsg.dynamicCards!.map((card) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: card.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: card.color.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: card.color, shape: BoxShape.circle),
                                child: Icon(card.icon, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text(card.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Suggested Medicines Pill
                if (latestAiMsg.suggestedMedicines != null && latestAiMsg.suggestedMedicines!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C4A6E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medication_rounded, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prescribed: ${latestAiMsg.suggestedMedicines!.first.name} (₹${latestAiMsg.suggestedMedicines!.first.price.toInt()})',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.read<PharmacyProvider>().addToCart(latestAiMsg.suggestedMedicines!.first);
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Order 15-Min', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Suggested Doctor Pill
                if (latestAiMsg.suggestedDoctors != null && latestAiMsg.suggestedDoctors!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, color: Color(0xFF34D399), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Doctor: ${latestAiMsg.suggestedDoctors!.first.name}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookAppointmentScreen(doctor: latestAiMsg.suggestedDoctors!.first),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Book Consult', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 4. Call Control Actions (Mute, End Call, Speaker)
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 16, 36, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute / Unmute
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: _isMuted ? const Color(0xFFDC2626).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: _isMuted ? const Color(0xFFEF4444) : Colors.white24, width: 1.5),
                              ),
                              child: Icon(
                                _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                color: _isMuted ? const Color(0xFFF87171) : Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isMuted ? 'Mic Muted' : 'Microphone',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // End Call Button
                      GestureDetector(
                        onTap: _endCall,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Color(0xFFDC2626), blurRadius: 18, offset: Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'End Call',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Speakerphone Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() => _isSpeaker = !_isSpeaker);
                          if (!_isSpeaker) {
                            ai.stopSpeaking();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: _isSpeaker ? AppColors.primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: _isSpeaker ? AppColors.primary : Colors.white24, width: 1.5),
                              ),
                              child: Icon(
                                _isSpeaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                color: _isSpeaker ? const Color(0xFF60A5FA) : Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isSpeaker ? 'Speaker (On)' : 'Speaker (Off)',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

