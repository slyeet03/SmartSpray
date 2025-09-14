import json
import os
from datetime import datetime

LOG_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "spray_log.json")

def safe_json_load(filepath):
    """Safely load JSON file, return empty list if file doesn't exist or is corrupted"""
    if not os.path.exists(filepath):
        return []
    
    try:
        with open(filepath, 'r') as f:
            # Check if file is empty
            if os.path.getsize(filepath) == 0:
                return []
            content = f.read().strip()
            if not content:  # Empty file
                return []
            return json.loads(content)
    except (json.JSONDecodeError, ValueError):
        print(f"Warning: {filepath} is corrupted. Resetting to empty list.")
        return []
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return []

def safe_json_save(filepath, data):
    """Safely save data to JSON file"""
    try:
        # Ensure directory exists
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        # Write to temporary file first
        temp_file = filepath + '.tmp'
        with open(temp_file, 'w') as f:
            json.dump(data, f, indent=2)
        
        # Replace original file
        if os.path.exists(filepath):
            os.remove(filepath)
        os.rename(temp_file, filepath)
        
    except Exception as e:
        print(f"Error saving {filepath}: {e}")

def load_logs():
    """Return all saved logs as a list."""
    return safe_json_load(LOG_PATH)

def save_log(entry: dict):
    """Append a new log entry with timestamp."""
    logs = load_logs()
    entry_with_time = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        **entry,
    }
    logs.append(entry_with_time)
    safe_json_save(LOG_PATH, logs)
    return entry_with_time