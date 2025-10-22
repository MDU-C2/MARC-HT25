import socket
import json
import time
import os


class CupPickingClient:
    def __init__(self, host='192.168.125.1', port=1025):
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        self.cups_data = None

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