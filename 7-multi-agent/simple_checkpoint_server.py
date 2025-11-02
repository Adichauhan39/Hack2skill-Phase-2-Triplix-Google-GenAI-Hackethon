"""
Simple Checkpoint Analyzer Server
Mock server for testing dynamic AI checkpoints (AI integration pending)
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any
import json

# Mock AI mode - will be replaced with real AI later
USE_AI = False
print("[INIT] Using mock AI responses (real AI integration pending)")

app = FastAPI(
    title="Checkpoint Analyzer Server",
    description="Simple server for AI checkpoint analysis"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AgentRequest(BaseModel):
    message: str
    context: Dict[str, Any] = {}
    agent_type: str = "checkpoint_analyzer"

@app.get("/")
def root():
    return {
        "status": "Checkpoint Analyzer Server Running",
        "version": "1.0",
        "endpoints": ["/api/agent"],
        "cors_enabled": True
    }

@app.post("/api/agent")
def handle_agent_request(request: AgentRequest):
    """
    Handle checkpoint analyzer requests
    """
    try:
        print(f"[CHECKPOINT] Request: {request.message}")
        print(f"[CONTEXT] {request.context}")

        # Use AI analysis (currently mock - real AI integration pending)
        if "checkpoint_analyzer" in request.message.lower() or request.agent_type == "checkpoint_analyzer":
            print("[AI] Processing checkpoint analysis request")

            # Build analysis prompt from context (for future AI integration)
            prompt = build_analysis_prompt(request.context)
            print(f"[PROMPT] {prompt[:100]}...")

            if USE_AI:
                # TODO: Implement real AI integration
                return get_mock_response()
            else:
                # Return mock response for now
                print("[MOCK] Returning mock AI analysis")
                return get_mock_response()

        # Fallback to mock response
        elif "checkpoint_analyzer" in request.message.lower() or request.agent_type == "checkpoint_analyzer":
            print("[MOCK] Using mock checkpoint analyzer response")
            return {
                "success": True,
                "response": "AI analysis completed successfully",
                "agent": "checkpoint_analyzer",
                "data": {
                    "summary": "Your travel preferences show a balanced approach with focus on comfort and adventure.",
                    "recommendations": [
                        "Consider Goa for beach relaxation with cultural experiences",
                        "Opt for AC Volvo buses for long-distance travel",
                        "Choose 3-star hotels for good value and amenities"
                    ],
                    "challenges": [
                        "Monsoon season might affect outdoor activities",
                        "Peak season pricing could increase costs"
                    ],
                    "budget_tips": [
                        "Book transportation in advance for better rates",
                        "Consider nearby destinations for cost savings"
                    ],
                    "alternatives": [
                        "Pondicherry as a cultural alternative to Goa",
                        "Coorg for hill station experience instead of Goa"
                    ],
                    "confidence": 0.85
                }
            }

        # Default response
        return {
            "success": True,
            "response": "Request processed successfully",
            "agent": "general",
            "data": {}
        }

    except Exception as e:
        print(f"[ERROR] {e}")
        return {
            "success": False,
            "error": str(e),
            "response": "Processing failed"
        }

def build_analysis_prompt(context: Dict[str, Any]) -> str:
    """Build analysis prompt from user preferences context"""
    prompt_parts = ["Analyze these travel preferences and provide intelligent insights:"]

    if context.get('destination'):
        prompt_parts.append(f"DESTINATION: {context['destination']}")

    if context.get('budget'):
        prompt_parts.append(f"BUDGET: ₹{context['budget']}")

    if context.get('selectedActivities'):
        activities = context['selectedActivities']
        if isinstance(activities, list):
            prompt_parts.append(f"ACTIVITIES: {', '.join(activities)}")
        else:
            prompt_parts.append(f"ACTIVITIES: {activities}")

    if context.get('selectedTransport'):
        transport = context['selectedTransport']
        if isinstance(transport, list):
            prompt_parts.append(f"TRANSPORT: {', '.join(transport)}")
        else:
            prompt_parts.append(f"TRANSPORT: {transport}")

    if context.get('selectedAccommodation'):
        accommodation = context['selectedAccommodation']
        if isinstance(accommodation, list):
            prompt_parts.append(f"ACCOMMODATION: {', '.join(accommodation)}")
        else:
            prompt_parts.append(f"ACCOMMODATION: {accommodation}")

    # Add context information
    context_info = []
    if context.get('companion'):
        context_info.append(f"Companion: {context['companion']}")
    if context.get('occasion'):
        context_info.append(f"Occasion: {context['occasion']}")
    if context.get('experience'):
        context_info.append(f"Experience: {context['experience']}")
    if context.get('numberOfPeople'):
        context_info.append(f"People: {context['numberOfPeople']}")

    if context_info:
        prompt_parts.append(f"TRAVEL CONTEXT: {', '.join(context_info)}")

    prompt_parts.append("""
