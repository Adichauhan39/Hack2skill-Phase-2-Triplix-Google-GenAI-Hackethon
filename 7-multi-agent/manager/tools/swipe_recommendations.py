"""
Swipe-based Recommendation System
Provides Tinder-like swipe interface for travel, hotel, and destination recommendations
"""

from typing import Any, List, Dict, Optional
import json


def generate_travel_recommendations(
    origin: str, 
    destination: str, 
    departure_date: str,
    passengers: int = 1,
    tool_context: Optional[Any] = None
) -> dict:
    """
    Generate swipeable travel recommendations (flights, trains, taxis).
    
    Args:
        origin: Starting city
        destination: Destination city
        departure_date: Date of travel
        passengers: Number of passengers
        tool_context: Context object
        
    Returns:
        Dictionary with swipeable travel cards in rich UI format
    """
    from ..sub_agents.travel_booking.agent import load_travel_data_from_csv
    
    travel_data = load_travel_data_from_csv()
    
    # Prepare swipeable cards
    cards = []
    card_id = 1
    
    for mode in ['flight', 'train', 'taxi']:
        for travel_option in travel_data.get(mode, []):
            if (travel_option.get('origin', '').lower() == origin.lower() and
                travel_option.get('destination', '').lower() == destination.lower()):
                
                card = {
                    "id": f"travel_{card_id}",
                    "type": "travel",
                    "mode": mode,
                    "data": travel_option,
                    "title": f"{travel_option.get('service_number', 'N/A')} - {mode.title()}",
                    "subtitle": f"{origin.title()} → {destination.title()}",
                    "details": {
                        "Price": travel_option.get('price', 'N/A'),
                        "Class": travel_option.get('class', 'N/A'),
                        "Duration": travel_option.get('duration', 'N/A'),
                        "Amenities": ", ".join(travel_option.get('amenities', [])[:3])
                    },
                    "action_data": {
                        "mode": mode,
                        "service_number": travel_option.get('service_number'),
                        "origin": origin,
                        "destination": destination,
                        "departure_date": departure_date,
                        "passengers": passengers
                    }
                }
                cards.append(card)
                card_id += 1
    
    return {
        "status": "recommendations_ready",
        "type": "swipe_cards",
        "cards": cards,
        "total_count": len(cards),
        "ui_hint": "swipe_interface"
    }


def generate_hotel_recommendations(
    location: str,
    check_in: str,
    check_out: str,
    guests: int = 1,
    tool_context: Optional[Any] = None

) -> dict:
    """
    Generate swipeable hotel/hostel recommendations.
    
    Args:
        location: City name
        check_in: Check-in date
        check_out: Check-out date
        guests: Number of guests
        tool_context: Context object
        
    Returns:
        Dictionary with swipeable hotel cards in rich UI format
    """
    from ..sub_agents.hotel_booking.agent import load_accommodations_from_csv
    
    accommodations_db = load_accommodations_from_csv()
    location_key = location.lower().strip()
    
    cards = []
    card_id = 1
    
    if location_key in accommodations_db:
        for acc in accommodations_db[location_key]:
            card = {
                "id": f"hotel_{card_id}",
                "type": "accommodation",
                "data": acc,
                "title": acc.get('name', 'Unknown Hotel'),
                "subtitle": f"{acc.get('type', 'Hotel')} in {location.title()}",
                "rating": acc.get('rating', 'N/A'),
                "details": {
                    "Price/Night": acc.get('price_per_night', 'N/A'),
                    "Rating": acc.get('rating', 'N/A'),
                    "Room Types": ", ".join(acc.get('room_types', [])[:2]),
                    "Ambiance": ", ".join(acc.get('ambiance', [])[:2]),
                    "Food": ", ".join(acc.get('food_options', [])[:2])
                },
                "highlights": acc.get('extras', [])[:3],
                "action_data": {
                    "accommodation_name": acc.get('name'),
                    "location": location,
                    "check_in": check_in,
                    "check_out": check_out,
                    "guests": guests
                }
            }
            cards.append(card)
            card_id += 1
    
    return {
        "status": "recommendations_ready",
        "type": "swipe_cards",
        "cards": cards,
        "total_count": len(cards),
        "ui_hint": "swipe_interface"
    }


