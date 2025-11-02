import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_config.dart';
import '../services/python_adk_service.dart';
import 'travel_results_screen.dart';

class TravelBookingScreen extends StatefulWidget {
  const TravelBookingScreen({super.key});

  @override
  State<TravelBookingScreen> createState() => _TravelBookingScreenState();
}

class _TravelBookingScreenState extends State<TravelBookingScreen> {
  final PythonADKService _apiService = PythonADKService();

  // Form controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _passengersController =
      TextEditingController(text: '1');
  final TextEditingController _durationController =
      TextEditingController(text: '24');

  // Form data
  String _selectedMode = 'flight';
  String _selectedClass = 'economy';
  String _selectedTravelType = 'one_way';
  DateTime? _departureDate;
  DateTime? _returnDate;

  // Preferences
  final List<String> _preferences = [];
  final List<String> _extras = [];
  final List<String> _accessibility = [];

  // Accommodation
  bool _needsAccommodation = false;
  String _accommodationType = 'hotel';
  int _rooms = 1;
  int _adults = 1;
  int _children = 0;

  bool _isLoading = false;

  final List<Map<String, dynamic>> _modes = [
    {'id': 'flight', 'name': 'Flight', 'icon': FontAwesomeIcons.plane},
    {'id': 'train', 'name': 'Train', 'icon': FontAwesomeIcons.train},
    {'id': 'bus', 'name': 'Bus', 'icon': FontAwesomeIcons.bus},
    {'id': 'car_rental', 'name': 'Car Rental', 'icon': FontAwesomeIcons.car},
    {'id': 'taxi', 'name': 'Taxi', 'icon': FontAwesomeIcons.taxi},
    {
      'id': 'bike_scooter',
      'name': 'Bike/Scooter',
      'icon': FontAwesomeIcons.motorcycle
    },
  ];

  final List<Map<String, dynamic>> _classes = [
    {'id': 'economy', 'name': 'Economy'},
    {'id': 'business', 'name': 'Business'},
    {'id': 'first_class', 'name': 'First Class'},
  ];

  final List<Map<String, dynamic>> _travelTypes = [
    {'id': 'one_way', 'name': 'One-Way'},
    {'id': 'round_trip', 'name': 'Round Trip'},
    {'id': 'multi_city', 'name': 'Multi-City'},
  ];

  final List<Map<String, dynamic>> _preferenceOptions = [
    {'id': 'ac', 'name': 'AC', 'icon': FontAwesomeIcons.snowflake},
    {'id': 'non_ac', 'name': 'Non-AC', 'icon': FontAwesomeIcons.sun},
    {'id': 'sleeper', 'name': 'Sleeper', 'icon': FontAwesomeIcons.bed},
    {'id': 'shared', 'name': 'Shared', 'icon': FontAwesomeIcons.users},
    {'id': 'private', 'name': 'Private', 'icon': FontAwesomeIcons.user},
  ];

  final List<Map<String, dynamic>> _extraOptions = [
    {'id': 'pickup', 'name': 'Pickup', 'icon': FontAwesomeIcons.mapMarkerAlt},
    {'id': 'luggage', 'name': 'Luggage', 'icon': FontAwesomeIcons.suitcase},
    {'id': 'wifi', 'name': 'Wi-Fi', 'icon': FontAwesomeIcons.wifi},
    {'id': 'meals', 'name': 'Meals', 'icon': FontAwesomeIcons.utensils},
  ];

