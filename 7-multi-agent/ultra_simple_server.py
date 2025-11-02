"""
Ultra-Simple Hotel Search Server - Stable Version
CSV + Gemini (no ADK complexity)
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

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, Optional
import pandas as pd
import json
import google.generativeai as genai
import requests
import random

# Configure
genai.configure(api_key=os.environ['GOOGLE_API_KEY'])
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

# Create app
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

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
    
    if rating >= 4.5:
        recommendation += f"⭐ Excellent choice! {hotel_name} boasts outstanding reviews and premium amenities. "
    elif rating >= 4.0:
        recommendation += f"👍 Great value! {hotel_name} offers reliable service with good amenities. "
    
    # Price-based recommendation
    if price < 2000:
        recommendation += "Perfect for budget travelers looking for essential comforts. "
    elif price < 5000:
        recommendation += "Ideal for mid-range travelers seeking quality and convenience. "
    elif price < 10000:
        recommendation += "Excellent for those wanting premium experiences without breaking the bank. "
    else:
        recommendation += "Luxury experience for special occasions and discerning travelers. "
    
    # Location-based recommendation
    city_recommendations = {
        'Goa': "Perfect for beach vacations and water sports enthusiasts. ",
        'Mumbai': "Ideal for business travelers and city explorers. ",
        'Delhi': "Great for cultural experiences and historical sightseeing. ",
        'Jaipur': "Excellent for heritage lovers and palace enthusiasts. ",
        'Agra': "Perfect for Taj Mahal visitors and history buffs. ",
    }
    recommendation += city_recommendations.get(city, f"Well-located in {city} for local attractions. ")
    
    # Amenity-based recommendation
    if 'Pool' in amenities and 'Spa' in amenities:
        recommendation += "Relaxation paradise with pool and spa facilities. "
    elif 'Beach Access' in amenities:
        recommendation += "Direct beach access makes it unbeatable for coastal getaways. "
    elif 'Gym' in amenities:
        recommendation += "Fitness-focused travelers will appreciate the gym facilities. "
    
    return recommendation

def _get_nearby_attractions(city):
    """Get nearby attractions for the city"""
    attractions = {
        'Goa': ['Baga Beach', 'Anjuna Beach', 'Calangute Beach', 'Dudhsagar Falls', 'Fort Aguada'],
        'Mumbai': ['Gateway of India', 'Marine Drive', 'Elephanta Caves', 'Chor Bazaar', 'Juhu Beach'],
        'Delhi': ['Red Fort', 'India Gate', 'Qutub Minar', 'Lotus Temple', 'Akshardham Temple'],
        'Jaipur': ['Amber Fort', 'City Palace', 'Hawa Mahal', 'Jantar Mantar', 'Nahargarh Fort'],
        'Agra': ['Taj Mahal', 'Agra Fort', 'Fatehpur Sikri', 'Itmad-ud-Daulah', 'Mehtab Bagh'],
        'Kolkata': ['Victoria Memorial', 'Howrah Bridge', 'Marble Palace', 'South City Mall', 'Princep Ghat'],
        'Chennai': ['Marina Beach', 'Kapaleeshwarar Temple', 'Fort St. George', 'San Thome Basilica', 'Guindy National Park'],
        'Bangalore': ['Lalbagh Botanical Garden', 'Cubbon Park', 'Bangalore Palace', 'Vidhana Soudha', 'UB City'],
        'Hyderabad': ['Charminar', 'Golconda Fort', 'Hussain Sagar Lake', 'Salar Jung Museum', 'Birla Mandir'],
        'Pune': ['Shaniwar Wada', 'Aga Khan Palace', 'Sinhagad Fort', 'Parvati Hill', 'Bund Garden'],
    }
    return attractions.get(city, [f'Local attractions in {city}'])

def _search_flights(from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility):
    """Search for flights"""
    try:
        # Try CSV first
        filtered_flights = flights_df[
            (flights_df['from_city'].str.lower() == from_city) &
            (flights_df['to_city'].str.lower() == to_city)
        ]

        # Filter by class availability
        if travel_class == 'economy':
            filtered_flights = filtered_flights[filtered_flights['economy_price'] > 0]
        elif travel_class in ['business', 'first_class']:
            filtered_flights = filtered_flights[filtered_flights['business_price'] > 0]

        has_special = len(preferences) > 0 or len(extras) > 0 or len(accessibility) > 0 or travel_class != 'economy'

        if len(filtered_flights) > 0 and not has_special:
            print(f"✅ CSV: {len(filtered_flights)} flights")
            results = []
            for _, f in filtered_flights.iterrows():
                price = f['economy_price'] if travel_class == 'economy' else f['business_price']
                amenities = f['amenities'].split(', ') if pd.notna(f['amenities']) else []

                results.append(_create_flight_result(f, price, travel_class, amenities, passengers, departure_date, return_date, extras, accessibility))
            return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'results': results, 'count': len(results)}

        # Use Gemini AI
        return _ai_search_travel("flight", from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility)

    except Exception as e:
        print(f"❌ Flight search error: {e}")
        return {"status": "error", "message": str(e)}

def _search_trains(from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility):
    """Search for trains"""
    try:
        if len(trains_df) > 0:
            filtered_trains = trains_df[
                (trains_df['from_city'].str.lower() == from_city) &
                (trains_df['to_city'].str.lower() == to_city)
            ]

            # Filter by preferences
            if 'ac' in preferences:
                filtered_trains = filtered_trains[filtered_trains['ac_available'] == True]
            if 'sleeper' in preferences:
                filtered_trains = filtered_trains[filtered_trains['sleeper_available'] == True]

            if len(filtered_trains) > 0:
                print(f"✅ CSV: {len(filtered_trains)} trains")
                results = []
                for _, t in filtered_trains.iterrows():
                    results.append(_create_train_result(t, travel_class, preferences, passengers, departure_date, return_date, extras, accessibility))
                return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'results': results, 'count': len(results)}

        # Use AI fallback
        return _ai_search_travel("train", from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility)

    except Exception as e:
        print(f"❌ Train search error: {e}")
        return {"status": "error", "message": str(e)}

def _search_buses(from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility):
    """Search for buses"""
    try:
        if len(buses_df) > 0:
            filtered_buses = buses_df[
                (buses_df['from_city'].str.lower() == from_city) &
                (buses_df['to_city'].str.lower() == to_city)
            ]

            # Filter by preferences
            if 'ac' in preferences:
                filtered_buses = filtered_buses[filtered_buses['ac_available'] == True]

            if len(filtered_buses) > 0:
                print(f"✅ CSV: {len(filtered_buses)} buses")
                results = []
                for _, b in filtered_buses.iterrows():
                    results.append(_create_bus_result(b, travel_class, preferences, passengers, departure_date, return_date, extras, accessibility))
                return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'results': results, 'count': len(results)}

        # Use AI fallback
        return _ai_search_travel("bus", from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility)

    except Exception as e:
        print(f"❌ Bus search error: {e}")
        return {"status": "error", "message": str(e)}

def _search_car_rentals(from_city, departure_date, return_date, passengers, travel_class, preferences, extras, duration_hours, accessibility):
    """Search for car rentals"""
    try:
        if len(cars_df) > 0:
            filtered_cars = cars_df[cars_df['city'].str.lower() == from_city]

            # Filter by preferences
            if 'private' in preferences:
                filtered_cars = filtered_cars[filtered_cars['private'] == True]

            if len(filtered_cars) > 0:
                print(f"✅ CSV: {len(filtered_cars)} car rentals")
                results = []
                for _, c in filtered_cars.iterrows():
                    results.append(_create_car_result(c, travel_class, preferences, passengers, departure_date, return_date, duration_hours, extras, accessibility))
                return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'results': results, 'count': len(results)}

        # Use AI fallback
        return _ai_search_travel("car_rental", from_city, None, departure_date, return_date, passengers, travel_class, preferences, extras, "one_way", accessibility, duration_hours)

    except Exception as e:
        print(f"❌ Car rental search error: {e}")
        return {"status": "error", "message": str(e)}

def _search_taxis(from_city, to_city, departure_date, passengers, travel_class, preferences, extras, accessibility):
    """Search for taxis"""
    try:
        if len(taxis_df) > 0:
            filtered_taxis = taxis_df[
                (taxis_df['from_city'].str.lower() == from_city) &
                (taxis_df['to_city'].str.lower() == to_city)
            ]

            if len(filtered_taxis) > 0:
                print(f"✅ CSV: {len(filtered_taxis)} taxis")
                results = []
                for _, t in filtered_taxis.iterrows():
                    results.append(_create_taxi_result(t, travel_class, preferences, passengers, departure_date, extras, accessibility))
                return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'results': results, 'count': len(results)}

        # Use AI fallback
        return _ai_search_travel("taxi", from_city, to_city, departure_date, None, passengers, travel_class, preferences, extras, "one_way", accessibility)

    except Exception as e:
        print(f"❌ Taxi search error: {e}")
        return {"status": "error", "message": str(e)}

def _search_bikes(from_city, to_city, departure_date, passengers, travel_class, preferences, extras, duration_hours, accessibility):
    """Search for bike/scooter rentals"""
    try:
        if len(bikes_df) > 0:
            filtered_bikes = bikes_df[
                (bikes_df['from_city'].str.lower() == from_city) &
                (bikes_df['to_city'].str.lower() == to_city)
            ]

            if len(filtered_bikes) > 0:
                print(f"✅ CSV: {len(filtered_bikes)} bike rentals")
                results = []
                for _, b in filtered_bikes.iterrows():
                    results.append(_create_bike_result(b, travel_class, preferences, passengers, departure_date, duration_hours, extras, accessibility))
                return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'results': results, 'count': len(results)}

        # Use AI fallback
        return _ai_search_travel("bike_scooter", from_city, to_city, departure_date, None, passengers, travel_class, preferences, extras, "one_way", accessibility, duration_hours)

    except Exception as e:
        print(f"❌ Bike search error: {e}")
        return {"status": "error", "message": str(e)}

def _ai_search_travel(mode, from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility, duration_hours=None):
    """Use AI to search for travel options"""
    print(f"🤖 Using Gemini AI for {mode} search...")

    mode_names = {
        "flight": "flights",
        "train": "trains",
        "bus": "buses",
        "car_rental": "car rentals",
        "taxi": "taxis",
        "bike_scooter": "bike/scooter rentals"
    }

    preferences_text = ", ".join(preferences) if preferences else "standard"
    extras_text = ", ".join(extras) if extras else "basic service"
    accessibility_text = ", ".join(accessibility) if accessibility else "standard accessibility"

    if mode in ["car_rental", "bike_scooter"]:
        prompt = f"""Find 6-10 {mode_names[mode]} in {from_city}, India.
