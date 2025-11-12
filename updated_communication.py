import socket
import json
import time
import os
import ast
import threading
import numpy as np
import math


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


        

    def disconnect(self):
        if not self.socket:
            return
        try:
            self._send_message("disconnect")
            try:
                self.socket.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass  # socket may already be closed or not connected
            self.socket.close()
            print("[INFO] Socket closed")
        except Exception as e:
            print(f"[ERROR] Close error: {e}")
        finally:
            self.connected = False
            self.socket = None

        
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
    
    def MoveRobtarget(self, robtarget):
        self._send_message("send robtarget")
        self._receive_message()  # Wait for "ACK"
        self._send_message(robtarget)
        self._receive_message()  # Wait for movement to complete
        return
    








class RobotInterface():

    def __init__(self):
        self.comms = Communication()
        self.CalibrationRobtarget = [] # these values should be copied from robotstudio


    def GetPosition(self):
        return self.comms.GetPosition()
    def Move(self, coordinates, orientation):
        return self.comms.Move(coordinates, orientation)
    def PickUpSequence(self, coordinates, orientation):
        return self.comms.PickUpSequence(coordinates, orientation)
    def LeaveSequence(self, coordinates, orientation):
        return self.comms.LeaveSequence(coordinates, orientation)
    def MoveRobtarget(self, robtarget):
        return self.comms.MoveRobtarget(robtarget)
    def Disconnect(self):
        return self.comms.disconnect()
    

    
    def MugProcess(self, PickUpcoordinates, PickUpOrientation, LeaveCoordinates, LeaveOrientation):
        # Current mug coordinate and orientation, leave coordinates and orientation, Camera detection
        # This function only handles one mug/cup at a time. Call it multiple times for multiple mugs/cups.

        self.comms.PickUpSequence(PickUpcoordinates, PickUpOrientation)
        self.comms.LeaveSequence(LeaveCoordinates, LeaveOrientation)


    def Calibration(self, position):
        # Move to a calibration point and get the coordinates from it.

        # LOAD ROBTARGETS FROM FILE HERE

        self.MoveRobtarget(self.CalibrationRobtarget[position]) # Move to calibration position
        coordinates = self.GetPosition() # Get current robot coordinates

        Robotcoordinates = self.comms.GetPosition() # In string format

        Robotcoordinates = ast.literal_eval(Robotcoordinates) # Convert string to list

        return Robotcoordinates







