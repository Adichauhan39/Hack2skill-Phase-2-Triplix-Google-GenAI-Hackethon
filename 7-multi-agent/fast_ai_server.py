"""
Fast & Stable AI Hotel Search Server
Hybrid approach: CSV + Direct Gemini (no ADK imports for faster startup)
"""
import os
os.environ['GOOGLE_API_KEY'] = 'AIzaSyAaC4DMxu0mHPggTp7eyEoG4rtAywCQ4z8'

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any
import pandas as pd
import json
import google.generativeai as genai
import hashlib

# Configure Gemini
genai.configure(api_key=os.environ['GOOGLE_API_KEY'])

def get_image_url_for_suggestion(title: str, type_name: str) -> str:
    """
    Generate consistent image URLs for suggestions based on type and title
    Uses Unsplash random images with seeds for consistency
    """
    # Create a seed from title to get consistent images for same place
    seed = int(hashlib.md5(title.encode()).hexdigest()[:8], 16) % 1000
    
    # Map types to Unsplash search terms
    type_keywords = {
        'hotel': 'luxury-hotel,resort',
        'spa': 'spa,wellness,massage',
        'restaurant': 'restaurant,dining,food',
        'activity': 'adventure,tourism,attraction',
        'transport': 'travel,transportation',
        'attraction': 'landmark,tourist-attraction',
        'general': 'travel,india'
    }
    
    keyword = type_keywords.get(type_name.lower(), 'travel')
    
    # Use Unsplash Source API with keywords and seed for consistency
    return f"https://source.unsplash.com/400x250/?{keyword}&sig={seed}"

def get_booking_url_for_suggestion(title: str, location: str, type_name: str) -> str:
    """
    Generate booking/website URLs for suggestions based on type
    """
    query = f"{title} {location}".strip()
    encoded_query = query.replace(' ', '+')
    
    # Map types to appropriate booking platforms
    if type_name == 'hotel':
        return f"https://www.booking.com/searchresults.html?ss={encoded_query}"
    elif type_name == 'spa':
        # Use Google search for spas (many don't have direct booking)
        return f"https://www.google.com/search?q={encoded_query}+booking"
    elif type_name == 'restaurant':
        return f"https://www.google.com/search?q={encoded_query}"
    elif type_name in ['activity', 'attraction']:
        return f"https://www.tripadvisor.com/Search?q={encoded_query}"
    else:
        return f"https://www.google.com/search?q={encoded_query}"