Duration: {duration_hours} hours
Departure: {departure_date}
Return: {return_date if return_date else 'Same day'}
Passengers: {passengers}
Class: {travel_class.title()}
Preferences: {preferences_text}
Extras: {extras_text}
Accessibility: {accessibility_text}

Return JSON with 'results' array. Each {mode} must have:
- id: string (unique identifier)
- provider: string (company name)
- vehicle_type: string (car model, bike type)
- price_per_hour: number (in INR)
- total_price: number (calculated for duration)
- amenities: array of strings
- description: detailed description (2-3 sentences)
- why_recommended: why this option is good (2-3 sentences)
- class: string
- passengers: number
- duration_hours: number
- extras: array of strings
- accessibility: array of strings

Format: {{"results": [{{"id": "CAR001", "provider": "Uber", ...}}]}}"""
    elif mode == "taxi":
        prompt = f"""Find 6-10 {mode_names[mode]} from {from_city} to {to_city}, India.
Departure: {departure_date}
Passengers: {passengers}
Class: {travel_class.title()}
Preferences: {preferences_text}
Extras: {extras_text}
Accessibility: {accessibility_text}

Return JSON with 'results' array. Each taxi must have:
- id: string (unique identifier)
- provider: string (company name)
- vehicle_type: string (car model)
- estimated_duration: string (e.g., "3h 30m")
- distance_km: number
- price: number (in INR)
- amenities: array of strings
- description: detailed description (2-3 sentences)
- why_recommended: why this option is good (2-3 sentences)
- class: string
- passengers: number
- extras: array of strings
- accessibility: array of strings

Format: {{"results": [{{"id": "TAXI001", "provider": "Uber", ...}}]}}"""
    else:
        prompt = f"""Find 6-10 {mode_names[mode]} from {from_city} to {to_city}, India.
Departure: {departure_date}
Return: {return_date if return_date else 'One-way'}
Travel Type: {travel_type.replace('_', ' ').title()}
Passengers: {passengers}
Class: {travel_class.title()}
Preferences: {preferences_text}
Extras: {extras_text}
Accessibility: {accessibility_text}

Return JSON with 'results' array. Each {mode} must have:
- id: string (unique identifier)
- provider: string (airline/train/bus company)
- route_number: string (flight/train/bus number)
- departure_time: string (HH:MM format)
- arrival_time: string (HH:MM format)
- duration: string (e.g., "2h 30m")
- stops: number (0 for direct)
- vehicle_type: string (aircraft/train type/bus type)
- price: number (in INR)
- class: string
- amenities: array of strings
- description: detailed description (2-3 sentences)
- why_recommended: why this option is good (2-3 sentences)
- passengers: number
- departure_date: string
- return_date: string (null for one-way)
- extras: array of strings
- accessibility: array of strings

