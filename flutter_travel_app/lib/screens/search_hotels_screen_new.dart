import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../models/hotel.dart';

class SearchHotelsScreen extends StatefulWidget {
  const SearchHotelsScreen({super.key});

  @override
  State<SearchHotelsScreen> createState() => _SearchHotelsScreenState();
}

class _SearchHotelsScreenState extends State<SearchHotelsScreen> {
  final ApiService _api = ApiService();
  final MockDataService _mockData = MockDataService();

  String? _selectedCity;
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _guests = 2;
  int _rooms = 1;
  String _specialRequest = '';
  RangeValues _priceRange = const RangeValues(0, 5000000);

  // Hotel preferences from home screen
  double _hotelBudget = 5000;
  String? _roomType;
  List<String> _foodTypes = [];
  String? _ambiance;
  List<String> _extras = [];

  List<Hotel> _searchResults = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    // Get parameters passed from home screen
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      setState(() {
        _selectedCity = arguments['city'] as String?;
        _checkIn = arguments['checkIn'] as DateTime? ?? DateTime.now();
        _checkOut = arguments['checkOut'] as DateTime? ??
            DateTime.now().add(const Duration(days: 1));
        _guests = arguments['guests'] as int? ?? 2;
        _rooms = arguments['rooms'] as int? ?? 1;
        _specialRequest = arguments['specialRequest'] as String? ?? '';

        // Get hotel preferences
        _hotelBudget = arguments['hotelBudget'] as double? ?? 5000;
        _roomType = arguments['roomType'] as String?;
        _foodTypes =
            (arguments['foodTypes'] as List<dynamic>?)?.cast<String>() ?? [];
        _ambiance = arguments['ambiance'] as String?;
        _extras = (arguments['extras'] as List<dynamic>?)?.cast<String>() ?? [];

        // Update price range based on budget
        _priceRange = RangeValues(0, _hotelBudget);
      });
      // Auto-search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchHotels();
      });
    }
  }

  Future<void> _searchHotels() async {
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
    });

    try {
      // Build AI prompt from preferences
      String aiPrompt = _specialRequest;
      if (_roomType != null) aiPrompt += ' $_roomType room';
      if (_foodTypes.isNotEmpty) aiPrompt += ' ${_foodTypes.join(" ")} food';
      if (_ambiance != null) aiPrompt += ' $_ambiance ambiance';
      if (_extras.isNotEmpty) aiPrompt += ' with ${_extras.join(" ")}';

      // Try API first
      bool usedMockData = false;
      try {
        final response = await _api.searchHotelsWithAI(
          message: aiPrompt.trim(),
          city: _selectedCity!,
          budget: _hotelBudget,
          roomType: _roomType,
          foodTypes: _foodTypes,
          ambiance: _ambiance,
          extras: _extras,
        );

        setState(() {
          _searchResults = response['hotels'] as List<Hotel>;
          _loading = false;
        });
      } catch (e) {
        // Fallback to mock data
        print('API failed, using mock data: $e');
        final mockResults = await _mockData.searchHotels(
          city: _selectedCity!,
          minPrice: _priceRange.start,
          maxPrice: _priceRange.end,
          aiPrompt: aiPrompt.trim(),
        );

        setState(() {
          _searchResults = mockResults;
          _loading = false;
        });
        usedMockData = true;

        // Show AI response
        final aiResponse =
            _mockData.generateAIResponse(aiPrompt, _searchResults.length);
        if (mounted && aiResponse.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(aiResponse),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      // Show status message
      if (mounted && usedMockData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing ${_searchResults.length} hotels (Offline mode)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Search error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching hotels: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _searchHotels,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Results'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.back(),
            tooltip: 'Edit Search',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching for hotels...'),
                ],
              ),
            )
          : Column(
              children: [
                // Search Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConfig.paddingMedium),
                  decoration: BoxDecoration(
                    gradient: AppConfig.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_city,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCity ?? 'Select City',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${_checkIn.day}/${_checkIn.month} - ${_checkOut.day}/${_checkOut.month}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.person,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_guests ${_guests == 1 ? 'Guest' : 'Guests'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.hotel,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_rooms ${_rooms == 1 ? 'Room' : 'Rooms'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_hotelBudget > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Budget: ₹${_hotelBudget.toStringAsFixed(0)}/night',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Hotel Preferences Display
                if (_roomType != null ||
                    _foodTypes.isNotEmpty ||
                    _ambiance != null ||
                    _extras.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: AppConfig.primaryColor, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Your Preferences',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_roomType != null)
                              _buildPreferenceChip('🛏️ $_roomType'),
                            if (_ambiance != null)
                              _buildPreferenceChip('✨ $_ambiance'),
                            ..._foodTypes.map(
                                (food) => _buildPreferenceChip('🍽️ $food')),
                            ..._extras.map(
                                (extra) => _buildPreferenceChip('🎁 $extra')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Results Section
                Expanded(
                  child: _searched
                      ? _searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hotels found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search criteria',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => Get.back(),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Modify Search'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // Results count
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConfig.paddingMedium,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_searchResults.length} ${_searchResults.length == 1 ? 'hotel' : 'hotels'} found',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Hotel list
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConfig.paddingMedium,
                                    ),
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      return FadeInUp(
                                        delay:
                                            Duration(milliseconds: 50 * index),
                                        child: _HotelCard(
                                            hotel: _searchResults[index]),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hotel,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ready to search!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
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

  Widget _buildPreferenceChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: AppConfig.primaryColor.withOpacity(0.3),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;

  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to hotel details
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: const Icon(Icons.hotel,
                    size: 40, color: AppConfig.primaryColor),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hotel.address ?? hotel.city,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${hotel.rating}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hotel.type,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppConfig.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${hotel.pricePerNight.toStringAsFixed(0)}/night',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Book',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
