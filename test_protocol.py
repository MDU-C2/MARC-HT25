import os
from datetime import datetime

def create_today_textfile():
    today_str = datetime.now().strftime("%Y-%m-%d")
    folder = "Test_Protocols"
    os.makedirs(folder, exist_ok=True)
    filename = os.path.join(folder, f"{today_str}.txt")
    if not os.path.exists(filename):
        with open(filename, "w") as f:
            f.write(f"File created on {today_str}\n")
    return filename