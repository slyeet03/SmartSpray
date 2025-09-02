import json
import os

SCHEDULE_PATH = os.path.join(
    os.path.dirname(__file__), "..", "data", "spray_schedule.json"
)

with open(SCHEDULE_PATH, "r") as f:
    schedule = json.load(f)


def get_recommendation(class_id: str):
    """
    Return spray recommendation for a given class.
    Always returns a dict.
    """
    if class_id in schedule:
        return schedule[class_id]
    return {
        "disease": "Unknown",
        "spray": False,
        "spray_time": 0,
        "servo_index": None,
        "chemical": "None",
    }
