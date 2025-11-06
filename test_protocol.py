import os
from datetime import datetime

def create_today_textfile():
    today_str = datetime.now().strftime("%Y-%m-%d_%H.%M")
    folder = "Test_Protocols"
    os.makedirs(folder, exist_ok=True)
    filename = os.path.join(folder, f"{today_str}.txt")
    if not os.path.exists(filename):
        with open(filename, "w") as f:
            f.write(f"File created on {today_str}\n")
    return filename


def fill_meta_data(file_path):
    with open(file_path, "a") as f:
        f.write("---------- Meta Data ----------\n")
        try:
            with open("saved_coordinates.txt", "r") as coord_file:
                num_lines = sum(1 for _ in coord_file)
        except FileNotFoundError:
            num_lines = 0
        f.write(f"Number of calibration positions: {num_lines}\n")


def ask_user(file_path):
    response = input("What variable was tested? ")
    with open(file_path, "a") as f:
        f.write("---------- Test Information ----------\n")
        f.write(f"Tested Variable: {response}\n")


# main
file_path = create_today_textfile()
ask_user(file_path)
fill_meta_data(file_path)

