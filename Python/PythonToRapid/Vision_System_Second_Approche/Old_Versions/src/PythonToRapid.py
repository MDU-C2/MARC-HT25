#### For presinting ####
########################
"""
Robot Communication Module _Handles communication with ABB YuMi robot via TCP/IP socket
WITH TIMING for real robot hardware + VISUAL SERVOING
"""

import socket
import time
from typing import List, Dict, Optional


class RobotCommunication:
    def __init__(self, host='127.0.0.1', port=1025):
        """Initialize robot communication"""
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        
        # Default release position
        self.release_position = [421, -186, 200]
        
        print(f"[ROBOT] Communication module initialized")
        print(f"[ROBOT] Target: {host}:{port}")

    def connect(self):
        """Connect to RAPID server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(30)
            self.socket.connect((self.host, self.port))
            self.connected = True
            print(f"[ROBOT] Connected to {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"[ROBOT] Connection failed: {e}")
            return False

    def send_message(self, message: str) -> Optional[str]:
        """Send message and wait for response"""
        if not self.connected:
            return None

        try:
            self.socket.send(message.encode())
            print(f"[ROBOT] -> {message}")
            time.sleep(0.5)
            
            response = self.socket.recv(1024).decode().strip()
            print(f"[ROBOT] <- {response}")
            time.sleep(0.5)
            
            return response
        except Exception as e:
            print(f"[ROBOT] Error: {e}")
            self.connected = False
            return None

    def receive_message(self, timeout: float = 30.0) -> Optional[str]:
        """Receive message from RAPID"""
        try:
            old_timeout = self.socket.gettimeout()
            self.socket.settimeout(timeout)
            
            message = self.socket.recv(1024).decode().strip()
            print(f"[ROBOT] <- {message}")
            
            self.socket.settimeout(old_timeout)
            time.sleep(0.5)
            
            return message
        except socket.timeout:
            return None
        except Exception as e:
            print(f"[ROBOT] Receive error: {e}")
            return None

    def send_position_correction(self, correction: Dict) -> bool:
        """
        Send position correction during movement (VISUAL SERVOING)
        
        Args:
            correction: {'x': float, 'y': float, 'z': float}
            
        Returns:
            bool: True if correction accepted
        """
        if not self.connected:
            return False
        
        try:
            correction_str = f"Update_Position:[{correction['x']},{correction['y']},{correction['z']}]"
            self.socket.send(correction_str.encode())
            
            self.socket.settimeout(0.5)
            response = self.socket.recv(1024).decode().strip()
            self.socket.settimeout(30)
            
            if response == "Ack_Update_Received":
                return True
            else:
                return False
                
        except socket.timeout:
            return False
        except Exception as e:
            print(f"[SERVOING] Correction send error: {e}")
            return False

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
        
        # 1. Wait for coordinate request
        request = self.receive_message()
        if not request or "Ask_Coordinate" not in request:
            print("[ROBOT] No coordinate request")
            return False
        
        # 2. Send position [x,y,z]
        pos = cup['position']
        coord_str = f"[{pos['x']},{pos['y']},{pos['z']}]"
        print(f"[ROBOT] Sending position: {coord_str}")
        
        response = self.send_message(coord_str)
        if response != "Ack_Coordinate_Received":
            print("[ROBOT] Coordinate not acknowledged")
            return False
        
        # 3. Wait for orientation request
        request = self.receive_message()
        if request != "Ask_Orientation":
            print("[ROBOT] No orientation request")
            return False
        
        # 4. Send orientation [q1,q2,q3,q4]
        ori = cup['orientation']
        orient_str = f"[{ori['q1']},{ori['q2']},{ori['q3']},{ori['q4']}]"
        print(f"[ROBOT] Sending orientation: {orient_str}")
        
        response = self.send_message(orient_str)
        if response != "Ack_Orientation_Received":
            print("[ROBOT] Orientation not acknowledged")
            return False
        
        # 5. Wait for release position request
        request = self.receive_message()
        if request != "Ask_Release_Position":
            print("[ROBOT] No release request")
            return False
        
        # 6. Send release position
        release_str = f"[{self.release_position[0]},{self.release_position[1]},{self.release_position[2]}]"
        print(f"[ROBOT] Sending release: {release_str}")
        
        response = self.send_message(release_str)
        if response != "Ack_Release_Position_Received":
            print("[ROBOT] Release not acknowledged")
            return False
        
        # 7. Wait for movement completion
        print("[ROBOT] Waiting for robot movement...")
        while self.connected:
            signal = self.receive_message(timeout=1.0)
            
            if not signal:
                continue
            
            if signal == "Robot_Moving":
                print("[ROBOT] -> Moving...")
            elif signal == "Cup_Picked_Up":
                print("[ROBOT] Picked up!")
            elif signal == "Cup_Released":
                print("[ROBOT] Released!")
            elif signal == "Movement_Complete":
                print("[ROBOT] Complete!")
                break
            elif signal == "Movement_Error":
                print("[ROBOT] Movement error")
                return False
        
        # 8. Wait 3 seconds before next cup
        print("[ROBOT] Waiting 3 seconds before next cup...")
        time.sleep(3.0)
        
        return True

    def start_session(self) -> bool:
        """Start robot session"""
        if not self.connected:
            return False
        
        print(f"\n[ROBOT] ====================================")
        print(f"[ROBOT] Starting session...")
        print(f"[ROBOT] ====================================")
        
        # Connection test - FIXED: send then receive separately
        print("[ROBOT] Sending connection test...")
        self.socket.send("Connection_Test".encode())
        print("[ROBOT] -> Connection_Test")
        
        response = self.receive_message(timeout=30.0)
        if response != "Connection_Confirmed":
            print("[ROBOT] Connection not confirmed")
            return False
        
        print("[ROBOT] Session started")
        return True

    def end_session(self):
        """End session"""
        if self.connected:
            self.send_message("Session_Complete")
            print("\n[ROBOT] ====================================")
            print("[ROBOT] Session ended")
            print("[ROBOT] ====================================")

    def disconnect(self):
        """Close connection"""
        if self.socket:
            try:
                self.socket.close()
                self.connected = False
                print("[ROBOT] Disconnected")
            except:
                pass

    def is_connected(self) -> bool:
        """Check connection"""
        return self.connected

################## For Testing ###################
##################################################
