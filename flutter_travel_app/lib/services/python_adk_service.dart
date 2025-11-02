import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to communicate with Python ADK Backend
/// Integrates Flutter frontend with Python Google ADK multi-agent system
class PythonADKService {
  // Python FastAPI backend URL
  static const String _baseUrl = 'http://localhost:8001';

  // API endpoints
  static const String _agentEndpoint = '/api/agent';
  static const String _managerEndpoint = '/api/manager';
  static const String _hotelEndpoint = '/api/hotel/search';
  static const String _flightEndpoint = '/api/flight/search';
  static const String _travelEndpoint = '/api/travel/search';
  static const String _destinationEndpoint = '/api/destination/info';

  /// Check if Python backend is running
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print('Python backend not available: $e');
      return false;
    }
  }

  /// Send request to swipe page
  Future<Map<String, dynamic>> sendToSwipe({
    required String city,
    String category = 'attractions', // attractions, hotels, restaurants
  }) async {
    return sendToManager(
      message: 'Show me swipeable $category in $city',
      context: {'city': city, 'category': category},
      page: 'swipe',
    );
  }

  /// Send request to bookings page
  Future<Map<String, dynamic>> sendToBookings({
    String action = 'view', // view, create, modify, cancel
    Map<String, dynamic>? bookingDetails,
  }) async {
    String message = 'Show me my bookings';
    if (action == 'create' && bookingDetails != null) {
      message = 'Create a booking with details: ${json.encode(bookingDetails)}';
    }

    return sendToManager(
      message: message,
      context: {'action': action, 'booking_details': bookingDetails},
      page: 'bookings',
    );
  }

  /// Send request to budget page
  Future<Map<String, dynamic>> sendToBudget({
    double? totalBudget,
    int? numPeople,
    String action = 'view', // view, set, track, split
  }) async {
    String message = 'Show me budget information';
    if (action == 'set' && totalBudget != null && numPeople != null) {
      message = 'Set budget of ₹$totalBudget for $numPeople people';
    }

    return sendToManager(
      message: message,
      context: {
        'action': action,
        'total_budget': totalBudget,
        'num_people': numPeople
      },
      page: 'budget',
    );
  }

  /// Send request to profile page
  Future<Map<String, dynamic>> sendToProfile({
    String action = 'view', // view, update, history
    Map<String, dynamic>? preferences,
  }) async {
    String message = 'Show my profile information';
    if (action == 'update' && preferences != null) {
      message = 'Update my preferences: ${json.encode(preferences)}';
    }

    return sendToManager(
      message: message,
      context: {'action': action, 'preferences': preferences},
      page: 'profile',
    );
  }

  /// Send request to ADK agent for general conversation (not itinerary generation)
  Future<Map<String, dynamic>> sendToAgent({
    required String message,
    Map<String, dynamic>? context,
    String page = 'home',
  }) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 [PythonADK] Sending AGENT request to Python backend');
      print('   URL: $_baseUrl$_agentEndpoint');
      print('   Message: "$message"');
      print('   Page: $page');

      final requestBody = {
        'message': message,
        'context': context ?? {},
        'page': page,
      };

      final response = await http
          .post(
        Uri.parse('$_baseUrl$_agentEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 [PythonADK] Response: ${response.statusCode}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'response': data['response'],
          'agent': data['agent'],
          'data': data['data'],
          'suggestions': data['suggestions'],
          'show_suggestions': data['show_suggestions'],
          'source': 'python_adk',
        };
      } else {
        return {
          'success': false,
          'error': 'Backend error: ${response.statusCode}',
          'response': 'Sorry, I encountered an error. Please try again.',
          'source': 'python_adk',
        };
      }
    } catch (e) {
      print('❌ [PythonADK] Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'response': 'I\'m having trouble connecting. Error: $e',
        'source': 'python_adk',
      };
    }
  }

  /// Send request to ADK manager agent with page context
  Future<Map<String, dynamic>> sendToManager({
    required String message,
    Map<String, dynamic>? context,
    String page = 'home', // home, swipe, bookings, budget, profile
  }) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 [PythonADK] Sending MANAGER request to Python backend');
      print('   URL: $_baseUrl$_managerEndpoint');
      print('   Message: "$message"');
      print('   Page: $page');
      print('   Context keys: ${context?.keys.toList() ?? []}');

      final requestBody = {
        'message': message,
        'context': context ?? {},
        'page': page,
      };

      print(
          '   Request body: ${json.encode(requestBody).substring(0, 200)}...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http
          .post(
        Uri.parse(
            '$_baseUrl$_managerEndpoint'), // Changed from _agentEndpoint to _managerEndpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(
            seconds:
                120), // Increased to 120 seconds for AI itinerary generation
        onTimeout: () {
          print('⏰ [PythonADK] Request timed out after 120 seconds');
          throw Exception(
              'Request timeout - AI is taking longer than expected');
        },
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📥 [PythonADK] Response received');
      print('   Status code: ${response.statusCode}');
      print('   Response length: ${response.body.length} bytes');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [PythonADK] Success! Response keys: ${data.keys.toList()}');
        return {
          'success': true,
          'response': data['response'],
          'agent': data['agent'],
          'data': data['data'],
          'page': data['page'],
          'source': 'python_adk',
        };
      } else {
        print('❌ [PythonADK] Backend error: ${response.statusCode}');
        print('   Body: ${response.body}');
        return {
          'success': false,
          'error': 'Backend error: ${response.statusCode}',
          'response': 'Sorry, I encountered an error. Please try again.',
          'source': 'python_adk',
        };
      }
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ [PythonADK] Error calling Python backend:');
      print('   Error type: ${e.runtimeType}');
      print('   Error: $e');
      print('   Stack trace:');
      print(stackTrace.toString().split('\n').take(5).join('\n'));
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return {
        'success': false,
        'error': 'Failed to connect to Python backend: ${e.toString()}',
        'response':
            'I\'m having trouble connecting to my AI brain. Error: ${e.toString()}',
        'source': 'python_adk',
      };
    }
  }

  /// Search hotels via Python ADK hotel_booking agent
  Future<Map<String, dynamic>> searchHotels({
    required String city,
    double? minPrice,
    double? maxPrice,
    String? roomType,
    String? ambiance,
    List<String>? amenities,
    String? specialRequest,
  }) async {
    try {
      print(
          '🔍 HOTEL SEARCH: Always using Manager Agent endpoint with intelligent routing');
      print('   📊 Backend will decide: CSV (free) or AI agent (when needed)');

      // Build natural language message
      final messageParts = <String>[];
      messageParts.add('Find hotels in $city');

      if (maxPrice != null) {
        messageParts.add('under ₹${maxPrice.toStringAsFixed(0)}');
      }
      if (roomType != null && roomType.isNotEmpty) {
        messageParts.add('with $roomType room');
      }
      if (ambiance != null && ambiance.isNotEmpty) {
        messageParts.add('$ambiance ambiance');
      }
      if (amenities != null && amenities.isNotEmpty) {
        messageParts.add('with ${amenities.join(", ")}');
      }
      if (specialRequest != null && specialRequest.isNotEmpty) {
        messageParts.add('Special: $specialRequest');
      }

      final message = messageParts.join('. ');

      print('   📨 Query: "$message"');
      print('   📡 POST request to: $_baseUrl$_hotelEndpoint');

      final response = await http.post(
        Uri.parse('$_baseUrl$_hotelEndpoint'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'message': message,
          'context': {
            'city': city,
            'budget':
                maxPrice ?? 25000, // Backend expects 'budget', not 'max_price'
            'min_price': minPrice ?? 0,
            'max_price': maxPrice ?? 100000,
            'room_type': roomType,
            'ambiance': ambiance,
            'amenities': amenities,
          },
        }),
      );

      print('   📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hotelCount = (data['hotels'] as List?)?.length ?? 0;
        final aiUsed = data['ai_used'] ?? false;
        final costInfo = data['cost'] ?? 'Unknown';

        if (aiUsed) {
          print('✅ SEARCH COMPLETE: $hotelCount hotels via Manager Agent (AI)');
          print('   💰 Cost: AI tokens used');
          print('   🤖 Reason: ${data['reason_for_ai']}');
        } else {
          print('✅ SEARCH COMPLETE: $hotelCount hotels via CSV database');
          print('   💰 Cost: Free (no AI used)');
        }

        // Limit hotels to maximum 5
        final allHotels = (data['hotels'] as List?) ?? [];
        final limitedHotels = allHotels.take(5).toList();

        return {
          'success': true,
          'response': data['overall_advice'] ?? 'Hotels found successfully',
          'agent': aiUsed ? 'web_hotel_search (Manager Agent)' : 'csv_database',
          'ai_used': aiUsed,
          'data': {
            'hotels': limitedHotels,
          },
          'source': 'python_adk',
        };
      } else {
        print('❌ Search failed with status ${response.statusCode}');
        return {
          'success': false,
          'error': 'Hotel search failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error in search: ${e.toString()}');
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  /// Search flights via Python ADK travel_booking agent
  Future<Map<String, dynamic>> searchFlights({
    required String from,
    required String to,
    DateTime? departureDate,
    String? travelClass,
  }) async {
    try {
      final message = 'Find flights from $from to $to';

      final response = await http.post(
        Uri.parse('$_baseUrl$_flightEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'context': {
            'from': from,
            'to': to,
            'departure_date': departureDate?.toIso8601String(),
            'travel_class': travelClass,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Limit flights to maximum 5
        final allFlights = (data['flights'] as List?) ?? [];
        final limitedFlights = allFlights.take(5).toList();

        // Also limit trains to maximum 5 if present
        final allTrains = (data['trains'] as List?) ?? [];
        final limitedTrains = allTrains.take(5).toList();

        return {
          'success': true,
          'response': data['response'],
          'agent': 'travel_booking',
          'flights': limitedFlights,
          'trains': limitedTrains,
          'source': 'python_adk',
        };
      } else {
        return {
          'success': false,
          'error': 'Flight search failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get destination info via Python ADK destination_info agent
  Future<Map<String, dynamic>> getDestinationInfo({
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_destinationEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': city,
          'context': {'city': city},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Limit destinations to maximum 10
        final allDestinations = (data['destinations'] as List?) ?? [];
        final limitedDestinations = allDestinations.take(10).toList();

        return {
          'success': true,
          'response': data['response'],
          'agent': 'destination_info',
          'destinations': limitedDestinations,
          'source': 'python_adk',
        };
      } else {
        return {
          'success': false,
          'error': 'Destination info failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if query requires AI (complex) or can use CSV (simple)
  bool _isComplexQuery({
    String? specialRequest,
    String? roomType,
    String? ambiance,
    List<String>? amenities,
  }) {
    // If user provided special request, use AI
    if (specialRequest != null && specialRequest.trim().isNotEmpty) {
      print('   → Complex: Special request detected - "$specialRequest"');
      return true;
    }

    // If user selected specific room type (not just "All"), use AI
    if (roomType != null &&
        roomType.trim().isNotEmpty &&
        roomType.toLowerCase() != 'all') {
      print('   → Complex: Specific room type - "$roomType"');
      return true;
    }

    // If user selected specific ambiance (not just "All"), use AI
    if (ambiance != null &&
        ambiance.trim().isNotEmpty &&
        ambiance.toLowerCase() != 'all') {
      print('   → Complex: Specific ambiance - "$ambiance"');
      return true;
    }

    // If user selected multiple specific amenities, use AI
    if (amenities != null && amenities.isNotEmpty) {
      print('   → Complex: Specific amenities - ${amenities.join(", ")}');
      return true;
    }

    print('   → Simple: Basic city + price search, using CSV');
    return false;
  }

  /// Search hotels using CSV filtering (fast, basic search)
  Future<Map<String, dynamic>> _searchHotelsCSV({
    required String city,
    double? minPrice,
    double? maxPrice,
    String? roomType,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'city': city,
        'min_price': (minPrice ?? 0).toString(),
        'max_price': (maxPrice ?? 100000).toString(),
      };

      if (roomType != null &&
          roomType.isNotEmpty &&
          roomType.toLowerCase() != 'all') {
        queryParams['type'] = roomType;
      }

      final uri =
          Uri.parse('$_baseUrl/hotels').replace(queryParameters: queryParams);

      print('   📡 GET request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      print('   📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hotelCount = (data['hotels'] as List?)?.length ?? 0;

        print('✅ SEARCH COMPLETE: $hotelCount hotels found via CSV');

        return {
          'success': true,
          'response':
              'Found $hotelCount hotels in $city matching your criteria',
          'agent': 'csv_filter',
          'data': {
            'hotels': data['hotels'] ?? [],
          },
          'source': 'csv_database',
        };
      } else {
        print('❌ CSV search failed with status ${response.statusCode}');
        return {
          'success': false,
          'error': 'Hotel search failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error in CSV search: ${e.toString()}');
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  /// Search travel options (flights, trains, buses, car rentals, taxis, bikes)
  Future<Map<String, dynamic>> searchTravel(
      Map<String, dynamic> requestData) async {
    try {
      print(
          '🚗 TRAVEL SEARCH: ${requestData['mode']} from ${requestData['from_city']}');

      final response = await http.post(
        Uri.parse('$_baseUrl$_travelEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final resultCount = (data['results'] as List?)?.length ?? 0;
        final aiUsed = data['ai_used'] ?? false;

        if (aiUsed) {
          print(
              '✅ SEARCH COMPLETE: $resultCount ${requestData['mode']} options via AI');
        } else {
          print(
              '✅ SEARCH COMPLETE: $resultCount ${requestData['mode']} options via CSV');
        }

        return {
          'success': true,
          'status': data['status'] ?? 'success',
          'powered_by': data['powered_by'] ?? 'Unknown',
          'ai_used': aiUsed,
          'results': data['results'] ?? [],
          'count': resultCount,
          'source': 'python_adk',
        };
      } else {
        print('❌ Travel search failed with status ${response.statusCode}');
        return {
          'success': false,
          'error': 'Travel search failed: ${response.statusCode}',
          'status': 'error',
        };
      }
    } catch (e) {
      print('❌ Error in travel search: ${e.toString()}');
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
        'status': 'error',
      };
    }
  }
}