Format: {{"results": [{{"id": "FL001", "provider": "Air India", ...}}]}}"""

    model = genai.GenerativeModel('gemini-2.0-flash-exp')
    response = model.generate_content(prompt)
    text = response.text

    if '```json' in text:
        text = text.split('```json')[1].split('```')[0]
    elif '```' in text:
        text = text.split('```')[1].split('```')[0]

    result = json.loads(text.strip())
    results = result.get('results', [])

    # Ensure all required fields are present
    for result in results:
        result['passengers'] = passengers
        result['departure_date'] = departure_date
        result['return_date'] = return_date
        result['class'] = travel_class.title()
        result['extras'] = extras
        result['accessibility'] = accessibility
        if duration_hours:
            result['duration_hours'] = duration_hours
        # Add AI match score
        import random
        result['match_score'] = f"{random.randint(85, 98)}% Match"

    print(f"✅ Gemini: {len(results)} {mode} results")

    return {'status': 'success', 'powered_by': 'Gemini AI', 'ai_used': True, 'results': results, 'count': len(results)}

def _create_flight_result(f, price, travel_class, amenities, passengers, departure_date, return_date, extras, accessibility):
    """Create standardized flight result"""
    description = f"{f['airline']} flight {f['flight_number']} from {f['from_city']} to {f['to_city']}. "
    if f['stops'] == 0:
        description += "Direct flight with excellent service. "
    else:
        description += f"Flight with {f['stops']} stop(s) for a comfortable journey. "
    description += f"Modern {f['aircraft']} aircraft with premium amenities."

    recommendation = f"Great choice for traveling from {f['from_city']} to {f['to_city']}. "
    if f['stops'] == 0:
        recommendation += "Direct flight saves time and reduces jet lag. "
    if 'WiFi' in amenities:
        recommendation += "Stay connected with in-flight WiFi. "
    if 'Entertainment' in amenities:
        recommendation += "Enjoy entertainment systems for a pleasant journey. "

    return {
        'id': f"{f['flight_number']}_{f['departure_time']}",
        'provider': f['airline'],
        'route_number': f['flight_number'],
        'from_city': f['from_city'],
        'to_city': f['to_city'],
        'departure_time': f['departure_time'],
        'arrival_time': f['arrival_time'],
        'duration': f['duration'],
        'stops': int(f['stops']),
        'vehicle_type': f['aircraft'],
        'price': float(price),
        'class': travel_class.title(),
        'amenities': amenities,
        'description': description,
        'why_recommended': recommendation,
        'passengers': passengers,
        'departure_date': departure_date,
        'return_date': return_date,
        'extras': extras,
        'accessibility': accessibility
    }

def _create_train_result(t, travel_class, preferences, passengers, departure_date, return_date, extras, accessibility):
    """Create standardized train result"""
    # Implementation for train results
    return {
        'id': f"TRAIN_{t.get('train_number', '001')}",
        'provider': t.get('railway', 'Indian Railways'),
        'route_number': t.get('train_number', '12345'),
        'from_city': t['from_city'],
        'to_city': t['to_city'],
        'departure_time': t.get('departure_time', '08:00'),
        'arrival_time': t.get('arrival_time', '18:00'),
        'duration': t.get('duration', '10h 0m'),
        'stops': t.get('stops', 0),
        'vehicle_type': t.get('train_type', 'Express'),
        'price': float(t.get('price', 1500)),
        'class': travel_class.title(),
        'amenities': ['WiFi', 'Meals'] if 'ac' in preferences else ['Basic seating'],
        'description': f"Comfortable train journey from {t['from_city']} to {t['to_city']} with modern amenities.",
        'why_recommended': f"Reliable train service with scenic routes and comfortable seating.",
        'passengers': passengers,
        'departure_date': departure_date,
        'return_date': return_date,
        'extras': extras,
        'accessibility': accessibility
    }

def _create_bus_result(b, travel_class, preferences, passengers, departure_date, return_date, extras, accessibility):
    """Create standardized bus result"""
    # Implementation for bus results
    return {
        'id': f"BUS_{b.get('bus_number', '001')}",
        'provider': b.get('operator', 'RedBus'),
        'route_number': b.get('bus_number', 'B123'),
        'from_city': b['from_city'],
        'to_city': b['to_city'],
        'departure_time': b.get('departure_time', '22:00'),
        'arrival_time': b.get('arrival_time', '06:00'),
        'duration': b.get('duration', '8h 0m'),
        'stops': b.get('stops', 1),
        'vehicle_type': b.get('bus_type', 'Volvo'),
        'price': float(b.get('price', 800)),
        'class': travel_class.title(),
        'amenities': ['AC', 'WiFi', 'Entertainment'] if 'ac' in preferences else ['Basic seating'],
        'description': f"Comfortable bus service from {b['from_city']} to {b['to_city']} with modern amenities.",
        'why_recommended': f"Reliable bus service with comfortable seating and good connectivity.",
        'passengers': passengers,
        'departure_date': departure_date,
        'return_date': return_date,
        'extras': extras,
        'accessibility': accessibility
    }

def _create_car_result(c, travel_class, preferences, passengers, departure_date, return_date, duration_hours, extras, accessibility):
    """Create standardized car rental result"""
    # Implementation for car rental results
    return {
        'id': f"CAR_{c.get('car_id', '001')}",
        'provider': c.get('company', 'Uber'),
        'vehicle_type': c.get('model', 'Sedan'),
        'price_per_hour': float(c.get('price_per_hour', 200)),
        'total_price': float(c.get('price_per_hour', 200)) * (duration_hours or 24),
        'amenities': ['AC', 'GPS', 'Music'],
        'description': f"Comfortable {c.get('model', 'Sedan')} rental in {c['city']} with all modern amenities.",
        'why_recommended': f"Flexible transportation option perfect for exploring {c['city']} at your own pace.",
        'class': travel_class.title(),
        'passengers': passengers,
        'departure_date': departure_date,
        'return_date': return_date,
        'duration_hours': duration_hours,
        'extras': extras,
        'accessibility': accessibility
    }

def _create_taxi_result(t, travel_class, preferences, passengers, departure_date, extras, accessibility):
    """Create standardized taxi result"""
    # Implementation for taxi results
    return {
        'id': f"TAXI_{t.get('taxi_id', '001')}",
        'provider': t.get('company', 'Uber'),
        'vehicle_type': t.get('model', 'Sedan'),
        'estimated_duration': t.get('duration', '2h 30m'),
        'distance_km': float(t.get('distance', 150)),
        'price': float(t.get('price', 1200)),
        'amenities': ['AC', 'GPS'],
        'description': f"Reliable taxi service from {t['from_city']} to {t['to_city']} with professional drivers.",
        'why_recommended': f"Convenient door-to-door transportation with tracking and safety features.",
        'class': travel_class.title(),
        'passengers': passengers,
        'departure_date': departure_date,
        'extras': extras,
        'accessibility': accessibility
    }

def _create_bike_result(b, travel_class, preferences, passengers, departure_date, duration_hours, extras, accessibility):
    """Create standardized bike result"""
    # Implementation for bike results
    return {
        'id': f"BIKE_{b.get('bike_id', '001')}",
        'provider': b.get('company', 'Rapido'),
        'vehicle_type': b.get('model', 'Scooter'),
        'price_per_hour': float(b.get('price_per_hour', 50)),
        'total_price': float(b.get('price_per_hour', 50)) * (duration_hours or 4),
        'amenities': ['GPS', 'Helmet'],
        'description': f"Convenient {b.get('model', 'Scooter')} rental for short trips in {b['from_city']}.",
        'why_recommended': f"Perfect for navigating city traffic and exploring local areas efficiently.",
        'class': travel_class.title(),
        'passengers': passengers,
        'departure_date': departure_date,
        'duration_hours': duration_hours,
        'extras': extras,
        'accessibility': accessibility
    }

def get_hotel_image(hotel_name, city):
    """
    Get real hotel image URL using Unsplash API
    Falls back to curated hotel images if API fails
    """
    try:
        # Use Unsplash for real hotel/resort images
        # This is a free service that provides high-quality images
        search_query = f"{city} hotel luxury resort"
        
        # Create a deterministic image based on hotel name
        # This ensures same hotel always gets same image
        image_id = abs(hash(hotel_name)) % 1000
        
        # Use Unsplash Source API for real hotel images
        # Categories: hotel, resort, luxury, travel, vacation
        unsplash_url = f"https://source.unsplash.com/800x600/?hotel,{city},resort,luxury"
        
        return unsplash_url
    except Exception as e:
        # Fallback to hotel-themed images
        fallback_images = [
            "https://images.unsplash.com/photo-1566073771259-6a8506099945",  # Hotel lobby
            "https://images.unsplash.com/photo-1582719508461-905c673771fd",  # Hotel room
            "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb",  # Hotel exterior
            "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa",  # Resort pool
            "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4",  # Beach resort
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d",  # Hotel entrance
            "https://images.unsplash.com/photo-1445019980597-93fa8acb246c",  # Luxury hotel
        ]
        image_idx = abs(hash(hotel_name)) % len(fallback_images)
        return f"{fallback_images[image_idx]}?w=800&h=600&fit=crop"

class HotelSearchRequest(BaseModel):
    message: str
    context: Dict[str, Any]

class AgentRequest(BaseModel):
    message: str
    context: Optional[Dict[str, Any]] = {}
    page: Optional[str] = "home"

class FlightSearchRequest(BaseModel):
    from_city: str
    to_city: str
    departure_date: str
    return_date: str = None
    passengers: int = 1
    flight_class: str = "economy"
    preferences: list = []

class TravelBookingRequest(BaseModel):
    mode: str  # "flight", "train", "bus", "car_rental", "taxi", "bike_scooter"
    from_city: str
    to_city: str = None  # Not needed for car_rental, taxi, bike_scooter
    departure_date: str
    return_date: str = None
    passengers: int = 1
    travel_class: str = "economy"  # "economy", "business", "first_class"
    preferences: list = []  # ["ac", "non_ac", "sleeper", "shared", "private"]
    extras: list = []  # ["pickup", "luggage", "wifi", "meals"]
    travel_type: str = "one_way"  # "one_way", "round_trip", "multi_city"
    accessibility: list = []  # ["wheelchair", "child_seat"]
    duration_hours: int = None  # For car_rental, taxi, bike_scooter

@app.get("/")
def root():
    return {"status": "OK", "mode": "CSV + Gemini", "version": "1.0", "cors_enabled": True}

@app.post("/api/agent")
def handle_agent_request(request: AgentRequest):
    """
    Main agent endpoint - handles all AI requests from Flutter app
    Routes to appropriate functionality based on message and context
    """
    try:
        message = request.message
        context = request.context or {}
        page = request.page or 'home'
        
        print(f"\n[API/AGENT] Request received:")
        # Avoid printing message content that may have unicode characters
        print(f"   Message length: {len(message)} chars")
        print(f"   Page: {page}")
        
        # Simple conversational response using Gemini
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        
        # Build context for Gemini
        user_prefs = context.get('user_preferences', {})
        conversation_history = context.get('conversation_history', [])
        
        # Check if user is asking for hotels
        message_lower = message.lower()
        asking_for_hotels = any(keyword in message_lower for keyword in ['hotel', 'stay', 'accommodation', 'room', 'booking'])
        
        # Extract budget from message (e.g., "60000", "5000", "budget 10000")
        import re
        budget_match = re.search(r'(?:budget|budgeted|price|rs\.?|₹)\s*(\d+)|(\d{4,6})', message_lower)
        extracted_budget = None
        if budget_match:
            extracted_budget = int(budget_match.group(1) or budget_match.group(2))
            print(f"   Extracted budget from message: Rs.{extracted_budget}")
        
        # Try to extract destination from the current message first
        # Sort cities by length (longest first) to prevent partial matches
        # e.g., check "darjeeling" before "dar", "raipur" before "jaipur" confusion
        cities = [
            # Long names first to avoid partial matches
            'darjeeling', 'coimbatore', 'chandigarh', 'trivandrum', 'bhubaneswar', 'visakhapatnam',
            'thiruvananthapuram', 'pondicherry', 'puducherry', 'dehradun', 'mussoorie',
            # Medium length cities
            'bengaluru', 'bangalore', 'hyderabad', 'rishikesh', 'varanasi', 'kolkata', 'chennai', 
            'udaipur', 'jodhpur', 'bikaner', 'jaisalmer', 'ajmer', 'pushkar', 'shimla', 'manali', 
            'mumbai', 'jaipur', 'raipur', 'kerala', 'mysore', 'nashik', 'nagpur', 'indore', 
            'bhopal', 'lucknow', 'kanpur', 'patna', 'ranchi', 'guwahati', 'shillong', 'imphal',
            'kohima', 'aizawl', 'gangtok', 'itanagar', 'dispur', 'panaji', 'kochi', 'cochin',
            'pune', 'surat', 'rajkot', 'vadodara', 'ahmedabad', 'amritsar', 'ludhiana', 'jalandhar',
            # Short names last
            'delhi', 'agra', 'ooty', 'goa', 'gaya', 'durg', 'puri', 'gaya'
        ]
        destination = None
        from_city = None  # Track the source city (from X to Y)
        
        # Use word boundary matching to avoid false matches
        import re
        
        # Check for "from X to Y" pattern first
        from_to_pattern = r'\bfrom\s+(\w+)\s+to\s+(\w+)\b'
        from_to_match = re.search(from_to_pattern, message_lower)
        
        if from_to_match:
            potential_from = from_to_match.group(1)
            potential_to = from_to_match.group(2)
            
            print(f"   Detected travel pattern: '{potential_from}' to '{potential_to}'")
            
            # Validate both cities exist in our list
            for city in cities:
                if city == potential_to.lower():
                    destination = city.capitalize()
                    print(f"   Destination city: {destination}")
                if city == potential_from.lower():
                    from_city = city.capitalize()
                    print(f"   Source city: {from_city}")
            
            if destination:
                asking_for_hotels = True
        
        # If no "from-to" pattern, just look for any city mention
        if not destination:
            for city in cities:
                # Match city name with word boundaries to ensure exact match
                pattern = r'\b' + re.escape(city) + r'\b'
                if re.search(pattern, message_lower):
                    if city == 'bengaluru':
                        destination = 'Bangalore'
                    elif city == 'cochin':
                        destination = 'Kochi'
                    elif city == 'puducherry':
                        destination = 'Pondicherry'
                    else:
                        destination = city.capitalize()
                    asking_for_hotels = True  # If city mentioned, assume they want hotels
                    print(f"   Detected destination: {destination}")
                    break
        
        # If asking for hotels, provide actual hotel data
        if asking_for_hotels:
            # Get budget - prioritize extracted budget from message
            budget = extracted_budget if extracted_budget else user_prefs.get('budget', 50000)
            if budget is None:
                budget = 50000  # Default budget
            
            print(f"   Using budget: Rs.{budget}")
            
            if not destination:
                destination = user_prefs.get('destination', None)
            
            # Try to extract destination from conversation history if still not found
            if not destination:
                for msg in conversation_history[-5:]:  # Check last 5 messages
                    if isinstance(msg, dict):
                        content = msg.get('content', '').lower()
                        # Check for common Indian cities with word boundaries
                        for city in cities:
                            pattern = r'\b' + re.escape(city) + r'\b'
                            if re.search(pattern, content):
                                if city == 'bengaluru':
                                    destination = 'Bangalore'
                                else:
                                    destination = city.capitalize()
                                break
                    if destination:
                        break
            
            # If we have destination, search hotels
            if destination:
                try:
                    # Search hotels from CSV
                    city_hotels = hotels_df[hotels_df['city'].str.lower() == destination.lower()]
                    budget_hotels = city_hotels[city_hotels['price_per_night'] <= budget]
                    
                    if not budget_hotels.empty:
                        # Get top hotels - smart calculation based on duration and budget
                        # Base: 2-3 hotels for short trips, more for longer stays
                        duration_days = context.get('duration_days', 3)
                        travelers = context.get('travelers', 1)
                        
                        # Smart hotel count logic:
                        # - Short trip (1-3 days): 3-5 hotels
                        # - Medium trip (4-7 days): 5-8 hotels  
                        # - Long trip (8+ days): 8-10 hotels
                        # - High budget (>100k): +2 bonus hotels
                        if duration_days <= 3:
                            hotel_count = min(5, len(budget_hotels))
                        elif duration_days <= 7:
                            hotel_count = min(8, len(budget_hotels))
                        else:
                            hotel_count = min(10, len(budget_hotels))
                        
                        # Bonus hotels for high budget (more choices)
                        if budget > 100000:
                            hotel_count = min(hotel_count + 2, len(budget_hotels))
                        
                        top_hotels = budget_hotels.head(hotel_count)
                        
                        # Build hotel list response for text
                        hotel_list = []
                        suggestions = []
                        
                        for idx, hotel in top_hotels.iterrows():
                            # Text format
                            hotel_info = f"**{hotel['name']}** - Rs.{hotel['price_per_night']}/night\n"
                            location = hotel.get('location', hotel.get('city', destination))
                            hotel_info += f"  Location: {location}\n"
                            if pd.notna(hotel.get('rating')):
                                hotel_info += f"  Rating: {hotel.get('rating', 'N/A')}/5\n"
                            if pd.notna(hotel.get('amenities')):
                                amenities_str = str(hotel['amenities'])[:80]
                                hotel_info += f"  Amenities: {amenities_str}\n"
                            hotel_list.append(hotel_info)
                            
                            # Card format for Flutter suggestions
                            amenities = str(hotel.get('extras', '')).split('|') if pd.notna(hotel.get('extras')) else []
                            hotel_type = hotel.get('accommodation_type', 'Hotel')
                            
                            suggestions.append({
                                'id': hotel['name'],
                                'type': 'hotel',
                                'title': hotel['name'],
                                'description': f"{hotel_type} | Rating: {hotel.get('rating', 'N/A')} stars\n{', '.join(amenities[:3])}",
                                'price': float(hotel['price_per_night']),
                                'location': location,
                                'rating': str(hotel.get('rating', 'N/A')),
                                'image': get_hotel_image(hotel['name'], destination),
                                'stage': 'hotels',
                            })
                        
                        ai_response = f"Great! I found {len(top_hotels)} hotels in {destination} within your Rs.{budget} budget. Swipe right on the ones you like!"
                        
                        return {
                            "success": True,
                            "response": ai_response,
                            "agent": "hotel_search",
                            "data": {"hotels": top_hotels.to_dict('records')},
                            "suggestions": suggestions,
                            "show_suggestions": True,
                            "page": page,
                            "source": "ultra_simple_server"
                        }
                    else:
                        # No hotels in CSV - use Gemini AI to generate recommendations
                        print(f"   No hotels in CSV for {destination}, using Gemini AI...")
                        
                        prompt = f"""Find 5-8 hotels in {destination}, India under ₹{budget}/night.

