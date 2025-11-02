import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/user_progress_checkpoint.dart';

class DestinationPreferencesScreen extends StatefulWidget {
  const DestinationPreferencesScreen({super.key});

  @override
  State<DestinationPreferencesScreen> createState() =>
      _DestinationPreferencesScreenState();
}

class _DestinationPreferencesScreenState
    extends State<DestinationPreferencesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Selected preferences
  final Set<String> _selectedClimates = {};
  final Set<String> _selectedTerrains = {};
  final Set<String> _selectedCultures = {};
  final Set<String> _selectedSunActivities = {};

  final List<String> _climates = ['Tropical', 'Temperate', 'Cold', 'Desert'];
  final List<String> _terrains = [
    'Beach',
    'Mountains',
    'Urban',
    'Rural',
    'Forest'
  ];
  final List<String> _cultures = [
    'Historical',
    'Modern',
    'Traditional',
    'Cosmopolitan'
  ];
  final List<String> _sunActivities = [
    'Beach Time',
    'Sunset Watching',
    'Pool Lounging',
    'Outdoor Dining',
    'Sunbathing',
    'Water Sports',
    'Beach Volleyball',
    'Sunrise Yoga'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Container(
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
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                            const Expanded(
                              child: Text(
                                '1/6',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 48), // Balance the back button
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Where to next?',
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
                            // Search Input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Type your dream destination... (e.g., Beach in Goa or South India)',
                                  prefixIcon:
                                      Icon(Icons.search, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Sun Activities (Above other preferences)
                            const Text(
                              'Sun Activities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sunActivities
                                  .map((activity) => _buildFilterChip(
                                        activity,
                                        _selectedSunActivities
                                            .contains(activity),
                                        () => _toggleSelection(
                                            _selectedSunActivities, activity),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),

                            // Climate Preferences
                            const Text(
                              'Climate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _climates
                                  .map((climate) => _buildFilterChip(
                                        climate,
                                        _selectedClimates.contains(climate),
                                        () => _toggleSelection(
                                            _selectedClimates, climate),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),

                            // Terrain Preferences
                            const Text(
                              'Terrain',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _terrains
                                  .map((terrain) => _buildFilterChip(
                                        terrain,
                                        _selectedTerrains.contains(terrain),
                                        () => _toggleSelection(
                                            _selectedTerrains, terrain),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),

                            // Cultural Context
                            const Text(
                              'Cultural Context',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _cultures
                                  .map((culture) => _buildFilterChip(
                                        culture,
                                        _selectedCultures.contains(culture),
                                        () => _toggleSelection(
                                            _selectedCultures, culture),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next Button
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
                          // Save destination preferences to provider
                          final provider = Provider.of<UserPreferencesProvider>(
                              context,
                              listen: false);
                          provider.updateDestinationPreferences(
                            climates: _selectedClimates.toList(),
                            terrains: _selectedTerrains.toList(),
                            cultures: _selectedCultures.toList(),
                            sunActivities: _selectedSunActivities.toList(),
                          );
                          Get.toNamed('/budget-preferences');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
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

          // AI Travel Insights Checkpoint Overlay
          const UserProgressCheckpoint(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
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
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _toggleSelection(Set<String> set, String item) {
    setState(() {
      if (set.contains(item)) {
        set.remove(item);
      } else {
        set.add(item);
      }
    });
  }
}
