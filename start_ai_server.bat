@echo off
echo Starting AI Hotel Search Server with CORS...
cd /d "c:\Hack2skill\Hack2skill finale\7-multi-agent"
start "AI Server - Port 8001" .\venv\Scripts\python.exe fast_ai_server.py
echo.
echo Server starting in new window...
timeout /t 5 /nobreak
echo.
echo Testing server...
curl http://localhost:8001/