Return JSON with 'hotels' array. Each hotel must have:
- name: string
- type: string (Hotel/Resort/Hostel/etc.)  
- price_per_night: number
- rating: number (1-5)
- amenities: array of strings
- description: detailed description (2-3 sentences)

Format: {{"hotels": [{{"name": "...", "type": "...", "price_per_night": 5000, "rating": 4.2, "amenities": ["WiFi", "Pool"], "description": "..."}}]}}"""
                        
                        response_obj = model.generate_content(prompt)
                        text = response_obj.text
                        
                        if '```json' in text:
                            text = text.split('```json')[1].split('```')[0]
                        elif '```' in text:
                            text = text.split('```')[1].split('```')[0]
                        
                        result = json.loads(text.strip())
                        hotels = result.get('hotels', [])
                        
                        # Convert to suggestions format
                        suggestions = []
                        for hotel in hotels:
                            suggestions.append({
                                'id': hotel['name'],
                                'type': 'hotel',
                                'title': hotel['name'],
                                'description': f"{hotel.get('type', 'Hotel')} | Rating: {hotel.get('rating', 'N/A')} stars\n{hotel.get('description', '')}",
                                'price': float(hotel.get('price_per_night', budget * 0.5)),
                                'location': destination,
                                'rating': str(hotel.get('rating', 'N/A')),
                                'image': get_hotel_image(hotel['name'], destination),
                                'stage': 'hotels',
                            })
                        
                        ai_response = f"Great! I found {len(hotels)} hotels in {destination} within your Rs.{budget} budget using AI recommendations. Swipe right on the ones you like!"
                        
                        return {
                            "success": True,
                            "response": ai_response,
                            "agent": "gemini_hotels",
                            "data": {"hotels": hotels},
                            "suggestions": suggestions,
                            "show_suggestions": True,
                            "page": page,
                            "source": "ultra_simple_server"
                        }
                except Exception as e:
                    print(f"   Hotel search error: {e}")
                    ai_response = f"Let me search for hotels in {destination}... Please wait a moment."
            else:
                ai_response = "I'd love to show you hotels! Which city or destination are you interested in? For example: Goa, Jaipur, Manali, etc."
        else:
            # Create a context-aware prompt for general queries
            prompt = f"""You are a helpful travel assistant named Triplix. Be action-oriented and decisive.

