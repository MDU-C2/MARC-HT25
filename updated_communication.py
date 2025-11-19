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
    
        ## What python can recive SEE BELOW
        self.ACKS = ["Ack_succesful","Ack_wait","Ack_Release done",
                "Ack_succesfull", "ACK","Ack_Coordinate", ] # these should be removed except ACK, it is not in the main switch case but inside a case
        
        self.CLOSE = ["Disconnect", ]
        self.ASKROBOTCOORDINATES = ["Ask_RobotCoordinate", ] # Python will answer with an ACK then receive coordinates then answer with an ACK again
        self.ASKROBOTORIENTATION = ["Ask_RobotOrientation", ] # RAPID gives the robots coordinates

        self.ASKMUGCOORDINATES = ["Ask_MugCoordinate", "Ask_Coordinate"] # Python gives a mugs coordinates
        self.ASKMUGORIENTATION = ["Ask_MugOrientation", "Ask_Orientation"]
        self.ASKNEXT = ["AskNext", "Connection_Confirmed", "Ack_Grip_Done", "Ack_Release done", ] # RAPID is ready for the next command
        self.ASKCALPOINT = ["AskCalPoint", ] 

        ## Special case
        ''' "Ack_AskRobotCoordinate", "Ack_AskRobotOrientation" '''

        ## TODO List of what python can send

        '''
        "Connection_test"
        "Cups_available"
        "Coordinates" dont add this one
        "Pos" 
        "Move"
        "Grip"
        "Release"
        "Home"
        "testmove" dont add this one
        "LeaveCup"
        "Move_Calibration_Position"


        TO BE ADDED LATER:

        "Get_Coordinates"
        "Move_Calibration_Position"
        "Pick_Up_Sequence"
        "Leave_Sequence"

        # Special cases, inside a switch case
        "Ack_AskRobotCoordinate"
        "Ack_AskRobotOrientation"
        "ACK"
        '''





        
        self.MugCoordinates = [200,-200,100] # x,y,z coordinates of the mug
        self.MugOrientation = [1,0,0,0] # quaternion, mug orientation
        self.CalPoint = 1 # calibration point number, corresponds to a point in RAPID
        self.RobTarget = [[200,-200,100],[1,0,0,0],[-1,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]] # RAPID format
        self.Robotcoordinates = [100,100,100] # Robot hand coordinates
        self.Robotorientation = [1,0,0,0] # Robot hand orientation, unused?
        self.MugNormal = [0,0,1]

        #self.RobTarget = []
        #self.Pos = []
        #self.Orient = []

        #self.RobTarget.append([[200,-200,100],[1,0,0,0],[-1,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]])
        #self.Pos.append([200,-200,100])
        #self.Orient.append([1,0,0,0])

    






    def _handle_response(self):
        """Handle response from RAPID"""
        
        while True: # It will loop until the response is in "ASKNEXT" or RAPID wants to close the connection (CLOSE).

            response = self._receive_message()


            match response:
                case next if next in self.ASKNEXT:
                    return None
                
                case ack if ack in self.ACKS:
                    continue

                case close if close in self.CLOSE:
                    self.disconnect() # Disconnect, don't send anything to RAPID
                    return None
                
                case ask_robot_coordinates if ask_robot_coordinates in self.ASKROBOTCOORDINATES: # RAPID wants to send robot coordinates
                    self._send_message("Ack_AskRobotCoordinate") # Tell RAPID to send coordinates
                    self.Robotcoordinates =  self._receive_message() # Receive coordinates
                    self._send_message("ACK") # Acknowledge so it can send AskNext or other commands

                case ask_robot_orientation if ask_robot_orientation in self.ASKROBOTORIENTATION: # RAPID wants to send robot orientation
                    self._send_message("Ack_AskRobotOrientation")
                    self.Robotorientation = self._receive_message()
                    self._send_message("ACK")

                case askmug_coordinates if askmug_coordinates in self.ASKMUGCOORDINATES: # RAPID wants mug coordinates
                    self._send_message(str(self.MugCoordinates)) # Send mug coordinates

                case askmug_orientation if askmug_orientation in self.ASKMUGORIENTATION: # RAPID wants mug orientation
                    self._send_message(str(self.MugOrientation)) # Send mug orientation

                case askcal_point if askcal_point in self.ASKCALPOINT: # RAPID wants calibration point number
                    self._send_message(str(self.CalPoint)) # Send calibration point number
                    self._handle_response()

                case _: # Error and unexpected response handling
                    #self.ErrorHandling()
                    print(f"[ERROR] Unexpected response: {response}")
                    #self.disconnect()
                    #exit(1)
                    return None

    def connect(self):

        """Connect to RAPID server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #socket.settimeout(120)  # Increased to 120 seconds for robot movement, Dont use time out
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
        self._send_message("Get_Coordinates")
        self._handle_response() # stores respone in self.Robotcoordinates
        self.Robotcoordinates = ast.literal_eval(self.Robotcoordinates) # Convert string to variable

        return self.Robotcoordinates # RobotCoordinates can be both string and a variable depending on when you check it.
    
    def Move(self, coordinates, orientation):

        """Move robot to specified coordinates and orientation"""
        self.MugCoordinates = coordinates
        self.MugOrientation = orientation
        self._send_message("Move")
        self._handle_response()  # Wait for "AskNext"


        return

    def PickUpSequence(self, coordinates, orientation):
        self._send_message("Pick_Up_Sequence")
        self.MugCoordinates = coordinates
        self.MugOrientation = orientation
        self._handle_response()

        #"""Perform pick-up sequence"""
        return None

    def LeaveSequence(self, coordinates, orientation):
        self._send_message("Leave_Sequence")
        self.MugCoordinates = coordinates
        self.MugOrientation = orientation
        self._handle_response()

        #"""Perform leave sequence"""
        return None
    
    def OpenGripper(self):
        self._send_message("Release")
        self._handle_response()
        return None
    
    def CloseGripper(self):
        self._send_message("Grip")
        self._handle_response()
        return None
    
    def MoveCalibrationPosition(self, position):
        self._send_message("Move_Calibration_Position")
        self.CalPoint = position
        self._handle_response()
        return None
    
    def MoveHome(self):
        self._send_message("Home")
        self._handle_response()
        return None
    
    def ConnectionTest(self):
        self._send_message("Connection_test")
        self._handle_response()
        return None
    







