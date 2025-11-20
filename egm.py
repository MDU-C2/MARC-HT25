import egm_pb2 as egm
import socket
import time
import numpy as np

#computer_ip = '192.168.125.50' or whatever IP address is #For use on physical controller (need static IP on a local network
robot_ip= "127.0.0.1" #For simulation in robotstudio
robot_port=6510
num=0

#Sets up a client to receive UDP messages
robot_socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

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

    Position.x=pos[0]
    Position.y=pos[1]
    Position.z=pos[2]
    
    planned.cartesian.euler.x=quat[0]
    planned.cartesian.euler.y=quat[1]
    planned.cartesian.euler.z=quat[2]

    
    return egmSensor

def send_planned_configuration(egmSensor, joint_list):
    headerOne=egmSensor.header
    headerOne.seqno=num
    headerOne.mtype=egm.EgmHeader.MessageType.MSGTYPE_CORRECTION
    
    #to change the position and/or orientation of the robot, change values of input vectors
    planned=egmSensor.planned
    #pose=planned.cartesian
    #joints = planned.joints

    conf_as_list = np.asarray(joint_list).tolist()
    joints_vals = conf_as_list[:6]
    external_joints = conf_as_list[6:]

    planned.joints.joints.extend(joints_vals)
    if len(external_joints) > 0:
        planned.externalJoints.joints.extend(external_joints)

    return egmSensor


print(f"Listening on {robot_ip}:{robot_port}")
# data, addr = robot_socket.recvfrom(1024)  # Buffer size is 1024 bytes

# print(f"Received message from {addr}")

# #Reads-in and deserializes the protocol buffer message from controller
# message=egm.EgmRobot()
# message.ParseFromString(data)

# #print(message)
# Seq=message.header.seqno
# Time=message.header.tm
# CurX=message.feedBack.cartesian.pos.x
# CurY=message.feedBack.cartesian.pos.y
# CurZ=message.feedBack.cartesian.pos.z
# CurOw=message.feedBack.cartesian.orient.u0
# CurOx=message.feedBack.cartesian.orient.u1
# CurOy=message.feedBack.cartesian.orient.u2
# CurOZ=message.feedBack.cartesian.orient.u3
# print(f"SeqNum={Seq}, Time={Time}, X={CurX}, Y={CurY}, Z={CurZ},OW={CurOw}, OX={CurOx},OY={CurOy}, OZ={CurOZ}")


Pos=[600,13,136] #[x,y,z] chords
Quat=[100,100,0] #[q0,q1,q2,q3] quaternion 

for i in range(500):

    time.sleep(0.004)
    data, addr = robot_socket.recvfrom(1024)

    m = egm.EgmRobot()
    m.ParseFromString(data)
    print("Recieved:",m)
    i += 1
    num+=1
    # Pos[1] = 13 + i
    Pos[0] = m.feedBack.cartesian.pos.x
    Pos[1] = m.feedBack.cartesian.pos.y + 5
    Pos[2] = m.feedBack.cartesian.pos.z

    CurX = m.feedBack.cartesian.euler.x
    CurY = m.feedBack.cartesian.euler.y
    CurZ = m.feedBack.cartesian.euler.z
    euler = [CurX,CurY,CurZ]
    egmSensor=egm.EgmSensor()
    egmSensor=CreateSensorMessage(egmSensor,Pos,euler)
    msg=egmSensor.SerializeToString()
    # print(egmSensor)
    # print(msg)
    robot_socket.sendto(msg, addr) 
    time.sleep(0.004)


# robot_socket.setblocking(False)
# time.sleep(0.1)
# data, addr = robot_socket.recvfrom(1024)
# # robot_socket.close()
# m = egm.EgmRobot()
# m.ParseFromString(data)

# cur_joints = m.feedBack.joints.joints
# robot_socket.setblocking(True)

# for i in range(1000):

#     i += 1
#     num += 1
#     cur_joints[0] += 0.1

#     egmSensor=egm.EgmSensor()
#     egmSensor=send_planned_configuration(egmSensor,cur_joints)
#     msg=egmSensor.SerializeToString()
#     print(egmSensor)
#     # msg2=egm.EgmSensor()
#     # msg2.ParseFromString(msg)
#     # print(msg2)
#     robot_socket.sendto(msg, (robot_ip, robot_port))  
#     time.sleep(0.01)    