# Create FastAPI app
app = FastAPI(
    title="AI Hotel Search - Fast & Stable",
    description="Hybrid CSV + AI with instant startup"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load hotel data (use absolute path relative to script location)
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
hotels_df = pd.read_csv(os.path.join(script_dir, 'data', 'hotels_india.csv'))

class HotelSearchRequest(BaseModel):
    message: str
    context: Dict[str, Any]

@app.get("/")
def root():
    return {
        "status": "AI Hotel Search Server Running", 
        "version": "2.0 - Fast & Stable",
        "mode": "Hybrid CSV + Gemini AI",
        "model": "Gemini 2.0 Flash",
        "cors_enabled": True
    }

@app.post("/chat")
def chat(request: dict):
    """Simple chat endpoint"""
    return {
        'status': 'success',
        'response': 'I understand your request. Let me search for the best hotels for you!',
        'agent': 'chat'
    }

@app.get("/hotels")
def get_hotels(
    city: str = "Goa",
    min_price: float = 0,
    max_price: float = 50000,
    type: str = None
):
    """GET endpoint for simple CSV filtering"""
    try:
        print(f"\n📊 CSV SEARCH: {city}, ₹{min_price}-{max_price}")
        
        filtered_hotels = hotels_df[
            (hotels_df['city'].str.lower() == city.lower()) &
            (hotels_df['price_per_night'] >= min_price) &
            (hotels_df['price_per_night'] <= max_price)
        ]
        
        if type and type.lower() != 'all':
            filtered_hotels = filtered_hotels[
                filtered_hotels['accommodation_type'].str.lower() == type.lower()
            ]
        
        hotels_list = []
        for _, hotel in filtered_hotels.head(20).iterrows():
            hotels_list.append({
                'name': hotel['name'],
                'city': hotel['city'],
                'type': hotel['accommodation_type'],
                'price_per_night': float(hotel['price_per_night']),
                'rating': float(hotel['rating']),
                'amenities': hotel['extras'].split('|') if '|' in str(hotel['extras']) else hotel['extras'].split(', '),
            })
        
        print(f"✅ Found {len(hotels_list)} hotels\n")
        
        return {
            'status': 'success',
            'hotels': hotels_list,
            'count': len(hotels_list)
        }
    except Exception as e:
        print(f"❌ Error: {e}\n")
        return {'status': 'error', 'message': str(e), 'hotels': []}

@app.post("/api/hotel/search")
def search_hotels(request: HotelSearchRequest):
    """
    Hybrid hotel search: CSV first, Gemini AI for special requests
    """
    try:
        city = request.context.get('city', 'Goa')
        budget = request.context.get('budget', 25000)
        message = request.message
        
        print(f"\n🔍 HOTEL SEARCH:")
        print(f"   City: {city}, Budget: ₹{budget}")
        print(f"   Query: {message}")
        
        # Detect special requests
        has_special_request = any([
            keyword in message.lower() 
            for keyword in ['near', 'airport', 'station', 'beach', 'mall', 'spa', 'pool', 
                           'gym', 'romantic', 'luxury', 'family', 'business', 'special']
        ])
        
        # STEP 1: Try CSV first
        print(f"   📊 Step 1: Checking CSV...")
        city_hotels = hotels_df[
            (hotels_df['city'].str.lower() == city.lower()) &
            (hotels_df['price_per_night'] <= budget)
        ]
        
        csv_count = len(city_hotels)
        print(f"   📊 CSV found: {csv_count} hotels")
        
        # Use CSV if available and no special request
        if csv_count > 0 and not has_special_request:
            print(f"   ✅ Using CSV (cost-free)\n")
            
            formatted_hotels = []
            for _, hotel in city_hotels.head(15).iterrows():
                formatted_hotels.append({
                    'name': hotel['name'],
                    'city': hotel['city'],
                    'type': hotel['accommodation_type'],
                    'price_per_night': float(hotel['price_per_night']),
                    'rating': float(hotel['rating']),
                    'amenities': hotel['extras'].split('|') if '|' in str(hotel['extras']) else hotel['extras'].split(', '),
                    'match_score': '90%',
                    'why_recommended': f"Available in {city}",
                    'highlights': ['Verified', 'Available'],
                    'perfect_for': 'All travelers'
                })
            
            return {
                'status': 'success',
                'powered_by': 'CSV Database',
                'ai_used': False,
                'cost': '₹0',
                'hotels': formatted_hotels,
                'count': len(formatted_hotels),
                'overall_advice': f'Found {len(formatted_hotels)} hotels in {city}',
                'location': city
            }
        
        # STEP 2: Use Gemini AI for special requests or missing cities
        print(f"   🤖 Step 2: Using Gemini AI...")
        
        reason = "Special request" if has_special_request else "City not in database"
        print(f"   💰 Reason: {reason}\n")
        
        # If CSV has some hotels, use them as context for AI
        context_hotels = ""
        if csv_count > 0:
            hotels_list = []
            for _, hotel in city_hotels.iterrows():
                hotels_list.append(f"- {hotel['name']} (₹{hotel['price_per_night']}/night, {hotel['accommodation_type']})")
            context_hotels = "\n".join(hotels_list[:10])
        
        prompt = f"""You are a travel hotel recommendation expert. Based on this request, provide hotel recommendations:

REQUEST: {message}
LOCATION: {city}, India
BUDGET: ₹{budget}/night
GUESTS: {request.context.get('guests', 2)}

{f"Available in our database:{context_hotels}" if context_hotels else "No hotels currently in our database for this city."}

Return ONLY valid JSON with no markdown:
{{
  "hotels": [
    {{
      "name": "Hotel Name",
      "type": "3-star/4-star/5-star",
      "price_per_night": "₹2000-3000",
      "amenities": ["WiFi", "Pool", "Gym"],
      "highlights": ["Location 1", "Highlight 2"],
      "perfect_for": "Type of guest",
      "location_area": "Area name"
    }}
  ],
  "overall_advice": "Summary recommendation"
}}

Provide 5-10 realistic hotel recommendations."""
        
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        
        # Parse response
        ai_text = response.text.strip()
        if '```json' in ai_text:
            ai_text = ai_text.split('```json')[1].split('```')[0].strip()
        elif '```' in ai_text:
            ai_text = ai_text.split('```')[1].split('```')[0].strip()
        
        ai_result = json.loads(ai_text)
        
        formatted_hotels = []
        for hotel in ai_result.get('hotels', []):
            formatted_hotels.append({
                'name': hotel.get('name', 'Hotel'),
                'city': city,
                'type': hotel.get('type', '3-star'),
                'price_per_night': hotel.get('price_per_night', f'₹{budget}'),
                'rating': 4.0,
                'amenities': hotel.get('amenities', []),
                'match_score': '95%',
                'why_recommended': hotel.get('highlights', [''])[0] if hotel.get('highlights') else '',
                'highlights': hotel.get('highlights', []),
                'perfect_for': hotel.get('perfect_for', 'All travelers'),
                'location_area': hotel.get('location_area', city)
            })
        
        print(f"✅ Gemini AI returned {len(formatted_hotels)} hotels\n")
        
        return {
            'status': 'success',
            'powered_by': 'Gemini 2.0 Flash AI',
            'ai_used': True,
            'reason_for_ai': reason,
            'hotels': formatted_hotels,
            'count': len(formatted_hotels),
            'overall_advice': ai_result.get('overall_advice', 'Great choices!'),
            'location': city
        }
        
    except Exception as e:
        print(f"❌ Error: {e}\n")
        import traceback
        traceback.print_exc()
        return {
            "status": "error",
            "message": str(e)
        }

class PreferencesRequest(BaseModel):
    destination: Dict[str, Any]
    budget: Dict[str, Any]
    activities: Dict[str, Any]
    transport: Dict[str, Any]
    allocation: Dict[str, Any]
    context: Dict[str, Any]

@app.post("/api/analyze-preferences")
def analyze_preferences(request: PreferencesRequest):
    """Analyze user preferences using multiple AI sub-agents"""
    try:
        print("\n🧠 PREFERENCES ANALYSIS REQUESTED")
        print("="*80)
        
        # Convert request to dict
        prefs = request.dict()
        
        # Create comprehensive prompt for Gemini
        prompt = f"""
You are an expert travel planning coordinator with access to specialized sub-agents. 
Analyze these comprehensive user travel preferences and provide detailed insights:

**DESTINATION PREFERENCES:**
{json.dumps(prefs['destination'], indent=2)}

**BUDGET PREFERENCES:**
{json.dumps(prefs['budget'], indent=2)}

**ACTIVITY PREFERENCES:**
{json.dumps(prefs['activities'], indent=2)}

**TRANSPORT PREFERENCES:**
{json.dumps(prefs['transport'], indent=2)}

**BUDGET ALLOCATION:**
{json.dumps(prefs['allocation'], indent=2)}

**ADDITIONAL CONTEXT:**
{json.dumps(prefs['context'], indent=2)}

Provide a comprehensive analysis in JSON format with these sections:

{{
  "overall_summary": {{
    "title": "Your Perfect Trip Summary",
    "content": "2-3 paragraph overview of the ideal trip based on all preferences"
  }},
  "destination_analysis": {{
    "recommendations": ["Top 3-5 destination recommendations for India with reasoning"],
    "warnings": ["Any concerns or considerations about destination choices"]
  }},
  "budget_analysis": {{
    "recommendations": ["Budget adequacy assessment", "Spending strategy", "Value optimization tips"],
    "warnings": ["Budget concerns", "Potential overspending areas", "Underfunded categories"]
  }},
  "activities_analysis": {{
    "recommendations": ["Top activity suggestions", "Daily schedule ideas", "Must-do experiences"],
    "warnings": ["Physical preparation needed", "Time management", "Weather considerations"]
  }},
  "transport_analysis": {{
    "recommendations": ["Best transport modes", "Booking priorities", "Cost vs time trade-offs"],
    "warnings": ["Booking timeline", "Availability concerns", "Alternative options"]
  }},
  "allocation_analysis": {{
    "recommendations": ["Allocation balance assessment", "Category-wise optimization", "Smart spending areas"],
    "warnings": ["Reallocation suggestions", "Under-budgeted categories", "Overspend risks"]
  }},
  "context_analysis": {{
    "recommendations": ["Special accommodations needed", "Dietary/accessibility planning", "Important preparations"],
    "warnings": ["Critical requirements", "Advance arrangements", "Potential challenges"]
  }},
  "action_items": [
    "Prioritized list of 5-8 next steps to book this trip effectively"
  ]
}}

Be specific, practical, and encouraging. Focus on Indian destinations and realistic planning.
"""
        
        print("🤖 Consulting AI sub-agents...")
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        
        # Parse response
        ai_text = response.text.strip()
        if '```json' in ai_text:
            ai_text = ai_text.split('```json')[1].split('```')[0].strip()
        elif '```' in ai_text:
            ai_text = ai_text.split('```')[1].split('```')[0].strip()
        
        analysis_result = json.loads(ai_text)
        
        print("✅ Analysis complete!")
        print(f"   - Overall summary: {len(analysis_result.get('overall_summary', {}).get('content', ''))} chars")
        print(f"   - Action items: {len(analysis_result.get('action_items', []))} items")
        print("="*80 + "\n")
        
        return {
            'status': 'success',
            'powered_by': 'Gemini 2.0 Flash AI Multi-Agent System',
            **analysis_result
        }
        
    except Exception as e:
        print(f"❌ Error analyzing preferences: {e}\n")
        import traceback
        traceback.print_exc()
        return {
            "status": "error",
            "message": str(e)
        }

class AgentRequest(BaseModel):
    message: str
    context: Dict[str, Any]
    page: str = "home"

@app.post("/api/agent")
def agent_chat(request: AgentRequest):
    """
    Main AI agent endpoint for conversational travel planning
    Handles all general queries with Gemini AI
    """
    try:
        print(f"\n💬 AGENT CHAT:")
        print(f"   Page: {request.page}")
        print(f"   Message: {request.message}")
        print(f"   Context keys: {list(request.context.keys())}")
        
        # Build comprehensive context from ALL previous screens
        context_info = ""
        preferences_info = ""
        
        # Travel details from popup
        if 'from' in request.context:
            context_info += f"\n- From: {request.context['from']}"
        if 'to' in request.context:
            context_info += f"\n- To: {request.context['to']}"
        if 'stay_city' in request.context:
            context_info += f"\n- Stay city: {request.context['stay_city']}"
        if 'start_date' in request.context and 'end_date' in request.context:
            context_info += f"\n- Travel dates: {request.context['start_date']} to {request.context['end_date']}"
        if 'duration_days' in request.context:
            context_info += f"\n- Duration: {request.context['duration_days']} days"
        
        # Budget and travelers
        if 'budget' in request.context:
            context_info += f"\n- Total Budget: ₹{request.context['budget']:,}"
        if 'travelers' in request.context:
            context_info += f"\n- Number of travelers: {request.context['travelers']}"
        
        # User preferences from previous screens
        prefs = request.context.get('preferences', {})
        user_prefs = request.context.get('user_preferences', {})
        
        # Merge both preference sources
        all_prefs = {**prefs, **user_prefs}
        
        if all_prefs.get('activities'):
            activities = all_prefs['activities']
            if activities:
                preferences_info += f"\n- Preferred activities: {', '.join(activities)}"
        
        if all_prefs.get('terrains'):
            terrains = all_prefs['terrains']
            if terrains:
                preferences_info += f"\n- Terrain preferences: {', '.join(terrains)}"
        
        if all_prefs.get('transport'):
            transport = all_prefs['transport']
            if transport:
                preferences_info += f"\n- Preferred transport: {', '.join(transport)}"
        
        if all_prefs.get('accommodation'):
            accommodation = all_prefs['accommodation']
            if accommodation:
                preferences_info += f"\n- Accommodation type: {', '.join(accommodation)}"
        
        if all_prefs.get('dietary'):
            dietary = all_prefs['dietary']
            if dietary:
                preferences_info += f"\n- Dietary preferences: {', '.join(dietary)}"
        
        if all_prefs.get('companion'):
            preferences_info += f"\n- Traveling with: {all_prefs['companion']}"
        
        if all_prefs.get('occasion'):
            preferences_info += f"\n- Trip occasion: {all_prefs['occasion']}"
        
        if all_prefs.get('destination'):
            preferences_info += f"\n- Destination interest: {all_prefs['destination']}"
        
        # Build enhanced prompt with ALL context
        full_context = context_info + preferences_info
        
        # Check if this is a specific query or general planning
        query_lower = request.message.lower()
        is_specific_query = any(keyword in query_lower for keyword in [
            'restaurant', 'eat', 'food', 'dining', 'lunch', 'dinner', 'breakfast',
            'hotel', 'stay', 'accommodation', 'resort', 'where to stay',
            'activity', 'things to do', 'visit', 'see', 'attraction', 'places',
            'transport', 'flight', 'train', 'bus', 'how to reach', 'travel',
            'budget', 'cost', 'price', 'expensive', 'cheap', 'affordable',
            'weather', 'season', 'when to visit', 'best time',
            'romantic', 'adventure', 'family', 'solo', 'group',
            'beach', 'mountain', 'city', 'temple', 'fort', 'museum',
            'shopping', 'market', 'nightlife', 'party', 'club',
            'vegetarian', 'vegan', 'non-veg', 'seafood', 'local food',
            'spa', 'massage', 'wellness', 'yoga', 'relaxation', 'therapy'  # Added spa keywords
        ])
        
        prompt = f"""You are Triplix, an expert AI travel assistant helping users plan amazing trips in India.

User's Query: "{request.message}"

COMPLETE TRAVEL PROFILE:{full_context if full_context else " (No specific context yet)"}

IMPORTANT INSTRUCTIONS:
1. ANALYZE THE USER'S QUERY CAREFULLY
   - If they ask about restaurants, focus ONLY on dining recommendations
   - If they ask about hotels, focus ONLY on accommodation
   - If they ask about activities, focus ONLY on things to do
   - If they ask about budget, provide detailed cost breakdowns
   - If they ask about weather, provide seasonal information
   - If they mention romantic/adventure/family, tailor suggestions accordingly

2. PROVIDE RICH, DETAILED INFORMATION:
   
   📍 **FOR DESTINATIONS:**
   - Exact names with GPS coordinates (e.g., "Calangute Beach (15.5470° N, 73.7524° E)")
   - Entry fees, timings, best time to visit
   - Key highlights and photo spots
   
   🏨 **FOR HOTELS/ACCOMMODATIONS:**
   - Specific hotel names with star ratings (e.g., "The Park Calangute 4.5⭐")
   - Price per night: ₹X,XXX
   - Key amenities (WiFi, Pool, Restaurant, Spa, Beach access)
   - Distance from attractions
   - Review quotes: "Perfect beachfront location! - Priya, Mumbai, Oct 2024"
   
   🍽️ **FOR RESTAURANTS:**
   - Specific restaurant names
   - Cuisine type and must-try dishes (respecting dietary preferences)
   - Price range: ₹₹ or ₹₹₹
   - Popular reviews: "Best Goan curry I've had! - Rajesh, Delhi, Sep 2024"
   - Location and distance from hotels
   
   🎭 **FOR ACTIVITIES:**
   - Activity name with booking details
   - Duration: 2-3 hours, Cost: ₹500-1000
   - Best time: Morning/Afternoon/Evening
   - Difficulty level: Easy/Moderate/Hard
   - Review: "Thrilling experience! - Sarah, Bangalore, Aug 2024"
   
   � **FOR SPAS & WELLNESS:**
   - Spa name with rating (e.g., "Ayurvedic Wellness Spa 4.7⭐")
   - Treatments offered (Ayurvedic, Thai, Swedish massage, etc.)
   - Duration and price per treatment: ₹2,000-5,000
   - Ambiance: Beachfront, Traditional, Luxury
   - Review: "Most relaxing massage ever! - Neha, Mumbai, Nov 2024"
   - Booking info and special packages
   
   �🚗 **FOR TRANSPORT:**
   - Specific options (flight, train, bus)
   - Travel time and costs
   - Booking tips
   - Local transport recommendations
   
   💰 **FOR BUDGET:**
   - Itemized cost breakdown
   - Day-wise estimates
   - Money-saving tips
   - "Where to splurge vs save"

3. MATCH USER PREFERENCES:
   - Budget: ₹{request.context.get('budget', 50000):,}
   - Travelers: {request.context.get('travelers', 2)}
   - Activities: {', '.join(all_prefs.get('activities', ['General']))}
   - Dietary: {', '.join(all_prefs.get('dietary', ['All']))}
   - Companion: {all_prefs.get('companion', 'Not specified')}
   - Occasion: {all_prefs.get('occasion', 'General')}

4. INCLUDE REALISTIC REVIEWS:
   - Use realistic names (Priya, Rajesh, Sarah, Amit, etc.)
   - Recent dates (2024)
   - Specific praise/concerns
   - Star ratings (4.2⭐, 4.8⭐, etc.)

5. BE SMART ABOUT ADDITIONAL QUERIES:
   - If user asks "spa" or "massage", suggest: Best spas, Ayurvedic centers, wellness treatments
   - If user asks "romantic places", suggest: Sunset spots, candlelight dinners, couple activities
   - If user asks "adventure", suggest: Water sports, trekking, paragliding
   - If user asks "family", suggest: Kid-friendly places, safe activities, family restaurants
   - If user asks "budget", suggest: Free attractions, cheap eats, money-saving tips
   - If user asks "luxury", suggest: 5-star hotels, fine dining, premium experiences

Response Format: Rich, conversational text with emojis, specific names, prices, GPS coordinates, ratings, and realistic traveler reviews."""

        print("   🤖 Consulting Gemini AI with FULL user profile...")
        print(f"   📊 Context length: {len(full_context)} chars")
        
        model = genai.GenerativeModel(
            'gemini-2.0-flash-exp',
            generation_config={'temperature': 0.7}
        )
        response = model.generate_content(prompt)
        
        ai_response = response.text.strip()
        
        # Check if this should have suggestions (swipeable cards)
        should_show_suggestions = is_specific_query or any(keyword in query_lower for keyword in [
            'suggest', 'recommend', 'best', 'top', 'show me', 'what are'
        ])
        
        # Generate suggestions with images if applicable
        suggestions = []
        if should_show_suggestions:
            # Try to extract location from query or context
            location = request.context.get('destination', '')
            if not location:
                # Try to extract from query (e.g., "spas in Goa" -> "Goa")
                location_keywords = ['in ', 'at ', 'near ']
                for keyword in location_keywords:
                    if keyword in query_lower:
                        parts = query_lower.split(keyword)
                        if len(parts) > 1:
                            potential_location = parts[1].split()[0] if parts[1].split() else ''
                            location = potential_location.title()
                            break
            
            # Fallback to "India" if no location found
            if not location:
                location = "India"
            
            # Detect type from query
            suggestion_type = 'general'
            if 'spa' in query_lower or 'massage' in query_lower or 'wellness' in query_lower:
                suggestion_type = 'spa'
            elif 'hotel' in query_lower or 'stay' in query_lower or 'accommodation' in query_lower:
                suggestion_type = 'hotel'
            elif 'restaurant' in query_lower or 'food' in query_lower or 'eat' in query_lower:
                suggestion_type = 'restaurant'
            elif 'activity' in query_lower or 'things to do' in query_lower or 'visit' in query_lower:
                suggestion_type = 'activity'
            elif 'attraction' in query_lower or 'places' in query_lower or 'sightseeing' in query_lower:
                suggestion_type = 'attraction'
            
            # Parse response for suggestions (look for names with ratings/prices)
            lines = ai_response.split('\n')
            current_suggestion = None
            
            for line in lines:
                # Look for titles with ratings (e.g., "Spa Name 4.5⭐")
                if '⭐' in line and ('**' in line or line.strip().startswith('-') or line.strip().startswith('•')):
                    if current_suggestion:
                        suggestions.append(current_suggestion)
                    
                    # Extract title
                    title = line.replace('**', '').replace('*', '').replace('-', '').replace('•', '').strip()
                    title = title.split('⭐')[0].strip() if '⭐' in title else title
                    
                    # Extract rating
                    rating_match = line.split('⭐')[0] if '⭐' in line else ''
                    rating = None
                    for part in rating_match.split():
                        try:
                            rating = float(part)
                            break
                        except:
                            continue
                    
                    current_suggestion = {
                        'type': suggestion_type,
                        'title': title[:100],  # Limit title length
                        'description': '',
                        'rating': rating,
                        'price': None,
                        'location': location,
                        'image': get_image_url_for_suggestion(title, suggestion_type),
                        'website': get_booking_url_for_suggestion(title, location, suggestion_type)
                    }
                
                # Look for prices
                elif current_suggestion and ('₹' in line or 'Price' in line):
                    # Try to extract price
                    price_text = line.replace('**', '').replace('*', '').strip()
                    for word in price_text.split():
                        word_clean = word.replace('₹', '').replace(',', '').strip()
                        try:
                            price = int(word_clean)
                            if 100 <= price <= 1000000:  # Reasonable range
                                current_suggestion['price'] = price
                                break
                        except:
                            continue
                
                # Add to description
                elif current_suggestion and line.strip():
                    if len(current_suggestion['description']) < 200:
                        current_suggestion['description'] += line.strip() + ' '
            
            # Add last suggestion
            if current_suggestion:
                suggestions.append(current_suggestion)
            
            # Limit to 8 suggestions
            suggestions = suggestions[:8]
        
        print(f"   ✅ Personalized response generated ({len(ai_response)} chars)")
        if suggestions:
            print(f"   🎴 Generated {len(suggestions)} swipeable suggestions with images")
        print("="*80 + "\n")
        
        return {
            'status': 'success',
            'response': ai_response,
            'agent': 'triplix_ai',
            'show_suggestions': len(suggestions) > 0,
            'suggestions': suggestions if suggestions else [],
            'data': {},
            'page': request.page,
            'powered_by': 'Gemini 2.0 Flash with Full Profile'
        }
        
    except Exception as e:
        print(f"❌ Error in agent chat: {e}\n")
        import traceback
        traceback.print_exc()
        return {
            "status": "error",
            "response": "I apologize, but I'm having trouble processing your request right now. Let me know how else I can help with your travel planning!",
            "error": str(e)
        }

if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*80)
    print("🚀 FAST AI HOTEL SEARCH SERVER - STARTED")
    print("="*80)
    print("Mode: Hybrid CSV + Gemini AI (No ADK - Ultra-Fast)")
    print("Server: http://0.0.0.0:8001")
    print("="*80 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8001)
