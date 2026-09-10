import logging
import os
from dotenv import load_dotenv
from livekit.agents import (
    Agent,
    AgentSession,
    JobContext,
    WorkerOptions,
    cli,
)
from livekit.plugins import sarvam

# ---------------------------------------------------------
# Load environment variables
# ---------------------------------------------------------
load_dotenv()

# ---------------------------------------------------------
# Logging Configuration
# ---------------------------------------------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("healthexpress-sarvam-agent")
logger.setLevel(logging.INFO)

# ---------------------------------------------------------
# HealthExpress Clinical AI Voice Agent
# ---------------------------------------------------------
class HealthExpressVoiceAgent(Agent):
    def __init__(self) -> None:
        instructions = """
You are the real-time Conversational Voice AI Clinical Doctor for HealthExpress AI (హెల్త్ ఎక్స్‌ప్రెస్).
Your clinical responsibilities:
1. Provide personalized, empathetic medical guidance directly tailored to whatever specific health issues the patient reports (e.g., fever, acidity, migraines, throat pain, knee/joint aches, diabetes, or chest tightness).
2. NEVER give generic templated responses; always mention actionable home care, safe hydration/diet, and relevant specialist fields for their specific problem.
3. If the user speaks in Telugu (తెలుగు), converse fluently and respectfully in Telugu.
4. If the user speaks in Hindi (हिंदी), converse warmly in Hindi.
5. If the user speaks English or mixed Indian languages (Hinglish/Telugish), converse naturally.
6. Keep spoken answers concise (2 to 3 short sentences max) for instant real-time speech delivery without markdown asterisks.
7. Remind them that verified doctor telehealth, 15-min medicine delivery, and 108 SOS ambulance are accessible in the app.
"""
        super().__init__(
            instructions=instructions,
            # ---------------------------------------------
            # Sarvam Real-Time Speech-to-Text (Saaras v4)
            # ---------------------------------------------
            stt=sarvam.STT(
                language="unknown", # Auto-detects Telugu, Hindi, English, etc.
                model="saaras:v4",
                mode="transcribe",
                flush_signal=True,
            ),
            # ---------------------------------------------
            # Sarvam 105B Conversational Medical LLM
            # ---------------------------------------------
            llm=sarvam.LLM(
                model="sarvam-105b-conversations"
            ),
            # ---------------------------------------------
            # Sarvam Real-Time Voice Synthesis (Bulbul v3)
            # ---------------------------------------------
            tts=sarvam.TTS(
                language_code="en-IN",
                model="bulbul:v3",
                speaker="shubh",
            ),
        )

# ---------------------------------------------------------
# LiveKit Room Entrypoint
# ---------------------------------------------------------
async def entrypoint(ctx: JobContext):
    logger.info(f"Connecting HealthExpress Voice Agent to room: {ctx.room.name}")
    
    # Ultra-low latency endpointing for immediate turn-taking response
    session = AgentSession(
        turn_detection="stt",
        min_endpointing_delay=0.07,
    )
    
    await session.start(
        agent=HealthExpressVoiceAgent(),
        room=ctx.room,
    )

# ---------------------------------------------------------
# Worker Runner
# ---------------------------------------------------------
if __name__ == "__main__":
    cli.run_app(
        WorkerOptions(
            entrypoint_fnc=entrypoint
        )
    )