def generate_destination_recommendations(
    preferences: Optional[Dict[str, Any]] = None,
    tool_context: Optional[Any] = None
) -> dict:
    
    """
    Generate swipeable destination recommendations based on preferences.
    
    Args:
        preferences: User preferences (location_type, activities, travel_style, season)
        tool_context: Context object
        
    Returns:
        Dictionary with swipeable destination cards
    """
    from ..sub_agents.destination_info.agent import load_destinations_from_csv, get_current_weather
    
    destinations = load_destinations_from_csv()
    
    # City to image mapping for better images
    city_images = {
        'Mumbai': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=200&fit=crop&auto=format',
        'Delhi': 'https://images.unsplash.com/photo-1587135941948-670b381f08ce?w=400&h=200&fit=crop&auto=format',
        'Goa': 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=400&h=200&fit=crop&auto=format',
        'Jaipur': 'https://images.unsplash.com/photo-1477587458883-47145ed94245?w=400&h=200&fit=crop&auto=format',
        'Agra': 'https://images.unsplash.com/photo-1587135941948-670b381f08ce?w=400&h=200&fit=crop&auto=format',
        'Kerala': 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=400&h=200&fit=crop&auto=format',
        'Rajasthan': 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400&h=200&fit=crop&auto=format',
        'Udaipur': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=200&fit=crop&auto=format',
        'Bangalore': 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?w=400&h=200&fit=crop&auto=format',
        'Chennai': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=400&h=200&fit=crop&auto=format',
    }
    
    cards = []
    card_id = 1
    
    for city_key, dest in destinations.items():
        # Filter by preferences if provided
        if preferences:
            match = True
            
            if 'location_type' in preferences:
                if preferences['location_type'].lower() not in [lt.lower() for lt in dest.get('location_type', [])]:
                    match = False
            
            if 'travel_style' in preferences:
                if preferences['travel_style'].lower() not in [ts.lower() for ts in dest.get('travel_style', [])]:
                    match = False
            
            if 'season' in preferences:
                if preferences['season'].lower() not in [s.lower() for s in dest.get('season_preference', [])]:
                    match = False
            
            if not match:
                continue
        
        # Get current weather for the destination
        weather_info = get_current_weather(dest.get('city', 'Unknown City'))
        
        # Get image for the city
        city_name = dest.get('city', 'Unknown City')
        image_url = city_images.get(city_name, f"https://images.unsplash.com/400x200/?{city_name.replace(' ', '-')},travel&w=400&h=200&fit=crop&auto=format")
        
        card = {
            "id": f"dest_{card_id}",
            "type": "destination",
            "data": dest,
            "title": dest.get('city', 'Unknown City'),
            "subtitle": dest.get('famous_for', ''),
            "description": dest.get('description', ''),
            "location": dest.get('city', 'Unknown City'),
            "rating": 4.5,  # Default rating for destinations
            "image": image_url,
            "current_weather": weather_info,
            "highlights": dest.get('activities', [])[:4],
            "attractions": dest.get('attractions', [])[:3],
            "details": {
                "Location Type": ", ".join(dest.get('location_type', [])[:2]),
                "Travel Style": ", ".join(dest.get('travel_style', [])[:2]),
                "Best Season": ", ".join(dest.get('season_preference', [])[:2]),
                "Cuisine": ", ".join(dest.get('cuisine', [])[:2]),
                "Activities": ", ".join(dest.get('activities', [])[:3])
            },
            "action_data": {
                "location": dest.get('city')
            }
        }
        cards.append(card)
        card_id += 1
    
    return {
        "status": "recommendations_ready",
        "type": "swipe_cards",
        "cards": cards,
        "total_count": len(cards),
        "ui_hint": "swipe_interface"
    }


