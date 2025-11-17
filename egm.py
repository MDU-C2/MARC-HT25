import egm_pb2 as egm
import socket
import time

#computer_ip = '192.168.125.50' or whatever IP address is #For use on physical controller (need static IP on a local network)
robot_ip= "127.0.0.1" #For simulation in robotstudio
robot_port=6510
num=0

#Sets up a client to receive UDP messages
robot_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

#Binds the client to listen on your IP and port (same as specified in Controller-Configuration-
robot_socket.bind((robot_ip, robot_port))
print("TEST")
robot_socket.settimeout(5)

def CreateSensorMessage(egmSensor, pos, quat):
    headerOne=egmSensor.header
    headerOne.seqno=num
    headerOne.mtype=egm.EgmHeader.MessageType.MSGTYPE_CORRECTION
    
    #to change the position and/or orientation of the robot, change values of input vectors
    planned=egmSensor.planned
    pose=planned.cartesian #ändra denna?
    Position=pose.pos
    Quaternion=pose.orient
    Position.x=pos[0]
    Position.y=pos[1]
    Position.z=pos[2]
    
    Quaternion.u0=quat[0]
    Quaternion.u1=quat[1]
    Quaternion.u2=quat[2]
    Quaternion.u3=quat[3]
    
    return egmSensor



print(f"Listening on {robot_ip}:{robot_port}")
data, addr = robot_socket.recvfrom(1024)  # Buffer size is 1024 bytes

print(f"Received message from {addr}")

#Reads-in and deserializes the protocol buffer message from controller
message=egm.EgmRobot()
message.ParseFromString(data)

#print(message)
Seq=message.header.seqno
Time=message.header.tm
CurX=message.feedBack.cartesian.pos.x
CurY=message.feedBack.cartesian.pos.y
CurZ=message.feedBack.cartesian.pos.z
CurOw=message.feedBack.cartesian.orient.u0
CurOx=message.feedBack.cartesian.orient.u1
CurOy=message.feedBack.cartesian.orient.u2
CurOZ=message.feedBack.cartesian.orient.u3
print(f"SeqNum={Seq}, Time={Time}, X={CurX}, Y={CurY}, Z={CurZ},OW={CurOw}, OX={CurOx},OY={CurOy}, OZ={CurOZ}")


Pos=[600,13,136] #[x,y,z] chords
Quat=[1,0,0,0] #[q0,q1,q2,q3] quaternion      
for i in range(500):
    data, addr = robot_socket.recvfrom(1024)
    m = egm.EgmRobot()
    m.ParseFromString(data)
    i += 1
    # Pos[1] = 13 + i
    Pos[1] = m.feedBack.cartesian.pos.y + 1

    CurW = m.feedBack.cartesian.orient.u0
    CurX = m.feedBack.cartesian.orient.u1
    CurY = m.feedBack.cartesian.orient.u2
    CurZ = m.feedBack.cartesian.orient.u3
    Quat = [CurW,CurX,CurY,CurZ]
    egmSensor=egm.EgmSensor()
    egmSensor=CreateSensorMessage(egmSensor,Pos,Quat)
    msg=egmSensor.SerializeToString()
    # print(egmSensor)
    # print(msg)
    robot_socket.sendto(msg, (robot_ip, robot_port))  
    time.sleep(0.004)