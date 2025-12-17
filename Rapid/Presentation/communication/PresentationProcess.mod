MODULE PresentationProcess
  
    PROC Presentation()
        
        VAR mug_vector hand_over_pose;
        VAR mug_vector buffer;
        
        ! === PICK UP MUG ===
        buffer := GetRobVector();
        
        ! if mug standing up
        IF abs(buffer.normal.z) < abs(buffer.normal.x) AND abs(buffer.normal.z) < abs(buffer.normal.y) THEN
            TPWrite "mug z value: " \Num:=buffer.normal.z;
            IF buffer.position.z < min_z_value THEN
                buffer.position.z := min_z_value;
            ENDIF
        ENDIF
        
        ! mug to far to the right
        IF buffer.position.y < -100 THEN
            
            shared_movement_right.mug := buffer; 
            shared_movement_right.flag := flag_presentation_fetch;
            
            ! go to position and change orientation
            
            TPWrite "go to pose + offset";
            shared_movement_right.wait_flag := TRUE;
            WaitUntil shared_movement_right.wait_flag = FALSE;
            AskNext;
            
            ! wait for gripper
            shared_movement_right.wait_flag := TRUE;
            WaitUntil shared_movement_right.wait_flag = FALSE;
            AskNext;
            
            ! wait to move close
            TPWrite "go to pose";
            shared_movement_right.wait_flag := TRUE;
            WaitUntil shared_movement_right.wait_flag = FALSE;
            AskNext;
            
            ! wait for gripper
            shared_movement_right.wait_flag := TRUE;
            WaitUntil shared_movement_right.wait_flag = FALSE;
            AskNext;
            
            ! wait to move away
            TPWrite "go to pose + offset";
            shared_movement_right.wait_flag := TRUE;
            WaitUntil shared_movement_right.wait_flag = FALSE;
            AskNext;
            
        ELSE
            shared_movement_left.mug := buffer; 
            shared_movement_left.flag := flag_presentation_fetch;
            
            ! go to position and change orientation
            shared_movement_left.wait_flag := TRUE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            
            ! wait for gripper
            shared_movement_left.wait_flag := TRUE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            
            ! wait to move close
            shared_movement_left.wait_flag := TRUE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            
            ! wait for gripper
            shared_movement_left.wait_flag := TRUE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            
            ! wait to move away
            shared_movement_left.wait_flag := TRUE;
            
            ! ============= HAND OVER SEQUENCE =================
            
          ! assumes left is holding the mug in right orient
            
            WaitUntil shared_movement_right.wait_flag = FALSE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            
            ! init all variables
            hand_over_pose := [GetHandOverPos(),[0,0,-1]];
            
            TPWrite "hand over pos:" \Pos:= hand_over_pose.position;
            
            shared_movement_left.hand_over_pose := hand_over_pose;
            shared_movement_right.hand_over_pose := hand_over_pose;
            
            shared_movement_left.flag := flag_hand_over;
            shared_movement_right.flag := flag_hand_over;
            
            shared_movement_left.wait_flag := TRUE;
            shared_movement_right.wait_flag := TRUE;
            
            TPWrite "left and right arm move to pos";
            
            ! wait until left and right arm is in right pose
            WaitUntil shared_movement_right.wait_flag = FALSE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            
            TPWrite "move right arm closer and close gripper";
            ! let right arm keep on going 
            shared_movement_right.wait_flag := TRUE;
            
            ! wait until right hand hold mug
            WaitUntil shared_movement_right.wait_flag = FALSE;
            AskNext;
            
            TPWrite "left arm release and move back";
            ! let left hand release and go back
            shared_movement_left.wait_flag := TRUE;
            
            ! wait until left hand moves back
            WaitUntil shared_movement_left.wait_flag = FALSE;
            AskNext;
            TPWrite "right arm move back";
            
            ! let right hand move back
            shared_movement_right.wait_flag := TRUE;
        
            
        ENDIF
      
        TPWrite "Start leave process";
           
        ! === LEAVE MUG ===
        
        shared_movement_right.flag := flag_move_home_target;
        shared_movement_right.wait_flag := TRUE;
        
        WaitUntil shared_movement_right.wait_flag = FALSE;
        AskNext;
        
        TPWrite "Go home";
        shared_movement_right.flag := flag_presentation_leave;
        shared_movement_right.wait_flag := TRUE;
        
        ! go to leave pose + offset
        WaitUntil shared_movement_right.wait_flag = FALSE;
        AskNext;
        shared_movement_right.wait_flag := TRUE;
        
        ! go to leave pose
        WaitUntil shared_movement_right.wait_flag = FALSE;
        AskNext;
        shared_movement_right.wait_flag := TRUE;
        
        ! go to leave pose + offset
        WaitUntil shared_movement_right.wait_flag = FALSE;
        AskNext;
        shared_movement_right.wait_flag := TRUE;
        
        
        WaitUntil shared_movement_right.wait_flag = FALSE;
        AskNext;
        
        ! go home
        shared_movement_right.wait_flag := TRUE;
        WaitUntil shared_movement_right.wait_flag = FALSE;
        
        shared_movement_right.wait_flag := TRUE;
        shared_movement_right.flag := flag_move_home_target;
        AskNext;
        
    ENDPROC
    
    PROC AskNext()
        VAR string message;

        SocketSend client_socket\Str:="Next_step";
        SocketReceive client_socket \Str:=message;
        
    ERROR
     IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
            ! socket never send annything, close connection and return to main
            RETURN ;
     ENDIF
    ENDPROC
ENDMODULE