def handle_swipe_action(
    card_id: str,
    action: str,
    card_data: dict,
    tool_context: Optional[Any] = None
) -> dict:
    """
    Handle user swipe action (right = interested, left = not interested).
    
    Args:
        card_id: Unique card identifier
        action: "swipe_right" (interested) or "swipe_left" (not interested)
        card_data: The card data including action_data
        tool_context: Context object
        
    Returns:
        Dictionary with action result
    """
    if not hasattr(tool_context, 'state'):
        tool_context.state = {}
    
    if "swipe_history" not in tool_context.state:
        tool_context.state["swipe_history"] = {
            "liked": [],
            "disliked": []
        }
    
    card_type = card_data.get('type')
    
    if action == "swipe_right":
        # User is interested - add to liked list
        tool_context.state["swipe_history"]["liked"].append({
            "card_id": card_id,
            "type": card_type,
            "data": card_data.get('action_data', {})
        })
        
        # Auto-save attractions to itinerary
        if card_type == "attraction":
            # Save to itinerary collection
            if "saved_attractions" not in tool_context.state:
                tool_context.state["saved_attractions"] = []
            
            attraction_data = card_data.get('action_data', {})
            tool_context.state["saved_attractions"].append({
                "name": attraction_data.get('attraction', card_data.get('title')),
                "location": attraction_data.get('city', 'Unknown'),
                "description": card_data.get('description', ''),
                "category": attraction_data.get('category', 'General')
            })
            
            total_saved = len(tool_context.state["saved_attractions"])
            message = f"✅ Added {card_data.get('title')} to your itinerary! (Total: {total_saved} attractions)"
            next_step = "continue_swiping"
        else:
            # Auto-book or show booking confirmation for other types
            message = f"✅ Added {card_data.get('title')} to your shortlist!"
            next_step = "explore_more"
            
            if card_type == "travel":
                message = f"✅ Added {card_data.get('title')} to your shortlist! Would you like to book this now?"
                next_step = "book_travel"
            elif card_type == "accommodation":
                message = f"✅ Added {card_data.get('title')} to your shortlist! Would you like to book this accommodation?"
                next_step = "book_accommodation"
            elif card_type == "destination":
                message = f"✅ Added {card_data.get('title')} to your wishlist! Let's explore hotels and travel options."
                next_step = "explore_destination"
        
        return {
            "status": "liked",
            "card_id": card_id,
            "message": message,
            "next_step": next_step,
            "action_data": card_data.get('action_data', {})
        }
    
    elif action == "swipe_left":
        # User is not interested
        tool_context.state["swipe_history"]["disliked"].append({
            "card_id": card_id,
            "type": card_type
        })
        
        return {
            "status": "disliked",
            "card_id": card_id,
            "message": f"👎 Noted! Showing you more options..."
        }
    
    return {
        "status": "error",
        "message": "Invalid swipe action. Use 'swipe_right' or 'swipe_left'"
    }


def get_liked_items(tool_context: Optional[Any] = None) -> dict:
    """
    Get all items user swiped right on.
    
    Args:
        tool_context: Context object
        
    Returns:
        Dictionary with liked items
    """
    if not hasattr(tool_context, 'state'):
        tool_context.state = {}
    
    swipe_history = tool_context.state.get("swipe_history", {})
    liked_items = swipe_history.get("liked", [])
    
    # Organize by type
    organized = {
        "travel": [],
        "accommodation": [],
        "destination": [],
        "attraction": []
    }
    
    for item in liked_items:
        item_type = item.get('type')
        if item_type in organized:
            organized[item_type].append(item.get('data', {}))
    
    return {
        "status": "success",
        "liked_count": len(liked_items),
        "liked_items": organized,
        "message": f"You have {len(liked_items)} items in your shortlist"
    }


