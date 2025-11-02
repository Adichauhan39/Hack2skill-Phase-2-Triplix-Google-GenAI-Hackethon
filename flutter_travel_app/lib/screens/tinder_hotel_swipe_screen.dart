import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class TinderHotelSwipeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;

  const TinderHotelSwipeScreen({
    super.key,
    required this.hotels,
  });

  @override
  State<TinderHotelSwipeScreen> createState() => _TinderHotelSwipeScreenState();
}

class _TinderHotelSwipeScreenState extends State<TinderHotelSwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final List<Map<String, dynamic>> _cartHotels = [];
  int _currentIndex = 0;

  // Store hotel images and loading states
  final Map<String, List<String>> _hotelImages = {};
  final Map<String, bool> _imageLoadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadHotelImages();
  }

  Future<void> _loadHotelImages() async {
    for (var hotel in widget.hotels) {
      final hotelName = hotel['name'] ?? '';
      setState(() {
        _imageLoadingStates[hotelName] = true;
      });

      try {
        final images = await _fetchHotelImages(hotelName, hotel['city'] ?? '');
        if (mounted) {
          setState(() {
            _hotelImages[hotelName] = images;
            _imageLoadingStates[hotelName] = false;
          });
        }
      } catch (e) {
        print('Error loading images for $hotelName: $e');
        if (mounted) {
          setState(() {
            _hotelImages[hotelName] =
                _getCitySpecificImages(hotel['city'] ?? '');
            _imageLoadingStates[hotelName] = false;
          });
        }
      }
    }
  }

  Future<List<String>> _fetchHotelImages(String hotelName, String city) async {
    try {
      // Use Google AI to generate specific search terms for authentic hotel images
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: 'AIzaSyAaC4DMxu0mHPggTp7eyEoG4rtAywCQ4z8',
      );

      final prompt = '''
      Generate 10 highly specific and varied search terms for finding authentic photos of "$hotelName" hotel in $city, India.
      Make each search term unique and focus on different aspects:

      1. Hotel exterior architecture
      2. Main lobby or reception
      3. Signature restaurant or dining area
      4. Presidential or executive suite
      5. Swimming pool or water features
      6. Spa or wellness center
      7. Hotel bar or lounge
      8. Guest room with city view
      9. Hotel garden or outdoor area
      10. Unique amenity (gym, business center, etc.)

      Return ONLY a JSON array of very specific search terms that would yield different images.
      Format: ["$hotelName $city luxury hotel exterior architecture", "$hotelName $city grand lobby reception area", ...]
      ''';

      final aiResponse = await model.generateContent([Content.text(prompt)]);
      final aiText = aiResponse.text ?? '';

      // Parse AI response for search terms
      final jsonStart = aiText.indexOf('[');
      final jsonEnd = aiText.lastIndexOf(']') + 1;
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = aiText.substring(jsonStart, jsonEnd);
        final List<dynamic> searchTerms = json.decode(jsonStr);

        // Convert search terms to Unsplash URLs with randomization for unique images
        final imageUrls = <String>[];
        final random = DateTime.now().millisecondsSinceEpoch;
        for (var i = 0; i < searchTerms.take(10).length; i++) {
          final term = searchTerms[i].toString().replaceAll('"', '').trim();
          final encodedTerm = Uri.encodeComponent(term);
          // Add randomization and hotel-specific parameters to ensure unique images
          final uniqueUrl =
              'https://source.unsplash.com/800x600/?$encodedTerm&r=${random + i}';
          imageUrls.add(uniqueUrl);
        }

        print(
            '✅ Generated ${imageUrls.length} AI-powered image URLs for $hotelName');
        return imageUrls;
      }
    } catch (e) {
      print('❌ AI image search failed: $e');
    }

    // Fallback: Use city-specific curated hotel images
    print('⚠️ Using fallback images for $hotelName in $city');
    return _getCitySpecificImages(city);
  }

  List<String> _getCitySpecificImages(String city) {
    final cityKey = city.toLowerCase();

    final cityImages = {
      'goa': [
        'https://source.unsplash.com/800x600/?goa-beachfront-hotel-lobby',
        'https://source.unsplash.com/800x600/?goa-luxury-resort-deluxe-room',
        'https://source.unsplash.com/800x600/?goa-hotel-infinity-pool-ocean-view',
        'https://source.unsplash.com/800x600/?goa-seafood-restaurant-hotel',
        'https://source.unsplash.com/800x600/?goa-ayurvedic-spa-treatment',
        'https://source.unsplash.com/800x600/?goa-beach-bar-sunset',
        'https://source.unsplash.com/800x600/?goa-tropical-garden-villa',
        'https://source.unsplash.com/800x600/?goa-colonial-architecture-hotel',
        'https://source.unsplash.com/800x600/?goa-presidential-suite-balcony',
        'https://source.unsplash.com/800x600/?goa-water-sports-hotel-amenity',
      ],
      'mumbai': [
        'https://source.unsplash.com/800x600/?mumbai-marina-bay-hotel-lobby',
        'https://source.unsplash.com/800x600/?mumbai-business-hotel-executive-room',
        'https://source.unsplash.com/800x600/?mumbai-rooftop-bar-city-skyline',
        'https://source.unsplash.com/800x600/?mumbai-fine-dining-restaurant',
        'https://source.unsplash.com/800x600/?mumbai-luxury-spa-massage',
        'https://source.unsplash.com/800x600/?mumbai-cocktail-lounge-night',
        'https://source.unsplash.com/800x600/?mumbai-hotel-gym-fitness',
        'https://source.unsplash.com/800x600/?mumbai-city-view-suite',
        'https://source.unsplash.com/800x600/?mumbai-ballroom-event-space',
        'https://source.unsplash.com/800x600/?mumbai-business-center-hotel',
      ],
      'delhi': [
        'https://source.unsplash.com/800x600/?delhi-heritage-hotel-lobby',
        'https://source.unsplash.com/800x600/?delhi-luxury-hotel-room',
        'https://source.unsplash.com/800x600/?delhi-hotel-garden',
        'https://source.unsplash.com/800x600/?delhi-hotel-restaurant',
        'https://source.unsplash.com/800x600/?delhi-hotel-spa',
        'https://source.unsplash.com/800x600/?delhi-hotel-bar',
        'https://source.unsplash.com/800x600/?delhi-hotel-exterior',
        'https://source.unsplash.com/800x600/?delhi-business-hotel',
        'https://source.unsplash.com/800x600/?delhi-hotel-suite',
        'https://source.unsplash.com/800x600/?delhi-boutique-hotel',
      ],
      'jaipur': [
        'https://source.unsplash.com/800x600/?jaipur-palace-hotel-lobby',
        'https://source.unsplash.com/800x600/?jaipur-heritage-hotel-room',
        'https://source.unsplash.com/800x600/?jaipur-hotel-courtyard',
        'https://source.unsplash.com/800x600/?jaipur-hotel-restaurant',
        'https://source.unsplash.com/800x600/?rajasthani-hotel-architecture',
        'https://source.unsplash.com/800x600/?jaipur-luxury-hotel',
        'https://source.unsplash.com/800x600/?jaipur-hotel-garden',
        'https://source.unsplash.com/800x600/?jaipur-hotel-spa',
        'https://source.unsplash.com/800x600/?jaipur-hotel-suite',
        'https://source.unsplash.com/800x600/?jaipur-boutique-hotel',
      ],
    };

    // Add randomization to prevent same images
    final random = DateTime.now().millisecondsSinceEpoch;
    final selectedImages = cityImages[cityKey] ??
        [
          'https://source.unsplash.com/800x600/?luxury-hotel-lobby',
          'https://source.unsplash.com/800x600/?luxury-hotel-room',
          'https://source.unsplash.com/800x600/?luxury-hotel-pool',
          'https://source.unsplash.com/800x600/?luxury-hotel-restaurant',
          'https://source.unsplash.com/800x600/?luxury-hotel-spa',
          'https://source.unsplash.com/800x600/?luxury-hotel-bar',
          'https://source.unsplash.com/800x600/?luxury-hotel-garden',
          'https://source.unsplash.com/800x600/?luxury-hotel-exterior',
          'https://source.unsplash.com/800x600/?luxury-hotel-suite',
          'https://source.unsplash.com/800x600/?luxury-hotel-bathroom',
        ];

    // Add random parameter to each URL to ensure uniqueness
    return selectedImages.map((url) => '$url&r=$random').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Discover Hotels',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          if (_cartHotels.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart,
                      color: Color(0xFFE74C3C),
                      size: 28,
                    ),
                    onPressed: _showCartDialog,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cartHotels.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: widget.hotels.isEmpty
          ? _buildEmptyState()
          : Stack(
              children: [
                Column(
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
                        backCardOffset: const Offset(20, 20),
                        padding: const EdgeInsets.all(20.0),
                        cardBuilder: (context, index, percentThresholdX,
                            percentThresholdY) {
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
                  ],
                ),
                // Swipe overlay indicators
                _buildSwipeOverlay(),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                '${_cartHotels.length} in Cart',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.hotels.length,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final hotelName = hotel['name'] ?? 'Hotel';
    final images = _hotelImages[hotelName] ?? [];
    const currentImageIndex = 0; // For vertical scrolling

    return Card(
      elevation: 12,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Image carousel with vertical scroll
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    // Main image or loading indicator
                    SizedBox(
                      width: double.infinity,
                      height: 300,
                      child: _imageLoadingStates[hotelName] == true
                          ? Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFE74C3C)),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading hotel images...',
                                      style: TextStyle(
                                        color: Color(0xFF2C3E50),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    images.isNotEmpty
                                        ? images[currentImageIndex]
                                        : 'https://source.unsplash.com/800x600/?luxury-hotel-lobby',
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    // Fallback to a default image if network image fails
                                    print(
                                        'Image load error for $hotelName: $exception');
                                  },
                                ),
                              ),
                            ),
                    ),
                    // Gradient overlay (only show when not loading)
                    if (_imageLoadingStates[hotelName] != true)
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    // Hotel info overlay (only show when not loading)
                    if (_imageLoadingStates[hotelName] != true)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotelName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hotel['city'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(hotel['rating'] as num?)?.toDouble() ?? 0.0}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Image indicators
                    if (images.length > 1)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: List.generate(
                            images.length,
                            (index) => Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                height: 3,
                                decoration: BoxDecoration(
                                  color: index == currentImageIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Hotel details (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
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
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${hotel['price_per_night'] ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Amenities
                      if (hotel['amenities'] != null) ...[
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (hotel['amenities'] as List).map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                amenity.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Description
                      if (hotel['description'] != null) ...[
                        const Text(
                          'About This Hotel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Text(
                            hotel['description'],
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Why recommended
                      if (hotel['why_recommended'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    color: Color(0xFFE91E63),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Recommendation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE91E63),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hotel['why_recommended'],
                                style: const TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Nearby attractions
                      if (hotel['nearby_attractions'] != null) ...[
                        const Text(
                          'Nearby Attractions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hotel['nearby_attractions'],
                                  style: const TextStyle(
                                    color: Color(0xFF2C3E50),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSwipeOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Left swipe indicator (Reject)
              Positioned(
                left: 20,
                top: constraints.maxHeight * 0.3,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              // Right swipe indicator (Like/Add to cart)
              Positioned(
                right: 20,
                top: constraints.maxHeight * 0.3,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
            'No hotels to swipe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for hotels first',
            style: TextStyle(
              fontSize: 16,
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
      // Add to cart
      _addToCart(widget.hotels[previousIndex]);
    } else if (direction == CardSwiperDirection.left) {
      // Reject - just show feedback
      _showSwipeFeedback('Passed', Colors.grey);
    }

    return true;
  }

  void _onEnd() {
    // Handle when all cards are swiped
    if (_currentIndex >= widget.hotels.length - 1) {
      _showCompletionDialog();
    }
  }

  void _addToCart(Map<String, dynamic> hotel) {
    setState(() {
      _cartHotels.add(hotel);
    });

    _showSwipeFeedback('Added to Cart!', const Color(0xFFE74C3C));

    // Check if we have multiple hotels and need date adjustment
    if (_cartHotels.length > 1) {
      Future.delayed(const Duration(seconds: 2), () {
        _showDateAdjustmentDialog();
      });
    }
  }

  void _showSwipeFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              message == 'Added to Cart!' ? Icons.favorite : Icons.close,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDateAdjustmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Multiple Hotels Selected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You have selected multiple hotels. Please adjust your dates to avoid conflicts.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Selected hotels: ${_cartHotels.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFE74C3C),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Swiping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCartDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('View Cart & Adjust Dates'),
          ),
        ],
      ),
    );
  }

  void _showCartDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE74C3C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_cartHotels.length} hotels',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cart items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cartHotels.length,
                itemBuilder: (context, index) {
                  final hotel = _cartHotels[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=100&h=100&fit=crop',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        hotel['name'] ?? 'Hotel',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('₹${hotel['price_per_night'] ?? 0}/night'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _cartHotels.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Total and book button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total (approx.)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_calculateTotal()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _cartHotels.isNotEmpty ? _proceedToBooking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('All Done!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 48,
              color: Color(0xFFE74C3C),
            ),
            const SizedBox(height: 16),
            Text(
              'You swiped through all ${_cartHotels.length} hotels!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Swiping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCartDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('View Cart'),
          ),
        ],
      ),
    );
  }

  int _calculateTotal() {
    return _cartHotels.fold(
        0, (sum, hotel) => sum + (hotel['price_per_night'] ?? 0) as int);
  }

  void _proceedToBooking() {
    // Navigate to booking screen with cart data
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: {'hotels': _cartHotels},
    );
  }
}