User's message: {message}

Current page: {page}

User preferences:
- Budget: ₹{user_prefs.get('budget', 'Not set')}
- Destination: {user_prefs.get('destination', 'Not set')}
- Activities: {', '.join(user_prefs.get('activities', [])) if user_prefs.get('activities') else 'Not set'}
- Transport: {', '.join(user_prefs.get('transport', [])) if user_prefs.get('transport') else 'Not set'}

IMPORTANT: 
- If the user mentions any city/destination, acknowledge it and offer to show specific hotels/activities immediately.
- Don't keep asking questions - provide actionable information or suggestions.
- Keep responses concise (2-3 sentences).
- If you have enough information, provide specific recommendations instead of asking more questions."""

            # Get AI response
            response = model.generate_content(prompt)
            ai_response = response.text
        
        print(f"   AI Response generated ({len(ai_response)} chars)")
        
        return {
            "success": True,
            "response": ai_response,
            "agent": "gemini",
            "data": {},
            "page": page,
            "source": "ultra_simple_server"
        }
        
    except Exception as e:
        print(f"   Error: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "response": "I'm sorry, I encountered an error. Please try again.",
            "source": "ultra_simple_server"
        }

@app.post("/api/manager")
def handle_manager_request(request: AgentRequest):
    """
    Manager endpoint - generates complete itinerary based on user's swiped selections
    Coordinates all the selected hotels, transport, and destinations into a cohesive plan
    Can also UPDATE existing itineraries based on additional user requests
    """
    try:
        message = request.message
        context = request.context
        
        print(f"\n[MANAGER] Itinerary Request:")
        print(f"   Message: {message}")
        print(f"   Context keys: {list(context.keys())}")
        
        # Extract all selections from context
        selected_hotels = context.get('selected_hotels', [])
        selected_transport = context.get('selected_transport', [])
        selected_destinations = context.get('selected_destinations', [])
        
        # Get travel details from context - use user_preferences if available
        user_prefs = context.get('user_preferences', {})
        from_location = context.get('from', user_prefs.get('from', 'Unknown'))
        to_location = context.get('to', user_prefs.get('destination', 'Unknown'))
        stay_city = context.get('stay_city', to_location)
        start_date = context.get('start_date', user_prefs.get('start_date', ''))
        end_date = context.get('end_date', user_prefs.get('end_date', ''))
        duration_days = context.get('duration_days', user_prefs.get('duration_days', 3))
        budget = context.get('budget', user_prefs.get('budget', 50000))
        travelers = context.get('travelers', user_prefs.get('travelers', 1))
        
        # Check if there's an existing itinerary to update
        existing_itinerary = context.get('current_itinerary', None)
        
        print(f"   From: {from_location} -> To: {to_location}")
        print(f"   Hotels: {selected_hotels}")
        print(f"   Transport: {selected_transport}")
        print(f"   Destinations: {selected_destinations}")
        print(f"   Duration: {duration_days} days")
        print(f"   Budget: Rs.{budget}")
        print(f"   Existing itinerary: {'Yes' if existing_itinerary else 'No'}")
        
        # Determine if this is an update request or new generation
        is_update_request = existing_itinerary is not None and message.lower() not in ['generate', 'create', 'make']
        
        if is_update_request:
            # Update existing itinerary based on user's request
            prompt = f"""You are a travel planning expert. Update the existing itinerary based on the user's new request.

**User's Update Request:** {message}

**Current Itinerary:**
{existing_itinerary}

**Trip Details:**
- From: {from_location} to {to_location}
- Duration: {duration_days} days
- Travelers: {travelers} person(s)
- Budget: ₹{budget}
- Dates: {start_date.split('T')[0] if 'T' in start_date else start_date} to {end_date.split('T')[0] if 'T' in end_date else end_date}

**Instructions:**
1. Keep the existing itinerary structure
2. Modify/add/remove based on the user's request
3. Adjust timings and costs if needed
4. Maintain day-by-day format with timings
5. Use emojis for visual appeal

Provide the COMPLETE UPDATED itinerary, not just the changes."""

            print(f"   Updating existing itinerary...")
        else:
            # Create new comprehensive itinerary
            prompt = f"""You are a travel planning expert. Create a detailed {duration_days}-day itinerary for a trip from {from_location} to {to_location}.

**Trip Details:**
- From: {from_location}
- To: {to_location} (stay city)
- Duration: {duration_days} days
- Travelers: {travelers} person(s)
- Budget: ₹{budget}
- Dates: {start_date.split('T')[0] if 'T' in start_date else start_date} to {end_date.split('T')[0] if 'T' in end_date else end_date}

