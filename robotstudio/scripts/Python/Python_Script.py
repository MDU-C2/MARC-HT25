import socket
import json
import time
import os


class CupPickingClient:
    def __init__(self, host='192.168.125.1', port=1025, json_file_path="cups_data.json"):
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        self.json_file_path = json_file_path
        self.cups_data = None
        self.load_cups_data()

    def load_cups_data(self, json_file_path=None):
        """Load cups data from JSON file provided by vision system"""
        if json_file_path:
            self.json_file_path = json_file_path

        try:
            if os.path.exists(self.json_file_path):
                with open(self.json_file_path, 'r') as file:
                    self.cups_data = json.load(file)
                print(f"[INFO] Loaded {len(self.cups_data['cups'])} cups from {self.json_file_path}")
                return True
            else:
                print(f"[ERROR] JSON file {self.json_file_path} not found")
                self.cups_data = {"cups": []}
                return False
        except Exception as e:
            print(f"[ERROR] Failed to load JSON file: {e}")
            self.cups_data = {"cups": []}
            return False

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
        # Check for both spellings to handle typos
        return len([cup for cup in self.cups_data['cups'] if cup.get('status') in ['Available', 'Avaliable']])

    def connect(self):
        """Connect to RAPID server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(30)
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
        except Exception as e:
            print(f"[ERROR] Receive error: {e}")
            self.connected = False
            return None

    def send_coordinate(self, position):
        """Send coordinate in format [x,y,z]"""
        coord_str = f"[{position['x']},{position['y']},{position['z']}]"
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
            available_cups = [cup for cup in self.cups_data['cups'] if cup.get('status') in ['Available', 'Avaliable']]
            num_cups = len(available_cups)
            self.send_message(str(num_cups))

            response = self.receive_message()
            if response == "Ack_amount_of_cups":
                print(f"[INFO] Robot acknowledged {num_cups} cups")

                # Process each available cup
                for i, cup in enumerate(available_cups):
                    print(f"\n=== Processing Cup {i + 1}: {cup.get('name', cup.get('id'))} ===")
                    self.process_single_cup(cup)

                # Wait for final Ack_stop
                response = self.receive_message()
                if response == "Ack_stop":
                    print("[INFO] Robot finished all cups, closing connection")

    def process_single_cup(self, cup):
        """Process a single cup - send start and end positions"""

        # Step 1: Wait for Ack_cup_current_position (this is the cup pickup position)
        response = self.receive_message()
        if response == "Ack_cup_current_position":
            print("[INFO] Sending cup pickup position...")

            # Send cup position (where to pick up the cup)
            response = self.receive_message()
            if response == "Ask_Coordinate":
                self.send_coordinate(cup['position'])

                response = self.receive_message()
                if response == "Ack_Coordinate":
                    response = self.receive_message()
                    if response == "Ask_Orientation":
                        self.send_orientation(cup['orientation'])

                        response = self.receive_message()
                        if response == "Ack_Orientation":
                            print("[INFO] Cup pickup position sent successfully")

        # Step 2: Wait for Ack_cup_end_position (where to place the cup)
        response = self.receive_message()
        if response == "Ack_cup_end_position":
            print("[INFO] Sending cup placement position...")

            # Send approach_position as the end position (where to place the cup)
            response = self.receive_message()
            if response == "Ask_Coordinate":
                self.send_coordinate(cup['approach_position'])

                response = self.receive_message()
                if response == "Ack_Coordinate":
                    response = self.receive_message()
                    if response == "Ask_Orientation":
                        self.send_orientation(cup['orientation'])  # Use same orientation

                        response = self.receive_message()
                        if response == "Ack_Orientation":
                            print("[INFO] Cup placement position sent successfully")
                            # Update cup status to 'Sent' after successfully sending all data
                            cup['status'] = 'Sent'
                            print(f"[INFO] Updated cup {cup.get('id')} status to 'Sent'")

        # Step 3: Wait for robot movement to pickup position (Ask_Wait)
        response = self.receive_message()
        if response == "Ask_Wait":
            print("[INFO] Robot is moving to cup pickup position...")

        # # Step 4: Wait for robot movement to placement position (Ask_Wait)
        # response = self.receive_message()
        # if response == "Ask_Wait":
        #     print("[INFO] Robot is moving to cup placement position...")

        # Step 5: Wait for Ask_amount_of_cups (checking for more cups)
        response = self.receive_message()
        if response == "Ask_amount_of_cups":
            # After processing this cup, check remaining available cups
            remaining_cups = self.get_available_cups_count()
            self.send_message(str(remaining_cups))
            print(f"[INFO] Sent remaining cups: {remaining_cups}")

    def disconnect(self):
        """Close connection"""
        if self.socket:
            try:
                self.socket.close()
                self.connected = False
                print("[INFO] Disconnected from robot")
            except:
                pass


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