enum VisionScope { food, medicine, general }

class NutrientBreakdown {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  NutrientBreakdown({
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatG = 0.0,
    this.fiberG = 0.0,
    this.sugarG = 0.0,
    this.sodiumMg = 0.0,
  });

  factory NutrientBreakdown.fromJson(Map<String, dynamic> json) {
    return NutrientBreakdown(
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      sugarG: (json['sugar_g'] as num?)?.toDouble() ?? 0.0,
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
        'sugar_g': sugarG,
        'sodium_mg': sodiumMg,
      };
}

class RelatedDish {
  final String name;
  final int calories;
  final String whyRecommended;

  RelatedDish({
    required this.name,
    required this.calories,
    required this.whyRecommended,
  });

  factory RelatedDish.fromJson(Map<String, dynamic> json) {
    return RelatedDish(
      name: json['name']?.toString() ?? 'Healthy Alternative',
      calories: (json['calories'] as num?)?.toInt() ?? 200,
      whyRecommended: json['why']?.toString() ??
          json['whyRecommended']?.toString() ??
          'Healthier substitute',
    );
  }
}

class VisionAnalysisResult {
  final VisionScope scope;
  final String name;
  final String description;
  final String? imageBase64;

  // Food specific fields
  final int calories;
  final String portionSize;
  final NutrientBreakdown nutrients;
  final String glycemicIndex;
  final int healthScore; // 1-10
  final String healthVerdict;
  final List<String> dietaryTags;
  final List<String> healthBenefits;
  final List<String> foodPrecautions;
  final List<RelatedDish> relatedDishes;

  // Medicine / Clinical specific fields
  final String composition;
  final String drugClass;
  final List<String> medicalUses;
  final String dosageGuidelines;
  final String howToTake;
  final List<String> criticalWarnings;
  final List<String> sideEffects;
  final bool prescriptionRequired;
  final String drugSchedule;
  final double estimatedPrice;

  VisionAnalysisResult({
    required this.scope,
    required this.name,
    required this.description,
    this.imageBase64,
    this.calories = 0,
    this.portionSize = '1 standard serving',
    NutrientBreakdown? nutrients,
    this.glycemicIndex = 'Medium',
    this.healthScore = 7,
    this.healthVerdict = '',
    this.dietaryTags = const [],
    this.healthBenefits = const [],
    this.foodPrecautions = const [],
    this.relatedDishes = const [],
    this.composition = '',
    this.drugClass = '',
    this.medicalUses = const [],
    this.dosageGuidelines = '',
    this.howToTake = '',
    this.criticalWarnings = const [],
    this.sideEffects = const [],
    this.prescriptionRequired = false,
    this.drugSchedule = 'OTC',
    this.estimatedPrice = 0.0,
  }) : nutrients = nutrients ?? NutrientBreakdown();

  bool get isFood => scope == VisionScope.food;
  bool get isMedicine => scope == VisionScope.medicine;

  factory VisionAnalysisResult.fromJson(Map<String, dynamic> json, {String? imageB64}) {
    final rawScope = json['scope']?.toString().toLowerCase().trim() ?? 'food';
    VisionScope scope = VisionScope.food;
    if (rawScope.contains('med') ||
        rawScope.contains('tablet') ||
        rawScope.contains('pill') ||
        rawScope.contains('drug') ||
        rawScope.contains('pharma')) {
      scope = VisionScope.medicine;
    } else if (rawScope.contains('general')) {
      scope = VisionScope.general;
    }

    // Parse nutrients
    NutrientBreakdown nut = NutrientBreakdown();
    if (json['nutrients'] is Map<String, dynamic>) {
      nut = NutrientBreakdown.fromJson(json['nutrients']);
    }

    // Parse related dishes
    List<RelatedDish> dishes = [];
    if (json['related_dishes'] is List) {
      for (final d in json['related_dishes']) {
        if (d is Map<String, dynamic>) {
          dishes.add(RelatedDish.fromJson(d));
        }
      }
    }

    List<String> listFrom(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        return val.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    return VisionAnalysisResult(
      scope: scope,
      name: json['name']?.toString() ?? (scope == VisionScope.medicine ? 'Identified Medicine' : 'Identified Dish'),
      description: json['description']?.toString() ?? json['summary']?.toString() ?? '',
      imageBase64: imageB64,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      portionSize: json['portion_size']?.toString() ?? '1 standard serving',
      nutrients: nut,
      glycemicIndex: json['glycemic_index']?.toString() ?? 'Medium',
      healthScore: (json['health_score'] as num?)?.toInt() ?? 8,
      healthVerdict: json['health_verdict']?.toString() ?? json['verdict']?.toString() ?? '',
      dietaryTags: listFrom(json['dietary_tags']),
      healthBenefits: listFrom(json['health_benefits'] ?? json['benefits']),
      foodPrecautions: listFrom(json['food_precautions'] ?? json['precautions']),
      relatedDishes: dishes,
      composition: json['composition']?.toString() ?? json['active_ingredient']?.toString() ?? '',
      drugClass: json['drug_class']?.toString() ?? json['category']?.toString() ?? '',
      medicalUses: listFrom(json['medical_uses'] ?? json['uses'] ?? json['indications']),
      dosageGuidelines: json['dosage_guidelines']?.toString() ?? json['dosage']?.toString() ?? '',
      howToTake: json['how_to_take']?.toString() ?? json['instructions']?.toString() ?? '',
      criticalWarnings: listFrom(json['critical_warnings'] ?? json['warnings']),
      sideEffects: listFrom(json['side_effects']),
      prescriptionRequired: json['prescription_required'] == true || json['is_prescription'] == true,
      drugSchedule: json['drug_schedule']?.toString() ?? 'OTC',
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 35.0,
    );
  }
}
