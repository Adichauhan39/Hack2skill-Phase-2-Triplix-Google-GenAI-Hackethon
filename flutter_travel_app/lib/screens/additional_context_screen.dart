import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/user_preferences_provider.dart';

class AdditionalContextScreen extends StatefulWidget {
  const AdditionalContextScreen({super.key});

  @override
  State<AdditionalContextScreen> createState() =>
      _AdditionalContextScreenState();
}

class _AdditionalContextScreenState extends State<AdditionalContextScreen> {
  String _selectedCompanion = '';
  String _selectedOccasion = '';
  String _selectedExperience = '';

  // Accessibility options
  final Set<String> _selectedAccessibility = {};
  final Set<String> _selectedDietary = {};
  final Set<String> _selectedMedical = {};
  final Set<String> _selectedLanguage = {};

  final List<String> _companions = [
    'Solo',
    'Couple',
    'Family with children',
    'Friend groups'
  ];
  final List<String> _occasions = [
    'Honeymoon',
    'Anniversary',
    'Birthday',
    'Business',
    'Adventure',
    'Relaxation'
  ];
  final List<String> _experiences = [
    'First-time travelers',
    'Experienced explorers',
    'Frequent travelers'
  ];

  final List<String> _accessibilityOptions = [
    'Wheelchair access',
    'Mobility assistance',
    'Visual assistance',
    'Hearing assistance'
  ];
  final List<String> _dietaryOptions = [
    'VEG',
    'NON-VEG',
    'CONTINENTAL',
    'SOUTH INDIAN',
    'NORTH INDIAN',
    'VEGAN',
  ];
  final List<String> _medicalOptions = [
    'Allergies',
    'Chronic conditions',
    'Medications',
    'Emergency contact'
  ];
  final List<String> _languageOptions = [
    'English',
    'Hindi',
    'Local language support',
    'Translation services'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConfig.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Progress
              Padding(
                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            '6/6',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tell us a bit more.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Travel Companion
                        const Text(
                          'Travel Companion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _companions
                              .map((companion) => _buildSelectionChip(
                                    companion,
                                    _selectedCompanion == companion,
                                    () => setState(
                                        () => _selectedCompanion = companion),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Special Occasions
                        const Text(
                          'Special Occasions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _occasions
                              .map((occasion) => _buildSelectionChip(
                                    occasion,
                                    _selectedOccasion == occasion,
                                    () => setState(
                                        () => _selectedOccasion = occasion),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Travel Experience Level
                        const Text(
                          'Travel Experience Level',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _experiences
                              .map((experience) => _buildSelectionChip(
                                    experience,
                                    _selectedExperience == experience,
                                    () => setState(
                                        () => _selectedExperience = experience),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 32),

                        // Accessibility Section
                        const Text(
                          'Accessibility & Special Needs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Accessibility Options
                        _buildMultiSelectSection(
                          'Accessibility Requirements',
                          _accessibilityOptions,
                          _selectedAccessibility,
                        ),
                        const SizedBox(height: 20),

                        // Dietary Restrictions
                        _buildMultiSelectSection(
                          'Dietary Restrictions',
                          _dietaryOptions,
                          _selectedDietary,
                        ),
                        const SizedBox(height: 20),

                        // Medical Needs
                        _buildMultiSelectSection(
                          'Medical Needs',
                          _medicalOptions,
                          _selectedMedical,
                        ),
                        const SizedBox(height: 20),

                        // Language Support
                        _buildMultiSelectSection(
                          'Language Support',
                          _languageOptions,
                          _selectedLanguage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Complete Profile Button
              Padding(
                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppConfig.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Save additional context preferences to provider
                      final provider = Provider.of<UserPreferencesProvider>(
                          context,
                          listen: false);
                      provider.updateAdditionalContext(
                        companion: _selectedCompanion.isNotEmpty
                            ? _selectedCompanion
                            : null,
                        occasion: _selectedOccasion.isNotEmpty
                            ? _selectedOccasion
                            : null,
                        experience: _selectedExperience.isNotEmpty
                            ? _selectedExperience
                            : null,
                        accessibility: _selectedAccessibility.toList(),
                        dietary: _selectedDietary.toList(),
                        medical: _selectedMedical.toList(),
                        languages: _selectedLanguage.toList(),
                      );
                      Get.offAllNamed('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Complete Profile & Start Discovery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionChip(
      String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: AppConfig.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildMultiSelectSection(
      String title, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((option) => FilterChip(
                    label: Text(
                      option,
                      style: TextStyle(
                        color: selected.contains(option)
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    selected: selected.contains(option),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          selected.add(option);
                        } else {
                          selected.remove(option);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppConfig.primaryColor,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
