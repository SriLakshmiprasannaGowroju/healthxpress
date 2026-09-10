import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../common/address_selection_modal.dart';
import 'ai_assistant_screen.dart';
import 'ai_voice_call_screen.dart';
import 'doctor_search_screen.dart';
import 'nearby_hospitals_map_screen.dart';
import 'pharmacy_screen.dart';
import 'lab_tests_screen.dart';
import 'rmp_doctor_booking_screen.dart';
import 'emergency_sos_screen.dart';
import 'health_records_screen.dart';
import 'health_qr_screen.dart';
import 'health_vitals_dashboard_screen.dart';
import 'my_appointments_screen.dart';
import 'medication_reminders_screen.dart';
import 'user_profile_screen.dart';
import '../common/basic_registration_screen.dart';
import '../../services/location_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.syncAppLocationWithLiveGps(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ai = context.watch<AiAssistantProvider>();
    final pharmacyProv = context.watch<PharmacyProvider>();
    final appointmentProv = context.watch<AppointmentProvider>();
    final nextAppointment = appointmentProv.getNextUpcomingForUser(auth.currentUser.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Brand, Bell, User Photo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'HealthExpress AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textPrimary),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Greeting (Row 1)
              Text(
                'Hello, ${auth.currentUser.name.split(' ').first} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Interactive Location / Address Selector (Row 2 - below greeting)
              InkWell(
                onTap: () => AddressSelectionModal.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          () {
                            final addr = pharmacyProv.selectedAddress.isNotEmpty
                                ? pharmacyProv.selectedAddress
                                : (auth.currentUser.address.isNotEmpty ? auth.currentUser.address : 'Live GPS Location');
                            return 'Deliver to: ${addr.split(',').first.trim()} ▼';
                          }(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('15 MINS', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Incomplete Onboarding Warning Banner (if patient profile is missing vital details)
              if (auth.currentUser.address.isEmpty || auth.currentUser.emergencyContactPhone.isEmpty) ...[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BasicRegistrationScreen(
                          initialName: auth.currentUser.name,
                          initialEmail: auth.currentUser.email,
                          initialPhone: auth.currentUser.phone,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.assignment_late_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Incomplete Onboarding Details',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap here to enter emergency contact, blood group & delivery address.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD97706)),
                      ],
                    ),
                  ),
                ),
              ],

              // AI Health Assistant Banner (Hero Section with Top-Right Call Button & 3D Mascot)
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E60F6), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Text and Action Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 116, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Heading + Live Call Button (Same Row, Right Side)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'AI Health Assistant',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AiVoiceCallScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 11),
                                      SizedBox(width: 3),
                                      Text(
                                        'Live Call',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'I can help you with symptoms, medicines, doctors and more.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Chat with AI',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Large 3D Health AI Mascot placed right into the right-side corner
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 146,
                          height: 146,
                          child: Image.asset(
                            AppIllustrations.heroHealthAi,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomRight,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.smart_toy_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Quick Actions Grid Header
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 4x2 Grid of Actions with 3D Assets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionFindDoctor,
                    label: 'Find Doctor',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorSearchScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionHospitals,
                    label: 'Hospitals',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyHospitalsMapScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionMedicines,
                    label: 'Medicines',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PharmacyScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionLabTests,
                    label: 'Lab Tests',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabTestsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionRmpDoctor,
                    label: 'RMP Doctor',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RmpDoctorBookingScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionAmbulance,
                    label: 'Ambulance',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionHealthRecords,
                    label: 'Health Records',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthRecordsScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionHealthVitals,
                    label: 'Health Vitals',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthVitalsDashboardScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 15-Min Medicine Delivery Feature Banner (3D Pop-out Effect)
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PharmacyScreen())),
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 125, 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 13),
                                SizedBox(width: 2),
                                Text(
                                  '15-MIN EXPRESS',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Doorstep Medicine Delivery',
                            style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.2),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Order from verified dark-store pharmacies nearby.',
                            style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    // 3D Delivery Bike Popping out of the card
                    Positioned(
                      right: -12,
                      top: -22,
                      bottom: -16,
                      child: Image.asset(
                        AppIllustrations.storeDeliveryBike,
                        width: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Disease Category Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Symptom Filter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Current: ${ai.activeDiagnosis}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ConditionChip(
                      label: 'Fever',
                      isSelected: ai.activeDiagnosis.contains('Fever'),
                      onTap: () => ai.selectCondition('Fever'),
                    ),
                    const SizedBox(width: 8),
                    _ConditionChip(
                      label: 'Cold & Cough',
                      isSelected: ai.activeDiagnosis.contains('Cold') || ai.activeDiagnosis.contains('Cough'),
                      onTap: () => ai.selectCondition('Cold & Cough'),
                    ),
                    const SizedBox(width: 8),
                    _ConditionChip(
                      label: 'Migraine',
                      isSelected: ai.activeDiagnosis.contains('Migraine'),
                      onTap: () => ai.selectCondition('Migraine'),
                    ),
                    const SizedBox(width: 8),
                    _ConditionChip(
                      label: 'Cardiology',
                      isSelected: ai.activeDiagnosis.contains('Cardiac'),
                      onTap: () => ai.selectCondition('Cardiac Alert / Emergency'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Health Summary Header & Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Health Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                    child: const Text('View all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Upcoming Appointment Card
              if (nextAppointment != null)
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF7C3AED), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Upcoming Appointment', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${nextAppointment.doctorName} • ${nextAppointment.hospitalName}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('dd MMM yyyy').format(nextAppointment.dateTime)}, ${nextAppointment.timeSlot}',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorSearchScreen())),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No Active Appointments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              SizedBox(height: 2),
                              Text('Consult top specialists or book RMP home visits.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Medicine Reminder Card
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicationRemindersScreen())),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF0284C7), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medicine Reminder & Schedule', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Prescription Dose Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            SizedBox(height: 2),
                            Text('Prescriptions from doctor consultations will sync here', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Aarogyasri / ABDM Digital Health Pass Card
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthQrScreen())),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        AppIllustrations.abdmHealthPass,
                        height: 56,
                        width: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Aarogyasri / ABDM Card', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 14),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text('View digital health ID & cashless QR', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