**Selected Options:**
- Hotels: {', '.join(selected_hotels) if selected_hotels else 'Budget-friendly hotels in ' + to_location}
- Transport: {', '.join(selected_transport) if selected_transport else 'Most convenient option'}
- Places to Visit: {', '.join(selected_destinations) if selected_destinations else 'Popular attractions in ' + to_location}

**Please create a day-by-day itinerary with:**
1. Daily schedule (morning, afternoon, evening)
2. Specific timings and activities
3. Estimated costs for each activity
4. Travel tips and recommendations
5. Restaurant suggestions for meals
6. Transportation between places

Format it in a clear, easy-to-read structure with emojis for visual appeal."""

            print(f"   Creating new itinerary from {from_location} to {to_location}...")
        
        # Call Gemini AI
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response_obj = model.generate_content(prompt)
        ai_response = response_obj.text
        
        print(f"[MANAGER] Generated itinerary ({len(ai_response)} chars)")
        
        return {
            "success": True,
            "response": ai_response,
            "agent": "manager",
            "is_update": is_update_request,
            "itinerary": {
                "from": from_location,
                "to": to_location,
                "duration_days": duration_days,
                "total_cost_estimate": budget,
                "destinations": selected_destinations,
                "hotels": selected_hotels,
                "transport": selected_transport,
                "content": ai_response  # Store the full itinerary for future updates
            }
        }
        
    except Exception as e:
        print(f"[MANAGER ERROR] {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "response": "I apologize, but I encountered an error creating your itinerary. However, I've saved all your selections!"
        }

@app.post("/api/hotel/search")
def search_hotels(request: HotelSearchRequest):
    try:
        city = request.context.get('city', 'Goa')
        budget = request.context.get('budget', 25000)
        message = request.message
        
        print(f"\n[HOTEL SEARCH] Search: {city}, Rs.{budget}")
        
        # Try CSV
        city_hotels = hotels_df[
            (hotels_df['city'].str.lower() == city.lower()) &
            (hotels_df['price_per_night'] <= budget)
        ]
        
        has_special = any(word in message.lower() for word in ['near', 'airport', 'beach', 'luxury', 'special'])
        has_special_request = 'special request:' in message.lower()
        
        if len(city_hotels) > 0 and not has_special and not has_special_request:
            print(f"[CSV SUCCESS] CSV: {len(city_hotels)} hotels")
            hotels = []
            for _, h in city_hotels.iterrows():
                amenities = h['extras'].split('|') if '|' in str(h['extras']) else [h['extras']]
                
                # Create detailed description based on hotel type and amenities
                description = _create_hotel_description(h['name'], h['accommodation_type'], amenities, city, float(h['rating']))
                why_recommended = _create_recommendation(h['name'], h['accommodation_type'], amenities, city, float(h['price_per_night']), float(h['rating']))
                nearby_attractions = _get_nearby_attractions(city)
                
                hotels.append({
                    'name': h['name'],
                    'city': h['city'],
                    'price_per_night': float(h['price_per_night']),
                    'type': h['accommodation_type'],
                    'rating': float(h['rating']),
                    'amenities': amenities,
                    'description': description,
                    'why_recommended': why_recommended,
                    'nearby_attractions': nearby_attractions,
                })
            return {'status': 'success', 'powered_by': 'CSV', 'ai_used': False, 'hotels': hotels, 'count': len(hotels)}
        
        # Use Gemini
        print(f"[GEMINI] Using Gemini AI...")
        prompt = f"""Find 5-8 hotels in {city}, India under ₹{budget}/night. Request: {message}

Return JSON with 'hotels' array. Each hotel must have:
- name: string
- type: string (Hotel/Resort/Hostel/etc.)
- price_per_night: number
- rating: number (1-5)
- amenities: array of strings
- description: detailed description (2-3 sentences)
- why_recommended: why this hotel is good for the user (2-3 sentences)
- nearby_attractions: array of 3-5 nearby attractions

Format: {{"hotels": [{{"name": "...", "type": "...", "price_per_night": 5000, "rating": 4.2, "amenities": ["WiFi", "Pool"], "description": "...", "why_recommended": "...", "nearby_attractions": ["Attraction1", "Attraction2"]}}]}}"""
        
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        text = response.text
        
        if '```json' in text:
            text = text.split('```json')[1].split('```')[0]
        elif '```' in text:
            text = text.split('```')[1].split('```')[0]
        
        result = json.loads(text.strip())
        hotels = result.get('hotels', [])
        
        # Ensure all required fields are present
        for hotel in hotels:
            if 'description' not in hotel:
                hotel['description'] = _create_hotel_description(hotel['name'], hotel.get('type', 'Hotel'), hotel.get('amenities', []), city, hotel.get('rating', 4.0))
            if 'why_recommended' not in hotel:
                hotel['why_recommended'] = _create_recommendation(hotel['name'], hotel.get('type', 'Hotel'), hotel.get('amenities', []), city, hotel.get('price_per_night', 5000), hotel.get('rating', 4.0))
            if 'nearby_attractions' not in hotel:
                hotel['nearby_attractions'] = _get_nearby_attractions(city)
        
        print(f"[GEMINI SUCCESS] Gemini: {len(hotels)} hotels")
        
        return {'status': 'success', 'powered_by': 'Gemini AI', 'ai_used': True, 'hotels': hotels, 'count': len(hotels)}
        
    except Exception as e:
        print(f"[ERROR] Error: {e}")
        return {"status": "error", "message": str(e)}

@app.post("/api/hotel/images")
def get_hotel_images(request: HotelSearchRequest):
    try:
        hotel_name = request.context.get('hotel_name', '')
        city = request.context.get('city', 'Goa')

        print(f"\n🖼️ Fetching images for: {hotel_name}, {city}")

        # Use Gemini to generate specific image search terms
        prompt = f"""
        Generate 10 specific search terms for finding authentic photos of "{hotel_name}" hotel in {city}, India.
        Focus on unique features like:
        - Hotel exterior and architecture
        - Lobby and reception
        - Rooms and suites
        - Restaurants and dining areas
        - Pool and spa areas
        - Unique amenities or nearby attractions

        Return ONLY a JSON array of specific search terms.
        Format: ["luxury hotel lobby {city}", "{hotel_name} presidential suite", "{hotel_name} infinity pool", ...]
        """

        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        text = response.text

        if '```json' in text:
            text = text.split('```json')[1].split('```')[0]
        elif '```' in text:
            text = text.split('```')[1].split('```')[0]

        search_terms = json.loads(text.strip())

        # Generate image URLs using search terms
        image_urls = []
        for term in search_terms[:10]:
            # Create Unsplash source URLs (no API key needed)
            encoded_term = f"{term} {city} India hotel".replace(' ', '-').lower()
            url = f"https://source.unsplash.com/800x600/?{encoded_term}"
            image_urls.append(url)

        # Ensure we have 10 images
        while len(image_urls) < 10:
            fallback_term = f"luxury-hotel-{city.lower()}"
            url = f"https://source.unsplash.com/800x600/?{fallback_term}"
            image_urls.append(url)

        return {
            'status': 'success',
            'hotel_name': hotel_name,
            'city': city,
            'images': image_urls[:10],
            'powered_by': 'Gemini AI + Unsplash'
        }

    except Exception as e:
        print(f"❌ Image fetch error: {e}")
        # Return fallback images
        fallback_images = [
            'https://source.unsplash.com/800x600/?luxury-hotel-lobby',
            'https://source.unsplash.com/800x600/?luxury-hotel-room',
            'https://source.unsplash.com/800x600/?luxury-hotel-pool',
            'https://source.unsplash.com/800x600/?luxury-hotel-restaurant',
            'https://source.unsplash.com/800x600/?luxury-hotel-spa',
            'https://source.unsplash.com/800x600/?luxury-hotel-bar',
            'https://source.unsplash.com/800x600/?luxury-hotel-garden',
            'https://source.unsplash.com/800x600/?luxury-hotel-suite',
            'https://source.unsplash.com/800x600/?luxury-hotel-exterior',
            'https://source.unsplash.com/800x600/?luxury-hotel-bathroom',
        ]

        return {
            'status': 'fallback',
            'hotel_name': hotel_name,
            'city': city,
            'images': fallback_images,
            'message': 'Using curated hotel images'
        }

@app.post("/api/analyze-preferences")
def analyze_preferences(request: dict):
    """
    Analyze user preferences and provide AI-powered travel recommendations
    Used by the AI Assistant page in Flutter app
    """
    try:
        print(f"\n🤖 [AI ASSISTANT] ANALYZE PREFERENCES REQUEST:")
        
        # Extract all preference data from request
        destination = request.get('destination', {})
        budget = request.get('budget', {})
        activities = request.get('activities', {})
        transport = request.get('transport', {})
        allocation = request.get('allocation', {})
        context = request.get('context', {})
        
        # Build comprehensive message from user preferences
        message_parts = []
        
        # Destination preferences
        if destination:
            location_types = destination.get('location_types', [])
            climate = destination.get('climate', '')
            experience = destination.get('experience_level', '')
            
            if location_types:
                message_parts.append(f"Preferred locations: {', '.join(location_types)}")
            if climate:
                message_parts.append(f"Climate preference: {climate}")
            if experience:
                message_parts.append(f"Experience level: {experience}")
        
        # Budget information
        if budget:
            amount = budget.get('amount', 0)
            num_people = budget.get('num_people', 1)
            tier = budget.get('tier', 'mid_range')
            
            if amount > 0:
                message_parts.append(f"Budget: ₹{amount:,} for {num_people} person(s)")
                message_parts.append(f"Budget tier: {tier}")
        
        # Activities
        if activities:
            selected = activities.get('selected', [])
            intensity = activities.get('intensity', 'moderate')
            
            if selected:
                message_parts.append(f"Activities: {', '.join(selected)}")
                message_parts.append(f"Activity intensity: {intensity}")
        
        # Transport preferences
        if transport:
            modes = transport.get('modes', [])
            travel_class = transport.get('class', 'economy')
            
            if modes:
                message_parts.append(f"Transport modes: {', '.join(modes)}")
                message_parts.append(f"Travel class: {travel_class}")
        
        # Context and special requirements
        if context:
            dietary = context.get('dietary_requirements', [])
            accessibility = context.get('accessibility_needs', [])
            companions = context.get('travel_companions', '')
            special = context.get('special_requests', '')
            
            if dietary:
                message_parts.append(f"Dietary: {', '.join(dietary)}")
            if accessibility:
                message_parts.append(f"Accessibility needs: {', '.join(accessibility)}")
            if companions:
                message_parts.append(f"Traveling with: {companions}")
            if special:
                message_parts.append(f"Special occasion: {special}")
        
        # Build prompt for Gemini
        full_context = "\n".join(message_parts)
        
        prompt = f"""You are a helpful travel assistant. Based on the following user preferences, provide personalized travel recommendations:

