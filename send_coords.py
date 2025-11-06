import socket
import json
import time
import os
import ast

class CupPickingClient:
    def __init__(self, host='192.168.125.1', port=1025):
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        #self.json_file_path = json_file_path
        self.cups_data = None
        #self.load_cups_data()

    # def load_cups_data(self, json_file_path=None):
    #     """Load cups data from JSON file provided by vision system"""
    #     if json_file_path:
    #         self.json_file_path = json_file_path

    #     try:
    #         if os.path.exists(self.json_file_path):
    #             with open(self.json_file_path, 'r') as file:
    #                 self.cups_data = json.load(file)
    #             print(f"[INFO] Loaded {len(self.cups_data['cups'])} cups from {self.json_file_path}")
    #             return True
    #         else:
    #             print(f"[ERROR] JSON file {self.json_file_path} not found")
    #             self.cups_data = {"cups": []}
    #             return False
    #     except Exception as e:
    #         print(f"[ERROR] Failed to load JSON file: {e}")
    #         self.cups_data = {"cups": []}
    #         return False

    def save_cups_data(self, json_file_path=None):
        """Save updated cups data back to JSON file"""
        if json_file_path:
            self.json_file_path = json_file_path

        try:
            with open(self.json_file_path, 'w') as file:
                json.dump(self.cups_data, file, indent=4)
            print(f"[INFO] Updated cup statuses saved to {self.json_file_path}")
        except Exception as e:
            print(f"[ERROR] Failed to save JSON file: {e}")

    def get_available_cups_count(self):
        """Get number of cups with Available status"""
        if not self.cups_data:
            return 0
        return len([cup for cup in self.cups_data['cups'] if cup.get('status') in ['Available', 'Avaliable']])

    def connect(self):
        """Connect to RAPID server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(120)  # Increased to 120 seconds for robot movement
            self.socket.connect((self.host, self.port))
            self.connected = True
            print(f"[INFO] Connected to RAPID server at {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"[ERROR] Connection failed: {e}")
            return False

    def send_message(self, message):
        """Send message to RAPID"""
        if not self.connected:
            print("[ERROR] Not connected to robot!")
            return None

        try:
            self.socket.send(message.encode())
            print(f"[SENT] {message}")
        except Exception as e:
            print(f"[ERROR] Send error: {e}")
            self.connected = False
            return None

    def receive_message(self):
        """Receive message from RAPID"""
        try:
            message = self.socket.recv(1024).decode()
            print(f"[RECEIVED] {message}")
            return message
        except socket.timeout:
            print(f"[ERROR] Receive timeout - no message received within timeout period")
            self.connected = False
            return None
        except Exception as e:
            print(f"[ERROR] Receive error: {e}")
            self.connected = False
            return None

    def send_coordinate(self, position):
        """Send coordinate in format [x,y,z]"""
        coord_str = f"[{position[0]},{position[1]},{position[2]}]"
        self.send_message(coord_str)

    def send_orientation(self, orientation):
        """Send orientation in format [q1,q2,q3,q4]"""
        orient_str = f"[{orientation['q1']},{orientation['q2']},{orientation['q3']},{orientation['q4']}]"
        self.send_message(orient_str)

    def execute_cup_picking_protocol(self):
        """Execute the complete cup picking communication protocol"""
        try:
            # Step 1: Initial connection confirmation
            print("\n=== Step 1: Connection Confirmation ===")
            self.send_message("Connection_test")
            response = self.receive_message()

            if response != "Connection_Confirmed":
                print("[ERROR] Connection confirmation failed")
                return

            # Step 2: Wait for Ask_next
            response = self.receive_message()
            if response != "Ask_next":
                print(f"[WARNING] Expected 'Ask_next', got: {response}")

            # Step 3: Check if cups are available
            print("\n=== Step 2: Cup Availability Check ===")
            available_cups_count = self.get_available_cups_count()

            if available_cups_count > 0:
                print(f"[INFO] {available_cups_count} cups available")
                self.send_message("Cups_available")

                # Start the cup moving sequence
                self.handle_moving_cups()

                # Save updated cup statuses
                self.save_cups_data()
            else:
                print("[INFO] No cups available")
                self.send_message("Cups_Not_available")

        except Exception as e:
            print(f"[ERROR] Protocol execution error: {e}")
        finally:
            self.disconnect()

    def handle_moving_cups(self):
        """Handle the MovingCups procedure from RAPID"""

        # Step 1: Respond to Ask_amount_of_cups
        print("\n=== Step 3: Amount of Cups ===")
        response = self.receive_message()

        if response == "Ask_amount_of_cups":
            available_cups_count = self.get_available_cups_count()
            self.send_message(str(available_cups_count))

            response = self.receive_message()
            if response == "Ack_amount_of_cups":
                print(f"[INFO] Robot acknowledged {available_cups_count} cups")

                # Process cups one by one until user says no
                while self.connected:
                    available_cups = [cup for cup in self.cups_data['cups'] if
                                      cup.get('status') in ['Available', 'Avaliable']]

                    if not available_cups:
                        print("[INFO] No more cups to process")
                        break

                    # Get the next available cup
                    cup = available_cups[0]
                    print(f"\n=== Processing Cup: {cup.get('name', cup.get('id'))} ===")

                    success = self.process_single_cup(cup)

                    if not success:
                        print(f"[WARNING] Failed to process cup {cup.get('id')}")
                        break

                    #Mark cup as sent (COMMENTED FOR NOW)
                    cup['status'] = 'Sent'
                    print(f"[INFO] Cup {cup.get('id')} marked as 'Sent'")
                    self.save_cups_data()

                    # After robot finishes movement, it will ask if we want to continue
                    print("\n[INFO] Waiting for robot to ask about next cup...")
                    response = self.receive_message()

                    if response == "Ask_next":
                        user_input = input("Continue with next cup? (y/n): ").strip().lower()

                        # Keep asking until valid input
                        while user_input not in ['y', 'n']:
                            print("[WARNING] Please enter 'y' or 'n'")

                            # Robot will send error and ask again
                            response = self.receive_message()
                            if "[ERROR]" in response:
                                print(f"[ROBOT] {response}")

                            response = self.receive_message()
                            if response == "Ask_next":
                                user_input = input("Continue with next cup? (y/n): ").strip().lower()

                        self.send_message(user_input)

                        if user_input == 'n':
                            print("[INFO] User chose to stop")
                            break
                    elif response is None:
                        print("[ERROR] Lost connection to robot")
                        break
                    else:
                        print(f"[WARNING] Expected 'Ask_next', got: {response}")
                        break

                # Wait for final Ack_stop
                print("\n[INFO] Waiting for robot to finish...")
                response = self.receive_message()
                if response == "Ack_stop":
                    print("[INFO] Robot finished all cups, closing connection")

    def process_single_cup(self, cup):
        """Process a single cup - send start and end positions"""

        try:
            # Step 1: Wait for Ack_cup_current_position (this is the cup pickup position)
            response = self.receive_message()
            if response != "Ack_cup_current_position":
                print(f"[ERROR] Expected Ack_cup_current_position, got: {response}")
                return False

            print("[INFO] Sending cup pickup position...")

            # Send cup position (where to pick up the cup)
            response = self.receive_message()
            if response != "Ask_Coordinate":
                print(f"[ERROR] Expected Ask_Coordinate, got: {response}")
                return False

            self.send_coordinate(cup['position'])

            response = self.receive_message()
            if response != "Ack_Coordinate":
                print(f"[ERROR] Expected Ack_Coordinate, got: {response}")
                return False

            response = self.receive_message()
            if response != "Ask_Orientation":
                print(f"[ERROR] Expected Ask_Orientation, got: {response}")
                return False

            self.send_orientation(cup['orientation'])

            response = self.receive_message()
            if response != "Ack_Orientation":
                print(f"[ERROR] Expected Ack_Orientation, got: {response}")
                return False

            print("[INFO] Cup pickup position sent successfully")

            # Step 2: Wait for Ack_cup_end_position (where to place the cup)
            response = self.receive_message()
            if response != "Ack_cup_end_position":
                print(f"[ERROR] Expected Ack_cup_end_position, got: {response}")
                return False

            print("[INFO] Sending cup placement position...")

            # Send release_position as the end position (where to place the cup)
            response = self.receive_message()
            if response != "Ask_Coordinate":
                print(f"[ERROR] Expected Ask_Coordinate, got: {response}")
                return False

            self.send_coordinate(cup['release_position'])

            response = self.receive_message()
            if response != "Ack_Coordinate":
                print(f"[ERROR] Expected Ack_Coordinate, got: {response}")
                return False

            response = self.receive_message()
            if response != "Ask_Orientation":
                print(f"[ERROR] Expected Ask_Orientation, got: {response}")
                return False

            self.send_orientation(cup['orientation'])

            response = self.receive_message()
            if response != "Ack_Orientation":
                print(f"[ERROR] Expected Ack_Orientation, got: {response}")
                return False

            print("[INFO] Cup placement position sent successfully")

            # Step 3: Wait for robot movement notification
            response = self.receive_message()
            if response == "Ask_Wait":
                print("[INFO] Robot is now moving to pickup and placement positions...")
                print("[INFO] This may take some time - please wait...")
            else:
                print(f"[WARNING] Expected 'Ask_Wait', got: {response}")

            # Robot will move to both positions and then ask for next cup
            # That's handled back in handle_moving_cups()
            return True

        except Exception as e:
            print(f"[ERROR] Error processing cup: {e}")
            return False

    def disconnect(self):
        """Close connection"""
        if self.socket:
            try:
                self.socket.close()
                self.connected = False
                print("[INFO] Disconnected from robot")
            except:
                pass

    def move_cup(self, coordinates, orientation):
        move = "Move"
        coord_str = f"[{coordinates[0]},{coordinates[1]},{coordinates[2]}]"
        orientation_str = f"[{orientation[0]},{orientation[1]},{orientation[2]},{orientation[3]}]"

        self.send_message(move)
        response = self.receive_message()
        if response != "Ask_Coordinate":
            print(f"[ERROR] Expected Ask_Coordinate, got: {response}")
            return False
        else:
            self.send_message(coord_str)
        
        response = self.receive_message()
        if response != "Ack_Coordinate":
            print(f"[ERROR] Expected Ack_Coordinate, got: {response}")
            return False

        response = self.receive_message()
        if response != "Ask_Orientation":
            print(f"[ERROR] Expected Ask_Orientation, got: {response}")
            return False
        
        else:
            self.send_message(orientation_str)
        
        response = self.receive_message()
        if response != "Ack_Orientation":
            print(f"[ERROR] Expected Ack_Orientation, got: {response}")
            return False

        response = self.receive_message()
        if response != "Ack_succesfull":
            print(f"[ERROR] Expected Ack_succesfull, got: {response}")
            return False
        
        print("[INFO] Cup pickup position sent successfully")

        response = self.receive_message()
        if response != "Ask_next":
            print(f"[ERROR] Expected Ask_next, got: {response}")
            return False

    def move_cup_test(self, coordinates, orientation):
        move = "testmove"
        print("Alive")
        coord_str = f"[{coordinates[0]},{coordinates[1]},{coordinates[2]}]"
        orientation_str = f"[{orientation[0]},{orientation[1]},{orientation[2]},{orientation[3]}]"

        self.send_message(move)
        response = self.receive_message()
        if response != "Ask_Coordinate":
            print(f"[ERROR] Expected Ask_Coordinate, got: {response}")
            return False
        else:
            self.send_message(coord_str)
        
        response = self.receive_message()
        if response != "Ack_Coordinate":
            print(f"[ERROR] Expected Ack_Coordinate, got: {response}")
            return False

        response = self.receive_message()
        if response != "Ask_Orientation":
            print(f"[ERROR] Expected Ask_Orientation, got: {response}")
            return False
        
        else:
            self.send_message(orientation_str)
        
        response = self.receive_message()
        if response != "Ack_Orientation":
            print(f"[ERROR] Expected Ack_Orientation, got: {response}")
            return False

        response = self.receive_message()
        if response != "Ack_succesfull":
            print(f"[ERROR] Expected Ack_succesfull, got: {response}")
            return False
        
        print("[INFO] Cup pickup position sent successfully")

        response = self.receive_message()
        if response != "Ask_next":
            print(f"[ERROR] Expected Ask_next, got: {response}")
            return False

        
    def grip(self):
        self.send_message("Grip")

        response = self.receive_message()
        if response != "Ack_wait":
            print(f"[ERROR] Expected Ack_wait, got: {response}")
            return False
        
        response = self.receive_message()
        if response != "Ack_Grip done":
            print(f"[ERROR] Expected Ack_Grip done, got: {response}")
            return False
        

    def get_coords(self):
        message = "Pos" #"Pos" is the command to get coordinates from robot
        print("alive")
        self.send_message(message)
         
        response = self.receive_message()
        time.sleep(0.1) # To not cause issue with the followup "ask_next" message
        _ = self.receive_message() # throw away ask message
        data_float = ast.literal_eval(response) #Covert the string that looks like a list into a actual list

        return data_float

    def leave_cup(self):
        print("ALIVE")
        self.send_message("LeaveCup")



def main():
    print("=== Cup Picking Communication Protocol ===")

    # Create client
    client = CupPickingClient()

    # Connect and execute protocol
    if client.connect():
        client.execute_cup_picking_protocol()
    else:
        print("[ERROR] Failed to establish connection")


if __name__ == "__main__":
    main()