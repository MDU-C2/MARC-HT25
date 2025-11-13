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
# robot_socket.bind((computer_ip, robot_port))


def CreateSensorMessage(egmSensor, pos, quat):
    headerOne=egmSensor.header
    headerOne.seqno=num
    headerOne.mtype=egm.EgmHeader.MessageType.MSGTYPE_CORRECTION
    
    #to change the position and/or orientation of the robot, change values of input vectors
    planned=egmSensor.planned
    pose=planned.cartesian
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

Pos=[600,13,136] #[x,y,z] chords
Quat=[1,0,0,0] #[q0,q1,q2,q3] quaternion

for i in range(500):
    i += 1
    Pos[1] = 13 + i
    Quat = [1,0,0,0]
    egmSensor=egm.EgmSensor()
    egmSensor=CreateSensorMessage(egmSensor,Pos,Quat)
    mess=egmSensor.SerializeToString()
    #print(egmSensor)
    print(mess)
    robot_socket.sendto(mess, (robot_ip, robot_port))  
    time.sleep(0.004)