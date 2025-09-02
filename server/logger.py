import json
import os
from datetime import datetime

LOG_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "spray_log.json")


def load_logs():
    """Return all saved logs as a list."""
    if not os.path.exists(LOG_PATH):
        return []
    with open(LOG_PATH, "r") as f:
        return json.load(f)


def save_log(entry: dict):
    """Append a new log entry with timestamp."""
    logs = load_logs()
    entry_with_time = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        **entry,
    }
    logs.append(entry_with_time)
    with open(LOG_PATH, "w") as f:
        json.dump(logs, f, indent=2)
    return entry_with_time
