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
        self._mutex_variable = threading.Lock()  #mutex for accessing variables
        self._mutex_function = threading.Lock()  #mutex for accessing functions
        self.socket = None
        self.port = 1025
        self.host = '192.168.125.1'
        self.connected = False


    
        ## What python can recive SEE BELOW
        self.ACKS = ["Ack_succesful","Ack_wait","Ack_Release done",
                "Ack_succesfull", "ACK","Ack_Coordinate","Ack_Orientation", "Ack_normal"] # these should be removed except ACK, it is not in the main switch case but inside a case
        
        self.CLOSE = ["Disconnect", ]
        self.ROBOTWANTSTOSENDCOORDINATES = ["Robot_Wants_To_Send_Coordinates", ] # Python will answer with an ACK then receive coordinates then answer with an ACK again
        self.ROBOTWANTSTOSENDORIENTATION = ["Robot_Wants_To_Send_Orientation", ] # RAPID gives the robots coordinates

        self.ASKMUGCOORDINATES = ["Ask_MugCoordinate", "Ask_Coordinate"] # Python gives a mugs coordinates
        self.ASKMUGORIENTATION = ["Ask_MugOrientation", "Ask_Orientation"]
        self.ASKNEXT = ["AskNext", "Connection_Confirmed", "Ack_Grip_Done", "Ack_Release done", ] # RAPID is ready for the next command

        self.ASKCALPOINT = ["AskCalPoint", ]
        self.ASKMUGNORMAL = ["Ask_MugNormal", ]

        ## Special case
        ''' "Ack_AskRobotCoordinate", "Ack_AskRobotOrientation" '''

        ## TODO List of what python can send

        '''
        "Connection_test"
        "Get_Coordinates"
        "Move"
        "Grip"
        "Release"
        "Home"
        "Pick_Up_Sequence"
        "Leave_Sequence"
        "Move_Calibration_Position"

        # Special cases, inside a switch case
        "ACK"
        '''
        
        self.MugCoordinates = [200,-200,100] # x,y,z coordinates of the mug
        self.MugOrientation = [1,0,0,0] # quaternion, mug orientation
        self.CalPoint = 1 # calibration point number, corresponds to a point in RAPID
        self.RobTarget = [[200,-200,100],[1,0,0,0],[-1,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]] # RAPID format
        self.Robotcoordinates = [100,100,100] # Robot hand coordinates
        self.Robotorientation = [1,0,0,0] # Robot hand orientation, unused?
        self.MugNormal = [0,0,1]

        self._watchdog_interval = 60  # seconds
        self._watchdog_thread = None
        self._watchdog_stop = threading.Event()

    






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
                
                case robot_wants_to_send_coordinates if robot_wants_to_send_coordinates in self.ROBOTWANTSTOSENDCOORDINATES: # RAPID wants to send robot coordinates
                    self._send_message("ACK") # Tell RAPID to send coordinates
                    self.Robotcoordinates =  self._receive_message() # Receive coordinates
                    self._send_message("ACK") # Acknowledge so it can send AskNext or other commands

                case robot_wants_to_send_orientation if robot_wants_to_send_orientation in self.ROBOTWANTSTOSENDORIENTATION: # RAPID wants to send robot orientation
                    self._send_message("ACK")
                    self.Robotorientation = self._receive_message()
                    self._send_message("ACK")

                case askmug_coordinates if askmug_coordinates in self.ASKMUGCOORDINATES: # RAPID wants mug coordinates
                    with self._mutex_variable:  # Lock mutex for thread-safe access
                        self._send_message(str(self.MugCoordinates)) # Send mug coordinates

                case askmug_orientation if askmug_orientation in self.ASKMUGORIENTATION: # RAPID wants mug orientation
                    with self._mutex_variable:  # Lock mutex for thread-safe access
                        self._send_message(str(self.MugOrientation)) # Send mug orientation
                    

                case askcal_point if askcal_point in self.ASKCALPOINT: # RAPID wants calibration point number
                    self._send_message(str(self.CalPoint)) # Send calibration point number
                    self._handle_response()
                
                case askmug_normal if askmug_normal in self.ASKMUGNORMAL: # RAPID wants mug normal
                    with self._mutex_variable:  # Lock mutex for thread-safe access
                        self._send_message(str(self.MugNormal)) # Send mug normal

                case _: # Error and unexpected response handling
                    #self.ErrorHandling()
                    print(f"[ERROR] Unexpected response: {response}")
                    self.disconnect()
                    #exit(1)
                    return None
            

    def connect(self):

        with self._mutex_function:  # Lock mutex for function-level thread safety

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

        with self._mutex_function:  # Lock mutex for function-level thread safety
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
        
    def UpdateVariables(self, MugCoordinates = None, MugOrientation = None):
        with self._mutex_variable: # Lock mutex for thread-safe access
            if MugCoordinates is not None:
                self.MugCoordinates = list(MugCoordinates)  # make defensive copy, unnecessary?
            if MugOrientation is not None:
                self.MugOrientation = list(MugOrientation)
        return

      
    
    def GetPosition(self):

        with self._mutex_function:  # Lock mutex for function-level thread safety
            #"""Get current position from RAPID"""
            self._send_message("Get_Coordinates")
            self._handle_response() # stores respone in self.Robotcoordinates
            self.Robotcoordinates = ast.literal_eval(self.Robotcoordinates) # Convert string to variable

            return self.Robotcoordinates # RobotCoordinates can be both string and a variable depending on when you check it.
    
    def Move(self, coordinates, orientation, normalized_vector):

        with self._mutex_function:  # Lock mutex for function-level thread safety

            """Move robot to specified coordinates and orientation"""
            with self._mutex_variable:
                self.MugCoordinates = list(coordinates)
                self.MugOrientation = list(orientation)
                self.MugNormal = list(normalized_vector)
            self._send_message("Move")
            self._handle_response()  # Wait for "AskNext"


            return

    def PickUpSequence(self, coordinates, orientation):
        with self._mutex_function:
            self._send_message("Pick_Up_Sequence")
            self.MugCoordinates = coordinates
            self.MugOrientation = orientation
            self._handle_response()

            #"""Perform pick-up sequence"""
            return None

    def LeaveSequence(self, coordinates, orientation):
        with self._mutex_function:
            self._send_message("Leave_Sequence")
            self.MugCoordinates = coordinates
            self.MugOrientation = orientation
            self._handle_response()

            #"""Perform leave sequence"""
            return None
    
    def OpenGripper(self):
        with self._mutex_function:
            self._send_message("Release")
            self._handle_response()
            return None
    
    def CloseGripper(self):
        with self._mutex_function:
            self._send_message("Grip")
            self._handle_response()
            return None
    
    def MoveCalibrationPosition(self, position):
        with self._mutex_function:
            self._send_message("Move_Calibration_Position")
            with self._mutex_variable:
                self.CalPoint = list(position) # make defensive copy
            self._handle_response()
            return None
    
    def MoveHome(self):
        with self._mutex_function:
            self._send_message("Home")
            self._handle_response()
            return None
    
    def ConnectionTest(self):
        with self._mutex_function:
            self._send_message("Connection_test")
            self._handle_response()
            return None
        

    def _start_watchdog(self):
        if self._watchdog_thread and self._watchdog_thread.is_alive():
            return
        self._watchdog_stop.clear()
        self._watchdog_thread = threading.Thread(target=self._watchdog_loop, daemon=True)
        self._watchdog_thread.start()
    
    def _stop_watchdog(self):
        self._watchdog_stop.set()
        if self._watchdog_thread:
            self._watchdog_thread.join(timeout=1)

    def _watchdog_loop(self):
        while not self._watchdog_stop.is_set():
            for _ in range(self._watchdog_interval):
                if self._watchdog_stop.is_set():
                    return
                time.sleep(1)
            if not self.connected:
                continue
            # Acquire function mutex to avoid overlap with active commands
            if self._mutex_function.acquire(blocking=False):
                try:
                    self._send_message("Connection_test")
                    # Optional: read and discard expected response
                    # self._handle_response()  # Uncomment if protocol expects AskNext
                finally:
                    self._mutex_function.release()
# ...existing code...


