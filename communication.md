## PYTHON FUNCTIONS

- GetPosition
    - Sends **Get_Coordinates** to RAPID
    - Returns (x,y,z) of the robots position

- Move (coordinates, orientation, normalized_vector)
    - Sends **Move** to the RAPID, the function is able to utilize coordinates, quaternion (orientation) and normalized vector.

- PickUpSequence (coordinates, orientation)
    - Sends **"Pick_Up_Sequence"** to RAPID and utilizes coordinates and orientation.

- LeaveSequence(coordinates, orientation)
    - Sends **"Leave_Sequence"** to RAPID

- OpenGripper
    - Sends **Release** to RAPID

- CloseGripper
    - Sends **Grip** to RAPID

- MoveCalibrationPosition (position)
    - Sends **Move_Calibration_Position** to RAPID

- MoveHome
    - Sends **Home** to RAPID

- ConnectionTest
    - Sends **Connection_test** to RAPID

## PYTHON MESSAGES THAT ARE ACCEPTED

- ACKS
    - **Ack_succesful**
    - **Ack_wait**
    - **Ack_Release done**
    - **Ack_succesfull**
    - **ACK**
    - **Ack_Coordinate**
    - **Ack_Orientation**
    - **Ack_normal**

- CLOSE
    - **Disconnect**

- ROBOT WANTS TO SEND COORDINATE
    - **Robot_Wants_To_Send_Coordinates**

- ROBOT WANTS TO SEND ORIENTATION
    - **Robot_Wants_To_Send_Orientation**

- ASK MUG COORDINATES
    - **Ask_MugCoordinate**
    - **Ask_Coordinate**

- ASK MUG ORIENTATION
    - **Ask_MugOrientation**
    - **Ask_Orientation**

- ASK MUG NORMAL
    - **Ask_MugNormal**

- ASK NEXT (RAPID is ready for next command)
    - **AskNext**
    - **Connection_Confirmed**
    - **Ack_Grip_Done**
    - **Ack_Release done**

- ASK CAL POINT
    - **AskCalPoint**

## RAPID FUNCTIONS (CASE)

- CASE "Connection_test"
    - Returns **Connection_Confirmed**

- CASE "Coordinates"
    - Returns **[Hand frame]_ack**

- CASE "Get_Coordinates"
    - Returns **Robot_Wants_To_Send_Coordinates**, **[x,y,z]** and **AskNext**

- CASE "Move"
    - Returns **Ask_Coordinate**, **Ack_Coordinate**, **Ask_Orientation**, **Ack_Orientation**, **AskNext**

- CASE "Grip"
    - Returns **Ack_wait**, **Ack_Grip_Done**

- CASE "Release"
    - Returns **AskNext**, **Ack_Realease done**

- CASE "Home"
    - Returns **Ack_Release done**

- CASE "Pick_Up_Sequence"
    - **Not implemented**

- CASE "Leave_Sequence"
    - **Not implemented**

- CASE "Move_Calibration_Position"
    - Returns **AskCalPoint** (Not fully implemented)

    
## RAPID MESSAGES

- CONFIRM
    - **Connection_Confirmed**

- ASK
    - **AskCalPoint**
    - **Ask_Next**
    - **Ask_Coordinate**
    - **Ask_Orientation**
    - **Ask_amount_of_cups**
    - **Ask_Wait**
    - **AskNext**
- ACKS
    - **Ack_stop**
    - **Ack_amount_of_cups**
    - **Ack_cup_current_position**
    - **Ack_cup_end_position**
    - **Ack_wait**
    - **Ack_Grip_Done**
    - **Ack_release done**
    - **Ack_succesfull** <--- felstavat
    - **[Hand frame]_ack**

- SEND
    - **Robot_Wants_To_Send_Coordinates**
    - **[x,y,z]**

- ERROR
    - **[ERROR]can't reach that possition,try again**
    - **[ERROR]_wrong_format,try_again(exampel[x,y,z])**
    - **[ERROR]not a number,try again**
    - **[ERROR]can't reach current frame,try again**
    - **[ERROR]can't reach end frame,try again**
    - **[ERROR]not a number,try again**
    - **[ERROR] enter yes or no,try again**

- DEFAULT
    - **default_[message]**