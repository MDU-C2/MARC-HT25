import egm_pb2 as egm
import socket
import time
import numpy as np

egm_ip= "127.0.0.1" #For simulation in robotstudio
egm_port=6510
num=0

# robot_socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
# robot_socket.bind((egm_ip, egm_port))
# print("TEST")
# robot_socket.settimeout(30)



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

# def send_planned_configuration(egmSensor, joint_list):
#     headerOne=egmSensor.header
#     headerOne.seqno=num
#     headerOne.mtype=egm.EgmHeader.MessageType.MSGTYPE_CORRECTION
    
#     #to change the position and/or orientation of the robot, change values of input vectors
#     planned=egmSensor.planned
#     #pose=planned.cartesian
#     #joints = planned.joints

#     conf_as_list = np.asarray(joint_list).tolist()
#     joints_vals = conf_as_list[:6]
#     external_joints = conf_as_list[6:]

#     planned.joints.joints.extend(joints_vals)
#     if len(external_joints) > 0:
#         planned.externalJoints.joints.extend(external_joints)

#     return egmSensor


# print(f"Listening on {egm_ip}:{egm_port}")
# Pos=[600,13,136] #[x,y,z] chords 
# for i in range(500):

#     time.sleep(0.004)
#     data, addr = robot_socket.recvfrom(1024)

#     m = egm.EgmRobot()
#     m.ParseFromString(data)
#     print("Recieved:",m)
#     i += 1
#     num+=1
#     # Pos[1] = 13 + i
#     Pos[0] = m.feedBack.cartesian.pos.x
#     Pos[1] = m.feedBack.cartesian.pos.y + 5
#     Pos[2] = m.feedBack.cartesian.pos.z

#     CurX = m.feedBack.cartesian.euler.x
#     CurY = m.feedBack.cartesian.euler.y
#     CurZ = m.feedBack.cartesian.euler.z
#     euler = [CurX,CurY,CurZ]
#     egmSensor=egm.EgmSensor()
#     egmSensor=CreateSensorMessage(egmSensor,Pos,euler)
#     msg=egmSensor.SerializeToString()
#     # print(egmSensor)
#     # print(msg)
#     robot_socket.sendto(msg, addr) 
#     time.sleep(0.004)

def send_pos_egm(egm_ip, egm_port, positions):
    print("Running EGM python client")
    robot_socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    print(f"Listening on {egm_ip}:{egm_port}")
    robot_socket.bind((egm_ip, egm_port))
    robot_socket.settimeout(30)
    
    while robot_socket.fileno() != -1:
        try:
            data, addr = robot_socket.recvfrom(1024)
        except TimeoutError:
            print("NO MSG RECIEVED")
            continue

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

        
pos = [600,13,136]
send_pos_egm(egm_ip, egm_port, pos)