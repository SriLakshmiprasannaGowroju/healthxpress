import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import 'video_consultation_screen.dart';
import 'audio_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const ChatScreen({super.key, required this.appointment});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isDoctorTyping = false;

  late final List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'isDoctor': true,
        'type': 'text',
        'text': 'Hello! I have received your appointment request and reviewed your medical history. How are you feeling today?',
        'time': '10:00 AM',
      },
      {
        'isDoctor': false,
        'type': 'text',
        'text': 'Good morning Doctor. I have had low grade fever (99.8°F) and throat pain since yesterday.',
        'time': '10:02 AM',
      },
      {
        'isDoctor': true,
        'type': 'text',
        'text': 'Understood. Please keep yourself hydrated with warm water. I have drafted an electronic prescription for you below.',
        'time': '10:05 AM',
      },
      {
        'isDoctor': true,
        'type': 'rx',
        'text': 'Prescription issued for Fever & Throat Infection',
        'time': '10:06 AM',
        'payload': {
          'diagnosis': 'Acute Pharyngitis & Mild Fever',
          'medicines': [
            {'name': 'Dolo 650mg', 'dose': '1 tablet after food (SOS)', 'days': '3 days'},
            {'name': 'Azithral 500mg', 'dose': '1 tablet once daily', 'days': '5 days'},
            {'name': 'Alex Syrup', 'dose': '10ml thrice daily', 'days': '5 days'},
          ]
        }
      },
    ];
  }

  void _sendMessage(String text, {String type = 'text', Map<String, dynamic>? payload}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && payload == null) return;

    final nowTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      _messages.add({
        'isDoctor': false,
        'type': type,
        'text': trimmed,
        'time': nowTime,
        'payload': payload,
      });
      _textController.clear();
      _isDoctorTyping = true;
    });

    _scrollToBottom();

    // Trigger dynamic clinical response after realistic doctor typing delay
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;

      final doctorReply = _generateClinicalReply(trimmed, type);
      setState(() {
        _isDoctorTyping = false;
        _messages.add(doctorReply);
      });
      _scrollToBottom();
    });
  }

  Map<String, dynamic> _generateClinicalReply(String userMessage, String type) {
    final lower = userMessage.toLowerCase();
    final nowTime = DateFormat('hh:mm a').format(DateTime.now());

    if (type == 'aarogyasri') {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'Thank you for sharing your Aarogyasri ABHA Digital Card. I have verified your scheme eligibility. All consultations and medications are covered 100% cashless under the state healthcare program.',
        'time': nowTime,
      };
    }

    if (type == 'vitals') {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'Your vitals have been received! Blood Pressure (120/80 mmHg), Heart Rate (74 bpm), and SpO2 (99%) are all in excellent healthy ranges. Continue current hydration.',
        'time': nowTime,
      };
    }

    if (type == 'lab_report') {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'I have thoroughly examined your attached Complete Blood Count (CBC) and diagnostic report. Platelets and hemoglobin are optimal. No sign of bacterial infection.',
        'time': nowTime,
      };
    }

    if (lower.contains('fever') || lower.contains('temp') || lower.contains('100') || lower.contains('101') || lower.contains('102')) {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'Please take Dolo 650mg after your meals with plenty of water. If your temperature stays above 101°F, apply a damp cool cloth to your forehead. Keep monitoring every 4 hours.',
        'time': nowTime,
      };
    }

    if (lower.contains('cough') || lower.contains('throat') || lower.contains('cold') || lower.contains('phlegm')) {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'For your throat and cough, do warm salt water gargles 3 times a day. Take 10ml of Alex Cough Syrup after meals. Avoid cold drinks, oily foods, and dust exposure.',
        'time': nowTime,
      };
    }

    if (lower.contains('medicine') || lower.contains('refill') || lower.contains('rx') || lower.contains('dose') || lower.contains('tablet')) {
      return {
        'isDoctor': true,
        'type': 'rx',
        'text': 'Updated Digital Prescription generated',
        'time': nowTime,
        'payload': {
          'diagnosis': 'Clinical Medication Refill (Doctor Verified)',
          'medicines': [
            {'name': 'Pantop 40mg', 'dose': '1 tablet empty stomach', 'days': '7 days'},
            {'name': 'Paracetamol 650mg', 'dose': '1 tablet SOS for bodyache', 'days': '3 days'},
            {'name': 'Multivitamin + Zinc', 'dose': '1 tablet after dinner', 'days': '15 days'},
          ]
        }
      };
    }

    if (lower.contains('headache') || lower.contains('pain') || lower.contains('stomach') || lower.contains('back')) {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'I have recorded your pain symptoms. Ensure you get 7-8 hours of restful sleep and avoid screen glare. Take Paracetamol 650mg if pain is severe. Join video call if symptoms persist.',
        'time': nowTime,
      };
    }

    if (lower.contains('call') || lower.contains('video') || lower.contains('urgent') || lower.contains('emergency')) {
      return {
        'isDoctor': true,
        'type': 'text',
        'text': 'I am available right now on our secure Agora consultation line. Tap the Video icon at the top right of this screen anytime to start live examination!',
        'time': nowTime,
      };
    }

    return {
      'isDoctor': true,
      'type': 'text',
      'text': 'Thank you for updating me. I have updated your health records and clinical chart. Let me know if you experience any new symptoms or need medication assistance.',
      'time': nowTime,
    };
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share Medical Records with Doctor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentOption(
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF0F766E),
                    label: 'Aarogyasri\nPass',
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendMessage(
                        'Aarogyasri Health Pass Attached',
                        type: 'aarogyasri',
                        payload: {
                          'cardNo': 'AAROGYA-TG-9824-2026',
                          'holderName': 'Rahul Sharma',
                          'coverage': '₹10,00,000 Cashless',
                          'abhaId': '91-4829-1029-4821',
                        },
                      );
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.monitor_heart_outlined,
                    color: Colors.redAccent,
                    label: 'Live\nVitals',
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendMessage(
                        'Live Vitals Snapshot Attached',
                        type: 'vitals',
                        payload: {
                          'bp': '120/80 mmHg',
                          'pulse': '74 bpm',
                          'spo2': '99%',
                          'temp': '98.6 °F',
                        },
                      );
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.description_outlined,
                    color: AppColors.primary,
                    label: 'Lab\nReport',
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendMessage(
                        'Diagnostic Blood Panel PDF',
                        type: 'lab_report',
                        payload: {
                          'testName': 'Comprehensive Blood Count (CBC) & CRP',
                          'lab': 'Apollo Diagnostics Hyderabad',
                          'status': 'Verified Normal',
                          'date': 'Today, 08:30 AM',
                        },
                      );
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.medical_services_outlined,
                    color: Colors.purple,
                    label: 'Refill\nRx',
                    onTap: () {
                      Navigator.of(context).pop();
                      _sendMessage('Doctor, could you please refill my regular prescription?');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.appointment.doctorPhoto),
                  onBackgroundImageError: (_, __) {},
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.appointment.doctorName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                  Text(
                    'Online • ${widget.appointment.doctorSpecialty}',
                    style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Audio Call Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 18),
            ),
            tooltip: 'Agora Voice Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AudioCallScreen(appointment: widget.appointment)),
              );
            },
          ),
          // Video Call Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 18),
            ),
            tooltip: 'Agora HD Video Consultation',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VideoConsultationScreen(appointment: widget.appointment)),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Secure Aarogyasri End-to-End Encrypted Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: const Color(0xFFEFF6FF),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 13, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'End-to-End Encrypted Aarogyasri Consultation Channel',
                  style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isDoctorTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isDoctorTyping) {
                  return _DoctorTypingBubble(doctorPhoto: widget.appointment.doctorPhoto);
                }

                final msg = _messages[index];
                final isDoctor = msg['isDoctor'] as bool;
                final type = msg['type'] as String? ?? 'text';
                final payload = msg['payload'] as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isDoctor ? MainAxisAlignment.start : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isDoctor) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(widget.appointment.doctorPhoto),
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: _buildMessageBubble(msg, isDoctor, type, payload),
                      ),
                      if (!isDoctor) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Quick Interactive Suggestion Pills
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _QuickChip(
                  label: '💊 Request Rx Refill',
                  onTap: () => _sendMessage('Doctor, could you please issue a prescription refill for my current symptoms?'),
                ),
                _QuickChip(
                  label: '📊 Send Live Vitals',
                  onTap: () => _sendMessage(
                    'Live Vitals Snapshot Attached',
                    type: 'vitals',
                    payload: {'bp': '120/80 mmHg', 'pulse': '74 bpm', 'spo2': '99%', 'temp': '98.6 °F'},
                  ),
                ),
                _QuickChip(
                  label: '📄 Share Aarogyasri Pass',
                  onTap: () => _sendMessage(
                    'Aarogyasri Health Pass Attached',
                    type: 'aarogyasri',
                    payload: {'cardNo': 'AAROGYA-TG-9824-2026', 'holderName': 'Rahul Sharma', 'coverage': '₹10,00,000 Cashless', 'abhaId': '91-4829-1029-4821'},
                  ),
                ),
                _QuickChip(
                  label: '🌡️ Report 100°F Fever',
                  onTap: () => _sendMessage('Doctor, my body temperature is currently 100.2°F with severe shivering and body ache.'),
                ),
                _QuickChip(
                  label: '🧪 Share CBC Lab Test',
                  onTap: () => _sendMessage(
                    'Diagnostic Blood Panel PDF',
                    type: 'lab_report',
                    payload: {'testName': 'Complete Blood Count (CBC)', 'lab': 'Apollo Diagnostics Hyderabad', 'status': 'Verified Normal', 'date': 'Today, 08:30 AM'},
                  ),
                ),
              ],
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                    ),
                    onPressed: _showAttachmentModal,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (val) => _sendMessage(val),
                      decoration: InputDecoration(
                        hintText: 'Type your message or symptoms...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_textController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDoctor, String type, Map<String, dynamic>? payload) {
    if (type == 'rx' && payload != null) {
      return Container(
        width: 290,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Digital Prescription (Rx)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(payload['diagnosis'] as String? ?? 'Consultation Rx', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
            const Divider(color: AppColors.border, height: 16),
            ...((payload['medicines'] as List<dynamic>? ?? []).map((med) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('${med['dose']} • ${med['days']}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 14, color: Colors.white),
                label: const Text('Order via HealthExpress Pharmacy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prescription dispatched to 24/7 Delivery Pharmacy!'), backgroundColor: AppColors.success),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(msg['time'] as String, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ),
          ],
        ),
      );
    }

    if (type == 'aarogyasri' && payload != null) {
      return Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF115E59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.amberAccent, size: 16),
                    SizedBox(width: 6),
                    Text('AAROGYASRI HEALTH PASS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(payload['holderName'] as String? ?? 'Rahul Sharma', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('ABHA: ${payload['abhaId']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coverage: ${payload['coverage']}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(msg['time'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9)),
              ],
            ),
          ],
        ),
      );
    }

    if (type == 'vitals' && payload != null) {
      return Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: Colors.redAccent, size: 16),
                SizedBox(width: 6),
                Text('Live Vitals Snapshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniVital(label: 'BP', value: payload['bp'] as String? ?? '120/80', color: Colors.orangeAccent),
                _MiniVital(label: 'Pulse', value: payload['pulse'] as String? ?? '74 bpm', color: Colors.redAccent),
                _MiniVital(label: 'SpO2', value: payload['spo2'] as String? ?? '99%', color: Colors.cyan),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(msg['time'] as String, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ),
          ],
        ),
      );
    }

    if (type == 'lab_report' && payload != null) {
      return Container(
        width: 270,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payload['testName'] as String? ?? 'Lab Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                      Text(payload['lab'] as String? ?? 'Diagnostics', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(payload['status'] as String? ?? 'Normal', style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(msg['time'] as String, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      );
    }

    // Default text bubble
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDoctor ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isDoctor ? 2 : 16),
          bottomRight: Radius.circular(isDoctor ? 16 : 2),
        ),
        border: isDoctor ? Border.all(color: AppColors.border) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: isDoctor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            msg['text'] as String,
            style: TextStyle(color: isDoctor ? AppColors.textPrimary : Colors.white, fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            msg['time'] as String,
            style: TextStyle(color: isDoctor ? AppColors.textMuted : Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DoctorTypingBubble extends StatelessWidget {
  final String doctorPhoto;
  const _DoctorTypingBubble({required this.doctorPhoto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(doctorPhoto),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(2),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Dr. is replying', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                const SizedBox(width: 6),
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .fade(duration: 400.ms),
                const SizedBox(width: 3),
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                    .animate(onPlay: (controller) => controller.repeat(reverse: true), delay: 200.ms)
                    .fade(duration: 400.ms),
                const SizedBox(width: 3),
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                    .animate(onPlay: (controller) => controller.repeat(reverse: true), delay: 400.ms)
                    .fade(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: onTap,
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _MiniVital extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniVital({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
