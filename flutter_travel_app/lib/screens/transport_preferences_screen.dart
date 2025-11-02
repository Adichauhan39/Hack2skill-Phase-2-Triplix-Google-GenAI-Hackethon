import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/user_progress_checkpoint.dart';

class TransportPreferencesScreen extends StatefulWidget {
  const TransportPreferencesScreen({super.key});

  @override
  State<TransportPreferencesScreen> createState() =>
      _TransportPreferencesScreenState();
}

class _TransportPreferencesScreenState
    extends State<TransportPreferencesScreen> {
  final Set<String> _selectedTransportModes = {};
  final Map<String, Set<String>> _transportDetails = {};
  final TextEditingController _additionalQueryController =
      TextEditingController();

  final List<Map<String, dynamic>> _transportModes = [
    {
      'id': 'air',
      'title': 'Air Travel',
      'icon': Icons.airplanemode_active,
      'color': const Color(0xFF2196F3),
      'options': [
        'Economy',
        'Premium Economy',
        'Business',
        'First Class',
        'Low-Cost Carrier',
        'Full-Service Airline',
        'Direct Flights',
        'Connecting Flights',
        'Red-Eye Flights',
        'Charter Flights'
      ],
    },
    {
      'id': 'rail',
      'title': 'Rail Transport',
      'icon': Icons.train,
      'color': const Color(0xFF4CAF50),
      'options': [
        'Standard',
        'AC Chair Car',
        'AC 3-Tier',
        'AC 2-Tier',
        'AC 1-Tier',
        'Sleeper Class',
        'Rajdhani Express',
        'Shatabdi Express',
        'Vande Bharat',
        'Local Trains',
        'Scenic Routes',
        'Overnight Trains'
      ],
    },
    {
      'id': 'road',
      'title': 'Road Travel',
      'icon': Icons.directions_bus,
      'color': const Color(0xFFFF9800),
      'options': [
        'Standard Bus',
        'Volvo/Sleeper',
        'Private Car',
        'Shared Taxi',
        'Luxury Coach',
        'Semi-Sleeper',
        'Self-Drive Car',
        'Chauffeur-Driven',
        'SUV/MUV',
        'Tempo Traveller',
        'AC Bus',
        'Non-AC Bus'
      ],
    },
    {
      'id': 'water',
      'title': 'Water Transport',
      'icon': Icons.directions_boat,
      'color': const Color(0xFF00BCD4),
      'options': [
        'Ferry',
        'Cruise',
        'Speed Boat',
        'Houseboat',
        'Yacht',
        'Shikara',
        'Catamaran',
        'Sailing Boat',
        'River Cruise',
        'Ocean Liner'
      ],
    },
    {
      'id': 'local',
      'title': 'Local Transport',
      'icon': Icons.directions_car,
      'color': const Color(0xFF9C27B0),
      'options': [
        'Taxi',
        'Ride Sharing',
        'Auto Rickshaw',
        'Local Bus',
        'Metro',
        'Tuk-Tuk',
        'Cycle Rickshaw',
        'E-Rickshaw',
        'Monorail',
        'Tram',
        'Cable Car'
      ],
    },
    {
      'id': 'specialty',
      'title': 'Specialty Transport',
      'icon': Icons.two_wheeler,
      'color': const Color(0xFF795548),
      'options': [
        'Bicycle Rental',
        'Motorcycle',
        'Helicopter',
        'Hot Air Balloon',
        'E-Bike/Scooter',
        'Segway',
        'Horse Carriage',
        'Ropeway/Cable Car',
        'Seaplane',
        'Private Jet'
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
                                '4/6',
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
                          'How do you like to move?',
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
                            // AI Search Input Prompt
                            const Text(
                              'Any specific transport preferences?',
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
                                      'e.g., I get motion sick easily so prefer trains over buses, or I love scenic routes even if they take longer...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            const Text(
                              'Select your preferred transport modes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Transport Mode Grid
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
                              itemCount: _transportModes.length,
                              itemBuilder: (context, index) {
                                final mode = _transportModes[index];
                                final isSelected = _selectedTransportModes
                                    .contains(mode['id']);
                                final selectedOptions =
                                    _transportDetails[mode['id']] ?? {};

                                return GestureDetector(
                                  onTap: () => _toggleTransportMode(mode['id']),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? mode['color'].withOpacity(0.1)
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isSelected
                                            ? mode['color']
                                            : Colors.grey[200]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? mode['color']
                                                : Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            mode['icon'],
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey[600],
                                            size: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          mode['title'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? mode['color']
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (selectedOptions.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: mode['color'],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${selectedOptions.length}',
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

                            // Transport Details Section
                            ..._selectedTransportModes
                                .map((modeId) {
                                  final mode = _transportModes
                                      .firstWhere((m) => m['id'] == modeId);
                                  final selectedOptions =
                                      _transportDetails[modeId] ?? {};

                                  return Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: mode['color'].withOpacity(0.05),
                                      border: Border.all(
                                          color:
                                              mode['color'].withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(mode['icon'],
                                                color: mode['color'], size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              mode['title'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: mode['color'],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Preferred options:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: mode['options']
                                              .map((option) {
                                                final isSelected =
                                                    selectedOptions
                                                        .contains(option);
                                                return FilterChip(
                                                  label: Text(
                                                    option,
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  selected: isSelected,
                                                  onSelected: (_) =>
                                                      _toggleTransportOption(
                                                          modeId, option),
                                                  backgroundColor: Colors.white,
                                                  selectedColor: mode['color'],
                                                  checkmarkColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                );
                                              })
                                              .toList()
                                              .cast<Widget>(),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList()
                                .cast<Widget>(),
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
                          // Save transport preferences to provider
                          final provider = Provider.of<UserPreferencesProvider>(
                              context,
                              listen: false);
                          provider.updateTransport(
                              _selectedTransportModes.toList());
                          Get.toNamed('/budget-allocation');
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

  @override
  void dispose() {
    _additionalQueryController.dispose();
    super.dispose();
  }

  void _toggleTransportMode(String modeId) {
    setState(() {
      if (_selectedTransportModes.contains(modeId)) {
        _selectedTransportModes.remove(modeId);
        _transportDetails.remove(modeId);
      } else {
        _selectedTransportModes.add(modeId);
        _transportDetails[modeId] = {};
      }
    });
  }

  void _toggleTransportOption(String modeId, String option) {
    setState(() {
      final options = _transportDetails[modeId] ?? {};
      if (options.contains(option)) {
        options.remove(option);
      } else {
        options.add(option);
      }
      _transportDetails[modeId] = options;
    });
  }
}