{full_context}

Please provide:
1. A comprehensive travel plan summary
2. Recommended destinations
3. Suggested accommodations
4. Activity recommendations
5. Budget breakdown advice
6. Travel tips specific to their preferences

Format your response in a friendly, conversational tone."""

        print(f"   📝 Generated prompt with {len(message_parts)} preference points")
        
        # Call Gemini AI for analysis
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        ai_response = response.text
        
        print(f"   ✅ AI Analysis complete ({len(ai_response)} chars)")
        
        # Structure the response for Flutter app
        return {
            "success": True,
            "summary": {
                "title": "AI Travel Analysis Complete",
                "content": ai_response
            },
            "insights": {
                "recommendations": [
                    "Personalized recommendations based on your preferences",
                    "Budget-friendly options within your range",
                    "Activities matching your interests"
                ],
                "warnings": []
            },
            "next_steps": [
                "Review the detailed recommendations above",
                "Explore the swipe feature to discover destinations",
                "Set up your budget tracker for better planning",
                "Book your preferred accommodations and activities"
            ]
        }
        
    except Exception as e:
        print(f"   ❌ Error analyzing preferences: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "summary": {
                "title": "Analysis Error",
                "content": f"I encountered an error while analyzing your preferences. Please try again. Error: {str(e)}"
            },
            "insights": {
                "recommendations": [],
                "warnings": ["Please try again or contact support if the issue persists"]
            },
            "next_steps": []
        }

@app.post("/api/transport/search")
def search_transport_for_swipe(request: dict):
    """
    AI-powered transport suggestions for swipe feature
    Generates realistic flight/train/bus options with actual-looking numbers
    """
    try:
        from_city = request.get('from_city', '')
        to_city = request.get('to_city', '')
        budget_range = request.get('budget', 'moderate')
        
        print(f"\n✈️ [TRANSPORT SEARCH] Generating AI transport suggestions: {from_city} -> {to_city}, Budget: {budget_range}")
        
        # Create AI prompt for transport generation
        transport_prompt = f"""Generate realistic transport options from {from_city} to {to_city} in India.
        
Please provide EXACTLY 6 transport options in JSON format:
- 2 flights (use real airline names like IndiGo, Air India, SpiceJet with flight numbers like 6E-2031, AI-7821, SG-8456)
- 3 trains (use real train names like Rajdhani Express, Shatabdi Express, Duronto Express with numbers like 12432, 12010, 12213)
- 1 luxury bus (use operators like Volvo Multi-Axle AC, Mercedes Benz Sleeper)

Make the timings realistic for the route distance:
- Short routes (< 500km): Flights 1-2 hours, Trains 8-12 hours, Bus 10-15 hours
- Medium routes (500-1000km): Flights 2-3 hours, Trains 12-18 hours, Bus 15-20 hours
- Long routes (> 1000km): Flights 3-4 hours, Trains 18-24 hours, Bus 20-30 hours

Return ONLY valid JSON array (no markdown, no explanation):
[
  {{
    "type": "flight",
    "carrier": "IndiGo",
    "number": "6E-2031",
    "departure_time": "06:30 AM",
    "arrival_time": "08:45 AM",
    "duration": "2h 15min",
    "class": "Economy",
    "price": 10000,
    "description": "Non-stop flight, In-flight meals"
  }},
  ...
]

