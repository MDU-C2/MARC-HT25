import socket
import json
import time
import os
import ast
import threading


class Communication():
    """Class to handle communication with RAPID server"""

    def __init__(self):
        self._mutex_orientation = threading.Lock()  #mutex for accessing variables
        self._mutex_coordinates = threading.Lock()
        self.coordinates = None
        self.orientation = None
        self.socket = None
        self.port = 1025
        self.host = '192.168.125.1'
        self.connected = False


        """Connect to RAPID server"""
        try:
            socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #socket.settimeout(120)  # Increased to 120 seconds for robot movement
            socket.connect((self.host, self.port))
            connected = True
            print(f"[INFO] Connected to RAPID server at {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"[ERROR] Connection failed: {e}")
            return False

        
    def _send_message(self, message):
        """Send message to RAPID"""
        if not connected:
            print("[ERROR] Not connected to robot!")
            return None

        try:
            socket.send(message.encode())
            print(f"[SENT] {message}")
        except Exception as e:
            print(f"[ERROR] Send error: {e}")
            connected = False
            return None

    def _receive_message(self):
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
        
    def _handle_response(self):
        while True:
            response = self._receive_message()
            if response == "send coordinates":
                self._send_message(self.coordinates)
            if response == "send orientation":
                self._send_message(self.orientation)
            if response == "Ack_Coordinates":
                continue
            if response == "Ack_Orientation":
                continue
            if response == "Ask_Next":
                break
    
    def GetPosition(self):
        #"""Get current position from RAPID"""
        self._send_message("get coordinates")
        response = self._handle_response()
        if response:
            with self._mutex_coordinates:
                self.coordinates = ast.literal_eval(response)
            self._send_message("Ack_Coordinates")
            return self.coordinates
        return None