from pathlib import Path
from google.cloud import texttospeech

OUTPUT_DIR = Path("frontend/static/audio/hr/alphabet")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

VOICE_NAME = "hr-HR-Chirp3-HD-Aoede"  # female
LANGUAGE_CODE = "hr-HR"

WORDS = {
    "a": "auto",
    "b": "brat",
    "c": "cesta",
    "c-caron": "čaj",
    "c-acute": "kuća",
    "d": "dan",
    "dz": "džep",
    "d-stroke": "dođem",
    "e": "euro",
    "f": "film",
    "g": "grad",
    "h": "hotel",
    "i": "ime",
    "j": "ja",
    "k": "kava",
    "l": "ljubav",
    "lj": "ljudi",
    "m": "more",
    "n": "noć",
    "nj": "konj",
    "o": "otac",
    "p": "posao",
    "r": "ruka",
    "s": "soba",
    "s-caron": "škola",
    "t": "tjedan",
    "u": "ulica",
    "v": "voda",
    "z": "zima",
    "z-caron": "žena",
}

def main():
    client = texttospeech.TextToSpeechClient()

    voice = texttospeech.VoiceSelectionParams(
        language_code=LANGUAGE_CODE,
        name=VOICE_NAME,
    )

    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3,
        speaking_rate=0.9,
    )

    for filename, word in WORDS.items():
        out_path = OUTPUT_DIR / f"{filename}.mp3"

        synthesis_input = texttospeech.SynthesisInput(text=word)

        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config,
        )

        out_path.write_bytes(response.audio_content)
        print(f"✅ {word} -> {out_path}")

if __name__ == "__main__":
    main()