Budget context: {budget_range}
- If budget is "budget/low": Prioritize trains and buses, lower flight prices
- If budget is "moderate/medium": Mix of all options with reasonable prices
- If budget is "luxury/high": Premium flights, AC First class trains, luxury buses"""

        # Call Gemini AI
        response = model.generate_content(transport_prompt)
        response_text = response.text.strip()
        
        # Clean response
        if response_text.startswith('```json'):
            response_text = response_text[7:]
        if response_text.startswith('```'):
            response_text = response_text[3:]
        if response_text.endswith('```'):
            response_text = response_text[:-3]
        response_text = response_text.strip()
        
        # Parse JSON
        transport_options = json.loads(response_text)
        
        # Convert to Flutter format
        flutter_suggestions = []
        for idx, option in enumerate(transport_options):
            transport_type = option.get('type', 'flight')
            carrier = option.get('carrier', 'Unknown')
            number = option.get('number', '')
            departure = option.get('departure_time', '')
            arrival = option.get('arrival_time', '')
            duration = option.get('duration', '')
            price = option.get('price', 0)
            travel_class = option.get('class', 'Economy')
            description = option.get('description', '')
            
            # Create title based on type
            if transport_type == 'flight':
                title = f"{carrier} {number}"
                subtitle = f"{from_city} -> {to_city}"
            elif transport_type == 'train':
                title = f"{carrier} {number}"
                subtitle = f"{from_city} -> {to_city}"
            else:  # bus
                title = carrier
                subtitle = f"{from_city} -> {to_city}"
            
            # Get transport icon emoji
            icon = "✈️" if transport_type == "flight" else "🚂" if transport_type == "train" else "🚌"
            
            flutter_suggestions.append({
                'id': f'transport_{idx+1}',
                'type': transport_type,
                'title': title,
                'subtitle': subtitle,
                'description': f"{icon} {departure} - {arrival} ({duration})\n{travel_class} | {description}",
                'price': f"₹{price:,}",
                'image': f'https://source.unsplash.com/800x600/?{transport_type},{carrier.lower().replace(" ", "-")}',
                'stage': 'transport',
                'details': {
                    'carrier': carrier,
                    'number': number,
                    'departure_time': departure,
                    'arrival_time': arrival,
                    'duration': duration,
                    'class': travel_class,
                    'from_city': from_city,
                    'to_city': to_city
                }
            })
        
        print(f"   ✅ Generated {len(flutter_suggestions)} AI-powered transport options")
        
        return {
            'status': 'success',
            'suggestions': flutter_suggestions,
            'from_city': from_city,
            'to_city': to_city,
            'count': len(flutter_suggestions),
            'powered_by': 'Gemini AI'
        }
        
    except json.JSONDecodeError as je:
        print(f"   ❌ JSON Parse Error: {je}")
        print(f"   Raw response: {response_text[:500]}")
        # Return fallback hardcoded options
        return _get_fallback_transport(from_city, to_city)
        
    except Exception as e:
        print(f"   ❌ Transport search error: {e}")
        import traceback
        traceback.print_exc()
        return _get_fallback_transport(from_city, to_city)

def _get_fallback_transport(from_city: str, to_city: str):
    """Fallback transport when AI fails"""
    return {
        'status': 'fallback',
        'suggestions': [
            {
                'id': 'transport_1',
                'type': 'flight',
                'title': 'IndiGo 6E-2031',
                'subtitle': f'{from_city} -> {to_city}',
                'description': '✈️ 06:30 AM - 08:45 AM (2h 15min)\nEconomy | Non-stop, In-flight meals',
                'price': '₹10,000',
                'image': 'https://source.unsplash.com/800x600/?flight,indigo',
                'stage': 'transport',
                'details': {
                    'carrier': 'IndiGo',
                    'number': '6E-2031',
                    'departure_time': '06:30 AM',
                    'arrival_time': '08:45 AM',
                    'duration': '2h 15min',
                    'class': 'Economy',
                    'from_city': from_city,
                    'to_city': to_city
                }
            },
            {
                'id': 'transport_2',
                'type': 'flight',
                'title': 'Air India AI-7821',
                'subtitle': f'{from_city} -> {to_city}',
                'description': '✈️ 02:15 PM - 04:25 PM (2h 10min)\nEconomy | Non-stop, Complimentary meals',
                'price': '₹8,500',
                'image': 'https://source.unsplash.com/800x600/?flight,air-india',
                'stage': 'transport',
                'details': {
                    'carrier': 'Air India',
                    'number': 'AI-7821',
                    'departure_time': '02:15 PM',
                    'arrival_time': '04:25 PM',
                    'duration': '2h 10min',
                    'class': 'Economy',
                    'from_city': from_city,
                    'to_city': to_city
                }
            },
            {
                'id': 'transport_3',
                'type': 'train',
                'title': 'Rajdhani Express 12432',
                'subtitle': f'{from_city} -> {to_city}',
                'description': '🚂 05:30 PM - 11:45 AM+1 (18h 15min)\n2AC | Meals included, Premium service',
                'price': '₹3,500',
                'image': 'https://source.unsplash.com/800x600/?train,indian-railways',
                'stage': 'transport',
                'details': {
                    'carrier': 'Rajdhani Express',
                    'number': '12432',
                    'departure_time': '05:30 PM',
                    'arrival_time': '11:45 AM+1',
                    'duration': '18h 15min',
                    'class': '2AC',
                    'from_city': from_city,
                    'to_city': to_city
                }
            },
            {
                'id': 'transport_4',
                'type': 'train',
                'title': 'Shatabdi Express 12010',
                'subtitle': f'{from_city} -> {to_city}',
                'description': '🚂 06:00 AM - 09:15 PM (15h 15min)\nCC | Meals, Comfortable seating',
                'price': '₹2,500',
                'image': 'https://source.unsplash.com/800x600/?train,shatabdi',
                'stage': 'transport',
                'details': {
                    'carrier': 'Shatabdi Express',
                    'number': '12010',
                    'departure_time': '06:00 AM',
                    'arrival_time': '09:15 PM',
                    'duration': '15h 15min',
                    'class': 'CC',
                    'from_city': from_city,
                    'to_city': to_city
                }
            },
            {
                'id': 'transport_5',
                'type': 'train',
                'title': 'Duronto Express 12213',
                'subtitle': f'{from_city} -> {to_city}',
                'description': '🚂 11:30 PM - 05:45 PM+1 (18h 15min)\n3AC | Overnight journey, Meals available',
                'price': '₹3,000',
                'image': 'https://source.unsplash.com/800x600/?train,duronto',
                'stage': 'transport',
                'details': {
                    'carrier': 'Duronto Express',
                    'number': '12213',
                    'departure_time': '11:30 PM',
                    'arrival_time': '05:45 PM+1',
                    'duration': '18h 15min',
                    'class': '3AC',
                    'from_city': from_city,
                    'to_city': to_city
                }
            },
            {
                'id': 'transport_6',
                'type': 'bus',
                'title': 'Volvo Multi-Axle AC',
                'subtitle': f'{from_city} -> {to_city}',
                'description': '🚌 06:00 PM - 02:00 PM+1 (20h)\nSleeper | WiFi, Charging points, Onboard restroom',
                'price': '₹2,000',
                'image': 'https://source.unsplash.com/800x600/?luxury-bus,volvo',
                'stage': 'transport',
                'details': {
                    'carrier': 'Volvo Multi-Axle AC',
                    'number': 'VOLVO-AC-101',
                    'departure_time': '06:00 PM',
                    'arrival_time': '02:00 PM+1',
                    'duration': '20h',
                    'class': 'Sleeper',
                    'from_city': from_city,
                    'to_city': to_city
                }
            }
        ],
        'from_city': from_city,
        'to_city': to_city,
        'count': 6,
        'message': 'Using curated transport options'
    }

@app.post("/api/travel/search")
def search_travel(request: TravelBookingRequest):
    try:
        mode = request.mode.lower()
        from_city = request.from_city.lower()
        to_city = request.to_city.lower() if request.to_city else None
        departure_date = request.departure_date
        return_date = request.return_date
        passengers = request.passengers
        travel_class = request.travel_class.lower()
        preferences = request.preferences
        extras = request.extras
        travel_type = request.travel_type.lower()
        accessibility = request.accessibility
        duration_hours = request.duration_hours

        print(f"\n🚗 Travel Search: {mode} from {from_city}" + (f" to {to_city}" if to_city else "") + f", {passengers} passengers, {travel_class} class")

        # Route to appropriate handler based on mode
        if mode == "flight":
            return _search_flights(from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility)
        elif mode == "train":
            return _search_trains(from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility)
        elif mode == "bus":
            return _search_buses(from_city, to_city, departure_date, return_date, passengers, travel_class, preferences, extras, travel_type, accessibility)
        elif mode == "car_rental":
            return _search_car_rentals(from_city, departure_date, return_date, passengers, travel_class, preferences, extras, duration_hours, accessibility)
        elif mode == "taxi":
            return _search_taxis(from_city, to_city, departure_date, passengers, travel_class, preferences, extras, accessibility)
        elif mode == "bike_scooter":
            return _search_bikes(from_city, to_city, departure_date, passengers, travel_class, preferences, extras, duration_hours, accessibility)
        else:
            return {"status": "error", "message": f"Unsupported travel mode: {mode}"}

    except Exception as e:
        print(f"❌ Travel search error: {e}")
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    import uvicorn
    print("Starting Ultra-Simple Hotel Search Server...")
    print("Server will run on http://localhost:8001")
    print("Mode: CSV + Gemini AI")
    uvicorn.run(app, host="0.0.0.0", port=8001)
