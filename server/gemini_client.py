import os

import requests

#GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_API_KEY = "AIzaSyCozpuNd_caNfR0Xo-htgW5J6RpqF9yD1c"

def get_disease_info(disease_name):
    if not GEMINI_API_KEY:
        return {"error": "No Gemini API key set"}

    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent"
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}

    prompt = (
        f"Explain {disease_name} in tomato plants in simple terms. Try to keep it short and simple.\n"
        f"- Symptoms\n- Treatment options\n- Prevention tips\n"
    )

    body = {"contents": [{"parts": [{"text": prompt}]}]}

    try:
        r = requests.post(url, headers=headers, params=params, json=body, timeout=20)
        data = r.json()

        print(f"[Gemini] Raw response for {disease_name}: {data}")  # DEBUG

        # Parse Gemini output safely
        if "candidates" in data and len(data["candidates"]) > 0:
            parts = data["candidates"][0].get("content", {}).get("parts", [])
            if parts and "text" in parts[0]:
                text = parts[0]["text"]
                return {"disease": disease_name, "gemini_info": text}

        return {"error": "No valid response from Gemini", "raw": data}

    except Exception as e:
        print(f"[Gemini] ERROR: {e}")
        return {"error": str(e)}
