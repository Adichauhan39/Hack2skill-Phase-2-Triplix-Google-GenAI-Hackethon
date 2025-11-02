# � Triplix - AI-Powered Travel Planning Assistant

**Triplix** is an intelligent travel planning platform that combines the power of Google Gemini AI with an intuitive swipe-based interface. Plan your perfect trip with AI-driven recommendations for destinations, hotels, restaurants, activities, and transportation - all in one seamless experience.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google%20Cloud-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)

## 🎯 Hackathon Project - Google GenAI Exchange

**Built for Google GenAI Exchange Hackathon showcasing innovative use of Google Cloud technologies**

---

## ✨ Key Features

### 🤖 **Multi-Agent AI Architecture**
- **Manager Agent**: Intelligent routing and orchestration
- **Destination Info Agent**: City information with real-time weather
- **Hotel Agent**: Accommodation search with Google Maps integration
- **Transport Agent**: Flight, train, bus, and taxi recommendations
- **Itinerary Agent**: Day-by-day planning with 5-day weather forecasts
- **Restaurant Agent**: Dining recommendations with Google Places

### 🌤️ **Weather Integration** (NEW!)
- Real-time current weather for destinations
- 5-day weather forecasts in itineraries
- Weather emoji mapping (☀️🌧️⛈️🌨️)
- Humidity and wind speed data
- Graceful fallback for offline use

### 💬 **AI-Powered Chat Interface**
- Natural language trip planning
- Context-aware responses
- Voice input with Google Speech-to-Text
- Multi-turn conversations
- Smart query understanding

### 🎴 **Tinder-Style Swipe Interface**
- Swipe right to like ❤️
- Swipe left to skip ❌
- View on Google Maps 📍
- Real images from Google Places
- Auto-exit after all cards viewed

### 📱 **Smart Features**
- **Mock Booking System**: Complete booking flow with payment
- **AI Learning**: Personalized recommendations based on swipes
- **Multi-stage Workflow**: Transport → Hotels → Destinations
- **Comparison Views**: Side-by-side option analysis
- **Full Scrollable Cards**: See all details without overflow

---

## 🏗️ Architecture

### **Multi-Agent System**
```
User Query → Manager Agent → Route to Specialist Agent
                ↓
    ┌───────────┴───────────┐
    │                       │
Destination Info      Hotel Search
Transport Info       Restaurant Search
Itinerary Planning    General Info
```

### **Technology Stack**

#### **Frontend**
- **Flutter 3.x**: Cross-platform mobile framework
- **Dart**: Programming language
- **Provider**: State management
- **Card Swiper**: Swipe interactions
- **URL Launcher**: Google Maps integration
- **HTTP**: API communication

#### **Backend**
- **Python 3.11+**: Core backend
- **FastAPI**: High-performance API framework
- **Google Gemini 2.0 Flash**: AI model
- **Google ADK**: Agent Development Kit
- **Uvicorn**: ASGI server

#### **Google Cloud Services**
- ☁️ **Google Gemini AI**: Conversational AI and recommendations
- 🗺️ **Google Maps Platform**: Places, Geocoding, Maps
- 🗣️ **Google Speech-to-Text**: Voice input recognition
- 🔊 **Google Text-to-Speech**: Voice responses
- 🌐 **Google Translate**: Multi-language support
- 👁️ **Google Vision**: Image analysis (future)

#### **Data & APIs**
- **OpenWeatherMap**: Real-time weather data
- **CSV Databases**: Fast local data for destinations, hotels, flights
- **Google Places API**: Real hotel/restaurant data with photos

---

## 🚀 Quick Start

### **Prerequisites**
- Python 3.11 or higher
- Flutter SDK 3.0+
- Google Cloud API Key
- OpenWeatherMap API Key (optional)

### **1. Clone Repository**
```bash
git clone https://github.com/Adichauhan39/Hack2skill-Phase-2-internal.git
cd Hack2skill-Phase-2-internal
```

### **2. Backend Setup**

#### Install Dependencies
```bash
cd 7-multi-agent
pip install -r ../requirements.txt
```

