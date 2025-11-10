import socket
import json
import time
import os
import ast

connected = False

def connect():
    """Connect to RAPID server"""
    host='192.168.125.1'
    port=1025
    global connected
    try:
        socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        socket.settimeout(120)  # Increased to 120 seconds for robot movement
        socket.connect((host, port))
        connected = True
        print(f"[INFO] Connected to RAPID server at {host}:{port}")
        return True
    except Exception as e:
        print(f"[ERROR] Connection failed: {e}")
        return False
    

def send_message(message):

    global connected
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
    

def communication(message, coordinates = None, Orientation = None):
    """Handle full communication cycle with RAPID"""
    global connected
    if not connected:
        if not connect():
            return None
    send_message(message)
    
    
    while True:
        response = receive_message()
        if response == "send coordinates":
            send_message(coordinates)
        if response == "send orientation":
            send_message(Orientation)
        if response == "Ack_Coordinates":
            continue
        if response == "Ack_Orientation":
            continue
        if response == "Ask_Next":
            break