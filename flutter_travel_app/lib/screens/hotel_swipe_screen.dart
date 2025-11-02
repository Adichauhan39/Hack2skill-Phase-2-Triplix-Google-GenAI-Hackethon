import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';

class HotelSwipeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;

  const HotelSwipeScreen({
    super.key,
    required this.hotels,
  });

  @override
  State<HotelSwipeScreen> createState() => _HotelSwipeScreenState();
}

class _HotelSwipeScreenState extends State<HotelSwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final List<Map<String, dynamic>> _acceptedHotels = [];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Swipe Hotels',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_acceptedHotels.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_acceptedHotels.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: widget.hotels.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                // Card swiper
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: widget.hotels.length,
                    numberOfCardsDisplayed:
                        widget.hotels.length > 2 ? 3 : widget.hotels.length,
                    backCardOffset: const Offset(40, 40),
                    padding: const EdgeInsets.all(24.0),
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      return _buildHotelCard(widget.hotels[index]);
                    },
                    onSwipe: _onSwipe,
                    onEnd: _onEnd,
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(
                      horizontal: true,
                    ),
                  ),
                ),
                // Swipe instructions and buttons
                _buildSwipeControls(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hotel ${_currentIndex + 1} of ${widget.hotels.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                '${_acceptedHotels.length} Liked',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF27AE60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.hotels.length,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Image
                _buildHotelImage(hotel),
                // Hotel Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Name and Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hotel['name'] ?? 'Hotel',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          _buildRatingBadge(hotel['rating']),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Location and Type
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFFE74C3C),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hotel['city'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7F8C8D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.hotel,
                            size: 16,
                            color: Color(0xFF3498DB),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hotel['type'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7F8C8D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price per night',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  currencyFormat
                                      .format(hotel['price_per_night'] ?? 0),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),

                      // AI Match Score (if available)
                      if (hotel['match_score'] != null) ...[
                        const SizedBox(height: 12),
                        _buildAIMatchScore(hotel),
                      ],

                      // Why Recommended
                      if (hotel['why_recommended'] != null) ...[
                        const SizedBox(height: 12),
                        _buildSection(
                          'Why We Recommend',
                          Icons.psychology,
                          const Color(0xFF9B59B6),
                          hotel['why_recommended'],
                        ),
                      ],

                      // Highlights
                      if (hotel['highlights'] != null) ...[
                        const SizedBox(height: 12),
                        _buildHighlights(hotel['highlights']),
                      ],

                      // Perfect For
                      if (hotel['perfect_for'] != null) ...[
                        const SizedBox(height: 12),
                        _buildSection(
                          'Perfect For',
                          Icons.person,
                          const Color(0xFF27AE60),
                          hotel['perfect_for'],
                        ),
                      ],

                      // Amenities
                      if (hotel['amenities'] != null) ...[
                        const SizedBox(height: 12),
                        _buildAmenities(hotel['amenities']),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelImage(Map<String, dynamic> hotel) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
        ),
      ),
      child: Stack(
        children: [
          // Placeholder image pattern
          Center(
            child: Icon(
              Icons.hotel,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Hotel name overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              hotel['name'] ?? 'Hotel',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(dynamic rating) {
    final ratingValue = rating is num
        ? rating.toDouble()
        : double.tryParse(rating.toString()) ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF39C12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            ratingValue.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIMatchScore(Map<String, dynamic> hotel) {
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
                  hotel['match_score'].toString(),
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

  Widget _buildSection(
      String title, IconData icon, Color color, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF7F8C8D),
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHighlights(List<dynamic> highlights) {
    // Limit to first 4 highlights
    final displayHighlights = highlights.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.star_border, color: Color(0xFFF39C12), size: 18),
            SizedBox(width: 6),
            Text(
              'Key Highlights',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: displayHighlights.map((highlight) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF5E7),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFF39C12).withOpacity(0.3)),
              ),
              child: Text(
                highlight.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2C3E50),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenities(List<dynamic> amenities) {
    // Take first 4 amenities to save space
    final displayAmenities = amenities.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Color(0xFF27AE60), size: 18),
            SizedBox(width: 6),
            Text(
              'Top Amenities',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: displayAmenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAmenityIcon(amenity.toString()),
                    size: 14,
                    color: const Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    amenity.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('pool')) return Icons.pool;
    if (lower.contains('gym')) return Icons.fitness_center;
    if (lower.contains('spa')) return Icons.spa;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('restaurant')) return Icons.restaurant;
    if (lower.contains('beach')) return Icons.beach_access;
    return Icons.check;
  }

  Widget _buildSwipeControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dislike button
              _buildActionButton(
                icon: Icons.close,
                color: const Color(0xFFE74C3C),
                label: 'Pass',
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),
              const SizedBox(width: 24),
              // Undo button
              _buildActionButton(
                icon: Icons.refresh,
                color: const Color(0xFFF39C12),
                label: 'Undo',
                onPressed: () => _controller.undo(),
                size: 50,
              ),
              const SizedBox(width: 24),
              // Like button
              _buildActionButton(
                icon: Icons.favorite,
                color: const Color(0xFF27AE60),
                label: 'Like',
                onPressed: () => _controller.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_acceptedHotels.isNotEmpty)
            ElevatedButton(
              onPressed: _showBookingOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Book ${_acceptedHotels.length} Selected Hotels',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          borderRadius: BorderRadius.circular(size / 2),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size / 2),
              ),
              child: Icon(icon, color: Colors.white, size: size * 0.4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hotels to display',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    setState(() {
      _currentIndex = currentIndex ?? previousIndex;
    });

    if (direction == CardSwiperDirection.right) {
      // Hotel accepted
      setState(() {
        _acceptedHotels.add(widget.hotels[previousIndex]);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Added ${widget.hotels[previousIndex]['name']} to favorites!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
      // Hotel rejected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.close, color: Colors.white),
              SizedBox(width: 8),
              Text('Passed'),
            ],
          ),
          backgroundColor: const Color(0xFFE74C3C),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return true;
  }

  void _onEnd() {
    if (_acceptedHotels.isNotEmpty) {
      _showBookingOptions();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF3498DB)),
              SizedBox(width: 8),
              Text('All Done!'),
            ],
          ),
          content: const Text(
            'You\'ve viewed all hotels. Would you like to search again?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Search Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showBookingOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookingBottomSheet(),
    );
  }

  Widget _buildBookingBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Select Dates for Your Hotels',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          // Hotels list with date pickers
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _acceptedHotels.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                return _buildHotelBookingItem(_acceptedHotels[index], index);
              },
            ),
          ),
          // Book button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAllHotels,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm All Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelBookingItem(Map<String, dynamic> hotel, int index) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel['name'] ?? 'Hotel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      '${currencyFormat.format(hotel['price_per_night'] ?? 0)}/night',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Check-in',
                  hotel['checkIn'],
                  (date) {
                    setState(() {
                      hotel['checkIn'] = date;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateSelector(
                  'Check-out',
                  hotel['checkOut'],
                  (date) {
                    setState(() {
                      hotel['checkOut'] = date;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
      String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: const Color(0xFF3498DB),
                colorScheme:
                    const ColorScheme.light(primary: Color(0xFF3498DB)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xFF3498DB)),
                const SizedBox(width: 6),
                Text(
                  selectedDate != null
                      ? DateFormat('dd MMM').format(selectedDate)
                      : 'Select',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bookAllHotels() {
    // Validate all hotels have dates
    bool allHavesDates = _acceptedHotels.every(
        (hotel) => hotel['checkIn'] != null && hotel['checkOut'] != null);

    if (!allHavesDates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select check-in and check-out dates for all hotels'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    // Show success
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 32),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Text(
          'Successfully booked ${_acceptedHotels.length} hotels!\n\nYour bookings have been added to your trip.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }
}
