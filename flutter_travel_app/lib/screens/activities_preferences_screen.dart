import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/user_progress_checkpoint.dart';

class ActivitiesPreferencesScreen extends StatefulWidget {
  const ActivitiesPreferencesScreen({super.key});

  @override
  State<ActivitiesPreferencesScreen> createState() =>
      _ActivitiesPreferencesScreenState();
}

class _ActivitiesPreferencesScreenState
    extends State<ActivitiesPreferencesScreen> {
  final Set<String> _selectedActivities = {};
  final Map<String, List<String>> _expandedCategories = {};
  final TextEditingController _additionalQueryController =
      TextEditingController();

  final List<Map<String, dynamic>> _activityCategories = [
    {
      'id': 'adventure',
      'title': 'Adventure',
      'icon': Icons.terrain,
      'color': const Color(0xFFFF5722),
      'subActivities': [
        'Trekking',
        'Scuba Diving',
        'Paragliding',
        'Rock Climbing',
        'White Water Rafting',
        'Bungee Jumping',
        'Zip Lining',
        'Skydiving',
        'Mountain Biking',
        'Caving',
        'Kayaking',
        'Surfing'
      ],
    },
    {
      'id': 'cultural',
      'title': 'Cultural',
      'icon': Icons.museum,
      'color': const Color(0xFF9C27B0),
      'subActivities': [
        'Museum Visits',
        'Historical Sites',
        'Local Festivals',
        'Art Galleries',
        'Traditional Crafts',
        'Temple Tours',
        'Heritage Walks',
        'Cultural Shows',
        'Language Classes',
        'Local Ceremonies',
        'Architecture Tours'
      ],
    },
    {
      'id': 'relaxation',
      'title': 'Relaxation',
      'icon': Icons.spa,
      'color': const Color(0xFF4CAF50),
      'subActivities': [
        'Beach Time',
        'Spa Treatments',
        'Meditation',
        'Reading',
        'Nature Walks',
        'Yoga Sessions',
        'Hot Springs',
        'Hammock Time',
        'Sunset Watching',
        'Aromatherapy',
        'Pool Lounging'
      ],
    },
    {
      'id': 'entertainment',
      'title': 'Entertainment',
      'icon': Icons.movie,
      'color': const Color(0xFFFF9800),
      'subActivities': [
        'Concerts',
        'Theater Shows',
        'Nightlife',
        'Amusement Parks',
        'Sports Events',
        'Comedy Clubs',
        'Music Festivals',
        'Dance Clubs',
        'Karaoke',
        'Cinema',
        'Casino Gaming'
      ],
    },
    {
      'id': 'nature',
      'title': 'Nature',
      'icon': Icons.forest,
      'color': const Color(0xFF2196F3),
      'subActivities': [
        'Wildlife Safari',
        'National Parks',
        'Hiking',
        'Bird Watching',
        'Photography',
        'Botanical Gardens',
        'Mountain Views',
        'Waterfall Visits',
        'Forest Trails',
        'Stargazing',
        'Camping'
      ],
    },
    {
      'id': 'photography',
      'title': 'Photography',
      'icon': Icons.camera_alt,
      'color': const Color(0xFF607D8B),
      'subActivities': [
        'Landscape',
        'Street Photography',
        'Wildlife',
        'Architecture',
        'Portrait',
        'Sunrise/Sunset',
        'Night Photography',
        'Food Photography',
        'Cultural Events',
        'Macro Photography'
      ],
    },
    {
      'id': 'food',
      'title': 'Food',
      'icon': Icons.restaurant,
      'color': const Color(0xFFE91E63),
      'subActivities': [
        'Street Food',
        'Fine Dining',
        'Cooking Classes',
        'Wine Tasting',
        'Local Markets',
        'Food Tours',
        'Brewery Visits',
        'Farm-to-Table',
        'Seafood Specials',
        'Dessert Cafes',
        'Coffee Tasting',
        'BBQ & Grills'
      ],
    },
    {
      'id': 'shopping',
      'title': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFF795548),
      'subActivities': [
        'Local Markets',
        'Boutiques',
        'Souvenirs',
        'Antiques',
        'Luxury Brands',
        'Handicrafts',
        'Jewelry',
        'Textiles',
        'Art & Paintings',
        'Books',
        'Spices & Tea'
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                                '3/6',
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
                          'What do you love to do?',
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
                            const Text(
                              'Select your interests',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // AI Search Input Prompt - Moved to top
                            const Text(
                              'Any specific activity preferences?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _additionalQueryController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText:
                                      'e.g., I prefer outdoor activities, or I want cultural experiences with local interactions...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Activity Grid with Floating Overlays
                            Stack(
                              children: [
                                // Base Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                    childAspectRatio: 0.9,
                                  ),
                                  itemCount: _activityCategories.length,
                                  itemBuilder: (context, index) {
                                    final category = _activityCategories[index];
                                    final hasSelections =
                                        category['subActivities'].any(
                                      (activity) => _selectedActivities
                                          .contains(activity),
                                    );

                                    return GestureDetector(
                                      onTap: () => _toggleCategoryExpansion(
                                          category['id']),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: hasSelections
                                              ? category['color']
                                                  .withOpacity(0.1)
                                              : Colors.grey[50],
                                          border: Border.all(
                                            color: hasSelections
                                                ? category['color']
                                                : Colors.grey[200]!,
                                            width: hasSelections ? 2 : 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: category['color'],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                category['icon'],
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              category['title'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: hasSelections
                                                    ? category['color']
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (hasSelections) ...[
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: category['color'],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${category['subActivities'].where((activity) => _selectedActivities.contains(activity)).length}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Floating Expanded Sub-Activities
                                ..._expandedCategories.entries
                                    .map<Widget>((entry) {
                                  final categoryId = entry.key;
                                  final categoryIndex =
                                      _activityCategories.indexWhere(
                                          (cat) => cat['id'] == categoryId);
                                  final category =
                                      _activityCategories[categoryIndex];

                                  // Calculate position based on grid layout
                                  final crossAxisCount = 4;
                                  final row = categoryIndex ~/ crossAxisCount;
                                  final col = categoryIndex % crossAxisCount;

                                  return Positioned(
                                    top: row * 80.0 +
                                        60, // Position above the icon
                                    left: col *
                                            (MediaQuery.of(context).size.width -
                                                32) /
                                            crossAxisCount +
                                        8,
                                    right: MediaQuery.of(context).size.width -
                                        (col + 1) *
                                            (MediaQuery.of(context).size.width -
                                                32) /
                                            crossAxisCount -
                                        8,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: category['color']
                                                .withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(category['icon'],
                                                  color: category['color'],
                                                  size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                category['title'],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: category['color'],
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: Icon(Icons.close,
                                                    color: category['color'],
                                                    size: 20),
                                                onPressed: () =>
                                                    _toggleCategoryExpansion(
                                                        categoryId),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: (category['subActivities']
                                                    as List<String>)
                                                .map<Widget>((activity) {
                                              final isSelected =
                                                  _selectedActivities
                                                      .contains(activity);
                                              return FilterChip(
                                                label: Text(
                                                  activity,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                selected: isSelected,
                                                onSelected: (_) =>
                                                    _toggleActivity(activity),
                                                backgroundColor: Colors.white,
                                                selectedColor:
                                                    category['color'],
                                                checkmarkColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),

                            const SizedBox(height: 32),
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
                          // Save activities preferences to provider
                          final provider = Provider.of<UserPreferencesProvider>(
                              context,
                              listen: false);
                          provider
                              .updateActivities(_selectedActivities.toList());
                          Get.toNamed('/transport-preferences');
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

  void _toggleCategoryExpansion(String categoryId) {
    setState(() {
      if (_expandedCategories.containsKey(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories[categoryId] = [];
      }
    });
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
      }
    });
  }
}
