class UserPreferences {
  String? destination;
  double? budget;
  List<String> selectedActivities = [];
  List<String> selectedTransport = [];
  List<String> selectedAccommodation = [];
  List<String> selectedClimates = [];
  List<String> selectedTerrains = [];
  List<String> selectedCultures = [];
  List<String> selectedSunActivities = [];
  String? companion;
  String? occasion;
  String? experience;
  List<String> selectedAccessibility = [];
  List<String> selectedDietary = [];
  List<String> selectedMedical = [];
  List<String> selectedLanguages = [];
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int? numberOfPeople;

  bool get hasDestination => destination != null && destination!.isNotEmpty;
  bool get hasBudget => budget != null && budget! > 0;
  bool get hasActivities => selectedActivities.isNotEmpty;
  bool get hasTransport => selectedTransport.isNotEmpty;
  bool get hasAccommodation => selectedAccommodation.isNotEmpty;
  bool get hasDestinationPreferences =>
      selectedClimates.isNotEmpty ||
      selectedTerrains.isNotEmpty ||
      selectedCultures.isNotEmpty ||
      selectedSunActivities.isNotEmpty;
  bool get hasSunActivities => selectedSunActivities.isNotEmpty;
  bool get hasCompanion => companion != null && companion!.isNotEmpty;
  bool get hasOccasion => occasion != null && occasion!.isNotEmpty;
  bool get hasExperience => experience != null && experience!.isNotEmpty;
  bool get hasAccessibility => selectedAccessibility.isNotEmpty;
  bool get hasDietary => selectedDietary.isNotEmpty;
  bool get hasMedical => selectedMedical.isNotEmpty;
  bool get hasLanguages => selectedLanguages.isNotEmpty;
  bool get hasDates => checkInDate != null && checkOutDate != null;
  bool get hasPeople => numberOfPeople != null && numberOfPeople! > 0;

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'budget': budget,
        'selectedActivities': selectedActivities,
        'selectedTransport': selectedTransport,
        'selectedAccommodation': selectedAccommodation,
        'selectedClimates': selectedClimates,
        'selectedTerrains': selectedTerrains,
        'selectedCultures': selectedCultures,
        'selectedSunActivities': selectedSunActivities,
        'companion': companion,
        'occasion': occasion,
        'experience': experience,
        'selectedAccessibility': selectedAccessibility,
        'selectedDietary': selectedDietary,
        'selectedMedical': selectedMedical,
        'selectedLanguages': selectedLanguages,
        'checkInDate': checkInDate?.toIso8601String(),
        'checkOutDate': checkOutDate?.toIso8601String(),
        'numberOfPeople': numberOfPeople,
      };

  void fromJson(Map<String, dynamic> json) {
    destination = json['destination'];
    budget = json['budget'];
    selectedActivities = List<String>.from(json['selectedActivities'] ?? []);
    selectedTransport = List<String>.from(json['selectedTransport'] ?? []);
    selectedAccommodation =
        List<String>.from(json['selectedAccommodation'] ?? []);
    selectedClimates = List<String>.from(json['selectedClimates'] ?? []);
    selectedTerrains = List<String>.from(json['selectedTerrains'] ?? []);
    selectedCultures = List<String>.from(json['selectedCultures'] ?? []);
    selectedSunActivities =
        List<String>.from(json['selectedSunActivities'] ?? []);
    companion = json['companion'];
    occasion = json['occasion'];
    experience = json['experience'];
    selectedAccessibility =
        List<String>.from(json['selectedAccessibility'] ?? []);
    selectedDietary = List<String>.from(json['selectedDietary'] ?? []);
    selectedMedical = List<String>.from(json['selectedMedical'] ?? []);
    selectedLanguages = List<String>.from(json['selectedLanguages'] ?? []);
    checkInDate = json['checkInDate'] != null
        ? DateTime.parse(json['checkInDate'])
        : null;
    checkOutDate = json['checkOutDate'] != null
        ? DateTime.parse(json['checkOutDate'])
        : null;
    numberOfPeople = json['numberOfPeople'];
  }
}
