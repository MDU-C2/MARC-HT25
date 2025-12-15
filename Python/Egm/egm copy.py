import egm_pb2 as egm
import socket
import time
import numpy as np

egm_ip= "127.0.0.1" #For simulation in robotstudio
egm_port=6510
num=0


def CreateSensorMessage(egmSensor, pos, euler):
    headerOne=egmSensor.header
    headerOne.seqno=num
    headerOne.mtype=egm.EgmHeader.MessageType.MSGTYPE_CORRECTION
    
    #to change the position and/or orientation of the robot, change values of input vectors
    planned=egmSensor.planned
    pose=planned.cartesian
    Position=pose.pos

    Position.x=pos[0]
    Position.y=pos[1]
    Position.z=pos[2]
    planned.cartesian.euler.x=euler[0]
    planned.cartesian.euler.y=euler[1]
    planned.cartesian.euler.z=euler[2]
    return egmSensor

def send_pos_egm(egm_ip, egm_port, positions):
    print("Running EGM python client")
    robot_socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    print(f"Listening on {egm_ip}:{egm_port}")
    robot_socket.bind((egm_ip, egm_port))
    robot_socket.settimeout(2)
    
    # while robot_socket.fileno() != -1:
    try:
        data, addr = robot_socket.recvfrom(1024)
    except TimeoutError:
        print("NO MSG RECIEVED")

    m = egm.EgmRobot()
    #print("message:", m)
    m.ParseFromString(data)
    # print("parsed message:", m)
    #positions[0] = m.feedBack.cartesian.pos.x
    #positions[1] = m.feedBack.cartesian.pos.y + 5
    #positions[2] = m.feedBack.cartesian.pos.z

    CurX = m.feedBack.cartesian.euler.x
    CurY = m.feedBack.cartesian.euler.y
    CurZ = m.feedBack.cartesian.euler.z
    euler = [CurX,CurY,CurZ]
    egmSensor=egm.EgmSensor()
    egmSensor=CreateSensorMessage(egmSensor,positions,euler)
    msg=egmSensor.SerializeToString()
    robot_socket.sendto(msg, addr)
    time.sleep(0.004)

delta = 5

pos1 = [400,-200,190]
pos2 = [200,0,190]
pos3 = [300,300,190]

time.sleep(1)   

for i in range(40):
    pos = [pos1[0]-i*5, pos1[1]-i*5, pos1[2]]
    send_pos_egm(egm_ip, egm_port, pos)
    time.sleep(0.1)
time.sleep(1)
for i in range(40):
    pos = [pos2[0]+i*2.5, pos2[1]+i*7.5, pos2[2]]
    send_pos_egm(egm_ip, egm_port, pos)
    time.sleep(0.1)


time.sleep(1)
pos = [405,-200,190]
send_pos_egm(egm_ip, egm_port, pos)