#### Configure Environment Variables
```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your API keys
GOOGLE_API_KEY=your_google_api_key_here
GOOGLE_PLACES_API_KEY=your_google_api_key_here
OPENWEATHER_API_KEY=your_openweather_key_here (optional)
```

#### Start Backend Server
```bash
# Option 1: Using PowerShell script
.\start_ai_server.ps1

# Option 2: Direct Python command
python ultra_simple_server.py
```

Server will run on: `http://localhost:8000`

### **3. Frontend Setup**

#### Install Flutter Dependencies
```bash
cd flutter_travel_app
flutter pub get
```

#### Run the App
```bash
# Run on connected device/emulator
flutter run

# Or run on specific platform
flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter run -d android     # Android
```

---

## 📖 Usage Guide

### **Basic Travel Planning**
1. **Open Triplix** → Greeting from AI assistant
2. **Enter Query**: "Plan a trip to Goa for 3 days"
3. **Review Suggestions**: Swipe through recommendations
4. **Like/Dislike**: Swipe right ❤️ or left ❌
5. **View Details**: Tap Maps to see location
6. **Book**: Complete mock booking flow

### **Voice Input**
1. Tap 🎤 microphone icon
2. Speak your travel query
3. AI processes and responds
4. Swipe through visual results

### **Weather Information**
- **Destinations**: See current weather in destination cards
- **Itineraries**: View 5-day forecasts for trip planning
- **Details**: Temperature, humidity, wind speed with emojis

### **Multi-Stage Workflow**
1. **Transport**: Select flights/trains
2. **Hotels**: Choose accommodation
3. **Destinations**: Pick attractions
4. **Itinerary**: Get day-by-day plan with weather

---

## 🗂️ Project Structure

```
Hack2skill-Phase-2-internal/
├── 7-multi-agent/                    # Python Backend
│   ├── manager/                      # AI Agent System
│   │   ├── agent.py                  # Manager agent
│   │   ├── sub_agents/               # Specialized agents
│   │   │   ├── destination_info/     # Destination + Weather
│   │   │   ├── hotel/                # Hotel search
│   │   │   ├── transport/            # Transport options
│   │   │   ├── itinerary/            # Trip planning
│   │   │   └── restaurant/           # Dining recommendations
│   │   └── tools/                    # Shared tools
│   │       ├── tools.py              # Google Maps integration
│   │       └── swipe_recommendations.py
│   ├── data/                         # CSV databases
│   │   ├── destinations_india.csv
│   │   ├── hotels_india.csv
│   │   ├── flights_india.csv
│   │   └── restaurants_india.csv
│   ├── ultra_simple_server.py        # FastAPI server
│   ├── .env.example                  # Environment template
│   └── requirements.txt              # Python dependencies
│
├── flutter_travel_app/               # Flutter Frontend
│   ├── lib/
│   │   ├── screens/                  # UI screens
│   │   │   ├── home_screen.dart      # Main chat + swipe
│   │   │   ├── login_screen.dart
│   │   │   ├── mock_booking_screen.dart
│   │   │   └── splash_screen.dart
│   │   ├── services/                 # API services
│   │   │   ├── python_adk_service.dart
│   │   │   └── voice_input_service.dart
│   │   ├── models/                   # Data models
│   │   ├── providers/                # State management
│   │   └── config/                   # App configuration
│   ├── pubspec.yaml                  # Flutter dependencies
│   └── assets/                       # Images, fonts
│
├── requirements.txt                  # Root Python dependencies
├── README.md                         # This file
├── .gitignore                        # Git ignore rules
└── Documentation/                    # Project docs (markdown files)
```

---

## 🌟 Google Technologies Used

### **1. Google Gemini 2.0 Flash**
- Multi-agent conversational AI
- Natural language understanding
- Context-aware responses
- Travel recommendation generation

### **2. Google Maps Platform**
- **Places API**: Hotel/restaurant search with photos
- **Geocoding API**: Location data
- **Maps integration**: In-app location viewing

### **3. Google Speech Services**
- **Speech-to-Text**: Voice input recognition
- **Text-to-Speech**: Voice responses

### **4. Google Cloud APIs**
- **Vision API**: Future image analysis
- **Translate API**: Multi-language support

---

## 📊 Features Breakdown

