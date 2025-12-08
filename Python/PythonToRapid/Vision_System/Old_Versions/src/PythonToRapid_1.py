"""
Robot Communication Module - Compatible with actual RAPID script
Handles communication with ABB YuMi robot via TCP/IP socket
Protocol: Connection_test → Cups_available → MovingCups flow
"""

import socket
import time
from typing import List, Dict, Optional


class RobotCommunication:
    def __init__(self, host='192.168.125.1', port=1025):
        """
        Initialize robot communication
        
        Args:
            host: Robot IP address (default: '192.168.125.1')
            port: Communication port (default: 1025)
        """
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        self.current_cup_index = 0
        
        # Default release position
        self.release_position = [421, -186, -53]  # [x, y, z] in mm
        
        print(f"[ROBOT] Communication module initialized")
        print(f"[ROBOT] Target: {host}:{port}")
        print(f"[ROBOT] Default release position: {self.release_position}")

    def set_release_position(self, x, y, z):
        """Set the release position for all cups"""
        self.release_position = [x, y, z]
        print(f"[ROBOT] Release position updated: {self.release_position}")

    def connect(self):
        """Connect to RAPID server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(120)
            self.socket.connect((self.host, self.port))
            self.connected = True
            print(f"[ROBOT] ✓ Connected to {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"[ROBOT] ✗ Connection failed: {e}")
            return False

    def send_message(self, message: str):
        """Send message to RAPID"""
        if not self.connected:
            print("[ROBOT] ✗ Not connected!")
            return

        try:
            self.socket.send(message.encode())
            print(f"[ROBOT] → {message}")
            time.sleep(0.1)
        except Exception as e:
            print(f"[ROBOT] ✗ Send error: {e}")
            self.connected = False

    def receive_message(self, timeout: float = 120.0) -> Optional[str]:
        """Receive message from RAPID"""
        try:
            old_timeout = self.socket.gettimeout()
            self.socket.settimeout(timeout)
            
            message = self.socket.recv(1024).decode().strip()
            print(f"[ROBOT] ← {message}")
            
            self.socket.settimeout(old_timeout)
            time.sleep(0.1)
            
            return message
        except socket.timeout:
            print(f"[ROBOT] ✗ Receive timeout")
            return None
        except Exception as e:
            print(f"[ROBOT] ✗ Receive error: {e}")
            self.connected = False
            return None

    def start_session(self) -> bool:
        """
        Start robot session
        
        Returns:
            bool: True if session started successfully
        """
        if not self.connected:
            print("[ROBOT] ✗ Cannot start session - not connected")
            return False
        
        print(f"\n[ROBOT] ====================================")
        print(f"[ROBOT] Starting session...")
        print(f"[ROBOT] ====================================")
        
        # Step 1: Connection test
        self.send_message("Connection_test")
        response = self.receive_message()
        
        if response != "Connection_Confirmed":
            print("[ROBOT] ✗ Connection not confirmed")
            return False
        
        # Step 2: Wait for Ask_next
        response = self.receive_message()
        if response != "Ask_next":
            print(f"[ROBOT] ⚠️ Expected 'Ask_next', got: {response}")
        
        # Step 3: Announce cups available
        self.send_message("Cups_available")
        
        print("[ROBOT] ✓ Session started")
        self.current_cup_index = 0
        return True

    def send_cup(self, cup: Dict) -> bool:
        """
        Send single cup to robot - COMPLETE TRANSACTION
        
        Args:
            cup: Cup data with position, orientation
            
        Returns:
            bool: True if successful
        """
        print(f"\n[ROBOT] ===================================")
        print(f"[ROBOT] Sending cup data...")
        print(f"[ROBOT] ===================================")
        
        try:
            # Step 1: Amount of cups
            response = self.receive_message()
            if response != "Ask_amount_of_cups":
                print(f"[ROBOT] ✗ Expected Ask_amount_of_cups, got: {response}")
                return False
            
            self.send_message("1")  # Always 1 cup at a time in automatic mode
            
            response = self.receive_message()
            if response != "Ack_amount_of_cups":
                print(f"[ROBOT] ✗ Expected Ack_amount_of_cups, got: {response}")
                return False
            
            # Step 2: Send cup pickup position
            response = self.receive_message()
            if response != "Ack_cup_current_position":
                print(f"[ROBOT] ✗ Expected Ack_cup_current_position, got: {response}")
                return False
            
            print("[ROBOT] Sending cup pickup position...")
            
            # Wait for Ask_Coordinate
            response = self.receive_message()
            if response != "Ask_Coordinate":
                print(f"[ROBOT] ✗ Expected Ask_Coordinate, got: {response}")
                return False
            
            # Send position
            pos = cup['position']
            coord_str = f"[{pos['x']},{pos['y']},{pos['z']}]"
            self.send_message(coord_str)
            
            response = self.receive_message()
            if response != "Ack_Coordinate":
                print(f"[ROBOT] ✗ Expected Ack_Coordinate, got: {response}")
                return False
            
            # Wait for Ask_Orientation
            response = self.receive_message()
            if response != "Ask_Orientation":
                print(f"[ROBOT] ✗ Expected Ask_Orientation, got: {response}")
                return False
            
            # Send orientation
            ori = cup['orientation']
            orient_str = f"[{ori['q1']},{ori['q2']},{ori['q3']},{ori['q4']}]"
            self.send_message(orient_str)
            
            response = self.receive_message()
            if response != "Ack_Orientation":
                print(f"[ROBOT] ✗ Expected Ack_Orientation, got: {response}")
                return False
            
            print("[ROBOT] ✓ Cup pickup position sent")
            
            # Step 3: Send cup release position
            response = self.receive_message()
            if response != "Ack_cup_end_position":
                print(f"[ROBOT] ✗ Expected Ack_cup_end_position, got: {response}")
                return False
            
            print("[ROBOT] Sending cup release position...")
            
            # Wait for Ask_Coordinate
            response = self.receive_message()
            if response != "Ask_Coordinate":
                print(f"[ROBOT] ✗ Expected Ask_Coordinate, got: {response}")
                return False
            
            # Send release position
            release_str = f"[{self.release_position[0]},{self.release_position[1]},{self.release_position[2]}]"
            self.send_message(release_str)
            
            response = self.receive_message()
            if response != "Ack_Coordinate":
                print(f"[ROBOT] ✗ Expected Ack_Coordinate, got: {response}")
                return False
            
            # Wait for Ask_Orientation
            response = self.receive_message()
            if response != "Ask_Orientation":
                print(f"[ROBOT] ✗ Expected Ask_Orientation, got: {response}")
                return False
            
            # Send orientation (same as pickup)
            self.send_message(orient_str)
            
            response = self.receive_message()
            if response != "Ack_Orientation":
                print(f"[ROBOT] ✗ Expected Ack_Orientation, got: {response}")
                return False
            
            print("[ROBOT] ✓ Cup release position sent")
            
            # Step 4: Wait for Ask_Wait (robot is moving)
            response = self.receive_message()
            if response == "Ask_Wait":
                print("[ROBOT] → Robot is moving...")
            
            # Step 5: Wait for Ask_next
            response = self.receive_message()
            if response == "Ask_next":
                print("[ROBOT] ✓ Movement complete")
                
                # Automatically send 'n' to continue (main loop will handle next cup)
                self.send_message("n")
                
                self.current_cup_index += 1
                return True
            
        except Exception as e:
            print(f"[ROBOT] ✗ Error sending cup: {e}")
            return False
        
        return False

    def end_session(self):
        """End robot session"""
        if self.connected:
            # Wait for Ack_stop
            response = self.receive_message(timeout=5.0)
            if response == "Ack_stop":
                print("\n[ROBOT] ====================================")
                print("[ROBOT] Session completed")
                print(f"[ROBOT] Total cups sent: {self.current_cup_index}")
                print("[ROBOT] ====================================")

    def disconnect(self):
        """Close connection"""
        if self.socket:
            try:
                self.socket.close()
                self.connected = False
                print("[ROBOT] ✓ Disconnected")
            except:
                pass

    def is_connected(self) -> bool:
        """Check if connected to robot"""
        return self.connected

    def get_status(self) -> Dict:
        """Get current communication status"""
        return {
            'connected': self.connected,
            'host': self.host,
            'port': self.port,
            'current_cup_index': self.current_cup_index,
            'release_position': self.release_position
        }