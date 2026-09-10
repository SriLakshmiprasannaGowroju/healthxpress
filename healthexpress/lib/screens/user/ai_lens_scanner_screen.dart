import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/vision_analysis_model.dart';
import '../../services/device_native_service.dart';
import '../../services/groq_vision_service.dart';
import 'medication_reminders_screen.dart';
import 'pharmacy_screen.dart';

class AiLensScannerScreen extends StatefulWidget {
  final VisionScope initialScope;
  final String? initialImageBase64;
  final String? initialHint;

  const AiLensScannerScreen({
    super.key,
    this.initialScope = VisionScope.food,
    this.initialImageBase64,
    this.initialHint,
  });

  @override
  State<AiLensScannerScreen> createState() => _AiLensScannerScreenState();
}

class _AiLensScannerScreenState extends State<AiLensScannerScreen>
    with SingleTickerProviderStateMixin {
  late VisionScope _selectedScope;
  bool _isAnalyzing = false;
  String _analysisStatus = 'Ready to scan';
  String? _capturedImageBase64;
  VisionAnalysisResult? _analysisResult;

  // Interactive Follow-up Chat state
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isAskingAi = false;

  late AnimationController _scanLineController;

  // Pre-loaded realistic sample data for instant exploration
  final List<Map<String, dynamic>> _foodSamples = [
    {
      'title': 'Masala Dosa',
      'calories': 320,
      'hint': 'South Indian Crispy Masala Dosa with Potato Masala and Sambar',
      'icon': '🥞',
      'tag': 'South Indian Classic',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC',
    },
    {
      'title': 'Chicken Biryani',
      'calories': 550,
      'hint': 'Hyderabadi Chicken Dum Biryani with spiced basmati rice and boiled egg',
      'icon': '🍛',
      'tag': 'High Protein',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
    {
      'title': 'Greek Salad',
      'calories': 160,
      'hint': 'Mediterranean Green Salad with cucumber, tomatoes, olives, and feta cheese',
      'icon': '🥗',
      'tag': 'Low Calorie & Fiber',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC',
    },
    {
      'title': 'Paneer Butter Masala',
      'calories': 380,
      'hint': 'Cottage Cheese cubes in rich tomato cashew gravy with 2 tandoori rotis',
      'icon': '🍲',
      'tag': 'Vegetarian Protein',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
  ];

  final List<Map<String, dynamic>> _medicineSamples = [
    {
      'title': 'Dolo 650 Tablet',
      'hint': 'Dolo 650mg Paracetamol tablet for fever, headache and body aches',
      'icon': '💊',
      'tag': 'Antipyretic & Analgesic',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
    {
      'title': 'Pantocid 40 Tablet',
      'hint': 'Pantoprazole Gastro-resistant tablet 40mg for acid reflux and gastritis',
      'icon': '💊',
      'tag': 'Proton Pump Inhibitor (PPI)',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC',
    },
    {
      'title': 'Azithromycin 500mg',
      'hint': 'Azithral 500mg antibiotic tablet for bacterial respiratory infections',
      'icon': '💊',
      'tag': 'Antibiotic (Macrolide)',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
    {
      'title': 'Allegra 120mg Tablet',
      'hint': 'Fexofenadine Hydrochloride tablet for allergic rhinitis and skin allergies',
      'icon': '💊',
      'tag': 'Antihistamine',
      'b64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (widget.initialImageBase64 != null) {
      _processImage(widget.initialImageBase64!, hint: widget.initialHint);
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    final res = await DeviceNativeService.capturePhoto(preferCamera: true);
    if (res['success'] == true && res['dataUrl'] != null) {
      final dataUrl = res['dataUrl'].toString();
      _processImage(dataUrl);
    }
  }

  Future<void> _pickFromGallery() async {
    final res = await DeviceNativeService.capturePhoto(preferCamera: false);
    if (res['success'] == true && res['dataUrl'] != null) {
      final dataUrl = res['dataUrl'].toString();
      _processImage(dataUrl);
    }
  }

  Future<void> _processImage(String base64Image, {String? hint}) async {
    setState(() {
      _isAnalyzing = true;
      _capturedImageBase64 = base64Image;
      _analysisStatus = _selectedScope == VisionScope.food
          ? 'Analyzing dish, calories & macro nutrients via Groq AI...'
          : 'Extracting medicine composition, dosage & clinical scope...';
      _chatHistory.clear();
    });

    try {
      final effectiveHint = hint ??
          (_selectedScope == VisionScope.food
              ? 'Analyze this food dish. Identify exact calories, nutrients, glycemic index, and related healthier dishes.'
              : 'Analyze this tablet / medicine. Process strictly in medical scope with active composition, indications, warnings and dosage.');

      final result = await GroqVisionService.analyzeImage(
        base64Image: base64Image,
        userHint: effectiveHint,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = 'Analysis complete';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Processing note: $e')),
        );
      }
    }
  }

  Future<void> _sendFollowUpQuestion() async {
    final q = _chatController.text.trim();
    if (q.isEmpty || _analysisResult == null || _isAskingAi) return;

    _chatController.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'content': q});
      _isAskingAi = true;
    });

    final answer = await GroqVisionService.askFollowUp(
      previousResult: _analysisResult!,
      question: q,
      conversationHistory: _chatHistory,
    );

    if (mounted) {
      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': answer});
        _isAskingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek Dark Viewfinder Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.aiAssistantGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'HealthExpress AI Lens',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            tooltip: 'Upload from Gallery',
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Switch Camera',
            onPressed: _captureFromCamera,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scope Selector Switcher
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ScopeTab(
                      title: '🥗 Food & Calories',
                      isSelected: _selectedScope == VisionScope.food,
                      onTap: () => setState(() => _selectedScope = VisionScope.food),
                    ),
                  ),
                  Expanded(
                    child: _ScopeTab(
                      title: '💊 Medicine & Tablets',
                      isSelected: _selectedScope == VisionScope.medicine,
                      onTap: () => setState(() => _selectedScope = VisionScope.medicine),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content: Scanner Viewfinder or Interactive Result Sheet
            Expanded(
              child: _analysisResult != null
                  ? _buildAnalysisResultView()
                  : _buildScannerCameraView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCameraView() {
    return Column(
      children: [
        // Camera Viewfinder Box
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Viewfinder Background Pattern
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Icon(
                            _selectedScope == VisionScope.food
                                ? Icons.restaurant_rounded
                                : Icons.medication_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedScope == VisionScope.food
                              ? 'Point at any dish, meal or food item'
                              : 'Point at tablet, pill strip, syrup or Rx',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            _selectedScope == VisionScope.food
                                ? '⚡ Calorie Counter • Macros • Glycemic Index'
                                : '🛡️ Strict Medical Scope • Composition • Dosage',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated Scanning Line (HUD)
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(0, (_scanLineController.value * 2) - 1),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Colors.cyanAccent,
                                AppColors.primary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Viewfinder Corner Brackets
                  const _ViewfinderCorners(),

                  // Analyzing Loading Overlay
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                color: Colors.cyanAccent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _analysisStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Powered by Groq Cloud Vision AI',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Quick Instant Demo Samples
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedScope == VisionScope.food
                    ? 'Explore Food Samples'
                    : 'Explore Medical Tablet Samples',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Tap to test instant AI',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _selectedScope == VisionScope.food
                ? _foodSamples.length
                : _medicineSamples.length,
            itemBuilder: (context, idx) {
              final item = _selectedScope == VisionScope.food
                  ? _foodSamples[idx]
                  : _medicineSamples[idx];
              return InkWell(
                onTap: () => _processImage(item['b64'] as String, hint: item['hint'] as String),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item['icon'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item['tag'] as String,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Shutter & Action Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery Picker Button
              IconButton(
                icon: const Icon(Icons.photo_size_select_actual_rounded, color: Colors.white70, size: 28),
                onPressed: _pickFromGallery,
                tooltip: 'Select from Gallery',
              ),

              // Large Shutter Camera Capture Button
              GestureDetector(
                onTap: _captureFromCamera,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        Colors.cyanAccent.shade400,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),

              // Manual Preset Trigger Button
              IconButton(
                icon: const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 28),
                onPressed: () {
                  final sample = _selectedScope == VisionScope.food ? _foodSamples[0] : _medicineSamples[0];
                  _processImage(sample['b64'] as String, hint: sample['hint'] as String);
                },
                tooltip: 'Instant Scan Demo',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisResultView() {
    final res = _analysisResult!;
    final isFood = res.isFood;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar with Retake Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_capturedImageBase64 != null && _capturedImageBase64!.startsWith('data:image/'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(_capturedImageBase64!.split(',').last),
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isFood ? const Color(0xFFFEF3C7) : const Color(0xFFE0E7FF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(isFood ? '🥗' : '💊', style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFood ? const Color(0xFFFEF3C7) : const Color(0xFFE0E7FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(isFood ? '🥗' : '💊', style: const TextStyle(fontSize: 18)),
                      ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFood ? 'Food & Nutrition Analysis' : 'Medical & Clinical Scope',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Powered by Groq Cloud AI Engine',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _analysisResult = null),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Scan Another', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Analysis Breakdown
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Health Verdict Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFood
                            ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                            : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFood ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                res.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isFood)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${res.calories} kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  res.drugSchedule,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          res.description,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                        if (isFood && res.healthVerdict.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  res.healthVerdict,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // FOOD SCOPE DETAILS
                  if (isFood) ...[
                    // Macronutrients Strip
                    const Text('Nutritional Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _MacroCard(label: 'Protein', value: '${res.nutrients.proteinG}g', color: const Color(0xFF3B82F6))),
                        const SizedBox(width: 8),
                        Expanded(child: _MacroCard(label: 'Carbs', value: '${res.nutrients.carbsG}g', color: const Color(0xFFEAB308))),
                        const SizedBox(width: 8),
                        Expanded(child: _MacroCard(label: 'Fats', value: '${res.nutrients.fatG}g', color: const Color(0xFFEF4444))),
                        const SizedBox(width: 8),
                        Expanded(child: _MacroCard(label: 'Fiber', value: '${res.nutrients.fiberG}g', color: const Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Glycemic Index & Dietary Tags
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: res.glycemicIndex.toLowerCase() == 'low'
                                ? const Color(0xFFDCFCE7)
                                : (res.glycemicIndex.toLowerCase() == 'high' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'GI: ${res.glycemicIndex}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              color: res.glycemicIndex.toLowerCase() == 'low'
                                  ? AppColors.success
                                  : (res.glycemicIndex.toLowerCase() == 'high' ? Colors.red.shade700 : Colors.amber.shade900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: res.dietaryTags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(tag, style: const TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Health Benefits & Precautions
                    if (res.healthBenefits.isNotEmpty) ...[
                      const Text('Health Benefits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      ...res.healthBenefits.map((b) => _BulletItem(text: b, isPositive: true)),
                      const SizedBox(height: 12),
                    ],

                    if (res.foodPrecautions.isNotEmpty) ...[
                      const Text('Dietary Precautions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      ...res.foodPrecautions.map((p) => _BulletItem(text: p, isPositive: false)),
                      const SizedBox(height: 16),
                    ],

                    // Related / Healthier Alternative Dishes
                    if (res.relatedDishes.isNotEmpty) ...[
                      const Text('Healthier Related Dishes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 10),
                      ...res.relatedDishes.map((dish) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), shape: BoxShape.circle),
                                child: const Icon(Icons.eco_rounded, color: AppColors.success, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                    Text(dish.whyRecommended, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${dish.calories} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  ] else ...[
                    // MEDICINE / CLINICAL TABLET SCOPE DETAILS
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Processed in Strict Medical Scope',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D4ED8)),
                                ),
                                Text(
                                  'Class: ${res.drugClass.isNotEmpty ? res.drugClass : "Pharmaceutical Form"}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Active Chemical Composition
                    _DetailSection(title: 'Active Chemical Composition', value: res.composition.isNotEmpty ? res.composition : res.name),
                    const SizedBox(height: 12),

                    // Clinical Indications & Uses
                    if (res.medicalUses.isNotEmpty) ...[
                      const Text('Clinical Uses & Indications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      ...res.medicalUses.map((u) => _BulletItem(text: u, isPositive: true)),
                      const SizedBox(height: 12),
                    ],

                    // Dosage & How to take
                    if (res.dosageGuidelines.isNotEmpty || res.howToTake.isNotEmpty) ...[
                      _DetailSection(title: 'Dosage & Administration', value: '${res.dosageGuidelines}\n${res.howToTake}'.trim()),
                      const SizedBox(height: 12),
                    ],

                    // Critical Warnings Alert Box
                    if (res.criticalWarnings.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Critical Medical Warnings',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...res.criticalWarnings.map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      Expanded(child: Text(w, style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)))),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Clinical Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MedicationRemindersScreen()),
                              );
                            },
                            icon: const Icon(Icons.alarm_add_rounded, size: 16, color: AppColors.primary),
                            label: const Text('Set Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PharmacyScreen()),
                              );
                            },
                            icon: const Icon(Icons.local_pharmacy_rounded, size: 16, color: Colors.white),
                            label: const Text('15-Min Pharmacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // INTERACTIVE AI FOLLOW-UP Q&A BOX
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              isFood ? 'Ask AI About This Dish' : 'Ask Clinical AI Pharmacist',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFood
                              ? 'e.g. "Is this okay for diabetes?", "What is a healthy substitute?"'
                              : 'e.g. "Can I take this with milk?", "What if I miss a dose?"',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        if (_chatHistory.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._chatHistory.map((msg) {
                            final isUser = msg['role'] == 'user';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isUser ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isUser ? '👤 ' : '🤖 ', style: const TextStyle(fontSize: 14)),
                                  Expanded(
                                    child: Text(
                                      msg['content'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        if (_isAskingAi)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Thinking via Groq AI...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                decoration: InputDecoration(
                                  hintText: isFood ? 'Ask question about this food...' : 'Ask question about this medicine...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                onSubmitted: (_) => _sendFollowUpQuestion(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _isAskingAi ? null : _sendFollowUpQuestion,
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final bool isPositive;
  const _BulletItem({required this.text, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 14,
            color: isPositive ? AppColors.success : Colors.amber.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String value;
  const _DetailSection({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }
}

class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.cyanAccent, width: 3),
                left: BorderSide(color: Colors.cyanAccent, width: 3),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.cyanAccent, width: 3),
                right: BorderSide(color: Colors.cyanAccent, width: 3),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.cyanAccent, width: 3),
                left: BorderSide(color: Colors.cyanAccent, width: 3),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.cyanAccent, width: 3),
                right: BorderSide(color: Colors.cyanAccent, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