def generate_attraction_recommendations(
    city: str,
    tool_context: Optional[Any] = None
) -> dict:
    """
    Generate swipeable attraction cards for a specific city (e.g., Delhi attractions).
    User can swipe right on multiple attractions to visit them all.
    
    Args:
        city: City name (e.g., "Delhi", "Mumbai")
        tool_context: Context object
        
    Returns:
        Dictionary with swipeable attraction cards
    """
    from ..sub_agents.destination_info.agent import load_destination_data_from_csv
    
    destination_data = load_destination_data_from_csv()
    
    # Find the city
    city_info = None
    for dest in destination_data:
        if dest.get('city', '').lower() == city.lower():
            city_info = dest
            break
    
    if not city_info:
        return {
            "status": "error",
            "message": f"City '{city}' not found in our database"
        }
    
    # Extract attractions
    attractions = city_info.get('attractions', [])
    if not attractions:
        return {
            "status": "error",
            "message": f"No attractions found for {city}"
        }
    
    # Create swipeable cards for each attraction
    cards = []
    for idx, attraction in enumerate(attractions, 1):
        card = {
            "id": f"attraction_{city.lower()}_{idx}",
            "type": "attraction",
            "city": city,
            "title": attraction,
            "subtitle": f"{city} • {city_info.get('location_type', [''])[0]}",
            "description": f"Visit {attraction}, one of {city}'s famous landmarks. {city_info.get('description', '')[:100]}",
            "details": {
                "City": city,
                "Category": ", ".join(city_info.get('nearby_attractions_type', [])[:2]),
                "Famous For": city_info.get('famous_for', 'N/A'),
                "Cuisine": ", ".join(city_info.get('cuisine', [])[:2])
            },
            "highlights": city_info.get('activities', [])[:3],
            "action_data": {
                "city": city,
                "attraction": attraction,
                "location_type": city_info.get('location_type', []),
                "activities": city_info.get('activities', [])
            }
        }
        cards.append(card)
    
    return {
        "status": "recommendations_ready",
        "type": "swipe_cards",
        "card_category": "attractions",
        "city": city,
        "cards": cards,
        "total_count": len(cards),
        "ui_hint": "swipe_interface",
        "instructions": "Swipe RIGHT on attractions you want to visit. You can select multiple! Swipe LEFT to skip."
    }


def book_all_liked_attractions(tool_context: Optional[Any] = None) -> dict:
    """
    Book/save all attractions that user swiped right on.
    
    Args:
        tool_context: Context object
        
    Returns:
        Dictionary with booking confirmation for all liked attractions
    """
    if not hasattr(tool_context, 'state'):
        tool_context.state = {}
    
    swipe_history = tool_context.state.get("swipe_history", {})
    liked_items = swipe_history.get("liked", [])
    
    # Filter only attractions
    attractions = [item for item in liked_items if item.get('type') == 'attraction']
    
    if not attractions:
        return {
            "status": "error",
            "message": "No attractions in your wishlist. Swipe right on attractions first!"
        }
    
    # Group by city
    by_city = {}
    for item in attractions:
        data = item.get('data', {})
        city = data.get('city', 'Unknown')
        attraction = data.get('attraction', 'Unknown')
        
        if city not in by_city:
            by_city[city] = []
        by_city[city].append(attraction)
    
    # Save to bookings
    if "booked_attractions" not in tool_context.state:
        tool_context.state["booked_attractions"] = []
    
    booking_id = len(tool_context.state["booked_attractions"]) + 1
    
    booking_record = {
        "booking_id": f"ATR{booking_id:04d}",
        "attractions_by_city": by_city,
        "total_attractions": len(attractions),
        "booking_date": "2025-10-25",  # Current date
        "status": "confirmed"
    }
    
    tool_context.state["booked_attractions"].append(booking_record)
    
    # Create success message
    attraction_list = []
    for city, attrs in by_city.items():
        attraction_list.append(f"\n**{city}:**")
        for attr in attrs:
            attraction_list.append(f"  • {attr}")
    
    message = f"""
🎉 **Successfully Added {len(attractions)} Attractions to Your Trip!**

**Booking ID:** {booking_record['booking_id']}

**Your Attractions:**
{''.join(attraction_list)}

✅ All attractions have been saved to your itinerary.
💡 Next steps: Book hotels near these attractions or plan your travel!
"""
    
    return {
        "status": "booking_confirmed",
        "booking_id": booking_record['booking_id'],
        "total_attractions": len(attractions),
        "attractions_by_city": by_city,
        "message": message
    }
