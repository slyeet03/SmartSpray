import os

import requests

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")


def get_disease_info(disease_name):
    if not GEMINI_API_KEY:
        return {"error": "No Gemini API key set"}

    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    headers = {"Content-Type": "application/json"}
    params = {"key": GEMINI_API_KEY}

    prompt = f"Explain {disease_name} in tomato plants in simple terms. \
Provide symptoms, treatment options, and prevention tips in 3-4 bullet points."

    body = {"contents": [{"parts": [{"text": prompt}]}]}

    try:
        r = requests.post(url, headers=headers, params=params, json=body)
        data = r.json()
        if "candidates" in data:
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            return {"disease": disease_name, "gemini_info": text}
        return {"error": "No response from Gemini", "raw": data}
    except Exception as e:
        return {"error": str(e)}
