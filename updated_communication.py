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
        self.socket = None
        self.port = 1025
        self.host = '192.168.125.1'
        self.connected = False


        """Connect to RAPID server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #socket.settimeout(120)  # Increased to 120 seconds for robot movement
            self.socket.connect((self.host, self.port))
            self.connected = True
            print(f"[INFO] Connected to RAPID server at {self.host}:{self.port}")

        except Exception as e:
            print(f"[ERROR] Connection failed: {e}")


        
    def _send_message(self, message):
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
        self.CalibrationRobtarget = [] # these values should be copied from robotstudio


    def GetPosition(self):
        return self.comms.GetPosition()
    def Move(self, coordinates, orientation):
        return self.comms.Move(coordinates, orientation)
    def PickUpSequence(self, coordinates, orientation):
        return self.comms.PickUpSequence(coordinates, orientation)
    def LeaveSequence(self, coordinates, orientation):
        return self.comms.LeaveSequence(coordinates, orientation)
    
    def MugProcess(self, PickUpcoordinates, PickUpOrientation, LeaveCoordinates, LeaveOrientation):
        # Current mug coordinate and orientation, leave coordinates and orientation.
        # This function will pick up one mug and leave it at a specified point.
        #  If you have multiple mugs you need to call it multiple times


        #time.sleep(1)
        #MugsInFrame = True

        self.comms.PickUpSequence(PickUpcoordinates, PickUpOrientation)
        self.comms.LeaveSequence(LeaveCoordinates, LeaveOrientation)


    def Calibration(self, NumberOfPositions = 10, q_rgb=None, q_depth=None, q_det=None):

        if q_rgb is None or q_depth is None or q_det is None:
            raise ValueError("Calibration requires q_rgb, q_depth and q_det to be provided (none of them may be None)")

        for i in range(1, NumberOfPositions + 1):

            print(f"[CAL] Position {position_id}/{NumberOfPositions}")
            # ...existing code...
            # Use position_id for naming/saving per-position data if needed

        return position_ids



        return 