Please provide:
1. A personalized travel profile summary (2-3 sentences)
2. 3 key recommendations based on their preferences
3. Potential challenges or considerations
4. Budget optimization suggestions
5. Alternative options they might not have considered

Keep responses concise but insightful. Focus on actionable intelligence.""")

    return "\n".join(prompt_parts)

def parse_gemini_response(ai_response: str) -> Dict[str, Any]:
    """
    Parse Gemini API response into structured format
    """
    try:
        # Try to extract JSON from the response
        response_text = ai_response.strip()

        # Look for JSON-like content
        if "{" in response_text and "}" in response_text:
            start = response_text.find("{")
            end = response_text.rfind("}") + 1
            json_str = response_text[start:end]

            try:
                parsed = json.loads(json_str)
                return {
                    "success": True,
                    "response": "AI analysis completed successfully",
                    "agent": "checkpoint_analyzer",
                    "data": parsed,
                    "source": "gemini_api"
                }
            except json.JSONDecodeError:
                pass

        # If no JSON found, return the raw response
        return {
            "success": True,
            "response": ai_response,
            "agent": "checkpoint_analyzer",
            "data": {
                "analysis": ai_response,
                "confidence": 0.8
            },
            "source": "gemini_api"
        }

    except Exception as e:
        print(f"[ERROR] Failed to parse Gemini response: {e}")
        return get_mock_response()

def get_mock_response() -> Dict[str, Any]:
    """
    Return mock checkpoint analysis response
    """
    return {
        "success": True,
        "response": "AI analysis completed successfully",
        "agent": "checkpoint_analyzer",
        "data": {
            "summary": "Your travel preferences show a balanced approach with focus on comfort and adventure.",
            "recommendations": [
                "Consider Goa for beach relaxation with cultural experiences",
                "Opt for AC Volvo buses for long-distance travel",
                "Choose 3-star hotels for good value and amenities"
            ],
            "challenges": [
                "Monsoon season might affect outdoor activities",
                "Peak season pricing could increase costs"
            ],
            "budget_tips": [
                "Book transportation in advance for better rates",
                "Consider nearby destinations for cost savings"
            ],
            "alternatives": [
                "Pondicherry as a cultural alternative to Goa",
                "Coorg for hill station experience instead of Goa"
            ],
            "confidence": 0.85
        },
        "source": "mock_fallback"
    }

def parse_adk_response(adk_response) -> Dict[str, Any]:
    """Parse ADK agent response into the expected format"""
    try:
        # Extract response content
        response_text = adk_response.get('response', '')

        # Try to parse JSON from response
        try:
            # Look for JSON in the response
            import re
            json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
            if json_match:
                parsed_data = json.loads(json_match.group())
                return {
                    "success": True,
                    "response": "AI analysis completed successfully",
                    "agent": "checkpoint_analyzer",
                    "data": parsed_data
                }
        except:
            pass

        # Fallback: extract information from text response
        return {
            "success": True,
            "response": "AI analysis completed successfully",
            "agent": "checkpoint_analyzer",
            "data": {
                "summary": response_text[:200] + "..." if len(response_text) > 200 else response_text,
                "recommendations": ["Analysis completed - check full response"],
                "challenges": ["AI processing completed"],
                "budget_tips": ["Review recommendations above"],
                "alternatives": ["Consider nearby destinations"],
                "confidence": 0.8
            }
        }

    except Exception as e:
        print(f"[PARSE ERROR] {e}")
        return {
            "success": False,
            "error": f"Failed to parse AI response: {e}",
            "response": "AI analysis failed"
        }

if __name__ == "__main__":
    import uvicorn
    print("Starting Checkpoint Analyzer Server...")
    print("Server will be available at: http://localhost:8001")
    uvicorn.run(app, host="0.0.0.0", port=8001)