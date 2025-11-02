import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tinder_hotel_swipe_screen.dart';

class SimpleResultsScreen extends StatelessWidget {
  final dynamic hotels;

  const SimpleResultsScreen({
    super.key,
    required this.hotels,
  });

  @override
  Widget build(BuildContext context) {
    final hotelList = hotels is List ? hotels as List : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Search Results'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: hotelList.isEmpty
            ? _buildEmptyState()
            : _buildResultsList(hotelList),
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
            'No hotels found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List hotelList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hotelList.length,
      itemBuilder: (context, index) {
        final hotel = hotelList[index];
        return _buildHotelCard(context, hotel, index);
      },
    );
  }

  Widget _buildHotelCard(BuildContext context, dynamic hotel, int index) {
    final hotelMap = hotel is Map ? hotel : {};
    final name = hotelMap['name'] ?? 'Hotel Name';
    final city = hotelMap['city'] ?? 'City';
    final price = hotelMap['price_per_night'] ?? 0;
    final rating = hotelMap['rating'] ?? 0.0;
    final type = hotelMap['type'] ?? hotelMap['accommodation_type'] ?? 'Hotel';
    final amenities = hotelMap['amenities'] ?? hotelMap['extras'] ?? [];
    final nearbyAttractions = hotelMap['nearby_attractions'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=400&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Hotel Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ),
                  ),
                  // Rating Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

          // Hotel Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Name and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${price.toString()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        Text(
                          'per night',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location with Map Link
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openLocation(city, name),
                      icon: const Icon(
                        Icons.map,
                        size: 16,
                        color: Color(0xFF1976D2),
                      ),
                      label: const Text(
                        'View Map',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amenities
                if (amenities is List && amenities.isNotEmpty) ...[
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: amenities.take(4).map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          amenity.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Nearby Attractions
                if (nearbyAttractions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Near: $nearbyAttractions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _bookHotel(context, hotelMap.cast<String, dynamic>()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tinder Swipe Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _startTinderSwipe(context),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Color(0xFFE74C3C), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe,
                          color: Color(0xFFE74C3C),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tinder Swipe to Choose',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE74C3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLocation(String city, String hotelName) async {
    final query = Uri.encodeComponent('$hotelName, $city, India');
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Fallback to city search
      final cityUrl =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$city, India')}';
      if (await canLaunch(cityUrl)) {
        await launch(cityUrl);
      }
    }
  }

  void _bookHotel(BuildContext context, Map<String, dynamic> hotel) {
    // For now, just show a snackbar. In a real app, this would navigate to booking screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${hotel['name']}...'),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );
  }

  void _startTinderSwipe(BuildContext context) {
    final hotelList = hotels is List ? hotels as List : [];
    final typedHotels =
        hotelList.map((hotel) => hotel as Map<String, dynamic>).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TinderHotelSwipeScreen(hotels: typedHotels),
      ),
    );
  }
}