  final List<Map<String, dynamic>> _accessibilityOptions = [
    {
      'id': 'wheelchair',
      'name': 'Wheelchair',
      'icon': FontAwesomeIcons.wheelchair
    },
    {'id': 'child_seat', 'name': 'Child Seat', 'icon': FontAwesomeIcons.child},
  ];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _passengersController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _showRoutePopup({bool isDestination = false}) {
    final TextEditingController controller =
        isDestination ? _toController : _fromController;
    final String title =
        isDestination ? 'Select Destination' : 'Select Departure City';
    final String hint =
        isDestination ? 'Enter destination city' : 'Enter departure city';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild to update display
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccommodationSelection() {
    return GestureDetector(
      onTap: () => _showAccommodationPopup(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppConfig.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.hotel, color: AppConfig.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accommodation',
                    style:
                        TextStyle(color: AppConfig.textSecondary, fontSize: 12),
                  ),
                  Text(
                    _needsAccommodation
                        ? '${_accommodationType} • ${_rooms} room${_rooms > 1 ? 's' : ''} • ${_adults + _children} guest${_adults + _children > 1 ? 's' : ''}'
                        : 'No accommodation needed',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppConfig.textSecondary),
          ],
        ),
      ),
    );
  }

  void _searchTravel() async {
    if (_fromController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter departure city');
      return;
    }

    // For car rental, taxi, bike - to city is optional
    if (_selectedMode != 'car_rental' &&
        _selectedMode != 'taxi' &&
        _selectedMode != 'bike_scooter' &&
        _toController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter destination city');
      return;
    }

    if (_departureDate == null) {
      Get.snackbar('Error', 'Please select departure date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestData = {
        'mode': _selectedMode,
        'from_city': _fromController.text,
        'to_city': _toController.text.isNotEmpty ? _toController.text : null,
        'departure_date': _departureDate!.toIso8601String().split('T')[0],
        'return_date': _returnDate?.toIso8601String().split('T')[0],
        'passengers': int.tryParse(_passengersController.text) ?? 1,
        'travel_class': _selectedClass,
        'preferences': _preferences,
        'extras': _extras,
        'travel_type': _selectedTravelType,
        'accessibility': _accessibility,
        'duration_hours':
            _selectedMode == 'car_rental' || _selectedMode == 'bike_scooter'
                ? int.tryParse(_durationController.text) ?? 24
                : null,
      };

      final response = await _apiService.searchTravel(requestData);

      if (response['status'] == 'success') {
        Get.to(() => TravelResultsScreen(
              results: response['results'] ?? [],
              searchParams: requestData,
            ));
      } else {
        Get.snackbar('Error', response['message'] ?? 'Search failed');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to search travel options: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Booking Agent'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selection
            _buildSectionTitle('Travel Mode'),
            _buildModeSelection(),

            const SizedBox(height: 24),

            // Route Selection
            _buildSectionTitle('Route'),
            _buildRouteSelection(),

            const SizedBox(height: 24),

            // Travel Type & Class
            Row(
              children: [
                Expanded(child: _buildTravelTypeSelection()),
                const SizedBox(width: 16),
                Expanded(child: _buildClassSelection()),
              ],
            ),

            const SizedBox(height: 24),

            // Dates
            _buildDateSelection(),

            const SizedBox(height: 24),

            // Accommodation
            _buildAccommodationSelection(),

            const SizedBox(height: 24),

            // Passengers & Duration
            Row(
              children: [
                Expanded(child: _buildPassengersInput()),
                if (_selectedMode == 'car_rental' ||
                    _selectedMode == 'bike_scooter') ...[
                  const SizedBox(width: 16),
                  Expanded(child: _buildDurationInput()),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Preferences
            _buildSectionTitle('Preferences'),
            _buildMultiSelect(_preferenceOptions, _preferences),

            const SizedBox(height: 24),

            // Extras
            _buildSectionTitle('Extras'),
            _buildMultiSelect(_extraOptions, _extras),

            const SizedBox(height: 24),

            // Accessibility
            _buildSectionTitle('Accessibility'),
            _buildMultiSelect(_accessibilityOptions, _accessibility),

            const SizedBox(height: 32),

            // Search Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchTravel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Search Travel Options',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConfig.textPrimary,
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _modes.length,
        itemBuilder: (context, index) {
          final mode = _modes[index];
          final isSelected = _selectedMode == mode['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedMode = mode['id']),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppConfig.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppConfig.primaryColor
                      : AppConfig.borderColor,
                ),
                boxShadow: isSelected ? [AppConfig.cardShadow] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    mode['icon'],
                    color: isSelected ? Colors.white : AppConfig.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppConfig.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteSelection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showRoutePopup(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppConfig.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff, color: AppConfig.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From City',
                        style: TextStyle(
                            color: AppConfig.textSecondary, fontSize: 12),
                      ),
                      Text(
                        _fromController.text.isNotEmpty
                            ? _fromController.text
                            : 'Select departure city',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppConfig.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedMode !=
            'car_rental') // Car rental doesn't need destination
          GestureDetector(
            onTap: () => _showRoutePopup(isDestination: true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppConfig.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flight_land, color: AppConfig.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To City',
                          style: TextStyle(
                              color: AppConfig.textSecondary, fontSize: 12),
                        ),
                        Text(
                          _toController.text.isNotEmpty
                              ? _toController.text
                              : 'Select destination city',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppConfig.textSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTravelTypeSelection() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTravelType,
      decoration: InputDecoration(
        labelText: 'Travel Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _travelTypes.map<DropdownMenuItem<String>>((type) {
        return DropdownMenuItem<String>(
          value: type['id'] as String,
          child: Text(type['name'] as String),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedTravelType = value!),
    );
  }

  Widget _buildClassSelection() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedClass,
      decoration: InputDecoration(
        labelText: 'Class',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _classes.map<DropdownMenuItem<String>>((cls) {
        return DropdownMenuItem<String>(
          value: cls['id'] as String,
          child: Text(cls['name'] as String),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedClass = value!),
    );
  }

  Widget _buildDateSelection() {
    return GestureDetector(
      onTap: () => _showDatePopup(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppConfig.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppConfig.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Travel Dates',
                    style:
                        TextStyle(color: AppConfig.textSecondary, fontSize: 12),
                  ),
                  Text(
                    _departureDate != null
                        ? _selectedTravelType == 'round_trip' &&
                                _returnDate != null
                            ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year} - ${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'
                            : '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'
                        : 'Select travel dates',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppConfig.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersInput() {
    return TextField(
      controller: _passengersController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Passengers',
        prefixIcon: const Icon(Icons.people),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDurationInput() {
    return TextField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Duration (hours)',
        prefixIcon: const Icon(Icons.schedule),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMultiSelect(
      List<Map<String, dynamic>> options, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option['id']);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(option['icon'], size: 16),
              const SizedBox(width: 4),
              Text(option['name']),
            ],
          ),
          selected: isSelected,
          onSelected: (bool selectedChip) {
            setState(() {
              if (selectedChip) {
                selected.add(option['id']);
              } else {
                selected.remove(option['id']);
              }
            });
          },
          selectedColor: AppConfig.primaryColor.withOpacity(0.2),
          checkmarkColor: AppConfig.primaryColor,
        );
      }).toList(),
    );
  }

  void _showAccommodationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Accommodation Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Need accommodation toggle
                  SwitchListTile(
                    title: const Text('Need Accommodation'),
                    value: _needsAccommodation,
                    onChanged: (value) {
                      setState(() {
                        _needsAccommodation = value;
                      });
                      this.setState(() {});
                    },
                  ),
                  if (_needsAccommodation) ...[
                    const SizedBox(height: 16),
                    // Accommodation type
                    DropdownButtonFormField<String>(
                      value: _accommodationType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['hotel', 'resort', 'apartment', 'villa', 'hostel']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                    type[0].toUpperCase() + type.substring(1)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _accommodationType = value;
                          });
                          this.setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Rooms
                    Row(
                      children: [
                        const Text('Rooms: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _rooms > 1
                              ? () {
                                  setState(() {
                                    _rooms--;
                                  });
                                  this.setState(() {});
                                }
                              : null,
                        ),
                        Text('$_rooms'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _rooms++;
                            });
                            this.setState(() {});
                          },
                        ),
                      ],
                    ),
                    // Adults
                    Row(
                      children: [
                        const Text('Adults: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _adults > 1
                              ? () {
                                  setState(() {
                                    _adults--;
                                  });
                                  this.setState(() {});
                                }
                              : null,
                        ),
                        Text('$_adults'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _adults++;
                            });
                            this.setState(() {});
                          },
                        ),
                      ],
                    ),
                    // Children
                    Row(
                      children: [
                        const Text('Children: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _children > 0
                              ? () {
                                  setState(() {
                                    _children--;
                                  });
                                  this.setState(() {});
                                }
                              : null,
                        ),
                        Text('$_children'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _children++;
                            });
                            this.setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDatePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Travel Dates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Departure Date
              ListTile(
                leading: const Icon(Icons.flight_takeoff,
                    color: AppConfig.primaryColor),
                title: const Text('Departure Date'),
                subtitle: Text(
                  _departureDate != null
                      ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'
                      : 'Not selected',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _departureDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _departureDate = picked;
                      if (_returnDate != null &&
                          _returnDate!.isBefore(picked)) {
                        _returnDate = picked.add(const Duration(days: 1));
                      }
                    });
                  }
                },
              ),
              if (_selectedTravelType == 'round_trip') ...[
                const Divider(),
                // Return Date
                ListTile(
                  leading: const Icon(Icons.flight_land,
                      color: AppConfig.primaryColor),
                  title: const Text('Return Date'),
                  subtitle: Text(
                    _returnDate != null
                        ? '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'
                        : 'Not selected',
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _returnDate ??
                          (_departureDate?.add(const Duration(days: 1)) ??
                              DateTime.now().add(const Duration(days: 2))),
                      firstDate: _departureDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _returnDate = picked;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