### **Implemented ✅**
- ✅ Multi-agent AI architecture with Google Gemini
- ✅ Real-time weather integration (current + 5-day forecast)
- ✅ Tinder-style swipe interface
- ✅ Google Maps integration with real photos
- ✅ Voice input/output
- ✅ Mock booking flow with payment
- ✅ AI learning from user preferences
- ✅ Multi-stage trip planning workflow
- ✅ Scrollable cards with full details
- ✅ Auto-exit after swiping
- ✅ Hotel/restaurant/transport search
- ✅ Day-by-day itinerary generation

### **Future Enhancements 🚀**
- 🔮 Real payment gateway integration
- 🔮 User account management
- 🔮 Trip history and favorites
- 🔮 Social sharing features
- 🔮 Multi-language support with Google Translate
- 🔮 Image upload with Google Vision
- 🔮 Real-time collaboration
- 🔮 Advanced filters and sorting

---

## 🔧 API Endpoints

### **Backend API (http://localhost:8000)**

#### **Chat Endpoint**
```
POST /chat
Content-Type: application/json

{
  "message": "Plan a trip to Mumbai",
  "history": []
}
```

#### **Swipe Action**
```
POST /swipe_action
{
  "item_id": "hotel_123",
  "action": "like",
  "item_type": "hotel"
}
```

#### **Health Check**
```
GET /health
Response: {"status": "healthy"}
```

---

## 🧪 Testing

### **Backend Testing**
```bash
# Test Gemini connection
cd 7-multi-agent
python test_gemini_connection.py

# Health check
curl http://localhost:8000/health
```

### **Frontend Testing**
```bash
cd flutter_travel_app
flutter test
```

---

## 📝 Environment Variables Setup

### **Backend Configuration (.env file)**
```properties
# Google Cloud Configuration
GOOGLE_GENAI_USE_VERTEXAI=FALSE
GOOGLE_API_KEY=your_google_api_key_here
GOOGLE_PLACES_API_KEY=your_google_api_key_here

# Weather API (Optional - fallback included)
OPENWEATHER_API_KEY=your_openweather_key_here
```

**Getting API Keys:**
- **Google API Key**: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
- **OpenWeatherMap**: [OpenWeatherMap API](https://openweathermap.org/api) (Free tier: 1000 calls/day)

**Security Note**: Use `.env.example` as template, never commit real keys!

---

## 🐛 Troubleshooting

### **Backend Issues**

**Problem**: `GOOGLE_API_KEY not found`
```bash
# Solution: Ensure .env file exists
cp 7-multi-agent/.env.example 7-multi-agent/.env
# Edit .env and add your API keys
```

**Problem**: `Module not found` errors
```bash
# Solution: Reinstall dependencies
pip install -r requirements.txt
```

**Problem**: Port 8000 already in use
```bash
# Solution: Kill the process or change port in ultra_simple_server.py
```

### **Frontend Issues**

**Problem**: `flutter pub get` fails
```bash
# Solution: Clean and retry
flutter clean
flutter pub get
```

**Problem**: Backend connection timeout
```bash
# Solution: Verify backend URL in python_adk_service.dart
# Default: http://localhost:8000
```

---

## 📚 Additional Documentation

Comprehensive guides available:

- **[DEMO_GUIDE.md](DEMO_GUIDE.md)**: Complete demo walkthrough
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)**: Testing procedures
- **[MULTI_AGENT_ARCHITECTURE.md](MULTI_AGENT_ARCHITECTURE.md)**: System architecture
- **[GOOGLE_TECHNOLOGIES_USED.md](GOOGLE_TECHNOLOGIES_USED.md)**: Google Cloud integration details
- **[WEATHER_SCROLL_FIXES.md](WEATHER_SCROLL_FIXES.md)**: Latest feature updates

---

## 🎥 Demo & Screenshots

### **App Flow**
1. **Splash Screen** → Animated welcome
2. **Login** → Google/Email authentication  
3. **Home** → AI chat interface
4. **Swipe Cards** → Browse recommendations
5. **Weather Info** → Real-time data
6. **Booking** → Complete reservation flow
7. **Itinerary** → Day-by-day schedule with weather

---

## 👥 Project Team

