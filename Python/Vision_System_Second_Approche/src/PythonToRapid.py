"""
Robot Communication Module - REFACTORED
Handles ALL robot operations:
- Connection management
- Cup queue with 'sent' flag tracking
- Background threading
- Dynamic message handling (event-driven)
Compatible with dynamic RAPID server
"""

import socket
import time
import threading
from typing import List, Dict, Optional, Callable


class RobotCommunication:
    def __init__(self, host='127.0.0.1', port=1025):
        """
        Initialize robot communication with full cup management
        
        Args:
            host: Robot IP address (default: '127.0.0.1') for virtual controller
            should be replaced when start operating
            port: Communication port (default: 1025)
        """
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        
        # Cup queue management
        self.cups = []
        self.cups_lock = threading.Lock()
        
        # Robot thread
        self.robot_thread = None
        self.robot_busy = False
        self.should_stop = False
        
        # Status tracking
        self.total_cups_sent = 0
        
        # Default release position
        self.release_position = [600, 100, 200]  # [x, y, z] in mm
        
        # Message handlers (dynamic dispatch)
        self.message_handlers = {
            'Ask_next': self._handle_ask_next,
            'Ask_amount_of_cups': self._handle_ask_amount_of_cups,
            'Ack_amount_of_cups': self._handle_ack_amount_of_cups,
            'Ack_cup_current_position': self._handle_ack_cup_current_position,
            'Ask_Coordinate': self._handle_ask_coordinate,
            'Ack_Coordinate': self._handle_ack_coordinate,
            'Ask_Orientation': self._handle_ask_orientation,
            'Ack_Orientation': self._handle_ack_orientation,
            'Ack_cup_end_position': self._handle_ack_cup_end_position,
            'Ask_Wait': self._handle_ask_wait,
            'Ack_stop': self._handle_ack_stop,
            'Connection_Confirmed': self._handle_connection_confirmed,
        }
        
        # State machine
        self.current_cup = None
        self.current_state = 'idle'
        self.waiting_for = None
        
        print(f"[ROBOT] Communication module initialized")
        print(f"[ROBOT] Target: {host}:{port}")
        print(f"[ROBOT] Default release position: {self.release_position}")

    def set_release_position(self, x, y, z):
        """Set the release position for all cups"""
        self.release_position = [x, y, z]
        print(f"[ROBOT] Release position updated: {self.release_position}")

    def add_cups(self, cups_data: List[Dict]):
        """
        Add detected cups to queue
        
        Args:
            cups_data: List of cup dictionaries with position, orientation
        """
        with self.cups_lock:
            for cup in cups_data:
                # Check if cup already exists
                exists = False
                for existing_cup in self.cups:
                    if existing_cup['cup_number'] == cup['cup_number']:
                        # Update position if not sent
                        if not existing_cup.get('sent', False):
                            existing_cup['position'] = cup['position']
                            existing_cup['orientation'] = cup['orientation']
                        exists = True
                        break
                
                if not exists:
                    # Add new cup
                    cup['sent'] = False
                    self.cups.append(cup)

    def get_unsent_cups(self) -> List[Dict]:
        """Get list of unsent cups"""
        with self.cups_lock:
            return [cup for cup in self.cups if not cup.get('sent', False)]

    def mark_cup_sent(self, cup_number: int):
        """Mark a cup as sent"""
        with self.cups_lock:
            for cup in self.cups:
                if cup['cup_number'] == cup_number:
                    cup['sent'] = True
                    self.total_cups_sent += 1
                    print(f"[ROBOT] Cup {cup_number} marked as sent")
                    break

    def get_status(self) -> Dict:
        """Get current status"""
        with self.cups_lock:
            num_cups = len(self.cups)
            num_unsent = sum(1 for cup in self.cups if not cup.get('sent', False))
        
        return {
            'connected': self.connected,
            'busy': self.robot_busy,
            'host': self.host,
            'port': self.port,
            'total_cups': num_cups,
            'unsent_cups': num_unsent,
            'cups_sent': self.total_cups_sent,
            'release_position': self.release_position,
            'state': self.current_state
        }

    # ==================== CONNECTION ====================
    
    def connect(self) -> bool:
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

    def disconnect(self):
        """Close connection"""
        if self.socket:
            try:
                self.socket.close()
                self.connected = False
                print("[ROBOT] ✓ Disconnected")
            except:
                pass

    # ==================== MESSAGE I/O ====================
    
    def send_message(self, message: str):
        """Send message to RAPID"""
        if not self.connected:
            print("[ROBOT] ✗ Not connected!")
            return False

        try:
            self.socket.send(message.encode())
            print(f"[ROBOT] → {message}")
            time.sleep(0.1)
            return True
        except Exception as e:
            print(f"[ROBOT] ✗ Send error: {e}")
            self.connected = False
            return False

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

    # ==================== DYNAMIC MESSAGE HANDLING ====================
    
    def handle_message(self, message: str) -> bool:
        """
        Dynamic message handler - dispatches to appropriate handler
        
        Args:
            message: Received message
            
        Returns:
            bool: True if handled successfully
        """
        if message in self.message_handlers:
            return self.message_handlers[message]()
        else:
            print(f"[ROBOT] ⚠ Unknown message: {message}")
            return True  # Continue anyway

    # ==================== MESSAGE HANDLERS ====================
    
    def _handle_connection_confirmed(self) -> bool:
        """Handle Connection_Confirmed"""
        print("[ROBOT] ✓ Connection confirmed")
        self.current_state = 'connected'
        return True

    def _handle_ask_next(self) -> bool:
        """Handle Ask_next - ready for next command"""
        self.current_state = 'ready'
        return True

    def _handle_ask_amount_of_cups(self) -> bool:
        """Handle Ask_amount_of_cups"""
        unsent = self.get_unsent_cups()
        
        if len(unsent) > 0:
            self.send_message("1")  # Send one cup at a time
            self.current_cup = unsent[0]
            self.current_state = 'sending_amount'
        else:
            self.send_message("0")  # No more cups
            self.current_state = 'no_cups'
        
        return True

    def _handle_ack_amount_of_cups(self) -> bool:
        """Handle Ack_amount_of_cups"""
        self.current_state = 'amount_confirmed'
        return True

    def _handle_ack_cup_current_position(self) -> bool:
        """Handle Ack_cup_current_position - ready to send pickup position"""
        self.current_state = 'sending_pickup'
        self.waiting_for = 'Ask_Coordinate'
        return True

    def _handle_ask_coordinate(self) -> bool:
        """Handle Ask_Coordinate - send coordinate"""
        if self.current_state == 'sending_pickup':
            # Send pickup position
            pos = self.current_cup['position']
            coord_str = f"[{pos['x']},{pos['y']},{pos['z']}]"
            self.send_message(coord_str)
            self.waiting_for = 'Ack_Coordinate'
            
        elif self.current_state == 'sending_release':
            # Send release position
            release_str = f"[{self.release_position[0]},{self.release_position[1]},{self.release_position[2]}]"
            self.send_message(release_str)
            self.waiting_for = 'Ack_Coordinate'
        
        return True

    def _handle_ack_coordinate(self) -> bool:
        """Handle Ack_Coordinate - coordinate received"""
        self.waiting_for = 'Ask_Orientation'
        return True

    def _handle_ask_orientation(self) -> bool:
        """Handle Ask_Orientation - send orientation"""
        ori = self.current_cup['orientation']
        orient_str = f"[{ori['x']},{ori['y']},{ori['z']}]"
        self.send_message(orient_str)
        self.waiting_for = 'Ack_Orientation'
        return True

    def _handle_ack_orientation(self) -> bool:
        """Handle Ack_Orientation - orientation received"""
        if self.current_state == 'sending_pickup':
            print("[ROBOT] ✓ Pickup position sent")
            self.current_state = 'pickup_sent'
        elif self.current_state == 'sending_release':
            print("[ROBOT] ✓ Release position sent")
            self.current_state = 'release_sent'
        return True

    def _handle_ack_cup_end_position(self) -> bool:
        """Handle Ack_cup_end_position - ready to send release position"""
        self.current_state = 'sending_release'
        self.waiting_for = 'Ask_Coordinate'
        return True

    def _handle_ask_wait(self) -> bool:
        """Handle Ask_Wait - robot is moving"""
        print("[ROBOT] ⏳ Robot is moving...")
        self.current_state = 'robot_moving'
        return True

    def _handle_ack_stop(self) -> bool:
        """Handle Ack_stop - session complete"""
        print("[ROBOT] ✓ Session complete")
        self.current_state = 'session_complete'
        return False  # Stop loop

    # ==================== SESSION MANAGEMENT ====================
    
    def start_session(self) -> bool:
        """Start robot session"""
        if not self.connected:
            print("[ROBOT] ✗ Cannot start session - not connected")
            return False
        
        print(f"\n[ROBOT] ====================================")
        print(f"[ROBOT] Starting session...")
        print(f"[ROBOT] ====================================")
        
        # Send connection test
        self.send_message("Connection_test")
        
        # Receive and handle response
        response = self.receive_message()
        if not response:
            return False
        
        self.handle_message(response)
        
        # Wait for Ask_next
        response = self.receive_message()
        if response:
            self.handle_message(response)
        
        # Announce cups available
        self.send_message("Cups_available")
        
        print("[ROBOT] ✓ Session started")
        return True

    def run_session_loop(self):
        """Main session loop - handles messages dynamically"""
        while self.connected and not self.should_stop:
            # Check for unsent cups
            unsent = self.get_unsent_cups()
            
            if len(unsent) == 0:
                time.sleep(0.5)
                continue
            
            # Receive message
            message = self.receive_message()
            
            if not message:
                break
            
            # Handle message dynamically
            continue_loop = self.handle_message(message)
            
            if not continue_loop:
                break
            
            # Check if cup was successfully sent
            if self.current_state == 'robot_moving':
                # Wait for completion
                response = self.receive_message()
                if response:
                    self.handle_message(response)
                    
                    # Mark cup as sent
                    if self.current_cup:
                        self.mark_cup_sent(self.current_cup['cup_number'])
                        self.current_cup = None
                    
                    self.current_state = 'ready'

    # ==================== THREADING ====================
    
    def robot_communication_thread(self):
        """Background thread for robot communication"""
        try:
            # Connect
            if not self.connect():
                print("[ROBOT] ✗ Connection failed")
                self.robot_busy = False
                return
            
            # Start session
            if not self.start_session():
                print("[ROBOT] ✗ Session start failed")
                self.disconnect()
                self.robot_busy = False
                return
            
            print("[ROBOT] ✓ Connected and ready")
            
            # Run session loop
            self.run_session_loop()
            
        except Exception as e:
            print(f"[ROBOT] ✗ Thread error: {e}")
            import traceback
            traceback.print_exc()
        
        finally:
            self.disconnect()
            self.robot_busy = False
            print("[ROBOT] ✓ Thread stopped")

    def start_robot_thread(self):
        """Start robot communication in background thread"""
        if self.robot_busy or self.connected:
            return False
        
        unsent = self.get_unsent_cups()
        if len(unsent) == 0:
            return False
        
        print(f"\n[ROBOT] Starting robot thread...")
        
        self.robot_busy = True
        self.should_stop = False
        self.robot_thread = threading.Thread(target=self.robot_communication_thread, daemon=True)
        self.robot_thread.start()
        
        return True

    def stop_robot_thread(self):
        """Stop robot thread gracefully"""
        self.should_stop = True
        if self.robot_thread and self.robot_thread.is_alive():
            self.robot_thread.join(timeout=2.0)
        self.disconnect()

    def is_busy(self) -> bool:
        """Check if robot is busy"""
        return self.robot_busy

    def is_connected(self) -> bool:
        """Check if connected to robot"""
        return self.connected