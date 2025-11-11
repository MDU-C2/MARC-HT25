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
        self._mutex_coordinates = threading.Lock() # unused?
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
        
    
    def GetPosition(self):
        #"""Get current position from RAPID"""
        self._send_message("get coordinates")
        response = self._receive_message()

        return response
    
    def Move(self, coordinates, orientation):

        #"""Move robot to specified coordinates and orientation"""
        self._send_message("move")
        self._receive_message()  # Wait for "ACK" so we dont read both messages at once, not sure if this is correct
        self._send_message(coordinates)
        self._receive_message()
        self._send_message(orientation)
        self._receive_message()  # Wait for Movement to complete

        return

    def PickUpSequence(self, coordinates, orientation):
        self._send_message("pick up mug")
        self._receive_message()  # Wait for "ACK"
        self._send_message(coordinates)
        self._receive_message()
        self._send_message(orientation)
        self._receive_message()  # Wait for pick-up to complete

        #"""Perform pick-up sequence"""
        return

    def LeaveSequence(self, coordinates, orientation):
        self._send_message("leave mug")
        self._receive_message()  # Wait for "ACK"
        self._send_message(coordinates)
        self._receive_message()
        self._send_message(orientation)
        self._receive_message()  # Wait for leave to complete

        #"""Perform leave sequence"""
        return
    

class RobotInterface():
    """Class to interface with robot for mug handling"""

    def __init__(self):
        self.comms = Communication()
        self.MugCoordinates = None
        self.MugOrientation = None

    def GetPosition(self):
        return self.comms.GetPosition()
    def Move(self, coordinates, orientation):
        return self.comms.Move(coordinates, orientation)
    def PickUpSequence(self, coordinates, orientation):
        return self.comms.PickUpSequence(coordinates, orientation)
    def LeaveSequence(self, coordinates, orientation):
        return self.comms.LeaveSequence(coordinates, orientation)
    
    def MugProcess(self):
        #"""Perform mug handling process"""
        # Current mug coordinate and orientation, leave position, coordinates and orientation, If there is a next mug.
        time.sleep(1)
        MugsInFrame = True
        UpdateMugCoordinates()  # Placeholder for code to update mug coordinates
        while MugsInFrame:

            self.comms.PickUpSequence(self.MugCoordinates, self.MugOrientation)
            self.comms.LeaveSequence(self.MugCoordinates, self.MugOrientation)
            UpdateMugCoordinates()  # Placeholder for code to update mug coordinates
        return

    def Calibration():
        #"""Calibrate robot position"""

        return

