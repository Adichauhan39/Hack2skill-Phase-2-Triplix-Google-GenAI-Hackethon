import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
// import '../services/gemini_service.dart';
// import '../services/gemini_agent_manager.dart';
// import '../services/mock_data_service.dart';
import '../services/python_adk_service.dart';
import '../services/voice_input_service.dart';
import '../providers/user_preferences_provider.dart';
import 'swipe_screen.dart';
import 'bookings_screen.dart';
import 'mock_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const SwipeScreen(),
    const BookingsScreen(),
    const BudgetTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConfig.primaryColor,
        unselectedItemColor: AppConfig.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swipe_outlined),
            activeIcon: Icon(Icons.swipe),
            label: 'Swipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode(); // Add focus node
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController =
      ScrollController(); // Add scroll controller
  bool _hasShownConfirmation = false;
  DateTime? _startDate;
  DateTime? _endDate;

  // Confirmation form controllers
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  final TextEditingController _datesController = TextEditingController();
  final TextEditingController _stayCityController = TextEditingController();
  final TextEditingController _additionalQueryController =
      TextEditingController();

  final PythonADKService _pythonADK = PythonADKService();

  // Add a dummy state variable to force rebuilds
  int _rebuildCounter = 0;
  bool _forceRebuild = false; // Add this flag

  // Swipe functionality
  final CardSwiperController _cardController = CardSwiperController();
  List<Map<String, dynamic>> _currentSuggestions = [];
  Set<String> _acceptedSuggestions = {};
  Set<String> _rejectedSuggestions = {};

  // Multi-stage swipe workflow
  String _currentSwipeStage =
      'transport'; // transport -> accommodation -> destinations
  bool _isFullItineraryMode =
      false; // Controls whether to use multi-stage workflow
  final List<Map<String, dynamic>> _acceptedTransport = [];
  final List<Map<String, dynamic>> _acceptedAccommodation = [];
  final List<Map<String, dynamic>> _acceptedDestinations = [];
  bool _showingComparison = false;
  Map<String, dynamic>? _comparisonData;

  @override
  void initState() {
    super.initState();
    // Add initial greeting message
    _messages.add({
      'sender': 'triplix',
      'message': 'Hi my name is Triplix, how can I help you for your Travel?',
      'type': 'text',
      'timestamp': DateTime.now().toString(),
    });

    // Show travel info dialog automatically when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTravelInfoDialog();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose(); // Dispose focus node
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _datesController.dispose();
    _stayCityController.dispose();
    _additionalQueryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showTravelInfoDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Triplix AI Assistant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please provide your travel details:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _fromLocationController,
                      decoration: InputDecoration(
                        labelText: 'From (City)',
                        hintText: 'Enter departure city',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toLocationController,
                      decoration: InputDecoration(
                        labelText: 'To (City)',
                        hintText: 'Enter destination city',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stayCityController,
                      decoration: InputDecoration(
                        labelText: 'Accommodation City',
                        hintText: 'Where do you need accommodation?',
                        prefixIcon: const Icon(Icons.hotel),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final dateRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (dateRange != null) {
                          setDialogState(() {
                            _startDate = dateRange.start;
                            _endDate = dateRange.end;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Travel Dates',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _startDate == null || _endDate == null
                              ? 'Select travel dates'
                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _additionalQueryController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Query (Optional)',
                        hintText: 'Any specific requirements or questions?',
                        prefixIcon: const Icon(Icons.chat),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.trim().toLowerCase() == 'hi') {
                          Navigator.of(context).pop();
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _showTravelInfoDialog();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_fromLocationController.text.isEmpty ||
                        _toLocationController.text.isEmpty ||
                        _stayCityController.text.isEmpty ||
                        _startDate == null ||
                        _endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _processTravelDetails();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                  ),
                  child: const Text('Start Planning'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processTravelDetails() async {
    // Calculate number of days
    final days = _endDate!.difference(_startDate!).inDays + 1;

    // Show confirmation message
    setState(() {
      _messages.add({
        'sender': 'triplix',
        'message': 'Great! I have your travel details:\n'
            '📍 From: ${_fromLocationController.text}\n'
            '📍 To: ${_toLocationController.text}\n'
            '🏨 Stay: ${_stayCityController.text}\n'
            '📅 Dates: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year} ($days days)\n\n'
            'Let me help you build your perfect itinerary step by step!',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
      _isTyping = true;
      _hasShownConfirmation = true;

      // Enable multi-stage workflow for full itinerary
      _isFullItineraryMode = true;

      // Reset swipe workflow
      _currentSwipeStage = 'hotels';
      _acceptedTransport.clear();
      _acceptedAccommodation.clear();
      _acceptedDestinations.clear();
    });
    _scrollToBottom();

    // Start multi-stage swipe workflow: HOTELS FIRST
    try {
      final prefsProvider = context.read<UserPreferencesProvider>();
      final userPrefs = prefsProvider.preferences;

      // Stage 1: Get hotel recommendations from AI
      final hotelResponse = await _pythonADK.searchHotels(
        city: _stayCityController.text,
        maxPrice: userPrefs.budget != null
            ? (userPrefs.budget! * 0.3)
            : 25000, // 30% of budget for accommodation
        roomType: userPrefs.selectedAccommodation.isNotEmpty
            ? userPrefs.selectedAccommodation.first
            : null,
        amenities: ['WiFi', 'Restaurant', 'Pool'],
      );

      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message': '🏨 Step 1/3: Let\'s find your perfect accommodation!\n\n'
              '👉 Swipe RIGHT on up to 3 hotels you like\n'
              '👈 Swipe LEFT to skip\n'
              '💡 Selecting 2-3 gives you backup options!',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });

        // Add hotel suggestions for swiping
        if (hotelResponse['success'] == true && hotelResponse['data'] != null) {
          final hotels =
              (hotelResponse['data']['hotels'] as List?)?.take(5).toList() ??
                  [];
          if (hotels.isNotEmpty) {
            _messages.add({
              'sender': 'triplix',
              'message': 'Swipe through these amazing hotels:',
              'type': 'suggestions',
              'suggestions': hotels
                  .map((hotel) => {
                        'id': hotel['name'],
                        'type': 'hotel',
                        'title': hotel['name'],
                        'description':
                            'Rating: ${hotel['rating']} ⭐\n${hotel['amenities']?.take(3).join(', ') ?? ''}',
                        'price': hotel['price_per_night'],
                        'image':
                            'https://picsum.photos/400/300?random=${hotel['name'].hashCode}',
                        'stage': 'hotels',
                      })
                  .toList(),
              'timestamp': DateTime.now().toString(),
            });
            _currentSuggestions = hotels
                .map((hotel) => {
                      'id': hotel['name'],
                      'type': 'hotel',
                      'title': hotel['name'],
                      'description':
                          'Rating: ${hotel['rating']} ⭐\n${hotel['amenities']?.take(3).join(', ') ?? ''}',
                      'price': hotel['price_per_night'],
                      'image':
                          'https://picsum.photos/400/300?random=${hotel['name'].hashCode}',
                      'stage': 'hotels',
                    })
                .toList()
                .cast<Map<String, dynamic>>();
          }
        }
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message':
              'I\'m ready to help you plan your trip! What would you like to know?',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final query = _queryController.text.trim();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 [HomeScreen] _sendMessage called');
    print('   Query: "$query"');
    print('   Query empty: ${query.isEmpty}');
    print('   Has shown confirmation: $_hasShownConfirmation');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (query.isEmpty) {
      print('⚠️ [HomeScreen] Query is empty, returning early');
      return;
    }

    // Add user message
    setState(() {
      _messages.add({
        'sender': 'user',
        'message': query,
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    _queryController.clear();

    // Check if this is the first interaction and user is asking for itinerary/recommendation
    if (!_hasShownConfirmation && _isItineraryRequest(query)) {
      print(
          'ℹ️ [HomeScreen] First itinerary request detected, showing confirmation dialog');
      setState(() {
        _isFullItineraryMode =
            true; // Enable multi-stage workflow for full itinerary
      });
      await _showConfirmationDialog();
      return;
    }

    // Check if user wants to book (and we have selections to book)
    if (_isBookingRequest(query)) {
      print('📋 [HomeScreen] Booking request detected');
      if (_hasCompletedSwipe()) {
        print('✅ [HomeScreen] User has completed swipe, proceeding to book');
        await _handleBookingRequest();
      } else {
        print('⚠️ [HomeScreen] No selections made yet, guiding user');
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'triplix',
            'message': '📋 I\'d love to help you book!\n\n'
                'To book hotels and flights, I need you to:\n'
                '1. Tell me your travel plans (e.g., "Plan a trip from Delhi to Goa")\n'
                '2. Swipe through and select hotels you like 🏨\n'
                '3. Swipe through and select transport 🚗✈️\n'
                '4. Then I can create your booking!\n\n'
                'Would you like to start planning your trip now?',
            'type': 'text',
            'timestamp': DateTime.now().toString(),
          });
        });
        _scrollToBottom();
      }
      return;
    }

    // For simple queries (not itinerary requests), disable multi-stage workflow
    if (!_isItineraryRequest(query)) {
      setState(() {
        _isFullItineraryMode = false;
      });
    }

    print('✅ [HomeScreen] Proceeding to send query to AI backend...');

    try {
      // Gather user preferences for context-aware AI response
      final prefsProvider = context.read<UserPreferencesProvider>();
      final userPrefs = prefsProvider.preferences;

      // Build rich context for AI agent
      final aiContext = {
        'page': 'home',
        'user_preferences': {
          'budget': userPrefs.budget,
          'destination': userPrefs.destination,
          'activities':
              userPrefs.selectedActivities.toList(), // Convert to list
          'transport': userPrefs.selectedTransport.toList(), // Convert to list
          'accommodation':
              userPrefs.selectedAccommodation.toList(), // Convert to list
          'dietary': userPrefs.selectedDietary.toList(), // Convert to list
          'companion': userPrefs.companion,
          'occasion': userPrefs.occasion,
        },
        'conversation_history': _messages
            .map((msg) => {
                  'role': msg['sender'] == 'user' ? 'user' : 'assistant',
                  'content': msg['message'],
                })
            .toList(),
        'accepted_suggestions':
            _acceptedSuggestions.toList(), // Convert Set to List
        'rejected_suggestions':
            _rejectedSuggestions.toList(), // Convert Set to List
        'has_shown_confirmation': _hasShownConfirmation,
      };

      // Determine if this is an itinerary generation/update request
      // Only use /api/manager for actual itinerary generation
      final bool isItineraryGenerationRequest =
          _isItineraryGenerationRequest(query);

      // Send to AI Manager Agent with rich context
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(
          '📤 [HomeScreen] Sending to AI ${isItineraryGenerationRequest ? "Manager (Itinerary)" : "Agent (Chat)"}:');
      print('   Query: "$query"');
      print('   Context keys: ${aiContext.keys.toList()}');
      print('   Has conversation history: ${_messages.length} messages');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Add timeout to prevent infinite waiting
      final response = await (isItineraryGenerationRequest
              ? _pythonADK.sendToManager(
                  message: query,
                  context: aiContext,
                  page: 'home',
                )
              : _pythonADK.sendToAgent(
                  message: query,
                  context: aiContext,
                  page: 'home',
                ))
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ [HomeScreen] AI request timed out after 30 seconds');
          return {
            'response':
                'I apologize for the delay. I\'m processing your request. Could you please rephrase or ask something else?',
            'status': 'timeout',
          };
        },
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ [HomeScreen] AI Response received:');
      print('   Response keys: ${response.keys.toList()}');
      print('   Full response: ${response.toString()}');
      print(
          '   Response text length: ${(response['response'] ?? '').toString().length} chars');
      print('   Success flag: ${response['success']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Handle AI response intelligently
      final responseMessage =
          response['response'] ?? 'I\'m here to help with your travel plans!';

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📝 [HomeScreen] Processing response message:');
      print('   Response is null: ${response['response'] == null}');
      print('   Response length: ${responseMessage.length} chars');
      print(
          '   First 200 chars: ${responseMessage.substring(0, responseMessage.length > 200 ? 200 : responseMessage.length)}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Check if AI agent wants to show suggestions
      final suggestions = response['suggestions'] as List<dynamic>?;
      final shouldShowSuggestions =
          response['show_suggestions'] as bool? ?? false;

      setState(() {
        if (shouldShowSuggestions &&
            suggestions != null &&
            suggestions.isNotEmpty) {
          // AI agent wants to show swipeable suggestions
          _messages.add({
            'sender': 'triplix',
            'message': responseMessage,
            'type': 'suggestions',
            'suggestions': suggestions,
            'timestamp': DateTime.now().toString(),
          });
          _currentSuggestions = suggestions.cast<Map<String, dynamic>>();
        } else {
          // Regular text response
          _messages.add({
            'sender': 'triplix',
            'message': responseMessage,
            'type': 'text',
            'timestamp': DateTime.now().toString(),
          });
        }
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ [HomeScreen] Error in _sendMessage:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      setState(() {
        _messages.add({
          'sender': 'triplix',
          'message':
              'I apologize, but I\'m having trouble processing your request. Please try again or rephrase your question.\n\nError details: $e',
          'timestamp': DateTime.now().toString(),
        });
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  bool _isItineraryRequest(String query) {
    final lowerQuery = query.toLowerCase();

    // Full itinerary indicators - these mean user wants complete trip planning
    final fullItineraryKeywords = [
      'full itinerary',
      'complete itinerary',
      'plan my trip',
      'plan my travel',
      'plan a trip',
      'book a trip',
      'organize my trip',
      'create itinerary',
      'multi-day trip',
      'vacation plan',
      'holiday plan',
    ];

    // Check for full itinerary keywords
    for (var keyword in fullItineraryKeywords) {
      if (lowerQuery.contains(keyword)) {
        return true;
      }
    }

    // If user mentions travel dates or duration, it's likely a full itinerary
    if ((lowerQuery.contains('day') || lowerQuery.contains('days')) &&
        (lowerQuery.contains('trip') || lowerQuery.contains('travel'))) {
      return true;
    }

    // Simple suggestions are NOT itinerary requests
    // Examples: "spas in Goa", "best hotels", "restaurants"
    final simpleQuestionIndicators = [
      'what are',
      'show me',
      'suggest',
      'recommend',
      'best',
      'top',
      'good',
      'popular',
      'famous',
    ];

    for (var indicator in simpleQuestionIndicators) {
      if (lowerQuery.startsWith(indicator) ||
          lowerQuery.contains('can you $indicator') ||
          lowerQuery.contains('could you $indicator')) {
        // This is a simple question/suggestion request, not full itinerary
        return false;
      }
    }

    // Default: only trigger itinerary if explicitly asks for planning
    return lowerQuery.contains('plan') && lowerQuery.contains('trip');
  }

  bool _isBookingRequest(String query) {
    final lowerQuery = query.toLowerCase();

    // Booking keywords
    final bookingKeywords = [
      'book',
      'reserve',
      'confirm booking',
      'make a booking',
      'finalize',
      'proceed to book',
      'complete booking',
      'book the',
      'book my',
      'reserve the',
      'reserve my',
    ];

    for (var keyword in bookingKeywords) {
      if (lowerQuery.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  bool _isItineraryGenerationRequest(String query) {
    final lowerQuery = query.toLowerCase();

    // This method determines if the query specifically asks for itinerary GENERATION
    // (not just general conversation about travel)

    // Keywords that indicate user wants an itinerary generated
    final itineraryGenerationKeywords = [
      'generate itinerary',
      'create itinerary',
      'make itinerary',
      'show itinerary',
      'show my itinerary',
      'create my plan',
      'generate my plan',
      'finalize itinerary',
      'complete my itinerary',
      'show the plan',
      'what\'s my plan',
      'show plan',
    ];

    for (var keyword in itineraryGenerationKeywords) {
      if (lowerQuery.contains(keyword)) {
        return true;
      }
    }

    // If user has completed swipe flow and asks about their selections/plan
    if (_hasCompletedSwipe()) {
      final contextualKeywords = [
        'my selections',
        'what did i select',
        'my choices',
        'combine',
        'put together',
        'organize',
      ];

      for (var keyword in contextualKeywords) {
        if (lowerQuery.contains(keyword)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _hasCompletedSwipe() {
    // Check if user has made selections in swipe stages
    return _acceptedAccommodation.isNotEmpty ||
        _acceptedTransport.isNotEmpty ||
        _acceptedDestinations.isNotEmpty;
  }

  Future<void> _handleBookingRequest() async {
    setState(() => _isTyping = true);

    try {
      // Check if comparison is needed
      bool needsHotelComparison = _acceptedAccommodation.length > 1;
      bool needsTransportComparison = _acceptedTransport.length > 1;

      if (needsHotelComparison || needsTransportComparison) {
        // Show message about comparison
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'triplix',
            'message': '🔍 I noticed you\'ve selected multiple options!\n\n'
                '${needsHotelComparison ? "✅ Hotels: ${_acceptedAccommodation.length}\n" : ""}'
                '${needsTransportComparison ? "✅ Transport: ${_acceptedTransport.length}\n" : ""}\n'
                'Let me help you compare them so you can decide which one to book! 📊',
            'type': 'text',
            'timestamp': DateTime.now().toString(),
          });
        });
        _scrollToBottom();

        await Future.delayed(const Duration(milliseconds: 800));

        // Show comparison dialog
        if (mounted) {
          final comparisonResult = await _showComparisonDialog(
            needsHotelComparison: needsHotelComparison,
            needsTransportComparison: needsTransportComparison,
          );

          if (comparisonResult == null) {
            // User cancelled
            setState(() {
              _messages.add({
                'sender': 'triplix',
                'message': '👋 Okay, no problem! Take your time to decide.\n\n'
                    'Just let me know when you\'re ready to book!',
                'type': 'text',
                'timestamp': DateTime.now().toString(),
              });
            });
            _scrollToBottom();
            return;
          }
        }
      }

      // Show confirmation message
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message': '✨ Perfect! Let me process your booking...\n\n'
              'Opening booking confirmation page...',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();

      // Navigate to mock booking screen
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockBookingScreen(
              acceptedHotels: _acceptedAccommodation,
              acceptedTransport: _acceptedTransport,
              acceptedDestinations: _acceptedDestinations,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message':
              '❌ Sorry, I encountered an error while preparing your booking.\n\n'
                  'Error: $e\n\n'
                  'Please try again or contact support.',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    }
  }

  Future<bool?> _showComparisonDialog({
    required bool needsHotelComparison,
    required bool needsTransportComparison,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.compare_arrows,
                              color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Compare Your Options',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (needsHotelComparison) ...[
                              _buildComparisonSection(
                                title: '🏨 Hotels Comparison',
                                items: _acceptedAccommodation,
                                onSelect: (index) {
                                  setDialogState(() {
                                    // Keep only the selected hotel
                                    final selected =
                                        _acceptedAccommodation[index];
                                    _acceptedAccommodation.clear();
                                    _acceptedAccommodation.add(selected);
                                  });
                                },
                              ),
                              if (needsTransportComparison)
                                const SizedBox(height: 24),
                            ],
                            if (needsTransportComparison) ...[
                              _buildComparisonSection(
                                title: '🚗 Transport Comparison',
                                items: _acceptedTransport,
                                onSelect: (index) {
                                  setDialogState(() {
                                    // Keep only the selected transport
                                    final selected = _acceptedTransport[index];
                                    _acceptedTransport.clear();
                                    _acceptedTransport.add(selected);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Action buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Check if all needed selections are made
                              bool hotelSelectionComplete =
                                  !needsHotelComparison ||
                                      _acceptedAccommodation.length == 1;
                              bool transportSelectionComplete =
                                  !needsTransportComparison ||
                                      _acceptedTransport.length == 1;

                              if (hotelSelectionComplete &&
                                  transportSelectionComplete) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            icon: const Icon(Icons.check_circle, size: 20),
                            label: const Text('Proceed with Selection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConfig.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
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
          },
        );
      },
    );
  }

  Widget _buildComparisonSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required Function(int) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConfig.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select one option to proceed:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = items.length == 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isSelected ? AppConfig.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppConfig.primaryColor.withOpacity(0.05)
                  : Colors.white,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSelected ? null : () => onSelect(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Selection indicator
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppConfig.primaryColor
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppConfig.primaryColor
                              : Colors.white,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),

                      // Item details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppConfig.primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            if (item['location'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item['location'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item['price'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${item['price']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                            if (item['description'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showConfirmationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Travel Details Confirmation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConfig.primaryColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'before i recommend you with the itennary, can you please confirm, from and to location for the travel, and the dates, and also, which city are you looking for the stay, or any additional query if you have.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fromLocationController,
                  decoration: const InputDecoration(
                    labelText: 'From Location',
                    hintText: 'Enter departure city',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _toLocationController,
                  decoration: const InputDecoration(
                    labelText: 'To Location',
                    hintText: 'Enter destination city',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _datesController,
                  decoration: const InputDecoration(
                    labelText: 'Travel Dates',
                    hintText: 'e.g., Dec 15-20, 2025',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _stayCityController,
                  decoration: const InputDecoration(
                    labelText: 'Stay City',
                    hintText: 'Which city are you looking for stay?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _additionalQueryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional Query (Optional)',
                    hintText: 'Any specific preferences or requirements?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isTyping = false;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _processConfirmedDetails();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Get Recommendations'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processConfirmedDetails() async {
    setState(() {
      _hasShownConfirmation = true;
      _messages.add({
        'sender': 'triplix',
        'message':
            'Great! I\'ve noted your travel details. Let me create a personalized itinerary for you.',
        'timestamp': DateTime.now().toString(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Create a comprehensive query with all the confirmed details
      final travelDetails = '''
Travel Details:
- From: ${_fromLocationController.text}
- To: ${_toLocationController.text}
- Dates: ${_datesController.text}
- Stay City: ${_stayCityController.text}
${_additionalQueryController.text.isNotEmpty ? '- Additional: ${_additionalQueryController.text}' : ''}

Please provide a detailed travel itinerary with recommendations for hotels, activities, and transportation.
      '''
          .trim();

      final response = await _pythonADK.sendToManager(
        message: travelDetails,
        context: {
          'from_location': _fromLocationController.text,
          'to_location': _toLocationController.text,
          'dates': _datesController.text,
          'stay_city': _stayCityController.text,
          'additional_query': _additionalQueryController.text,
        },
        page: 'home',
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ [HomeScreen] Itinerary AI Response received:');
      print('   Response keys: ${response.keys.toList()}');
      print('   Full response: ${response.toString()}');
      print(
          '   Response text length: ${(response['response'] ?? '').toString().length} chars');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Process the AI response and extract suggestions
      final aiResponse = response['response'] ?? '';
      if (aiResponse.isNotEmpty) {
        // Add the AI response message
        setState(() {
          _messages.add({
            'sender': 'triplix',
            'message': aiResponse,
            'type': 'text',
            'timestamp': DateTime.now().toString(),
          });
        });
        _scrollToBottom();
      }

      setState(() {
        _messages.add({
          'sender': 'triplix',
          'message':
              'Here are some personalized recommendations for your trip! Swipe right to add them to your itinerary, or left to see alternatives.',
          'type': 'suggestions',
          'suggestions': _generateInitialSuggestions(),
          'timestamp': DateTime.now().toString(),
        });
        _currentSuggestions = _generateInitialSuggestions();
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'triplix',
          'message':
              'Sorry, I\'m having trouble generating your itinerary. Please try again.',
          'timestamp': DateTime.now().toString(),
        });
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConfig.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.airplanemode_active,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Triplix Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    child: Column(
                      children: [
                        ..._messages.map((message) {
                          final isTriplix = message['sender'] == 'triplix';
                          return _buildMessageBubble(message, isTriplix);
                        }).toList(),
                        if (_isTyping) _buildTypingIndicator(),
                      ],
                    ),
                  ),
                ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Voice Input Button
                    VoiceInputButton(
                      onTranscript: (transcript) {
                        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                        print('🎤 [HomeScreen] Voice callback triggered!');
                        print('📝 [HomeScreen] Transcript: "$transcript"');
                        print(
                            '📝 [HomeScreen] Length: ${transcript.length} characters');

                        if (transcript.isEmpty) {
                          print('⚠️ [HomeScreen] Empty transcript received!');
                          return;
                        }

                        // IMMEDIATE update - no delay
                        print(
                            '✏️ [HomeScreen] Setting text controller IMMEDIATELY...');

                        // Update in setState for immediate UI refresh
                        setState(() {
                          // Try multiple ways to ensure text updates
                          _queryController.value =
                              TextEditingValue(text: transcript);
                          _queryController.text = transcript;
                          _rebuildCounter++; // Force rebuild with new key
                          _forceRebuild =
                              !_forceRebuild; // Toggle to force complete rebuild
                        });

                        print(
                            '✅ [HomeScreen] Text controller value: "${_queryController.text}"');
                        print(
                            '🔄 [HomeScreen] UI rebuild triggered, counter: $_rebuildCounter, forceRebuild: $_forceRebuild');

                        // Request focus AFTER setState completes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _queryFocusNode.requestFocus();
                          print('🎯 [HomeScreen] Focus requested on TextField');

                          // Show visual confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Voice text set: "$transcript"'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        });

                        print(
                            '✅ [HomeScreen] Text should now be visible in input field!');
                        print(
                            '💡 [HomeScreen] Text is ready. User can now edit or send manually.');
                        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                      },
                      size: 28,
                      color: AppConfig.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _forceRebuild
                          ? TextField(
                              key: ValueKey(
                                  'query_input_$_rebuildCounter'), // Force rebuild with key
                              controller: _queryController,
                              focusNode: _queryFocusNode, // Add focus node
                              decoration: InputDecoration(
                                hintText: 'Ask me about your travel plans...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            )
                          : TextField(
                              key: ValueKey(
                                  'query_input_alt_$_rebuildCounter'), // Alternate key for complete rebuild
                              controller: _queryController,
                              focusNode: _queryFocusNode, // Add focus node
                              decoration: InputDecoration(
                                hintText: 'Ask me about your travel plans...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppConfig.primaryGradient,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isTriplix) {
    final messageType = message['type'] ?? 'text';

    if (messageType == 'suggestions') {
      return _buildSuggestionsMessage(message, isTriplix);
    }

    if (messageType == 'comparison') {
      return _buildComparisonMessage(message, isTriplix);
    }

    if (messageType == 'replacement_prompt') {
      return _buildReplacementPromptMessage(message, isTriplix);
    }

    return Align(
      alignment: isTriplix ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: isTriplix
            ? _buildTriplixMessage(message)
            : _buildUserMessage(message),
      ),
    );
  }

  Widget _buildTriplixMessage(Map<String, dynamic> message) {
    final messageText = message['message'] ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConfig.primaryColor.withOpacity(0.15),
            AppConfig.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          // Header with AI icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppConfig.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Triplix AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Message content with enhanced formatting
          Padding(
            padding: const EdgeInsets.all(16),
            child: _formatAIMessage(messageText),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(Map<String, dynamic> message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConfig.primaryColor,
            AppConfig.primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message['message'] ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _formatAIMessage(String text) {
    // Remove excessive markdown asterisks and clean up formatting
    String cleanedText = text
        .replaceAll('**', '') // Remove bold markdown
        .replaceAll('__', '') // Remove alternative bold markdown
        .replaceAll('###', '') // Remove h3 headers
        .replaceAll('##', '') // Remove h2 headers
        .replaceAll('#', ''); // Remove h1 headers

    // Split message into sections for better formatting
    final lines = cleanedText.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check for emoji headers (lines starting with emoji)
      final emojiMatch = RegExp(
              r'^([\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}])\s*(.+)',
              unicode: true)
          .firstMatch(line);
      if (emojiMatch != null && line.length < 80) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConfig.primaryColor.withOpacity(0.1),
                    AppConfig.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: AppConfig.primaryColor,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    emojiMatch.group(1)!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      emojiMatch.group(2)!.trim(),
                      style: TextStyle(
                        color: AppConfig.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // Check for bullet points or numbered lists
      else if (line.startsWith('•') ||
          line.startsWith('-') ||
          RegExp(r'^\d+[\.)]\s').hasMatch(line)) {
        final content = line.replaceFirst(RegExp(r'^[•\-\d+[\.)]\s]+'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConfig.primaryColor,
                        AppConfig.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConfig.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Check for headers (lines ending with :)
      else if (line.endsWith(':') && line.length < 60) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      color: AppConfig.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Check for price/cost lines (contains ₹ or Rs.)
      else if (line.contains('₹') ||
          line.contains('Rs.') ||
          line.toLowerCase().contains('cost') ||
          line.toLowerCase().contains('price')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // Regular text with improved styling
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent overflow by sizing to content
      children: widgets.isNotEmpty
          ? widgets
          : [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
    );
  }

  Widget _buildSuggestionsMessage(
      Map<String, dynamic> message, bool isTriplix) {
    final dynamic rawSuggestions = message['suggestions'];
    if (rawSuggestions == null || rawSuggestions is! List) {
      return _buildMessageBubble({
        'sender': message['sender'],
        'message': message['message'] ?? 'No suggestions available',
        'type': 'text',
        'timestamp': message['timestamp'],
      }, isTriplix);
    }

    final List<Map<String, dynamic>> suggestions = [];
    for (final item in rawSuggestions) {
      if (item is Map<String, dynamic>) {
        suggestions.add(item);
      }
    }

    if (suggestions.isEmpty) {
      return _buildMessageBubble({
        'sender': message['sender'],
        'message': message['message'] ?? 'No suggestions available',
        'type': 'text',
        'timestamp': message['timestamp'],
      }, isTriplix);
    }

    // Show message with a button to open overlay
    return Align(
      alignment: isTriplix ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConfig.primaryColor.withOpacity(0.15),
              AppConfig.primaryColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: const Radius.circular(24),
            bottomLeft: const Radius.circular(24),
            bottomRight: const Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppConfig.primaryColor.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Personalized Recommendations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${suggestions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['message'] != null &&
                      message['message'].toString().isNotEmpty)
                    Text(
                      message['message'],
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Preview cards
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          suggestions.length > 3 ? 3 : suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        final type = suggestion['type'] ?? 'general';
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTypeColor(type).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getTypeIcon(type),
                                    size: 16,
                                    color: _getTypeColor(type),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _getTypeLabel(type),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getTypeColor(type),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                suggestion['title'] ?? 'Suggestion',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (suggestions.length > 3) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${suggestions.length - 3} more suggestions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Swipe button with animation
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConfig.primaryColor,
                          AppConfig.primaryColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _showSuggestionsOverlay(suggestions),
                      icon: const Icon(Icons.swipe_right, size: 22),
                      label: const Text(
                        'Start Swiping',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

  Widget _buildComparisonMessage(Map<String, dynamic> message, bool isTriplix) {
    final options = message['options'] as List<dynamic>? ?? [];
    final analysis = message['analysis'] ?? '';
    final comparisonType = message['comparison_type'] ?? 'option';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: AppConfig.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppConfig.primaryColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.compare_arrows,
                    color: AppConfig.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compare ${comparisonType == 'transport' ? 'Transport Options' : 'Accommodation Options'}',
                    style: TextStyle(
                      color: AppConfig.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Analysis
            if (analysis.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  analysis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Option Cards
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value as Map<String, dynamic>;
              return Container(
                margin: EdgeInsets.only(
                    bottom: index < options.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppConfig.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Option Header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppConfig.primaryColor,
                          radius: 14,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option['name'] ??
                                option['airline'] ??
                                option['hotel_name'] ??
                                'Option ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Option Details
                    if (option['price'] != null)
                      Text('Price: ${option['price']}',
                          style: const TextStyle(fontSize: 14)),
                    if (option['duration'] != null)
                      Text('Duration: ${option['duration']}',
                          style: const TextStyle(fontSize: 14)),
                    if (option['rating'] != null)
                      Text('Rating: ${option['rating']} ⭐',
                          style: const TextStyle(fontSize: 14)),

                    const SizedBox(height: 12),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _confirmSelection(comparisonType, option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Confirm This Option',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplacementPromptMessage(
      Map<String, dynamic> message, bool isTriplix) {
    final removedItem = message['removed_item'] as Map<String, dynamic>? ?? {};
    final itemName =
        removedItem['name'] ?? removedItem['destination'] ?? 'this item';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title
            Row(
              children: [
                Icon(Icons.help_outline,
                    color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replacement Needed?',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message['message'] ??
                  'You removed "$itemName". Would you like me to suggest a replacement?',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Yes/No Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _handleReplacementResponse(true, removedItem),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Yes, Please',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _handleReplacementResponse(false, removedItem),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('No, Thanks',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuggestionsOverlay(List<Map<String, dynamic>> suggestions) {
    // Store current suggestions for swipe handler
    _currentSuggestions = suggestions;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400, // Fixed max width to prevent overflow
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Swipe to Choose',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Swipeable cards
                Flexible(
                  child: Container(
                    height: 400,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CardSwiper(
                      controller: _cardController,
                      cardsCount: suggestions.length,
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final result = _handleSuggestionSwipe(
                            previousIndex, currentIndex, direction);
                        // DON'T auto-close - let user close manually
                        // User can click X button or press back to close
                        return result;
                      },
                      numberOfCardsDisplayed: suggestions.length > 1 ? 2 : 1,
                      backCardOffset: const Offset(15, 15),
                      padding: const EdgeInsets.all(8),
                      cardBuilder: (context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage) {
                        if (index < 0 || index >= suggestions.length) {
                          return const SizedBox.shrink();
                        }
                        final suggestion = suggestions[index];
                        return _buildSuggestionCard(suggestion, index);
                      },
                    ),
                  ),
                ),
                // Action buttons with Finish button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Swipe instruction text
                      Text(
                        'Swipe left to skip, right to like',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Swipe buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            onPressed: () =>
                                _cardController.swipe(CardSwiperDirection.left),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 30),
                          ),
                          FloatingActionButton(
                            onPressed: () => _cardController
                                .swipe(CardSwiperDirection.right),
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.favorite,
                                color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Finish button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _finishCurrentStage(),
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          label: Text(
                            _getFinishButtonText(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, int index) {
    final type = (suggestion['type'] as String?) ?? 'general';
    final title = (suggestion['title'] as String?) ?? 'Suggestion';
    final description = (suggestion['description'] as String?) ?? '';
    final price = suggestion['price'];
    final rating = suggestion['rating'];
    final location = suggestion['location'] ?? suggestion['address'];
    final distance = suggestion['distance'];
    final amenities = suggestion['amenities'];
    final openingHours = suggestion['opening_hours'] ?? suggestion['hours'];
    final highlights = suggestion['highlights'];
    final imageUrl =
        suggestion['image'] ?? suggestion['image_url'] ?? suggestion['photo'];

    // Extract review/summary if available
    final review =
        suggestion['review'] ?? suggestion['summary'] ?? suggestion['reviews'];

    return Card(
      elevation: 12,
      shadowColor: _getTypeColor(type).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        height:
            380, // Reduced to fit within swiper's 400px constraint (was 520)
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced header with REAL IMAGE or gradient fallback
            Stack(
              children: [
                // Image or gradient background
                Container(
                  height: 100, // Reduced from 130px to save space
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    gradient: imageUrl == null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getTypeColor(type).withOpacity(0.85),
                              _getTypeColor(type).withOpacity(0.65),
                            ],
                          )
                        : null,
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // The actual image
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to gradient if image fails to load
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _getTypeColor(type).withOpacity(0.85),
                                          _getTypeColor(type).withOpacity(0.65),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getTypeIcon(type),
                                        size: 50, // Reduced from 60
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: _getTypeColor(type).withOpacity(0.1),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _getTypeColor(type),
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Dark overlay for better text readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Icon(
                            _getTypeIcon(type),
                            size: 50, // Reduced from 60
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                ),
                // Type badge
                Positioned(
                  top: 8, // Reduced from 12
                  right: 8, // Reduced from 12
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16), // Reduced from 20
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          color: _getTypeColor(type),
                          size: 12, // Reduced from 14
                        ),
                        const SizedBox(width: 3), // Reduced from 4
                        Text(
                          _getTypeLabel(type),
                          style: TextStyle(
                            color: _getTypeColor(type),
                            fontWeight: FontWeight.bold,
                            fontSize: 10, // Reduced from 11
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Rating badge
                if (rating != null)
                  Positioned(
                    top: 8, // Reduced from 12
                    left: 8, // Reduced from 12
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius:
                            BorderRadius.circular(16), // Reduced from 20
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 14, // Reduced from 16
                          ),
                          const SizedBox(width: 3), // Reduced from 4
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11, // Reduced from 13
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Make everything below header scrollable to prevent overflow
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content with more information
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          12, 8, 12, 8), // Reduced padding for compact layout
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Location with icon
                          if (location != null) ...[
                            const SizedBox(height: 4), // Reduced from 6
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (distance != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppConfig.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      distance.toString(),
                                      style: TextStyle(
                                        color: AppConfig.primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],

                          // Weather Information (if available)
                          if (suggestion['current_weather'] != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.1),
                                    Colors.lightBlue.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    suggestion['current_weather']['icon'] ??
                                        '🌤️',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggestion['current_weather']['temp'] ??
                                            'N/A',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        suggestion['current_weather']
                                                ['description'] ??
                                            'Weather info',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (suggestion['current_weather']
                                          ['humidity'] !=
                                      null) ...[
                                    Column(
                                      children: [
                                        Icon(Icons.water_drop,
                                            size: 12, color: Colors.blue[700]),
                                        Text(
                                          suggestion['current_weather']
                                              ['humidity'],
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (suggestion['current_weather']['wind'] !=
                                      null) ...[
                                    const SizedBox(width: 8),
                                    Column(
                                      children: [
                                        Icon(Icons.air,
                                            size: 12, color: Colors.grey[600]),
                                        Text(
                                          suggestion['current_weather']['wind'],
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 6), // Reduced from 8

                          // Description - Full text, scrollable
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              height: 1.4,
                            ),
                            // Removed maxLines to allow full description to show when scrolling
                          ),

                          // Review/Summary section if available
                          if (review != null &&
                              review.toString().isNotEmpty) ...[
                            const SizedBox(height: 8), // Reduced from 12
                            Container(
                              padding:
                                  const EdgeInsets.all(8), // Reduced from 10
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.rate_review,
                                        size: 12, // Reduced from 14
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(
                                          width: 4), // Reduced from 6
                                      Text(
                                        'Reviews',
                                        style: TextStyle(
                                          fontSize: 11, // Reduced from 12
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4), // Reduced from 6
                                  Text(
                                    review.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 11, // Reduced from 12
                                      height: 1.4,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Highlights/Amenities
                          if (highlights != null || amenities != null) ...[
                            const SizedBox(height: 6), // Reduced from 8
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children:
                                  _buildFeatureTags(highlights ?? amenities),
                            ),
                          ],

                          // Opening hours
                          if (openingHours != null) ...[
                            const SizedBox(height: 4), // Reduced from 6
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    openingHours.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Additional details based on type
                          const SizedBox(height: 6), // Reduced from 8
                          _buildAdditionalDetails(suggestion, type),

                          // Add padding at bottom for better scroll (reduced for compact layout)
                          const SizedBox(
                              height: 20), // Reduced from 60 for compact layout
                        ],
                      ),
                    ),

                    // Maps button - Now part of scrollable content
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4), // Reduced from 6
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top:
                              BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final locationText = location ?? title;
                            final query =
                                Uri.encodeComponent('$title $locationText');
                            final url =
                                'https://www.google.com/maps/search/?api=1&query=$query';
                            final uri = Uri.parse(url);

                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              print('Error launching maps: $e');
                            }
                          },
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text(
                            'View on Google Maps',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1976D2),
                            side: const BorderSide(
                                color: Color(0xFF1976D2), width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 6), // Reduced from 8
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Price section at bottom (if available)
                    if (price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${price.toString()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureTags(dynamic features) {
    if (features == null) return [];

    List<String> featureList;
    if (features is List) {
      featureList =
          features.map((e) => e.toString()).take(4).toList(); // Limit to 4
    } else if (features is String) {
      featureList = features.split(',').take(4).toList();
    } else {
      return [];
    }

    return featureList.map((feature) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConfig.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          feature.trim(),
          style: TextStyle(
            fontSize: 10,
            color: AppConfig.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAdditionalDetails(Map<String, dynamic> suggestion, String type) {
    // Extract type-specific details
    final details = suggestion['details'] as Map<String, dynamic>?;

    if (details == null) return const SizedBox.shrink();

    List<Widget> detailWidgets = [];

    // Hotel-specific details
    if (type == 'hotel' || type == 'accommodation') {
      if (details['check_in'] != null || details['check_out'] != null) {
        detailWidgets.add(
          _buildDetailRow(
            Icons.access_time,
            'Check-in: ${details['check_in'] ?? 'N/A'} | Check-out: ${details['check_out'] ?? 'N/A'}',
          ),
        );
      }
      if (details['room_type'] != null) {
        detailWidgets.add(
          _buildDetailRow(Icons.bed, 'Room: ${details['room_type']}'),
        );
      }
    }

    // Transport-specific details
    if (type == 'transport') {
      if (details['departure'] != null || details['arrival'] != null) {
        detailWidgets.add(
          _buildDetailRow(
            Icons.schedule,
            'Depart: ${details['departure'] ?? 'N/A'} → Arrive: ${details['arrival'] ?? 'N/A'}',
          ),
        );
      }
      if (details['duration'] != null) {
        detailWidgets.add(
          _buildDetailRow(Icons.timer, 'Duration: ${details['duration']}'),
        );
      }
    }

    // Destination-specific details
    if (type == 'destination' || type == 'activity') {
      // Handle the details map from destination recommendations
      if (details['Location Type'] != null &&
          details['Location Type'].toString().isNotEmpty) {
        detailWidgets.add(
          _buildDetailRow(
            Icons.location_city,
            'Type: ${details['Location Type']}',
          ),
        );
      }
      if (details['Travel Style'] != null &&
          details['Travel Style'].toString().isNotEmpty) {
        detailWidgets.add(
          _buildDetailRow(
            Icons.style,
            'Style: ${details['Travel Style']}',
          ),
        );
      }
      if (details['Best Season'] != null &&
          details['Best Season'].toString().isNotEmpty) {
        detailWidgets.add(
          _buildDetailRow(
            Icons.wb_sunny,
            'Best: ${details['Best Season']}',
          ),
        );
      }
      if (details['Cuisine'] != null &&
          details['Cuisine'].toString().isNotEmpty) {
        detailWidgets.add(
          _buildDetailRow(
            Icons.restaurant,
            'Food: ${details['Cuisine']}',
          ),
        );
      }
    }

    // If no specific details, show generic ones
    if (detailWidgets.isEmpty) {
      if (suggestion['category'] != null) {
        detailWidgets.add(
          _buildDetailRow(
              Icons.category, 'Category: ${suggestion['category']}'),
        );
      }
      if (suggestion['subcategory'] != null) {
        detailWidgets.add(
          _buildDetailRow(Icons.info_outline, '${suggestion['subcategory']}'),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detailWidgets.take(2).toList(), // Limit to 2 lines
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'hotel':
        return Colors.blue;
      case 'activity':
        return Colors.green;
      case 'restaurant':
        return Colors.orange;
      case 'transport':
        return Colors.purple;
      default:
        return AppConfig.primaryColor;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'hotel':
        return Icons.hotel;
      case 'activity':
        return Icons.local_activity;
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      default:
        return Icons.place;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'hotel':
        return 'HOTEL';
      case 'activity':
        return 'ACTIVITY';
      case 'restaurant':
        return 'RESTAURANT';
      case 'transport':
        return 'TRANSPORT';
      default:
        return 'SUGGESTION';
    }
  }

  bool _handleSuggestionSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (_currentSuggestions.isEmpty ||
        previousIndex >= _currentSuggestions.length) return true;

    final suggestion = _currentSuggestions[previousIndex];

    if (direction == CardSwiperDirection.right) {
      // Swiped right - add to stage-specific collection
      _acceptedSuggestions.add(suggestion['id'] ?? suggestion['title'] ?? '');
      _showSwipeFeedback('Added! ❤️', Colors.green);

      // Only proceed with multi-stage workflow if in full itinerary mode
      if (_isFullItineraryMode) {
        // Add to appropriate stage collection based on NEW order: hotels → transport → destinations
        if (_currentSwipeStage == 'hotels') {
          _acceptedAccommodation.add(suggestion);

          // Allow user to select 1-3 hotels
          // Auto-proceed only when:
          // 1. User selected 3 hotels (max reached), OR
          // 2. User reached the last card (ran out of options)
          if (_acceptedAccommodation.length >= 3) {
            // Max hotels selected, auto-advance
            Future.delayed(const Duration(milliseconds: 800), () {
              _proceedToTransportStage();
            });
          } else if (currentIndex == null ||
              currentIndex >= _currentSuggestions.length - 1) {
            // Reached last card, proceed with whatever they selected (1-2 hotels)
            if (_acceptedAccommodation.length >= 1) {
              Future.delayed(const Duration(milliseconds: 800), () {
                _proceedToTransportStage();
              });
            }
          }
        } else if (_currentSwipeStage == 'transport') {
          _acceptedTransport.add(suggestion);

          // Allow user to select 1-2 transport options
          // Auto-proceed when:
          // 1. User selected 2 transport (max for comparison), OR
          // 2. User reached the last card
          if (_acceptedTransport.length >= 2) {
            // Max transport selected, auto-advance
            Future.delayed(const Duration(milliseconds: 800), () {
              _proceedToDestinationsStage();
            });
          } else if (currentIndex == null ||
              currentIndex >= _currentSuggestions.length - 1) {
            // Reached last card, proceed with whatever they selected (1 transport)
            if (_acceptedTransport.length >= 1) {
              Future.delayed(const Duration(milliseconds: 800), () {
                _proceedToDestinationsStage();
              });
            }
          }
        } else if (_currentSwipeStage == 'destinations') {
          _acceptedDestinations.add(suggestion);

          // Allow unlimited destinations until user runs out of cards
          // Generate itinerary when user reaches the last card
          if (currentIndex == null ||
              currentIndex >= _currentSuggestions.length - 1) {
            // Minimum 2 destinations required for a proper trip
            if (_acceptedDestinations.length >= 2) {
              Future.delayed(const Duration(milliseconds: 800), () {
                _generateFinalItinerary();
              });
            } else {
              // Show message to select at least 2 destinations
              _showSwipeFeedback(
                  'Select at least 2 destinations!', Colors.orange);
            }
          }
        }
      }
    } else {
      // Swiped left - rejected
      _rejectedSuggestions.add(suggestion['id'] ?? suggestion['title'] ?? '');
      _showSwipeFeedback('Skipped 👎', Colors.red);
    }

    return true;
  }

  // Stage 2: Proceed to Transport selection
  Future<void> _proceedToTransportStage() async {
    // Close the swipe overlay
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Parse and update transport preferences from user's messages
    _parseAndUpdateTransportPreferences();

    setState(() {
      _currentSwipeStage = 'transport';
      _isTyping = true;
      _messages.add({
        'sender': 'triplix',
        'message':
            '✅ Awesome! You\'ve selected ${_acceptedAccommodation.length} hotel(s)!\n\n'
                '🚗 Step 2/3: Now let\'s choose your transport\n\n'
                '👉 Swipe RIGHT on up to 2 transport options (for comparison)\n'
                '👈 Swipe LEFT to skip\n'
                '💡 Selecting 2 helps you compare and choose the best!',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();

    // Generate transport suggestions from AI
    setState(() => _isTyping = true);
    final transportOptions = await _generateTransportSuggestions();

    setState(() {
      _isTyping = false;
      _messages.add({
        'sender': 'triplix',
        'message': 'Swipe through these transport options:',
        'type': 'suggestions',
        'suggestions': transportOptions,
        'timestamp': DateTime.now().toString(),
      });
      _currentSuggestions = transportOptions;
    });
    _scrollToBottom();
  }

  // Parse user messages to extract and update transport preferences
  void _parseAndUpdateTransportPreferences() {
    final prefsProvider = context.read<UserPreferencesProvider>();

    // Combine all user messages and additional query
    final allUserText = _messages
            .where((msg) => msg['sender'] == 'user')
            .map((msg) => msg['message'].toString().toLowerCase())
            .join(' ') +
        ' ' +
        _additionalQueryController.text.toLowerCase() +
        ' ' +
        _queryController.text.toLowerCase();

    print('🔍 Parsing transport preferences from: "$allUserText"');

    List<String> detectedTransport = [];

    // Check for flight/air preferences
    if (allUserText.contains('flight') ||
        allUserText.contains('fly') ||
        allUserText.contains('air') ||
        allUserText.contains('plane') ||
        allUserText.contains('airplane')) {
      detectedTransport.add('air');
      print('✈️ Detected: Flight preference');
    }

    // Check for train preferences
    if (allUserText.contains('train') ||
        allUserText.contains('rail') ||
        allUserText.contains('railway') ||
        allUserText.contains('rajdhani') ||
        allUserText.contains('shatabdi') ||
        allUserText.contains('express') ||
        allUserText.contains('vande bharat')) {
      detectedTransport.add('train');
      print('🚂 Detected: Train preference');
    }

    // Check for road/bus preferences
    if (allUserText.contains('bus') ||
        allUserText.contains('road') ||
        allUserText.contains('car') ||
        allUserText.contains('drive') ||
        allUserText.contains('taxi') ||
        allUserText.contains('volvo') ||
        allUserText.contains('coach')) {
      detectedTransport.add('road');
      print('🚌 Detected: Road/Bus preference');
    }

    // Update preferences if any transport was detected
    if (detectedTransport.isNotEmpty) {
      print('✅ Updating transport preferences to: $detectedTransport');
      prefsProvider.updateTransport(detectedTransport);
    } else {
      print(
          'ℹ️ No specific transport preferences detected, showing all options');
    }
  }

  // Stage 3: Proceed to Destinations selection
  Future<void> _proceedToDestinationsStage() async {
    // Close the swipe overlay
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _currentSwipeStage = 'destinations';
      _isTyping = true;
      _messages.add({
        'sender': 'triplix',
        'message':
            '✅ Perfect! You\'ve selected ${_acceptedTransport.length} transport option(s)!\n\n'
                '📍 Step 3/3: Finally, let\'s pick your destinations\n\n'
                '👉 Swipe RIGHT on places you want to visit (select multiple!)\n'
                '👈 Swipe LEFT to skip\n'
                '⚠️ Minimum 2 destinations required for itinerary',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();

    // Generate destination suggestions
    final destinationOptions = _generateDestinationSuggestions();

    setState(() {
      _isTyping = false;
      _messages.add({
        'sender': 'triplix',
        'message': 'Swipe through these amazing destinations:',
        'type': 'suggestions',
        'suggestions': destinationOptions,
        'timestamp': DateTime.now().toString(),
      });
      _currentSuggestions = destinationOptions;
    });
    _scrollToBottom();
  }

  // Stage 4: Generate Final Itinerary based on all swipes
  Future<void> _generateFinalItinerary() async {
    // Close the swipe overlay
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isTyping = true;
      _messages.add({
        'sender': 'triplix',
        'message': '🎉 Awesome! You\'ve completed all selections!\n\n'
            '📋 Hotels: ${_acceptedAccommodation.length}\n'
            '🚗 Transport: ${_acceptedTransport.length}\n'
            '📍 Destinations: ${_acceptedDestinations.length}\n\n'
            'Let me create your personalized itinerary using AI...',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();

    try {
      final prefsProvider = context.read<UserPreferencesProvider>();
      final userPrefs = prefsProvider.preferences;
      final days = _endDate!.difference(_startDate!).inDays + 1;

      // Call AI to generate complete itinerary
      final itineraryResponse = await _pythonADK.sendToManager(
        message:
            'Create a detailed $days-day itinerary from ${_fromLocationController.text} to ${_toLocationController.text}',
        context: {
          'from': _fromLocationController.text,
          'to': _toLocationController.text,
          'stay_city': _stayCityController.text,
          'start_date': _startDate!.toIso8601String(),
          'end_date': _endDate!.toIso8601String(),
          'duration_days': days,
          'budget': userPrefs.budget ?? 0,
          'travelers': userPrefs.numberOfPeople ?? 1,
          'selected_hotels':
              _acceptedAccommodation.map((h) => h['title']).toList(),
          'selected_transport':
              _acceptedTransport.map((t) => t['title']).toList(),
          'selected_destinations':
              _acceptedDestinations.map((d) => d['title']).toList(),
          'preferences': {
            'activities': userPrefs.selectedActivities,
            'dietary': userPrefs.selectedDietary,
            'accommodation': userPrefs.selectedAccommodation,
          },
        },
        page: 'home',
      );

      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message': itineraryResponse['response'] ??
              'Here is your personalized itinerary!',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message':
              'I\'ve noted all your preferences! Your itinerary is ready to be finalized.',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    }
  }

  // Get button text based on current stage
  String _getFinishButtonText() {
    switch (_currentSwipeStage) {
      case 'hotels':
        final count = _acceptedAccommodation.length;
        if (count == 0) {
          return 'Skip Hotels - Continue';
        } else if (count == 1) {
          return 'Done with 1 Hotel - Continue';
        } else {
          return 'Done with $count Hotels - Continue';
        }
      case 'transport':
        final count = _acceptedTransport.length;
        if (count == 0) {
          return 'Skip Transport - Continue';
        } else if (count == 1) {
          return 'Done with 1 Transport - Continue';
        } else {
          return 'Done with $count Transport - Continue';
        }
      case 'destinations':
        final count = _acceptedDestinations.length;
        if (count < 2) {
          return 'Select at least 2 destinations';
        } else {
          return 'Done with $count Destinations - Generate Itinerary';
        }
      default:
        return 'Finish Selection';
    }
  }

  // Finish current stage and proceed to next
  void _finishCurrentStage() {
    // Close the swipe overlay
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Proceed based on current stage
    if (_currentSwipeStage == 'hotels') {
      if (_acceptedAccommodation.isEmpty) {
        // Show warning but allow to continue
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No hotels selected. Proceeding to transport...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _proceedToTransportStage();
    } else if (_currentSwipeStage == 'transport') {
      if (_acceptedTransport.isEmpty) {
        // Show warning but allow to continue
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('⚠️ No transport selected. Proceeding to destinations...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _proceedToDestinationsStage();
    } else if (_currentSwipeStage == 'destinations') {
      if (_acceptedDestinations.length < 2) {
        // Don't allow to proceed with less than 2 destinations
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('❌ Please select at least 2 destinations for your trip!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        _generateFinalItinerary();
      }
    }
  }

  Future<List<Map<String, dynamic>>> _generateTransportSuggestions() async {
    // Get source and destination cities for AI transport generation
    final prefsProvider = context.read<UserPreferencesProvider>();
    final fromCity = _fromLocationController.text.isNotEmpty
        ? _fromLocationController.text
        : 'Delhi'; // Use from location input or default
    final toCity = _toLocationController.text.isNotEmpty
        ? _toLocationController.text
        : (_stayCityController.text.isNotEmpty
            ? _stayCityController.text
            : prefsProvider.preferences.destination ?? 'Jaipur');

    final budget = prefsProvider.preferences.budget;
    final selectedTransport = prefsProvider.preferences.selectedTransport;

    print('🚗 Calling AI transport API: $fromCity → $toCity, Budget: $budget');
    print('🎯 User selected transport modes: $selectedTransport');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8001/api/transport/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'from_city': fromCity,
          'to_city': toCity,
          'budget': budget,
          'transport_preferences': selectedTransport,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = (data['suggestions'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        print('✅ Got ${suggestions.length} AI-generated transport options');

        // Filter based on user preferences
        final filtered =
            _filterTransportByPreferences(suggestions, selectedTransport);
        print('✅ After filtering: ${filtered.length} matching options');
        return filtered;
      } else {
        print('⚠️ API returned ${response.statusCode}, using fallback');
        return _getFallbackTransport(fromCity, toCity, selectedTransport);
      }
    } catch (e) {
      print('❌ Error calling transport API: $e');
      return _getFallbackTransport(fromCity, toCity, selectedTransport);
    }
  }

  // Filter transport options based on user preferences
  List<Map<String, dynamic>> _filterTransportByPreferences(
      List<Map<String, dynamic>> options, List<String> preferences) {
    if (preferences.isEmpty) {
      // No preferences selected, show all
      return options;
    }

    // Normalize preferences to lowercase for matching
    final normalizedPrefs = preferences.map((p) => p.toLowerCase()).toList();

    return options.where((option) {
      final title = (option['title'] as String?)?.toLowerCase() ?? '';
      final description =
          (option['description'] as String?)?.toLowerCase() ?? '';

      // Check if option matches any selected preference
      for (final pref in normalizedPrefs) {
        // Map preferences to transport types
        if (pref.contains('flight') || pref.contains('air')) {
          if (title.contains('✈️') ||
              title.contains('flight') ||
              title.contains('indigo') ||
              title.contains('air india') ||
              title.contains('spicejet') ||
              title.contains('vistara')) {
            return true;
          }
        }

        if (pref.contains('train') ||
            pref.contains('rail') ||
            pref.contains('express') ||
            pref.contains('rajdhani') ||
            pref.contains('shatabdi') ||
            pref.contains('vande bharat')) {
          if (title.contains('🚂') ||
              title.contains('train') ||
              title.contains('express') ||
              title.contains('railway')) {
            return true;
          }
        }

        if (pref.contains('road') ||
            pref.contains('bus') ||
            pref.contains('car') ||
            pref.contains('taxi') ||
            pref.contains('volvo') ||
            pref.contains('coach')) {
          if (title.contains('🚌') ||
              title.contains('bus') ||
              title.contains('🚗') ||
              title.contains('car') ||
              title.contains('taxi') ||
              title.contains('volvo')) {
            return true;
          }
        }

        // Direct string matching for other preferences
        if (title.contains(pref) || description.contains(pref)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  List<Map<String, dynamic>> _getFallbackTransport(
      String fromCity, String toCity, List<String> preferences) {
    // Fallback transport options when AI fails
    final allOptions = [
      {
        'id': 'flight_1',
        'type': 'transport',
        'title': '✈️ IndiGo 6E-2031',
        'description':
            '$fromCity → $toCity\nDirect flight • 2h 15min\nDeparture: 06:30 AM\n₹8,500 - ₹12,000 per person',
        'price': 10000,
        'image':
            'https://source.unsplash.com/800x600/?indigo-airlines,airplane,flight',
        'stage': 'transport',
        'details': {
          'carrier': 'IndiGo',
          'flight_number': '6E-2031',
          'departure': '06:30 AM',
          'arrival': '08:45 AM',
          'duration': '2h 15min',
          'type': 'Direct'
        }
      },
      {
        'id': 'flight_2',
        'type': 'transport',
        'title': '✈️ Air India AI-7821',
        'description':
            '$fromCity → $toCity\nDirect flight • 2h 10min\nDeparture: 02:15 PM\n₹7,200 - ₹10,500 per person',
        'price': 8500,
        'image':
            'https://source.unsplash.com/800x600/?air-india,boeing,aircraft',
        'stage': 'transport',
        'details': {
          'carrier': 'Air India',
          'flight_number': 'AI-7821',
          'departure': '02:15 PM',
          'arrival': '04:25 PM',
          'duration': '2h 10min',
          'type': 'Direct'
        }
      },
      {
        'id': 'train_1',
        'type': 'transport',
        'title': '🚂 Rajdhani Express 12432',
        'description':
            '$fromCity → $toCity\n2AC/3AC available • 18-20 hours\nDeparture: 05:30 PM\n₹2,800 - ₹4,200 per person',
        'price': 3500,
        'image':
            'https://source.unsplash.com/800x600/?indian-railways,rajdhani-express,train',
        'stage': 'transport',
        'details': {
          'train_name': 'Rajdhani Express',
          'train_number': '12432',
          'departure': '05:30 PM',
          'arrival': '11:45 AM +1',
          'duration': '18h 15min',
          'class': '2AC/3AC'
        }
      },
      {
        'id': 'train_2',
        'type': 'transport',
        'title': '🚂 Shatabdi Express 12010',
        'description':
            '$fromCity → $toCity\nChair Car/Executive • 15-17 hours\nDeparture: 06:00 AM\n₹1,800 - ₹3,500 per person',
        'price': 2500,
        'image':
            'https://source.unsplash.com/800x600/?shatabdi-express,railway,train',
        'stage': 'transport',
        'details': {
          'train_name': 'Shatabdi Express',
          'train_number': '12010',
          'departure': '06:00 AM',
          'arrival': '09:15 PM',
          'duration': '15h 15min',
          'class': 'CC/EC'
        }
      },
      {
        'id': 'train_3',
        'type': 'transport',
        'title': '🚂 Duronto Express 12213',
        'description':
            '$fromCity → $toCity\nNon-stop train • 16-18 hours\nDeparture: 11:30 PM\n₹2,200 - ₹3,800 per person',
        'price': 3000,
        'image':
            'https://source.unsplash.com/800x600/?duronto-express,indian-train',
        'stage': 'transport',
        'details': {
          'train_name': 'Duronto Express',
          'train_number': '12213',
          'departure': '11:30 PM',
          'arrival': '05:45 PM +1',
          'duration': '18h 15min',
          'class': 'Sleeper/3AC'
        }
      },
      {
        'id': 'bus_1',
        'type': 'transport',
        'title': '🚌 Volvo Multi-Axle AC',
        'description':
            '$fromCity → $toCity\nLuxury sleeper bus • 20-22 hours\nDeparture: 06:00 PM\n₹1,500 - ₹2,800 per person',
        'price': 2000,
        'image':
            'https://source.unsplash.com/800x600/?volvo-bus,luxury-bus,sleeper',
        'stage': 'transport',
        'details': {
          'operator': 'Redbus/RSRTC',
          'bus_type': 'Volvo Multi-Axle AC Sleeper',
          'departure': '06:00 PM',
          'arrival': '02:00 PM +1',
          'duration': '20h',
          'amenities': 'WiFi, Charging, Blankets'
        }
      },
    ];

    // Filter based on user preferences
    return _filterTransportByPreferences(allOptions, preferences);
  }

  List<Map<String, dynamic>> _generateDestinationSuggestions() {
    // Use the TO location (destination city) not the stay city
    // This fixes the issue where traveling From Jaipur To Goa was showing Jaipur attractions
    final city = _toLocationController.text.toLowerCase();

    // Smart destination count based on trip duration:
    // - 1-2 days: 4-6 places (focused visit)
    // - 3-5 days: 7-10 places (balanced)
    // - 6-10 days: 10-15 places (comprehensive)
    // - 10+ days: 15-20 places (extensive exploration)

    final days = _endDate != null && _startDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : 3;

    int maxDestinations;
    if (days <= 2) {
      maxDestinations = 6; // Quick trip - must-see places only
    } else if (days <= 5) {
      maxDestinations = 10; // Medium trip - balanced exploration
    } else if (days <= 10) {
      maxDestinations = 15; // Long trip - comprehensive tour
    } else {
      maxDestinations = 20; // Extended stay - deep exploration
    }

    print(
        '🗓️ Trip duration: $days days → Showing up to $maxDestinations places to visit in $city');

    // Generate places to visit WITHIN the destination city
    List<Map<String, dynamic>> attractions = [];

    if (city.contains('jaipur')) {
      attractions = [
        {
          'id': 'hawa_mahal',
          'type': 'destination',
          'title': 'Hawa Mahal - Palace of Winds',
          'description':
              'Iconic pink sandstone palace\n953 windows & intricate lattice\nPerfect for photography',
          'image':
              'https://source.unsplash.com/800x600/?hawa-mahal,jaipur,rajasthan',
          'stage': 'destinations',
        },
        {
          'id': 'amber_fort',
          'type': 'destination',
          'title': 'Amber Fort',
          'description':
              'Majestic hilltop fort\nElephant rides available\nSheesh Mahal mirror palace',
          'image':
              'https://source.unsplash.com/800x600/?amber-fort,jaipur,palace',
          'stage': 'destinations',
        },
        {
          'id': 'city_palace',
          'type': 'destination',
          'title': 'City Palace Jaipur',
          'description':
              'Royal residence & museums\nCourtyards and gardens\nRajasthani architecture',
          'image':
              'https://source.unsplash.com/800x600/?city-palace,jaipur,museum',
          'stage': 'destinations',
        },
        {
          'id': 'jantar_mantar',
          'type': 'destination',
          'title': 'Jantar Mantar',
          'description':
              'UNESCO World Heritage site\nAstronomical observatory\n18th century instruments',
          'image':
              'https://source.unsplash.com/800x600/?jantar-mantar,jaipur,observatory',
          'stage': 'destinations',
        },
        {
          'id': 'nahargarh_fort',
          'type': 'destination',
          'title': 'Nahargarh Fort',
          'description':
              'Stunning sunset views\nOverlooks Pink City\nRang De Basanti filming location',
          'image':
              'https://source.unsplash.com/800x600/?nahargarh-fort,jaipur,sunset',
          'stage': 'destinations',
        },
        {
          'id': 'jal_mahal',
          'type': 'destination',
          'title': 'Jal Mahal - Water Palace',
          'description':
              'Palace in Man Sagar Lake\nBeautiful photo spot\nEvening boat rides',
          'image': 'https://source.unsplash.com/800x600/?jal-mahal,jaipur,lake',
          'stage': 'destinations',
        },
        {
          'id': 'albert_hall',
          'type': 'destination',
          'title': 'Albert Hall Museum',
          'description':
              'Oldest museum in Rajasthan\nIndo-Saracenic architecture\nEgyptian mummy collection',
          'image':
              'https://source.unsplash.com/800x600/?albert-hall,jaipur,museum',
          'stage': 'destinations',
        },
        {
          'id': 'jaigarh_fort',
          'type': 'destination',
          'title': 'Jaigarh Fort',
          'description':
              'World\'s largest cannon\nVictory Fort\nPanoramic city views',
          'image':
              'https://source.unsplash.com/800x600/?jaigarh-fort,jaipur,cannon',
          'stage': 'destinations',
        },
        {
          'id': 'johari_bazaar',
          'type': 'destination',
          'title': 'Johari Bazaar',
          'description':
              'Jewelry shopping paradise\nTraditional Rajasthani items\nLively market atmosphere',
          'image':
              'https://source.unsplash.com/800x600/?johari-bazaar,jaipur,market',
          'stage': 'destinations',
        },
        {
          'id': 'bapu_bazaar',
          'type': 'destination',
          'title': 'Bapu Bazaar',
          'description':
              'Textiles & handicrafts\nJuttis and mojaris\nLocal street food',
          'image':
              'https://source.unsplash.com/800x600/?bapu-bazaar,jaipur,shopping',
          'stage': 'destinations',
        },
        {
          'id': 'chokhi_dhani',
          'type': 'destination',
          'title': 'Chokhi Dhani',
          'description':
              'Rajasthani village resort\nCultural shows & folk dance\nTraditional thali dinner',
          'image':
              'https://source.unsplash.com/800x600/?chokhi-dhani,jaipur,cultural',
          'stage': 'destinations',
        },
        {
          'id': 'sisodia_rani',
          'type': 'destination',
          'title': 'Sisodia Rani Garden',
          'description':
              'Beautiful Mughal garden\nFountains and pavilions\nPeaceful retreat',
          'image':
              'https://source.unsplash.com/800x600/?sisodia-garden,jaipur,palace',
          'stage': 'destinations',
        },
        {
          'id': 'galtaji_temple',
          'type': 'destination',
          'title': 'Galtaji Temple - Monkey Temple',
          'description':
              'Ancient Hindu pilgrimage\nNatural water springs\nPlayful monkeys',
          'image': 'https://source.unsplash.com/800x600/?galtaji,jaipur,temple',
          'stage': 'destinations',
        },
        {
          'id': 'birla_mandir',
          'type': 'destination',
          'title': 'Birla Mandir',
          'description':
              'White marble temple\nLaxmi Narayan temple\nEvening aarti ceremony',
          'image':
              'https://source.unsplash.com/800x600/?birla-temple,jaipur,marble',
          'stage': 'destinations',
        },
        {
          'id': 'lmb_restaurant',
          'type': 'destination',
          'title': 'LMB Restaurant',
          'description':
              'Famous vegetarian food\nGheewar and dal baati\nTraditional Rajasthani thali',
          'image':
              'https://source.unsplash.com/800x600/?rajasthani-food,thali,restaurant',
          'stage': 'destinations',
        },
        {
          'id': 'statue_circle',
          'type': 'destination',
          'title': 'Statue Circle',
          'description':
              'Maharaja Sawai Jai Singh II statue\nCentral landmark\nEvening hangout spot',
          'image':
              'https://source.unsplash.com/800x600/?statue-circle,jaipur,landmark',
          'stage': 'destinations',
        },
        {
          'id': 'raj_mandir',
          'type': 'destination',
          'title': 'Raj Mandir Cinema',
          'description':
              'Iconic movie theater\nArt Deco architecture\nUnique Bollywood experience',
          'image':
              'https://source.unsplash.com/800x600/?raj-mandir,jaipur,cinema',
          'stage': 'destinations',
        },
        {
          'id': 'world_trade_park',
          'type': 'destination',
          'title': 'World Trade Park',
          'description':
              'Modern shopping mall\nBrands and food court\nEntertainment zone',
          'image':
              'https://source.unsplash.com/800x600/?shopping-mall,jaipur,modern',
          'stage': 'destinations',
        },
        {
          'id': 'central_park',
          'type': 'destination',
          'title': 'Central Park Jaipur',
          'description':
              'Large urban park\nJogging track & gardens\nMusical fountain',
          'image':
              'https://source.unsplash.com/800x600/?central-park,jaipur,garden',
          'stage': 'destinations',
        },
        {
          'id': 'masala_chowk',
          'type': 'destination',
          'title': 'Masala Chowk Food Court',
          'description':
              'Street food paradise\nLaal maas and pyaaz kachori\nLocal delicacies',
          'image':
              'https://source.unsplash.com/800x600/?street-food,jaipur,kachori',
          'stage': 'destinations',
        },
      ];
    } else if (city.contains('goa')) {
      attractions = [
        {
          'id': 'calangute_beach',
          'type': 'destination',
          'title': 'Calangute Beach',
          'description':
              'Popular beach with water sports\nVibrant nightlife nearby\nPerfect for swimming',
          'image': 'https://source.unsplash.com/800x600/?calangute-beach,goa',
          'stage': 'destinations',
        },
        {
          'id': 'baga_beach',
          'type': 'destination',
          'title': 'Baga Beach',
          'description':
              'Famous for nightclubs\nWater sports available\nLively atmosphere',
          'image': 'https://source.unsplash.com/800x600/?baga-beach,goa',
          'stage': 'destinations',
        },
        {
          'id': 'aguada_fort',
          'type': 'destination',
          'title': 'Aguada Fort',
          'description':
              'Historic Portuguese fort\nStunning sunset views\nGreat for photography',
          'image': 'https://source.unsplash.com/800x600/?aguada-fort,goa',
          'stage': 'destinations',
        },
        {
          'id': 'dudhsagar_falls',
          'type': 'destination',
          'title': 'Dudhsagar Falls',
          'description':
              'Spectacular waterfall\nTrekking adventure\nNature photography',
          'image': 'https://source.unsplash.com/800x600/?dudhsagar-falls,goa',
          'stage': 'destinations',
        },
        {
          'id': 'old_goa',
          'type': 'destination',
          'title': 'Old Goa Churches',
          'description':
              'UNESCO World Heritage\nBeautiful architecture\nCultural experience',
          'image': 'https://source.unsplash.com/800x600/?old-goa,church',
          'stage': 'destinations',
        },
        {
          'id': 'palolem_beach',
          'type': 'destination',
          'title': 'Palolem Beach',
          'description':
              'Serene crescent beach\nDolphin watching\nYoga and wellness',
          'image': 'https://source.unsplash.com/800x600/?palolem-beach,goa',
          'stage': 'destinations',
        },
        {
          'id': 'anjuna_flea_market',
          'type': 'destination',
          'title': 'Anjuna Flea Market',
          'description':
              'Vibrant shopping\nLocal crafts and jewelry\nEvery Wednesday',
          'image': 'https://source.unsplash.com/800x600/?anjuna-market,goa',
          'stage': 'destinations',
        },
        {
          'id': 'spice_plantation',
          'type': 'destination',
          'title': 'Spice Plantation Tour',
          'description':
              'Aromatic spice gardens\nTraditional Goan lunch\nNature walk',
          'image': 'https://source.unsplash.com/800x600/?spice-plantation,goa',
          'stage': 'destinations',
        },
        {
          'id': 'chapora_fort',
          'type': 'destination',
          'title': 'Chapora Fort',
          'description': 'Dil Chahta Hai fort\nPanoramic views\nSunset spot',
          'image': 'https://source.unsplash.com/800x600/?chapora-fort,goa',
          'stage': 'destinations',
        },
        {
          'id': 'grand_island',
          'type': 'destination',
          'title': 'Grand Island',
          'description':
              'Scuba diving paradise\nSnorkeling spots\nDolphin sighting',
          'image': 'https://source.unsplash.com/800x600/?grand-island,goa',
          'stage': 'destinations',
        },
      ];
    } else if (city.contains('raipur')) {
      attractions = [
        {
          'id': 'naya_raipur',
          'type': 'destination',
          'title': 'Naya Raipur',
          'description':
              'Planned smart city\nModern infrastructure\nJungle Safari Park',
          'image':
              'https://source.unsplash.com/800x600/?naya-raipur,chhattisgarh',
          'stage': 'destinations',
        },
        {
          'id': 'mahant_ghasidas',
          'type': 'destination',
          'title': 'Mahant Ghasidas Museum',
          'description':
              'State museum\nTribal artifacts\nHistorical collection',
          'image':
              'https://source.unsplash.com/800x600/?museum,raipur,chhattisgarh',
          'stage': 'destinations',
        },
        {
          'id': 'swami_vivekananda_sarovar',
          'type': 'destination',
          'title': 'Swami Vivekananda Sarovar',
          'description':
              'Beautiful lake & gardens\nBoating facility\nEvening recreation',
          'image':
              'https://source.unsplash.com/800x600/?lake,raipur,chhattisgarh',
          'stage': 'destinations',
        },
        {
          'id': 'purkhouti_muktangan',
          'type': 'destination',
          'title': 'Purkhouti Muktangan',
          'description':
              'Tribal cultural museum\nOpen-air exhibition\nChhattisgarh heritage',
          'image':
              'https://source.unsplash.com/800x600/?cultural-center,chhattisgarh',
          'stage': 'destinations',
        },
        {
          'id': 'nandan_van_zoo',
          'type': 'destination',
          'title': 'Nandan Van Zoo & Safari',
          'description':
              'Modern zoo & safari\nWildlife conservation\nFamily-friendly',
          'image': 'https://source.unsplash.com/800x600/?zoo,safari,wildlife',
          'stage': 'destinations',
        },
        {
          'id': 'ghatarani_falls',
          'type': 'destination',
          'title': 'Ghatarani Waterfalls',
          'description':
              'Scenic waterfall\n90 km from Raipur\nTrekking & photography',
          'image':
              'https://source.unsplash.com/800x600/?waterfall,chhattisgarh',
          'stage': 'destinations',
        },
        {
          'id': 'barnawapara',
          'type': 'destination',
          'title': 'Barnawapara Wildlife Sanctuary',
          'description':
              'Wildlife sanctuary\nLeopards & sloth bears\nNature trails',
          'image':
              'https://source.unsplash.com/800x600/?wildlife-sanctuary,forest',
          'stage': 'destinations',
        },
        {
          'id': 'marine_drive_raipur',
          'type': 'destination',
          'title': 'Marine Drive Raipur',
          'description': 'Scenic lake promenade\nEvening walks\nFood stalls',
          'image': 'https://source.unsplash.com/800x600/?marine-drive,raipur',
          'stage': 'destinations',
        },
        {
          'id': 'magneto_mall',
          'type': 'destination',
          'title': 'Magneto The Mall',
          'description':
              'Modern shopping mall\nBrands & food court\nEntertainment',
          'image': 'https://source.unsplash.com/800x600/?shopping-mall,raipur',
          'stage': 'destinations',
        },
        {
          'id': 'city_centre_mall',
          'type': 'destination',
          'title': 'City Centre Mall',
          'description':
              'Large shopping center\nMultiplex cinema\nDining options',
          'image': 'https://source.unsplash.com/800x600/?mall,shopping',
          'stage': 'destinations',
        },
        {
          'id': 'sirpur',
          'type': 'destination',
          'title': 'Sirpur Archaeological Site',
          'description':
              'Ancient Buddhist site\n80 km from Raipur\nHistorical temples',
          'image':
              'https://source.unsplash.com/800x600/?ancient-temple,archaeological',
          'stage': 'destinations',
        },
        {
          'id': 'mahakoshal_art_gallery',
          'type': 'destination',
          'title': 'Mahakoshal Art Gallery',
          'description':
              'Contemporary art\nLocal artists\nCultural exhibitions',
          'image': 'https://source.unsplash.com/800x600/?art-gallery,paintings',
          'stage': 'destinations',
        },
        {
          'id': 'kanan_pendari_zoo',
          'type': 'destination',
          'title': 'Kanan Pendari Zoo',
          'description': 'Mini zoo in city\nLocal wildlife\nFamily outing',
          'image': 'https://source.unsplash.com/800x600/?zoo,animals',
          'stage': 'destinations',
        },
        {
          'id': 'budha_talab',
          'type': 'destination',
          'title': 'Budha Talab',
          'description': 'Historic pond\nBird watching\nMorning walks',
          'image': 'https://source.unsplash.com/800x600/?pond,birds,park',
          'stage': 'destinations',
        },
        {
          'id': 'mm_fun_city',
          'type': 'destination',
          'title': 'MM Fun City',
          'description':
              'Water park & amusement\nSlides & wave pool\nFamily fun',
          'image': 'https://source.unsplash.com/800x600/?water-park,amusement',
          'stage': 'destinations',
        },
      ];
    } else {
      // Default places for other cities
      attractions = [
        {
          'id': 'place_1',
          'type': 'destination',
          'title': 'Historic Monuments',
          'description':
              'Explore ancient architecture\nRich cultural heritage\nGuided tours available',
          'image':
              'https://source.unsplash.com/800x600/?monument,heritage,india',
          'stage': 'destinations',
        },
        {
          'id': 'place_2',
          'type': 'destination',
          'title': 'Local Markets',
          'description':
              'Shopping and street food\nAuthentic local experience\nHandicrafts & souvenirs',
          'image': 'https://source.unsplash.com/800x600/?market,bazaar,india',
          'stage': 'destinations',
        },
        {
          'id': 'place_3',
          'type': 'destination',
          'title': 'Nature Parks',
          'description':
              'Scenic views and wildlife\nPerfect for relaxation\nFamily-friendly',
          'image': 'https://source.unsplash.com/800x600/?park,garden,nature',
          'stage': 'destinations',
        },
        {
          'id': 'place_4',
          'type': 'destination',
          'title': 'Cultural Centers',
          'description':
              'Museums and art galleries\nLocal traditions\nCultural shows',
          'image': 'https://source.unsplash.com/800x600/?museum,culture,india',
          'stage': 'destinations',
        },
        {
          'id': 'place_5',
          'type': 'destination',
          'title': 'Food Street',
          'description':
              'Famous food joints\nLocal cuisine tasting\nStreet food paradise',
          'image':
              'https://source.unsplash.com/800x600/?street-food,restaurant,india',
          'stage': 'destinations',
        },
        {
          'id': 'place_6',
          'type': 'destination',
          'title': 'Religious Sites',
          'description':
              'Temples and spiritual places\nPeaceful atmosphere\nArchitectural beauty',
          'image': 'https://source.unsplash.com/800x600/?temple,mosque,church',
          'stage': 'destinations',
        },
        {
          'id': 'place_7',
          'type': 'destination',
          'title': 'Shopping Malls',
          'description':
              'Modern retail centers\nBrands & food courts\nEntertainment zones',
          'image': 'https://source.unsplash.com/800x600/?shopping-mall,modern',
          'stage': 'destinations',
        },
        {
          'id': 'place_8',
          'type': 'destination',
          'title': 'Waterfront',
          'description':
              'Lakes & river views\nBoating & recreation\nEvening hangout',
          'image': 'https://source.unsplash.com/800x600/?lake,waterfront,india',
          'stage': 'destinations',
        },
      ];
    }

    return attractions.take(maxDestinations).toList();
  }

  // Show AI-powered transport comparison
  Future<void> _showTransportComparison() async {
    // Close the swipe overlay
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isTyping = true;
      _messages.add({
        'sender': 'triplix',
        'message':
            'Great! You\'ve selected 2 transport options. Let me analyze and compare them for you using AI...',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();

    try {
      // Call AI to compare transport options
      final comparison = await _pythonADK.sendToManager(
        message:
            'Compare these two transport options and help me decide which is better',
        context: {
          'page': 'home',
          'action': 'compare_transport',
          'options': _acceptedTransport,
        },
        page: 'home',
      );

      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message': comparison['response'] ??
              'Here is the comparison of your transport options:',
          'type': 'comparison',
          'comparison_data': {
            'type': 'transport',
            'options': _acceptedTransport,
            'ai_analysis':
                comparison['analysis'] ?? 'Both options are good choices.',
          },
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message':
              'Here are your selected transport options. Which one would you like to confirm?',
          'type': 'comparison',
          'comparison_data': {
            'type': 'transport',
            'options': _acceptedTransport,
          },
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    }
  }

  // Show AI-powered accommodation comparison
  Future<void> _showAccommodationComparison() async {
    // Close the swipe overlay
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isTyping = true;
      _messages.add({
        'sender': 'triplix',
        'message':
            'Perfect! You\'ve selected 2 accommodations. Let me compare them for you...',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();

    try {
      // Call AI to compare accommodation options
      final comparison = await _pythonADK.sendToManager(
        message:
            'Compare these two accommodation options and help me decide which is better',
        context: {
          'page': 'home',
          'action': 'compare_accommodation',
          'options': _acceptedAccommodation,
        },
        page: 'home',
      );

      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message': comparison['response'] ??
              'Here is the comparison of your accommodation options:',
          'type': 'comparison',
          'comparison_data': {
            'type': 'accommodation',
            'options': _acceptedAccommodation,
            'ai_analysis':
                comparison['analysis'] ?? 'Both options are excellent choices.',
          },
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'triplix',
          'message':
              'Here are your selected accommodations. Which one would you like to confirm?',
          'type': 'comparison',
          'comparison_data': {
            'type': 'accommodation',
            'options': _acceptedAccommodation,
          },
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    }
  }

  // Ask for destination replacement
  Future<void> _askForDestinationReplacement(
      Map<String, dynamic> suggestion) async {
    setState(() {
      _messages.add({
        'sender': 'triplix',
        'message':
            'You removed "${suggestion['title']}" from your itinerary. Would you like me to suggest a replacement?',
        'type': 'replacement_prompt',
        'removed_item': suggestion,
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();
  }

  void _handleReplacementResponse(
      bool wantsReplacement, Map<String, dynamic> removedItem) async {
    if (wantsReplacement) {
      setState(() {
        _isTyping = true;
        _messages.add({
          'sender': 'user',
          'message': 'Yes, show me alternatives',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();

      try {
        // Call AI to get replacement suggestions
        final replacement = await _pythonADK.sendToManager(
          message: 'Find alternatives for ${removedItem['title']}',
          context: {
            'page': 'home',
            'action': 'find_replacement',
            'removed_item': removedItem,
            'type': 'destination',
          },
          page: 'home',
        );

        final replacementSuggestions =
            replacement['suggestions'] as List<dynamic>? ?? [];

        setState(() {
          _isTyping = false;
          if (replacementSuggestions.isNotEmpty) {
            _messages.add({
              'sender': 'triplix',
              'message': 'Here are some great alternatives for you!',
              'type': 'suggestions',
              'suggestions': replacementSuggestions,
              'timestamp': DateTime.now().toString(),
            });
            _currentSuggestions =
                replacementSuggestions.cast<Map<String, dynamic>>();
          } else {
            _messages.add({
              'sender': 'triplix',
              'message':
                  'I apologize, but I couldn\'t find suitable alternatives at the moment. Would you like to try different criteria?',
              'type': 'text',
              'timestamp': DateTime.now().toString(),
            });
          }
        });
        _scrollToBottom();
      } catch (e) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'triplix',
            'message':
                'I had trouble finding alternatives. Please try again or let me know your preferences.',
            'type': 'text',
            'timestamp': DateTime.now().toString(),
          });
        });
        _scrollToBottom();
      }
    } else {
      setState(() {
        _messages.add({
          'sender': 'user',
          'message': 'No, thanks',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
        _messages.add({
          'sender': 'triplix',
          'message': 'No problem! Continue exploring other destinations.',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    }
  }

  void _confirmSelection(String type, Map<String, dynamic> selectedOption) {
    setState(() {
      _messages.add({
        'sender': 'user',
        'message': 'I choose: ${selectedOption['title']}',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
      _messages.add({
        'sender': 'triplix',
        'message':
            'Excellent choice! "${selectedOption['title']}" has been added to your itinerary. Let\'s continue with your planning!',
        'type': 'text',
        'timestamp': DateTime.now().toString(),
      });
    });
    _scrollToBottom();

    // Move to next stage
    if (type == 'transport') {
      _currentSwipeStage = 'accommodation';
      // Show accommodation suggestions
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _messages.add({
            'sender': 'triplix',
            'message':
                'Now let\'s find you the perfect accommodation! Swipe right on 2 options you like.',
            'type': 'suggestions',
            'suggestions': _generateStageSpecificSuggestions('accommodation'),
            'timestamp': DateTime.now().toString(),
          });
          _currentSuggestions =
              _generateStageSpecificSuggestions('accommodation');
        });
        _scrollToBottom();
      });
    } else if (type == 'accommodation') {
      _currentSwipeStage = 'destinations';
      // Show destination suggestions
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _messages.add({
            'sender': 'triplix',
            'message':
                'Great! Now let\'s explore destinations. I\'ll show you 10 amazing places. Swipe left if you\'re not interested!',
            'type': 'suggestions',
            'suggestions': _generateStageSpecificSuggestions('destinations'),
            'timestamp': DateTime.now().toString(),
          });
          _currentSuggestions =
              _generateStageSpecificSuggestions('destinations');
        });
        _scrollToBottom();
      });
    }
  }

  List<Map<String, dynamic>> _generateStageSpecificSuggestions(String stage) {
    switch (stage) {
      case 'transport':
        return [
          {
            'id': 'transport_1',
            'type': 'transport',
            'title': 'Private Car with Driver',
            'description':
                'Comfortable AC sedan with experienced driver for city tours and airport transfers',
            'price': 2500,
            'rating': 4.5,
          },
          {
            'id': 'transport_2',
            'type': 'transport',
            'title': 'Express Train First Class',
            'description':
                'High-speed rail with comfortable seating, meals included, and scenic route views',
            'price': 1800,
            'rating': 4.6,
          },
          {
            'id': 'transport_3',
            'type': 'transport',
            'title': 'Domestic Flight Economy',
            'description':
                'Direct flight with major airline, checked baggage included, fastest option',
            'price': 4500,
            'rating': 4.7,
          },
          {
            'id': 'transport_4',
            'type': 'transport',
            'title': 'Luxury Coach Bus',
            'description':
                'Premium bus service with reclining seats, entertainment, and refreshments',
            'price': 1200,
            'rating': 4.3,
          },
          {
            'id': 'transport_5',
            'type': 'transport',
            'title': 'Bike Rental Package',
            'description':
                'Self-drive motorcycle rental with helmet, insurance, and roadside assistance',
            'price': 800,
            'rating': 4.4,
          },
        ];

      case 'accommodation':
        return [
          {
            'id': 'hotel_1',
            'type': 'hotel',
            'title': 'Luxury Beach Resort',
            'description':
                '5-star beachfront resort with private villas, spa, and infinity pool',
            'price': 12500,
            'rating': 4.8,
          },
          {
            'id': 'hotel_2',
            'type': 'hotel',
            'title': 'Heritage Palace Hotel',
            'description':
                'Restored 18th-century palace with royal suites and cultural performances',
            'price': 8500,
            'rating': 4.7,
          },
          {
            'id': 'hotel_3',
            'type': 'hotel',
            'title': 'Mountain View Resort',
            'description':
                'Scenic hillside property with valley views and adventure sports',
            'price': 6500,
            'rating': 4.6,
          },
          {
            'id': 'hotel_4',
            'type': 'hotel',
            'title': 'Business Class Hotel',
            'description':
                'Modern business hotel in city center with conference facilities',
            'price': 5500,
            'rating': 4.5,
          },
          {
            'id': 'hotel_5',
            'type': 'hotel',
            'title': 'Budget Boutique Inn',
            'description':
                'Cozy boutique hotel with comfortable rooms and complimentary breakfast',
            'price': 3500,
            'rating': 4.4,
          },
        ];

      case 'destinations':
        return [
          {
            'id': 'destination_1',
            'type': 'destination',
            'title': 'City Heritage Walk',
            'description':
                'Guided walking tour through historic forts, markets, and colonial architecture',
            'price': 800,
            'rating': 4.6,
          },
          {
            'id': 'destination_2',
            'type': 'destination',
            'title': 'Beach Paradise',
            'description':
                'Pristine beaches with water sports, seafood shacks, and stunning sunset views',
            'price': 500,
            'rating': 4.8,
          },
          {
            'id': 'destination_3',
            'type': 'destination',
            'title': 'Mountain Adventure Trail',
            'description':
                'Trekking route through pine forests, waterfalls, and panoramic viewpoints',
            'price': 1200,
            'rating': 4.7,
          },
          {
            'id': 'destination_4',
            'type': 'destination',
            'title': 'Ancient Temple Complex',
            'description':
                'UNESCO heritage site with intricate carvings, spiritual ambiance, and history',
            'price': 300,
            'rating': 4.9,
          },
          {
            'id': 'destination_5',
            'type': 'destination',
            'title': 'Wildlife Safari Park',
            'description':
                'Jungle safari with chances to spot tigers, elephants, and exotic birds',
            'price': 2500,
            'rating': 4.8,
          },
          {
            'id': 'destination_6',
            'type': 'destination',
            'title': 'Local Food Market Tour',
            'description':
                'Culinary journey through bustling markets, street food, and cooking classes',
            'price': 600,
            'rating': 4.5,
          },
          {
            'id': 'destination_7',
            'type': 'destination',
            'title': 'Art Gallery District',
            'description':
                'Contemporary art galleries, street murals, and artisan workshops',
            'price': 400,
            'rating': 4.4,
          },
          {
            'id': 'destination_8',
            'type': 'destination',
            'title': 'Sunset Cruise',
            'description':
                'Relaxing boat ride with live music, dinner, and spectacular coastal views',
            'price': 1800,
            'rating': 4.7,
          },
          {
            'id': 'destination_9',
            'type': 'destination',
            'title': 'Adventure Theme Park',
            'description':
                'Thrilling rides, water slides, and family-friendly entertainment',
            'price': 1500,
            'rating': 4.6,
          },
          {
            'id': 'destination_10',
            'type': 'destination',
            'title': 'Spa & Wellness Retreat',
            'description':
                'Rejuvenating spa treatments, yoga sessions, and meditation in tranquil gardens',
            'price': 3500,
            'rating': 4.8,
          },
        ];

      default:
        return [];
    }
  }

  void _handleAcceptedSuggestion(Map<String, dynamic> suggestion) {
    // Check if this matches user preferences/checklist
    final provider = context.read<UserPreferencesProvider>();
    final userPrefs = provider.preferences;

    final matches = _checkSuggestionAgainstChecklist(suggestion, userPrefs);
    final matchMessage = matches.isNotEmpty
        ? 'This matches your preferences: ${matches.join(", ")}'
        : 'This has been added to your itinerary';

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          'sender': 'triplix',
          'message':
              'Great choice! "${suggestion['title']}" has been added to your itinerary. $matchMessage. Would you like me to suggest something else?',
          'type': 'text',
          'timestamp': DateTime.now().toString(),
        });
      });
      _scrollToBottom();
    });
  }

  List<String> _checkSuggestionAgainstChecklist(
      Map<String, dynamic> suggestion, userPrefs) {
    final matches = <String>[];
    final type = suggestion['type'] ?? 'general';
    final title = suggestion['title']?.toString().toLowerCase() ?? '';
    final description =
        suggestion['description']?.toString().toLowerCase() ?? '';

    switch (type) {
      case 'hotel':
        // Check accommodation preferences
        if (userPrefs.selectedAccommodation.isNotEmpty) {
          for (final pref in userPrefs.selectedAccommodation) {
            if (title.contains(pref.toLowerCase()) ||
                description.contains(pref.toLowerCase())) {
              matches.add('Accommodation: $pref');
            }
          }
        }
        // Check budget
        if (userPrefs.hasBudget && suggestion['price'] != null) {
          final price = suggestion['price'] as num;
          if (price <= userPrefs.budget!) {
            matches.add('Within budget (₹${userPrefs.budget})');
          }
        }
        break;

      case 'activity':
        // Check activity preferences
        if (userPrefs.selectedActivities.isNotEmpty) {
          for (final activity in userPrefs.selectedActivities) {
            if (title.contains(activity.toLowerCase()) ||
                description.contains(activity.toLowerCase())) {
              matches.add('Activity: $activity');
            }
          }
        }
        // Check sun activities
        if (userPrefs.selectedSunActivities.isNotEmpty) {
          for (final sunActivity in userPrefs.selectedSunActivities) {
            if (title.contains(sunActivity.toLowerCase()) ||
                description.contains(sunActivity.toLowerCase())) {
              matches.add('Sun Activity: $sunActivity');
            }
          }
        }
        break;

      case 'restaurant':
        // Check dietary preferences
        if (userPrefs.selectedDietary.isNotEmpty) {
          for (final dietary in userPrefs.selectedDietary) {
            if (description.contains(dietary.toLowerCase())) {
              matches.add('Dietary: $dietary');
            }
          }
        }
        break;

      case 'transport':
        // Check transport preferences
        if (userPrefs.selectedTransport.isNotEmpty) {
          for (final transport in userPrefs.selectedTransport) {
            if (title.contains(transport.toLowerCase()) ||
                description.contains(transport.toLowerCase())) {
              matches.add('Transport: $transport');
            }
          }
        }
        break;
    }

    // Check general preferences
    if (userPrefs.hasCompanion && userPrefs.companion != null) {
      final companion = userPrefs.companion!.toLowerCase();
      if (description.contains(companion)) {
        matches.add('Companion: ${userPrefs.companion}');
      }
    }

    if (userPrefs.hasOccasion && userPrefs.occasion != null) {
      final occasion = userPrefs.occasion!.toLowerCase();
      if (description.contains(occasion)) {
        matches.add('Occasion: ${userPrefs.occasion}');
      }
    }

    return matches;
  }

  void _handleRejectedSuggestion(Map<String, dynamic> suggestion) {
    // Just track the rejection, don't show alternatives in chat
    // User can continue swiping through current suggestions
  }

  List<Map<String, dynamic>> _generateAlternativeSuggestions(
      Map<String, dynamic> rejectedSuggestion) {
    final type = rejectedSuggestion['type'] ?? 'general';

    // Generate alternative suggestions based on type
    // This would ideally come from the AI backend
    switch (type) {
      case 'hotel':
        return [
          {
            'id': 'alt_hotel_1',
            'type': 'hotel',
            'title': 'Luxury Resort Alternative',
            'description':
                'A premium resort with spa facilities and ocean views',
            'price': 8500,
            'rating': 4.5,
          },
          {
            'id': 'alt_hotel_2',
            'type': 'hotel',
            'title': 'Boutique Hotel Option',
            'description': 'Charming boutique hotel in the city center',
            'price': 6200,
            'rating': 4.2,
          },
        ];
      case 'activity':
        return [
          {
            'id': 'alt_activity_1',
            'type': 'activity',
            'title': 'Cultural Experience',
            'description':
                'Explore local culture through traditional arts and crafts',
            'price': 1200,
            'rating': 4.3,
          },
          {
            'id': 'alt_activity_2',
            'type': 'activity',
            'title': 'Adventure Alternative',
            'description':
                'Thrilling outdoor adventure with professional guides',
            'price': 2500,
            'rating': 4.7,
          },
        ];
      default:
        return [
          {
            'id': 'alt_general_1',
            'type': 'general',
            'title': 'Popular Local Experience',
            'description':
                'A highly rated local experience recommended by travelers',
            'price': 1800,
            'rating': 4.4,
          },
        ];
    }
  }

  void _showSwipeFeedback(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _generateInitialSuggestions() {
    // Generate initial suggestions: 5 hotels, 5 transport, 10 destinations
    final suggestions = <Map<String, dynamic>>[];

    // Add 5 hotels
    suggestions.addAll([
      {
        'id': 'hotel_1',
        'type': 'hotel',
        'title': 'Luxury Beach Resort',
        'description':
            '5-star beachfront resort with private villas, spa, and infinity pool overlooking the Arabian Sea',
        'price': 12500,
        'rating': 4.8,
      },
      {
        'id': 'hotel_2',
        'type': 'hotel',
        'title': 'Heritage Palace Hotel',
        'description':
            'Restored 18th-century palace with royal suites, traditional dining, and cultural performances',
        'price': 8500,
        'rating': 4.7,
      },
      {
        'id': 'hotel_3',
        'type': 'hotel',
        'title': 'Mountain View Resort',
        'description':
            'Scenic hillside property with valley views, adventure sports, and organic farm-to-table restaurant',
        'price': 6500,
        'rating': 4.6,
      },
      {
        'id': 'hotel_4',
        'type': 'hotel',
        'title': 'Business Class Hotel',
        'description':
            'Modern business hotel in city center with conference facilities, gym, and rooftop bar',
        'price': 5500,
        'rating': 4.5,
      },
      {
        'id': 'hotel_5',
        'type': 'hotel',
        'title': 'Budget Boutique Inn',
        'description':
            'Cozy boutique hotel with comfortable rooms, local charm, and complimentary breakfast',
        'price': 3500,
        'rating': 4.4,
      },
    ]);

    // Add 5 transport options
    suggestions.addAll([
      {
        'id': 'transport_1',
        'type': 'transport',
        'title': 'Private Car with Driver',
        'description':
            'Comfortable AC sedan with experienced driver for city tours and airport transfers',
        'price': 2500,
        'rating': 4.5,
      },
      {
        'id': 'transport_2',
        'type': 'transport',
        'title': 'Express Train First Class',
        'description':
            'High-speed rail with comfortable seating, meals included, and scenic route views',
        'price': 1800,
        'rating': 4.6,
      },
      {
        'id': 'transport_3',
        'type': 'transport',
        'title': 'Domestic Flight Economy',
        'description':
            'Direct flight with major airline, checked baggage included, fastest option',
        'price': 4500,
        'rating': 4.7,
      },
      {
        'id': 'transport_4',
        'type': 'transport',
        'title': 'Luxury Coach Bus',
        'description':
            'Premium bus service with reclining seats, entertainment, and refreshments',
        'price': 1200,
        'rating': 4.3,
      },
      {
        'id': 'transport_5',
        'type': 'transport',
        'title': 'Bike Rental Package',
        'description':
            'Self-drive motorcycle rental with helmet, insurance, and roadside assistance',
        'price': 800,
        'rating': 4.4,
      },
    ]);

    // Add 10 destinations
    suggestions.addAll([
      {
        'id': 'destination_1',
        'type': 'destination',
        'title': 'City Heritage Walk',
        'description':
            'Guided walking tour through historic forts, markets, and colonial architecture',
        'price': 800,
        'rating': 4.6,
      },
      {
        'id': 'destination_2',
        'type': 'destination',
        'title': 'Beach Paradise',
        'description':
            'Pristine beaches with water sports, seafood shacks, and stunning sunset views',
        'price': 500,
        'rating': 4.8,
      },
      {
        'id': 'destination_3',
        'type': 'destination',
        'title': 'Mountain Adventure Trail',
        'description':
            'Trekking route through pine forests, waterfalls, and panoramic viewpoints',
        'price': 1200,
        'rating': 4.7,
      },
      {
        'id': 'destination_4',
        'type': 'destination',
        'title': 'Ancient Temple Complex',
        'description':
            'UNESCO heritage site with intricate carvings, spiritual ambiance, and history',
        'price': 300,
        'rating': 4.9,
      },
      {
        'id': 'destination_5',
        'type': 'destination',
        'title': 'Wildlife Safari Park',
        'description':
            'Jungle safari with chances to spot tigers, elephants, and exotic birds',
        'price': 2500,
        'rating': 4.8,
      },
      {
        'id': 'destination_6',
        'type': 'destination',
        'title': 'Local Food Market Tour',
        'description':
            'Culinary journey through bustling markets, street food, and cooking classes',
        'price': 600,
        'rating': 4.5,
      },
      {
        'id': 'destination_7',
        'type': 'destination',
        'title': 'Art Gallery District',
        'description':
            'Contemporary art galleries, street murals, and artisan workshops',
        'price': 400,
        'rating': 4.4,
      },
      {
        'id': 'destination_8',
        'type': 'destination',
        'title': 'Sunset Cruise',
        'description':
            'Relaxing boat ride with live music, dinner, and spectacular coastal views',
        'price': 1800,
        'rating': 4.7,
      },
      {
        'id': 'destination_9',
        'type': 'destination',
        'title': 'Adventure Theme Park',
        'description':
            'Thrilling rides, water slides, and family-friendly entertainment',
        'price': 1500,
        'rating': 4.6,
      },
      {
        'id': 'destination_10',
        'type': 'destination',
        'title': 'Spa & Wellness Retreat',
        'description':
            'Rejuvenating spa treatments, yoga sessions, and meditation in tranquil gardens',
        'price': 3500,
        'rating': 4.8,
      },
    ]);

    return suggestions;
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppConfig.primaryColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Triplix is typing',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConfig.primaryColor.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs
class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Budget Screen (Coming Soon)'));
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen (Coming Soon)'));
}
