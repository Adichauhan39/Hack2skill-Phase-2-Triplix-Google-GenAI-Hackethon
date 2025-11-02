"""
Minimal AI Server for Triplix Assistant - No pandas dependency
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
import google.generativeai as genai

# Configure Gemini
genai.configure(api_key=os.environ['GOOGLE_API_KEY'])

# Create app
app = FastAPI(title="Triplix AI Server", description="Minimal AI server for Triplix Assistant")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

class AgentRequest(BaseModel):
    message: str
    context: Optional[Dict[str, Any]] = {}
    page: Optional[str] = "home"

class AnalyzePreferencesRequest(BaseModel):
    destination: Optional[Dict[str, Any]] = {}
    budget: Optional[Dict[str, Any]] = {}
    activities: Optional[Dict[str, Any]] = {}
    transport: Optional[Dict[str, Any]] = {}
    allocation: Optional[Dict[str, Any]] = {}
    context: Optional[Dict[str, Any]] = {}

@app.get("/")
def root():
    return {
        "status": "Triplix AI Server Running",
        "version": "1.0",
        "model": "gemini-1.5-flash",
        "cors_enabled": True,
        "endpoints": [
            "/api/agent - Main AI agent endpoint",
            "/api/analyze-preferences - Analyze user preferences"
        ]
    }

@app.post("/api/agent")
def handle_agent_request(request: AgentRequest):
    """
    Main agent endpoint - handles all AI requests from Flutter app
    """
    try:
        message = request.message
        context = request.context or {}
        page = request.page or 'home'

        print(f"\n🤖 [API/AGENT] Request received:")
        print(f"   Message: {message}")
        print(f"   Page: {page}")

        # Simple conversational response using Gemini
        model = genai.GenerativeModel('gemini-1.5-flash')

        # Build context for Gemini
        user_prefs = context.get('user_preferences', {})
        conversation_history = context.get('conversation_history', [])

        # Create a context-aware prompt
        prompt = f"""You are Triplix, a helpful travel assistant.

User's message: {message}

Current page: {page}

User preferences:
- Budget: ₹{user_prefs.get('budget', 'Not set')}
- Destination: {user_prefs.get('destination', 'Not set')}
- Activities: {', '.join(user_prefs.get('activities', [])) if user_prefs.get('activities') else 'Not set'}
- Transport: {', '.join(user_prefs.get('transport', [])) if user_prefs.get('transport') else 'Not set'}

Please provide a helpful, friendly response. Keep it concise (2-3 sentences) unless the user asks for detailed information."""

        # Get AI response
        response = model.generate_content(prompt)
        ai_response = response.text

        print(f"   ✅ AI Response generated ({len(ai_response)} chars)")

        return {
            "success": True,
            "response": ai_response,
            "agent": "gemini",
            "data": {},
            "page": page,
            "source": "minimal_ai_server"
        }

    except Exception as e:
        print(f"   ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "response": "I'm sorry, I encountered an error. Please try again.",
            "source": "minimal_ai_server"
        }

@app.post("/api/analyze-preferences")
def analyze_preferences(request: AnalyzePreferencesRequest):
    """
    Analyze user preferences and provide AI-powered travel recommendations
    Used by the AI Assistant page in Flutter app
    """
    try:
        print(f"\n🤖 [AI ASSISTANT] ANALYZE PREFERENCES REQUEST:")

        # Extract all preference data from request
        destination = request.destination or {}
        budget = request.budget or {}
        activities = request.activities or {}
        transport = request.transport or {}
        allocation = request.allocation or {}
        context = request.context or {}

        # Build comprehensive message from user preferences
        message_parts = []

        # Destination preferences
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
        amount = budget.get('amount', 0)
        num_people = budget.get('num_people', 1)
        tier = budget.get('tier', 'mid_range')

        if amount > 0:
            message_parts.append(f"Budget: ₹{amount:,} for {num_people} person(s)")
            message_parts.append(f"Budget tier: {tier}")

        # Activities
        selected = activities.get('selected', [])
        intensity = activities.get('intensity', 'moderate')

        if selected:
            message_parts.append(f"Activities: {', '.join(selected)}")
            message_parts.append(f"Activity intensity: {intensity}")

        # Transport preferences
        modes = transport.get('modes', [])

        if modes:
            message_parts.append(f"Transport modes: {', '.join(modes)}")

        # Context and special requirements
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

        prompt = f"""You are Triplix, a helpful travel assistant. Based on the following user preferences, provide personalized travel recommendations:

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
        model = genai.GenerativeModel('gemini-1.5-flash')
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

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Minimal Triplix AI Server...")
    print("📍 Server will run on http://localhost:8001")
    print("🤖 AI Model: gemini-1.5-flash")
    uvicorn.run(app, host="0.0.0.0", port=8001)