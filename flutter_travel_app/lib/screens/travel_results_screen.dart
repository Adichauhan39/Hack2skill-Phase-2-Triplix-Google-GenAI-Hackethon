import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/app_config.dart';

class TravelResultsScreen extends StatefulWidget {
  final List<dynamic> results;
  final Map<String, dynamic> searchParams;

  const TravelResultsScreen({
    super.key,
    required this.results,
    required this.searchParams,
  });

  @override
  State<TravelResultsScreen> createState() => _TravelResultsScreenState();
}

class _TravelResultsScreenState extends State<TravelResultsScreen> {
  String _getModeIcon(String mode) {
    switch (mode) {
      case 'flight':
        return '✈️';
      case 'train':
        return '🚂';
      case 'bus':
        return '🚌';
      case 'car_rental':
        return '🚗';
      case 'taxi':
        return '🚕';
      case 'bike_scooter':
        return '🏍️';
      default:
        return '🚌';
    }
  }

  String _getModeTitle(String mode) {
    switch (mode) {
      case 'flight':
        return 'Flight';
      case 'train':
        return 'Train';
      case 'bus':
        return 'Bus';
      case 'car_rental':
        return 'Car Rental';
      case 'taxi':
        return 'Taxi';
      case 'bike_scooter':
        return 'Bike/Scooter';
      default:
        return 'Travel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.searchParams['mode'] ?? 'flight';
    final results = widget.results;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getModeTitle(mode)} Results'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: results.isEmpty
          ? _buildEmptyState()
          : _buildResultsList(results, mode),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppConfig.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: AppConfig.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: AppConfig.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<dynamic> results, String mode) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(result, mode);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, String mode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with provider and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _getModeIcon(mode),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['provider'] ?? result['company'] ?? 'Provider',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (result['route_number'] != null)
                          Text(
                            result['route_number'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConfig.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${result['price'] ?? result['total_price'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                    if (result['class'] != null)
                      Text(
                        result['class'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConfig.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route and timing info
            if (mode == 'flight' || mode == 'train' || mode == 'bus') ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['from_city'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (result['departure_time'] != null)
                          Text(
                            result['departure_time'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConfig.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppConfig.textSecondary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          result['to_city'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.end,
                        ),
                        if (result['arrival_time'] != null)
                          Text(
                            result['arrival_time'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConfig.textSecondary,
                            ),
                            textAlign: TextAlign.end,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (result['duration'] != null)
                    Text(
                      'Duration: ${result['duration']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConfig.textSecondary,
                      ),
                    ),
                  if (result['stops'] != null)
                    Text(
                      '${result['stops']} stop(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConfig.textSecondary,
                      ),
                    ),
                ],
              ),
            ] else if (mode == 'taxi') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${result['from_city']} → ${result['to_city']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${result['estimated_duration']} • ${result['distance_km']} km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ] else if (mode == 'car_rental' || mode == 'bike_scooter') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    result['vehicle_type'] ?? 'Vehicle',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${result['duration_hours'] ?? 24} hours',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Amenities
            if (result['amenities'] != null &&
                (result['amenities'] as List).isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (result['amenities'] as List).map<Widget>((amenity) {
                  return Chip(
                    label: Text(
                      amenity.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppConfig.primaryColor),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Description
            if (result['description'] != null) ...[
              Text(
                result['description'],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConfig.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],

            // Why recommended
            if (result['why_recommended'] != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result['why_recommended'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _bookTravel(result, mode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookTravel(Map<String, dynamic> result, String mode) {
    // For now, just show a success message
    // In a real app, this would integrate with a booking system
    Get.snackbar(
      'Booking Confirmed!',
      'Your ${_getModeTitle(mode).toLowerCase()} has been booked successfully.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // Navigate back to home
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed('/home');
    });
  }
}
