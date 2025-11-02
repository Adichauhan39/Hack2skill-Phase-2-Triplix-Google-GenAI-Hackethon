import 'package:google_generative_ai/google_generative_ai.dart';
import 'mock_data_service.dart';

/// Hotel Booking Agent - Mirrors Python ADK hotel_booking/agent.py
/// Specialized sub-agent for hotel search and booking operations
/// Uses Gemini 2.0 Flash for intelligent hotel recommendations
class HotelBookingAgent {
  static const String _apiKey = 'AIzaSyB491Ttpz_6iQEQb5cLPDmvklvZk0Zz9E0';
  late final GenerativeModel _model;
  final MockDataService _mockDataService = MockDataService();

  // Agent configuration (mirrors Python ADK Agent class)
  final String name = 'hotel_booking';
  final String description =
      'Accommodation booking agent for hotels and hostels';

  // Tools available to this agent (ADK pattern)
  final List<Tool> _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'search_accommodations',
        'Search hotels and hostels from database with comprehensive filters',
        Schema(SchemaType.object, properties: {
          'location': Schema(SchemaType.string, description: 'City name'),
          'check_in': Schema(SchemaType.string,
              description: 'Check-in date (YYYY-MM-DD)'),
          'check_out': Schema(SchemaType.string,
              description: 'Check-out date (YYYY-MM-DD)'),
          'guests': Schema(SchemaType.integer, description: 'Number of guests'),
          'accommodation_type':
              Schema(SchemaType.string, description: 'Hotel or Hostel'),
          'room_type':
              Schema(SchemaType.string, description: 'Preferred room type'),
          'food_preference':
              Schema(SchemaType.string, description: 'Food options'),
          'ambiance':
              Schema(SchemaType.string, description: 'Preferred ambiance'),
          'min_price':
              Schema(SchemaType.number, description: 'Minimum price per night'),
          'max_price':
              Schema(SchemaType.number, description: 'Maximum price per night'),
        }, requiredProperties: [
          'location',
          'guests'
        ]),
      ),
      FunctionDeclaration(
        'book_accommodation',
        'Book a specific hotel after user confirms selection',
        Schema(SchemaType.object, properties: {
          'hotel_id':
              Schema(SchemaType.string, description: 'ID of the hotel to book'),
          'check_in': Schema(SchemaType.string, description: 'Check-in date'),
          'check_out': Schema(SchemaType.string, description: 'Check-out date'),
          'guests': Schema(SchemaType.integer, description: 'Number of guests'),
        }, requiredProperties: [
          'hotel_id',
          'check_in',
          'check_out',
          'guests'
        ]),
      ),
    ]),
  ];

  HotelBookingAgent() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 4096,
      ),
      tools: _tools,
      systemInstruction: Content.text(_getSystemInstruction()),
    );
  }

  /// System instruction for the hotel booking agent (mirrors Python agent.py)
  String _getSystemInstruction() {
    return '''
You are a specialized hotel booking agent with expertise in finding and recommending accommodations.

**Your Capabilities**:
- Search hotels and hostels across Indian cities
- Filter by: Room type, Food options, Ambiance, Price range, Amenities
- Provide personalized recommendations based on user preferences
- Handle special requests (accessibility, pet-friendly, dietary needs)
- Book accommodations after user confirmation

**Search Criteria You Understand**:
- Location preferences: City center, Beachfront, Near airport, Quiet area
- Trip purpose: Business, Leisure, Honeymoon, Family vacation, Solo travel
- Budget levels: Budget-friendly, Mid-range, Luxury, Premium
- Ambiance: Romantic, Modern, Traditional, Party, Peaceful
- Amenities: WiFi, Pool, Gym, Spa, Parking, Airport pickup, Pet-friendly

**Your Response Style**:
- Be friendly and professional
- Understand natural language requests
- Extract hidden preferences from context
- Provide 3-5 top recommendations with reasoning
- Ask clarifying questions when needed
- Explain why each hotel matches their needs

**Special Handling**:
- Anniversary/Honeymoon → Prioritize romantic hotels with couples amenities
- Business travel → Hotels near business districts with meeting rooms
- Family travel → Family-friendly hotels with kids' facilities
- Budget travel → Hostels and budget hotels with good ratings
- Luxury travel → 5-star hotels with premium services

Always use the search_accommodations tool to find hotels from the database.
Never make up hotel information - only use real data from search results.
''';
  }

  /// Main entry point - Process user request for hotel search/booking
  Future<Map<String, dynamic>> processRequest({
    required String userMessage,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Build prompt with context
      final prompt = _buildPromptWithContext(userMessage, context);

      // Start chat with agent
      final chat = _model.startChat();
      final response = await chat.sendMessage(Content.text(prompt));

      // Handle function calls if present (ADK-style tool execution)
      if (response.functionCalls.isNotEmpty) {
        return await _handleFunctionCalls(
            response.functionCalls.toList(), chat);
      }

      // Return direct response
      return {
        'success': true,
        'response': response.text ??
            'I can help you find hotels. Which city would you like to visit?',
        'agent': name,
      };
    } catch (e) {
      print('Hotel Agent Error: $e');
      return {
        'success': false,
        'response':
            'Sorry, I encountered an error searching for hotels. Please try again.',
        'agent': name,
        'error': e.toString(),
      };
    }
  }

  /// Build prompt with user context (location, budget, preferences)
  String _buildPromptWithContext(
      String userMessage, Map<String, dynamic>? context) {
    if (context == null || context.isEmpty) {
      return userMessage;
    }

    final parts = <String>['User Request: $userMessage'];
    parts.add('\nContext:');

    if (context['city'] != null) {
      parts.add('- Destination: ${context['city']}');
    }
    if (context['hotelBudget'] != null) {
      parts.add('- Budget: ₹${context['hotelBudget']} per night');
    }
    if (context['roomType'] != null) {
      parts.add('- Room Type: ${context['roomType']}');
    }
    if (context['foodTypes'] != null &&
        (context['foodTypes'] as List).isNotEmpty) {
      parts.add(
          '- Food Preferences: ${(context['foodTypes'] as List).join(', ')}');
    }
    if (context['ambiance'] != null) {
      parts.add('- Ambiance: ${context['ambiance']}');
    }
    if (context['extras'] != null && (context['extras'] as List).isNotEmpty) {
      parts.add(
          '- Required Amenities: ${(context['extras'] as List).join(', ')}');
    }
    if (context['guests'] != null) {
      parts.add('- Number of Guests: ${context['guests']}');
    }
    if (context['specialRequest'] != null &&
        context['specialRequest'].toString().isNotEmpty) {
      parts.add('- Special Request: ${context['specialRequest']}');
    }

    return parts.join('\n');
  }

  /// Handle function calls from Gemini (ADK-style tool execution)
  Future<Map<String, dynamic>> _handleFunctionCalls(
    List<FunctionCall> functionCalls,
    ChatSession chat,
  ) async {
    final functionResponses = <FunctionResponse>[];

    for (final functionCall in functionCalls) {
      print('🔧 Hotel Agent calling tool: ${functionCall.name}');

      Map<String, dynamic> toolResult;

      switch (functionCall.name) {
        case 'search_accommodations':
          toolResult = await _searchAccommodations(functionCall.args);
          break;

        case 'book_accommodation':
          toolResult = await _bookAccommodation(functionCall.args);
          break;

        default:
          toolResult = {
            'error': 'Unknown function: ${functionCall.name}',
          };
      }

      functionResponses.add(
        FunctionResponse(functionCall.name, toolResult),
      );
    }

    // Send function responses back to model
    final response = await chat.sendMessage(
      Content.functionResponses(functionResponses),
    );

    // Parse the final response
    return await _parseFinalResponse(response);
  }

  /// Search accommodations tool implementation (mirrors Python CSV loading)
  Future<Map<String, dynamic>> _searchAccommodations(
      Map<String, dynamic> args) async {
    try {
      final location = args['location'] as String;
      final minPrice = (args['min_price'] as num?)?.toDouble() ?? 0;
      final maxPrice = (args['max_price'] as num?)?.toDouble() ?? 100000;
      final roomType = args['room_type'] as String?;
      final ambiance = args['ambiance'] as String?;

      print('🔍 Searching hotels in $location (₹$minPrice - ₹$maxPrice)');

      // Call mock data service (simulates Python CSV loading)
      final hotels = await _mockDataService.searchHotels(
        city: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        type: args['accommodation_type'] as String?,
        amenities: args['extras'] as List<String>?,
      );

      // Filter by room type if specified
      var filteredHotels = hotels;
      if (roomType != null) {
        filteredHotels = hotels
            .where((h) =>
                h.roomType?.toLowerCase().contains(roomType.toLowerCase()) ?? false)
            .toList();
      }

      // Filter by ambiance if specified
      if (ambiance != null) {
        filteredHotels = filteredHotels
            .where((h) =>
                h.ambiance?.toLowerCase().contains(ambiance.toLowerCase()) ?? false)
            .toList();
      }

      // Return results in ADK-compatible format
      return {
        'success': true,
        'count': filteredHotels.length,
        'hotels': filteredHotels
            .map((h) => {
                  'id': h.id,
                  'name': h.name,
                  'type': h.type,
                  'city': h.city,
                  'price_per_night': h.pricePerNight,
                  'rating': h.rating,
                  'room_types': h.roomType,
                  'food_options': h.food,
                  'ambiance': h.ambiance,
                  'amenities': h.amenities,
                })
            .toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error searching hotels: ${e.toString()}',
      };
    }
  }

  /// Book accommodation tool implementation
  Future<Map<String, dynamic>> _bookAccommodation(
      Map<String, dynamic> args) async {
    try {
      final hotelId = args['hotel_id'] as String;
      final checkIn = args['check_in'] as String;
      final checkOut = args['check_out'] as String;
      final guests = args['guests'] as int;

      // In production, this would call a real booking API
      // For now, simulate successful booking
      final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';

      return {
        'success': true,
        'booking_id': bookingId,
        'hotel_id': hotelId,
        'check_in': checkIn,
        'check_out': checkOut,
        'guests': guests,
        'status': 'confirmed',
        'message': 'Booking confirmed! Your booking ID is $bookingId',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error booking hotel: ${e.toString()}',
      };
    }
  }

  /// Parse the final response from Gemini after tool execution
  Future<Map<String, dynamic>> _parseFinalResponse(
      GenerateContentResponse response) async {
    final text = response.text ?? '';

    // Check if hotels were found (parse from agent's response)
    final hotelCountMatch =
        RegExp(r'(\d+)\s+hotel').firstMatch(text.toLowerCase());
    final hotelCount = hotelCountMatch != null
        ? int.tryParse(hotelCountMatch.group(1) ?? '0') ?? 0
        : 0;

    return {
      'success': true,
      'response': text,
      'agent': name,
      'hotels_found': hotelCount,
      'has_results': hotelCount > 0,
    };
  }

  /// Search hotels directly (without AI - for fallback)
  Future<Map<String, dynamic>> searchHotelsDirectly({
    required String city,
    double minPrice = 0,
    double maxPrice = 100000,
    String? roomType,
    String? ambiance,
    List<String>? amenities,
  }) async {
    try {
      final hotels = await _mockDataService.searchHotels(
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        amenities: amenities,
      );

      return {
        'success': true,
        'hotels': hotels,
        'count': hotels.length,
        'agent': name,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'agent': name,
      };
    }
  }
}