**Project Name:** Triplix - AI Travel Assistant  
**Hackathon:** Google GenAI Exchange  
**Repository:** [Hack2skill-Phase-2-internal](https://github.com/Adichauhan39/Hack2skill-Phase-2-internal)  
**Tech Stack:** Flutter, Python, Google Gemini AI, Google Cloud

---

## 🤝 Contributing

We welcome contributions! Follow these steps:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

**Guidelines:**
- Follow code style conventions
- Add tests for new features
- Update documentation
- Keep commits atomic and descriptive

---

## 📄 License

Developed for **Google GenAI Exchange Hackathon**.  
See [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Google Cloud** - Gemini AI, Maps, Speech services
- **OpenWeatherMap** - Weather API
- **Flutter Team** - Amazing framework
- **FastAPI** - High-performance backend
- **Hackathon Organizers** - For this amazing opportunity

---

## 📞 Support & Contact

**Issues & Questions:**
- GitHub Issues: [Create Issue](https://github.com/Adichauhan39/Hack2skill-Phase-2-internal/issues)
- Documentation: Check markdown files in repo
- Demo Videos: Coming soon

---

## 🚀 Deployment

### **Backend (Python)**
- **Google Cloud Run**: Serverless containers
- **Google App Engine**: Managed platform
- **Docker**: Container support included

### **Frontend (Flutter)**
- **Web**: Firebase Hosting, Vercel
- **Android**: Google Play Store
- **iOS**: Apple App Store  
- **Desktop**: Windows/Mac/Linux executables

---

## 📈 Project Status

**Version**: 1.0.0  
**Status**: ✅ Production Ready  
**Last Updated**: November 2, 2025

### **Recent Updates (v1.0.0)**
- ✅ Weather integration (current + 5-day forecast)
- ✅ Fixed scrollable cards overflow
- ✅ Enhanced UI with reviews and full descriptions
- ✅ Multi-agent architecture refinements
- ✅ Google Maps real photo integration
- ✅ Voice input improvements

---

## 🎯 Hackathon Highlights

### **💡 Innovation**
- Multi-agent AI architecture for intelligent routing
- Unique swipe interface for travel planning
- Real-time weather in recommendations
- Voice-enabled natural language queries
- Seamless Google Cloud integration

### **☁️ Google Technologies**
- **Gemini 2.0 Flash**: Conversational AI engine
- **Google Maps Platform**: Location & photo services
- **Speech-to-Text**: Voice recognition
- **Cloud-Ready**: Scalable architecture

### **✨ User Experience**
- Intuitive Tinder-style swipes
- Beautiful weather visualizations
- Context-aware AI responses
- Complete booking flow
- Smooth animations

---

## 🎬 Demo Resources

**Live Demo**: Coming Soon  
**Video Walkthrough**: Check YouTube  
**Presentation**: See PowerPoint in repo  
**Architecture Diagram**: See PROJECT_FLOW_DIAGRAM.md

---

**Made with ❤️ for Google GenAI Exchange Hackathon**

🌟 **If you find this project helpful, please star the repository!** 🌟

---

*Triplix - Your AI-Powered Travel Companion* ✈️🌍🤖

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/Adichauhan39/Hack2skill-Phase-2-internal.git
cd Hack2skill-Phase-2-internal
```

### 2. Backend Setup (Python/FastAPI)

#### Install Python Dependencies
```bash
cd 7-multi-agent
pip install -r ../requirements.txt
```

#### Configure Environment Variables
Create a `.env` file in the `7-multi-agent` directory:
```env
GOOGLE_API_KEY=your_google_ai_api_key_here
GOOGLE_GENAI_USE_VERTEXAI=FALSE
```

**🔐 Security Note**: Never commit your `.env` file to version control!

### 3. Frontend Setup (Flutter)

#### Install Flutter Dependencies
```bash
cd ../flutter_travel_app
flutter pub get
```

#### Configure Flutter
Make sure Flutter is properly set up:
```bash
flutter doctor
```

## 🎮 Running the Application

### Start Backend Server
```bash
# From the 7-multi-agent directory
cd 7-multi-agent
python ultra_simple_server.py
```

The server will start on `http://localhost:8001`

### Start Flutter App
```bash
# From the flutter_travel_app directory
cd flutter_travel_app
flutter run
```

### Alternative: Run on Specific Platform
```bash
# For Chrome web browser
flutter run -d chrome

# For Android emulator
flutter run -d emulator

# For connected device
flutter run -d <device_id>
```

## 📖 Usage Guide

### 🏨 Finding Hotels

1. **Launch the App**: Start the Flutter application
2. **Enter Destination**: Type your destination city (e.g., "Goa", "Mumbai")
3. **Set Budget**: Use the slider to set your maximum budget per night
4. **Add Preferences**:
   - Room type (Executive, Deluxe, etc.)
   - Food preferences (Veg, Non-Veg)
   - Ambiance (Modern, Traditional)
   - Amenities (WiFi, Pool, Gym, Spa)
5. **Special Requests**: Add any special requirements in natural language
6. **Search**: Tap the search button to find hotels

### 🎯 Swipe Interface

- **❤️ Like**: Swipe right or tap heart icon to save hotel
- **👎 Pass**: Swipe left or tap X icon to skip
- **View Details**: Tap on hotel card to see full details
- **Cart**: Access saved hotels from the cart icon

### 🔍 Hotel Information Displayed

- **Hotel Name & Location**
- **Price per Night**
- **Star Rating**
- **Amenities List**
- **Detailed Description**
- **AI Recommendations**
- **Nearby Attractions**
- **Real Hotel Images**

## 🔧 API Documentation

### Hotel Search Endpoint
```http
POST /api/hotel/search
Content-Type: application/json

{
  "message": "Find hotels in Goa under ₹5000 with pool",
  "context": {
    "city": "Goa",
    "budget": 5000
  }
}
```

**Response:**
```json
{
  "status": "success",
  "powered_by": "CSV or Gemini AI",
  "ai_used": false,
  "hotels": [
    {
      "name": "Hotel Name",
      "city": "Goa",
      "price_per_night": 3500,
      "rating": 4.5,
      "type": "Hotel",
      "amenities": ["WiFi", "Pool", "Spa"],
      "description": "Detailed hotel description...",
      "why_recommended": "AI recommendation...",
      "nearby_attractions": ["Beach 1", "Beach 2"]
    }
  ],
  "count": 1
}
```

### Hotel Images Endpoint
```http
POST /api/hotel/images
Content-Type: application/json

{
  "message": "Get images for Taj Hotel",
  "context": {
    "hotel_name": "Taj Hotel",
    "city": "Mumbai"
  }
}
```

## 🏗️ Project Structure

```
Hack2skill-Phase-2-internal/
├── flutter_travel_app/          # Flutter frontend
│   ├── lib/
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API services
│   │   └── models/             # Data models
│   ├── android/                # Android config
│   ├── ios/                    # iOS config
│   └── pubspec.yaml           # Flutter dependencies
├── 7-multi-agent/              # Python backend
│   ├── ultra_simple_server.py # FastAPI server
│   ├── data/                   # CSV datasets
│   ├── .env                    # Environment variables
│   └── requirements.txt        # Python dependencies
├── data/                       # Shared data files
├── requirements.txt           # Root dependencies
├── .gitignore                # Git ignore rules
└── README.md                 # This file
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature-name`
3. **Commit** your changes: `git commit -m 'Add feature'`
4. **Push** to the branch: `git push origin feature-name`
5. **Submit** a Pull Request

### Development Guidelines
- Follow Flutter/Dart best practices
- Write clear, documented code
- Test your changes thoroughly
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Gemini AI**: For powering intelligent hotel recommendations
- **Unsplash**: For providing beautiful hotel images
- **Flutter Team**: For the amazing cross-platform framework
- **FastAPI**: For the robust API framework

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/Adichauhan39/Hack2skill-Phase-2-internal/issues) page
2. Create a new issue with detailed description
3. Include error logs and steps to reproduce

## 🎯 Future Enhancements

- [ ] User authentication and profiles
- [ ] Booking integration with real APIs
- [ ] Advanced filtering options
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Push notifications
- [ ] Hotel comparison feature

---

**Built with ❤️ for Hack2skill Phase 2**

*Experience the future of hotel booking with AI-powered recommendations and intuitive swipe interface!* 🚀