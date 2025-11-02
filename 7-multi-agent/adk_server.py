"""
ADK-Integrated Travel Server
Combines FastAPI with Google ADK Manager Agent for comprehensive travel booking
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get API key from environment
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY not found in environment variables. Please set it in a .env file.")

os.environ['GOOGLE_API_KEY'] = GOOGLE_API_KEY

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
import pandas as pd
import json
import google.generativeai as genai
from manager.agent import root_agent

# Configure Gemini
genai.configure(api_key=os.environ['GOOGLE_API_KEY'])

# Create FastAPI app
app = FastAPI(
    title="ADK Travel Booking Server",
    description="Google ADK Manager Agent + FastAPI for comprehensive travel booking",
    version="3.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load data files
hotels_df = pd.read_csv('data/hotels_india.csv')
flights_df = pd.read_csv('data/flights_india.csv')

# Load transportation data
try:
    trains_df = pd.read_csv('data/trains_india.csv')
except (FileNotFoundError, pd.errors.ParserError) as e:
    print(f"Warning: Could not load trains data: {e}")
    trains_df = pd.DataFrame()

try:
    buses_df = pd.read_csv('data/buses_india.csv')
except (FileNotFoundError, pd.errors.ParserError) as e:
    print(f"Warning: Could not load buses data: {e}")
    buses_df = pd.DataFrame()

try:
    cars_df = pd.read_csv('data/car_rentals_india.csv')
except (FileNotFoundError, pd.errors.ParserError) as e:
    print(f"Warning: Could not load car rentals data: {e}")
    cars_df = pd.DataFrame()

try:
    taxis_df = pd.read_csv('data/taxis_india.csv')
except (FileNotFoundError, pd.errors.ParserError) as e:
    print(f"Warning: Could not load taxis data: {e}")
    taxis_df = pd.DataFrame()

try:
    bikes_df = pd.read_csv('data/bikes_india.csv')
except (FileNotFoundError, pd.errors.ParserError) as e:
    print(f"Warning: Could not load bikes data: {e}")
    bikes_df = pd.DataFrame()

# Pydantic models
class AgentRequest(BaseModel):
    message: str
    context: Optional[Dict[str, Any]] = {}
    page: Optional[str] = "home"  # home, swipe, bookings, budget, profile

class HotelSearchRequest(BaseModel):
    city: str
    min_price: Optional[float] = 0
    max_price: Optional[float] = 50000
    room_type: Optional[str] = None
    ambiance: Optional[str] = None
    amenities: Optional[List[str]] = []
    special_request: Optional[str] = None

class TravelSearchRequest(BaseModel):
    origin: str
    destination: str
    date: Optional[str] = None
    transport_type: Optional[str] = "flight"  # flight, train, bus, car, taxi, bike
    passengers: Optional[int] = 1

class DestinationInfoRequest(BaseModel):
    city: str
    travel_style: Optional[str] = "general"  # luxury, budget, family, romantic, adventure

class SwipeRequest(BaseModel):
    city: str
    category: Optional[str] = "attractions"  # attractions, hotels, restaurants

class BudgetRequest(BaseModel):
    total_budget: float
    num_people: int
    currency: Optional[str] = "INR"

class BookingRequest(BaseModel):
    type: str  # hotel, flight, train, bus, car, taxi, bike
    details: Dict[str, Any]

class AnalyzePreferencesRequest(BaseModel):
    destination: Optional[Dict[str, Any]] = {}
    budget: Optional[Dict[str, Any]] = {}
    activities: Optional[Dict[str, Any]] = {}
    transport: Optional[Dict[str, Any]] = {}
    allocation: Optional[Dict[str, Any]] = {}
    context: Optional[Dict[str, Any]] = {}

# Helper functions
def _create_hotel_description(hotel_name, hotel_type, amenities, city, rating):
    """Create a detailed description for the hotel"""
    type_descriptions = {
        'Hotel': 'a premium accommodation',
        'Resort': 'a luxurious resort experience',
        'Hostel': 'a budget-friendly shared accommodation',
        'Homestay': 'a cozy home-like stay',
        'Villa': 'a private villa experience',
        'Boutique Hotel': 'a stylish boutique hotel',
        'Guesthouse': 'a charming guesthouse',
    }

    description = f"{hotel_name} is {type_descriptions.get(hotel_type, 'an excellent accommodation')} located in {city}, India. "

    # Add rating description
    if rating >= 4.5:
        description += f"This highly-rated property ({rating}/5) offers exceptional service and quality. "
    elif rating >= 4.0:
        description += f"This well-rated property ({rating}/5) provides good value and comfort. "
    else:
        description += f"This property ({rating}/5) offers basic amenities at an affordable price. "

    # Add amenities description
    if 'Pool' in amenities:
        description += "Enjoy the refreshing swimming pool and relax in style. "
    if 'Spa' in amenities:
        description += "Unwind with spa treatments and wellness facilities. "
    if 'Beach Access' in amenities:
        description += "Direct beach access makes it perfect for beach lovers. "
    if 'WiFi' in amenities:
        description += "Stay connected with complimentary high-speed WiFi. "
    if 'Gym' in amenities:
        description += "Maintain your fitness routine with the on-site gym. "

    return description

def _create_recommendation(hotel_name, hotel_type, amenities, city, price, rating):
    """Create a personalized recommendation for why this hotel is good"""
    recommendation = ""
    return recommendation

# API Endpoints

@app.get("/")
def root():
    return {
        "status": "ADK Travel Booking Server Running",
        "version": "3.0 - ADK Integrated",
        "mode": "Google ADK Manager + FastAPI",
        "model": "Gemini 2.0 Flash",
        "cors_enabled": True,
        "endpoints": [
            "/api/agent - Main ADK manager endpoint",
            "/api/analyze-preferences - Analyze user travel preferences (AI Assistant)",
            "/api/hotel/search - Hotel search",
            "/api/travel/search - Travel search",
            "/api/destination/info - Destination information",
            "/api/swipe - Swipe recommendations",
            "/api/budget - Budget management",
            "/api/bookings - Booking management"
        ]
    }

@app.post("/api/agent")
def handle_agent_request(request: AgentRequest):
    """
    Main ADK Manager Agent endpoint - handles all travel requests
    Routes to appropriate sub-agents based on context and page
    """
    try:
        print(f"\n[AI] ADK AGENT REQUEST:")
        print(f"   [PAGE] Page: {request.page}")
        print(f"   [MSG] Message: {request.message}")
        print(f"   [DATA] Context: {request.context}")

        # Enhance message with page context for better routing
        enhanced_message = request.message

        # Add page-specific context to help the manager agent
        if request.page == "swipe":
            enhanced_message = f"[SWIPE PAGE] {request.message}"
        elif request.page == "bookings":
            enhanced_message = f"[BOOKINGS PAGE] {request.message}"
        elif request.page == "budget":
            enhanced_message = f"[BUDGET PAGE] {request.message}"
        elif request.page == "profile":
            enhanced_message = f"[PROFILE PAGE] {request.message}"
        elif request.page == "home":
            enhanced_message = f"[HOME ASSISTANT] {request.message}"

        # Add context information
        if request.context:
            context_str = ", ".join([f"{k}: {v}" for k, v in request.context.items()])
            enhanced_message += f" [CONTEXT: {context_str}]"

        print(f"   [PROCESS] Enhanced message: {enhanced_message}")

        # Call ADK manager agent using run_live (synchronous execution)
        print(f"   [ADK] Calling root_agent.run_live()...")
        response_iter = root_agent.run_live(message=enhanced_message)
        
        # Collect all responses from the iterator
        full_response = ""
        agent_used = "manager"
        response_data = {}
        
        for response_chunk in response_iter:
            if hasattr(response_chunk, 'text'):
                full_response += response_chunk.text
            elif isinstance(response_chunk, dict):
                full_response += response_chunk.get('text', response_chunk.get('response', str(response_chunk)))
                agent_used = response_chunk.get('agent', agent_used)
                response_data.update(response_chunk.get('data', {}))
            else:
                full_response += str(response_chunk)
        
        response = {
            "response": full_response,
            "agent": agent_used,
            "data": response_data
        }

        print(f"   [OK] ADK Response received: {full_response[:100]}...")

        return {
            "success": True,
            "response": response.get("response", "I understand your request. Let me help you with your travel plans."),
            "agent": response.get("agent", "manager"),
            "data": response.get("data", {}),
            "page": request.page,
            "source": "adk_manager"
        }

    except Exception as e:
        print(f"   [ERROR] ADK Error: {e}")
        return {
            "success": False,
            "error": f"ADK Manager error: {str(e)}",
            "response": "Sorry, I'm having trouble processing your request. Please try again.",
            "source": "adk_manager"
        }

@app.post("/api/analyze-preferences")
def analyze_preferences(request: AnalyzePreferencesRequest):
    """
    Analyze user preferences and provide AI-powered travel recommendations
    Used by the AI Assistant page in Flutter app
    """
    try:
        print(f"\n[AI ASSISTANT] ANALYZE PREFERENCES REQUEST:")
        print(f"   [DATA] Request data received")
        
        # Build comprehensive message from user preferences
        message_parts = ["I need help planning my trip. Here are my preferences:"]
        
        # Destination preferences
        if request.destination:
            dest = request.destination
            if dest.get('location_types'):
                message_parts.append(f"I prefer {', '.join(dest['location_types'])} locations.")
            if dest.get('climate'):
                message_parts.append(f"I like {dest['climate']} climate.")
            if dest.get('experience_level'):
                message_parts.append(f"My experience level is {dest['experience_level']}.")
        
        # Budget information
        if request.budget:
            budget = request.budget
            amount = budget.get('amount', 0)
            num_people = budget.get('num_people', 1)
            if amount > 0:
                message_parts.append(f"My budget is ₹{amount} for {num_people} person(s).")
        
        # Activities
        if request.activities and request.activities.get('selected'):
            activities = request.activities['selected']
            if activities:
                message_parts.append(f"I'm interested in: {', '.join(activities)}.")
        
        # Transport preferences
        if request.transport and request.transport.get('modes'):
            transport = request.transport['modes']
            if transport:
                message_parts.append(f"I prefer traveling by: {', '.join(transport)}.")
        
        # Context and special requirements
        if request.context:
            ctx = request.context
            if ctx.get('dietary_requirements'):
                message_parts.append(f"Dietary requirements: {', '.join(ctx['dietary_requirements'])}.")
            if ctx.get('travel_companions'):
                message_parts.append(f"Traveling with: {ctx['travel_companions']}.")
            if ctx.get('special_requests'):
                message_parts.append(f"Special occasion: {ctx['special_requests']}.")
        
        # Combine all parts into a comprehensive message
        full_message = " ".join(message_parts)
        full_message += " Please provide me with personalized travel recommendations, including destinations, accommodations, activities, and budget breakdown."
        
        print(f"   [MESSAGE] Generated message: {full_message[:200]}...")
        
        # Call ADK agent with the comprehensive message
        agent_request = AgentRequest(
            message=full_message,
            context={
                "page": "ai_assistant",
                "preferences": {
                    "destination": request.destination,
                    "budget": request.budget,
                    "activities": request.activities,
                    "transport": request.transport,
                    "allocation": request.allocation,
                    "context": request.context
                }
            },
            page="ai_assistant"
        )
        
        print(f"   [ADK] Calling ADK agent with preferences...")
        response_iter = root_agent.run_live(message=full_message)
        
        # Collect response
        full_response = ""
        for response_chunk in response_iter:
            if hasattr(response_chunk, 'text'):
                full_response += response_chunk.text
            elif isinstance(response_chunk, dict):
                full_response += response_chunk.get('text', response_chunk.get('response', str(response_chunk)))
            else:
                full_response += str(response_chunk)
        
        print(f"   [OK] Analysis complete: {full_response[:100]}...")
        
        # Structure the response for the Flutter app
        return {
            "success": True,
            "summary": {
                "title": "AI Travel Analysis",
                "content": full_response
            },
            "insights": {
                "recommendations": [
                    "Based on your preferences, I've analyzed your travel needs",
                    "Check the detailed analysis above for personalized suggestions"
                ],
                "warnings": []
            },
            "next_steps": [
                "Review the recommendations provided",
                "Explore the swipe feature to discover destinations",
                "Set up your budget tracker for better planning"
            ]
        }
        
    except Exception as e:
        print(f"   [ERROR] Analyze preferences error: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "summary": {
                "title": "Analysis Error",
                "content": f"I encountered an error while analyzing your preferences: {str(e)}"
            },
            "insights": {
                "recommendations": [],
                "warnings": ["Please try again or contact support if the issue persists"]
            },
            "next_steps": []
        }

@app.post("/api/hotel/search")
def search_hotels(request: HotelSearchRequest):
    """
    Hotel search endpoint - can use ADK hotel_booking agent or direct CSV
    """
    try:
        print(f"\n[HOTEL] HOTEL SEARCH:")
        print(f"   [CITY] City: {request.city}")
        print(f"   [BUDGET] Budget: Rs.{request.min_price} - Rs.{request.max_price}")

        # Build search message for ADK agent
        message_parts = [f"Find hotels in {request.city}"]

        if request.max_price:
            message_parts.append(f"under Rs.{request.max_price}")
        if request.room_type:
            message_parts.append(f"with {request.room_type} room")
        if request.ambiance:
            message_parts.append(f"{request.ambiance} ambiance")
        if request.amenities:
            message_parts.append(f"with amenities: {', '.join(request.amenities)}")
        if request.special_request:
            message_parts.append(f"Special request: {request.special_request}")

        search_message = ". ".join(message_parts)

        # Use ADK hotel_booking agent
        agent_request = AgentRequest(
            message=search_message,
            context={"page": "hotel_search", "city": request.city},
            page="hotel_search"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"[ERROR] Hotel search error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't search for hotels right now."
        }

@app.post("/api/travel/search")
def search_travel(request: TravelSearchRequest):
    """
    Travel search endpoint - flights, trains, buses, etc.
    """
    try:
        print(f"\n[TRAVEL] TRAVEL SEARCH:")
        print(f"   [FROM] From: {request.origin}")
        print(f"   [TO] To: {request.destination}")
        print(f"   [DATE] Date: {request.date}")
        print(f"   [TYPE] Type: {request.transport_type}")
        print(f"   [PASSENGERS] Passengers: {request.passengers}")

        # Build search message for ADK agent
        message = f"Find {request.transport_type} from {request.origin} to {request.destination}"

        if request.date:
            message += f" on {request.date}"
        if request.passengers and request.passengers > 1:
            message += f" for {request.passengers} passengers"

        # Use ADK travel_booking agent
        agent_request = AgentRequest(
            message=message,
            context={
                "page": "travel_search",
                "origin": request.origin,
                "destination": request.destination,
                "transport_type": request.transport_type
            },
            page="travel_search"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"❌ Travel search error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't search for travel options right now."
        }

@app.post("/api/destination/info")
def get_destination_info(request: DestinationInfoRequest):
    """
    Destination information endpoint
    """
    try:
        print(f"\n📍 DESTINATION INFO:")
        print(f"   🏙️ City: {request.city}")
        print(f"   🎯 Style: {request.travel_style}")

        message = f"Tell me about {request.city} for {request.travel_style} travel"

        # Use ADK destination_info agent
        agent_request = AgentRequest(
            message=message,
            context={"page": "destination_info", "city": request.city},
            page="destination_info"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"❌ Destination info error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't get destination information right now."
        }

@app.post("/api/swipe")
def get_swipe_recommendations(request: SwipeRequest):
    """
    Swipe recommendations endpoint - attractions, hotels, restaurants
    """
    try:
        print(f"\n👆 SWIPE RECOMMENDATIONS:")
        print(f"   🏙️ City: {request.city}")
        print(f"   📂 Category: {request.category}")

        message = f"Show me swipeable {request.category} recommendations in {request.city}"

        # Use ADK swipe_recommendation_agent
        agent_request = AgentRequest(
            message=message,
            context={"page": "swipe", "city": request.city, "category": request.category},
            page="swipe"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"❌ Swipe recommendations error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't get swipe recommendations right now."
        }

@app.post("/api/budget")
def manage_budget(request: BudgetRequest):
    """
    Budget management endpoint
    """
    try:
        print(f"\n💰 BUDGET MANAGEMENT:")
        print(f"   💵 Total: {request.currency} {request.total_budget}")
        print(f"   👥 People: {request.num_people}")

        message = f"Set budget of {request.currency} {request.total_budget} for {request.num_people} people"

        # Use ADK budget_tracker agent
        agent_request = AgentRequest(
            message=message,
            context={"page": "budget", "total_budget": request.total_budget, "num_people": request.num_people},
            page="budget"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"❌ Budget management error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't manage the budget right now."
        }

@app.get("/api/bookings")
def get_bookings():
    """
    Get all bookings
    """
    try:
        print(f"\n📋 GETTING BOOKINGS")

        message = "Show me all my current bookings"

        # Use ADK manager to get booking summary
        agent_request = AgentRequest(
            message=message,
            context={"page": "bookings"},
            page="bookings"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"❌ Get bookings error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't retrieve your bookings right now."
        }

@app.post("/api/bookings")
def create_booking(request: BookingRequest):
    """
    Create a new booking
    """
    try:
        print(f"\n📝 CREATE BOOKING:")
        print(f"   📂 Type: {request.type}")
        print(f"   📊 Details: {request.details}")

        message = f"Book {request.type} with details: {json.dumps(request.details)}"

        # Use appropriate ADK agent based on booking type
        agent_request = AgentRequest(
            message=message,
            context={"page": "bookings", "booking_type": request.type, "details": request.details},
            page="bookings"
        )

        return handle_agent_request(agent_request)

    except Exception as e:
        print(f"[ERROR] Create booking error: {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Sorry, I couldn't create the booking right now."
        }

# Legacy endpoints for backward compatibility
@app.get("/hotels")
def get_hotels_legacy(
    city: str = "Goa",
    min_price: float = 0,
    max_price: float = 50000,
    type: str = None
):
    """Legacy GET endpoint for simple CSV filtering"""
    try:
        print(f"\n[LEGACY] CSV SEARCH: {city}, Rs.{min_price}-{max_price}")

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

        print(f"[OK] Found {len(hotels_list)} hotels\n")

        return {
            'status': 'success',
            'hotels': hotels_list,
            'count': len(hotels_list)
        }
    except Exception as e:
        print(f"[ERROR] Error: {e}\n")
        return {'status': 'error', 'message': str(e), 'hotels': []}

if __name__ == "__main__":
    import uvicorn
    print("Starting ADK Travel Booking Server...")
    print("Server will be available at: http://localhost:8001")
    print("ADK Manager Agent integrated and ready!")
    uvicorn.run(app, host="0.0.0.0", port=8001)