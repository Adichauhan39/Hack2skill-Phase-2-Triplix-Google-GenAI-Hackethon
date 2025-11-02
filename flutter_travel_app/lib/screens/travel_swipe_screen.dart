import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../config/app_config.dart';

class TravelSwipeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> travelOptions;
  final Map<String, dynamic> searchParams;

  const TravelSwipeScreen({
    super.key,
    required this.travelOptions,
    required this.searchParams,
  });

  @override
  State<TravelSwipeScreen> createState() => _TravelSwipeScreenState();
}

class _TravelSwipeScreenState extends State<TravelSwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final List<Map<String, dynamic>> _likedOptions = [];
  int _currentIndex = 0;

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

  Future<bool> _onSwipe(int previousIndex, int? currentIndex,
      CardSwiperDirection direction) async {
    if (direction == CardSwiperDirection.right) {
      // Liked
      final likedOption = widget.travelOptions[previousIndex];
      _likedOptions.add(likedOption);
      print('❤️ Liked: ${likedOption['provider']} ${likedOption['id']}');
    } else if (direction == CardSwiperDirection.left) {
      // Disliked
      final dislikedOption = widget.travelOptions[previousIndex];
      print(
          '👎 Disliked: ${dislikedOption['provider']} ${dislikedOption['id']}');
    }

    setState(() {
      _currentIndex = currentIndex ?? widget.travelOptions.length;
    });

    return true; // Allow the swipe
  }

  void _showBookingDialog(Map<String, dynamic> option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${option['provider'] ?? 'Travel'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Price: ₹${option['price'] ?? option['total_price'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(option['description'] ?? 'No description available'),
            const SizedBox(height: 16),
            const Text(
              'This will redirect you to the booking platform.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bookTravel(option);
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  void _bookTravel(Map<String, dynamic> option) {
    // Mock booking - in real app, this would integrate with booking APIs
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${option['provider']}... (Mock)'),
        backgroundColor: AppConfig.primaryColor,
      ),
    );

    // Simulate booking process
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed! Check your email for details.'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.searchParams['mode'] ?? 'flight';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Swipe ${_getModeTitle(mode)}s'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_likedOptions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () => _showLikedOptions(),
            ),
        ],
      ),
      body: widget.travelOptions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Progress indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        '${_currentIndex + 1}/${widget.travelOptions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value:
                              (_currentIndex + 1) / widget.travelOptions.length,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppConfig.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // Card swiper
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: widget.travelOptions.length,
                    onSwipe: _onSwipe,
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(horizontal: true),
                    numberOfCardsDisplayed: 2,
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      final option = widget.travelOptions[index];
                      return _buildTravelCard(option, mode);
                    },
                  ),
                ),

                // Swipe instructions and buttons
                _buildSwipeControls(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No travel options found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelCard(Map<String, dynamic> option, String mode) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header with mode icon and provider
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppConfig.primaryGradient,
                ),
                child: Row(
                  children: [
                    Text(
                      _getModeIcon(mode),
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['provider'] ?? 'Provider',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (option['route_number'] != null)
                            Text(
                              option['route_number'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Travel details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${option['price'] ?? option['total_price'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Route and timing
                      if (option['departure_time'] != null &&
                          option['arrival_time'] != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${option['departure_time']} - ${option['arrival_time']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (option['duration'] != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: ${option['duration']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (option['stops'] != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.flight_takeoff, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${option['stops']} stop(s)',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      if (option['description'] != null) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['description'],
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // AI Match Score (if available)
                      if (option['match_score'] != null) ...[
                        const SizedBox(height: 16),
                        _buildAIMatchScore(option),
                      ],

                      // Why recommended
                      if (option['why_recommended'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.thumb_up,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Why Recommended',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                option['why_recommended'],
                                style:
                                    const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Amenities
                      if (option['amenities'] != null &&
                          (option['amenities'] as List).isNotEmpty) ...[
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (option['amenities'] as List)
                              .map<Widget>((amenity) {
                            return Chip(
                              label: Text(amenity.toString()),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              labelStyle: const TextStyle(color: Colors.blue),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Book button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showBookingDialog(option),
                          icon: const Icon(Icons.book_online),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppConfig.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button
          FloatingActionButton(
            onPressed: () => _controller.swipe(CardSwiperDirection.left),
            backgroundColor: Colors.red,
            child: const Icon(Icons.close, color: Colors.white, size: 30),
          ),

          // Like button
          FloatingActionButton(
            onPressed: () => _controller.swipe(CardSwiperDirection.right),
            backgroundColor: Colors.green,
            child: const Icon(Icons.favorite, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  void _showLikedOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Liked Options (${_likedOptions.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _likedOptions.length,
                  itemBuilder: (context, index) {
                    final option = _likedOptions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Text(
                            _getModeIcon(
                                widget.searchParams['mode'] ?? 'flight'),
                            style: const TextStyle(fontSize: 24)),
                        title: Text(option['provider'] ?? 'Provider'),
                        subtitle: Text(
                            '₹${option['price'] ?? option['total_price'] ?? 'N/A'}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showBookingDialog(option);
                          },
                          child: const Text('Book'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIMatchScore(Map<String, dynamic> option) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Match Score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  option['match_score'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
