MODULE simulated_communication
    
    RECORD mug_vector
        pos position;
        pos normal;
    ENDRECORD
    
    !flag values:
    ! -1 = stop program
    ! 1 = hand over
    ! 2 = fetch
    ! 3 = drop off
    ! 4 = go home
    RECORD shared_information
      num right_flag;  
      num left_flag;
      mug_vector hand_over_pose;
      mug_vector mug;
      bool right_in_process;
      bool left_in_process;
    ENDRECORD
    
    PERS shared_information multi_move;
    CONST speeddata movespeed:= v200;    CONST robtarget fetch_mup_target:=[[355.37,130.65,50.38],[0.0303038,0.909324,-0.409024,0.0700746],[-1,2,-2,4],[132.67,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget leave_mup_target:=[[355.37,-130.65,50.38],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST mug_vector mug:=[[400,10.65,-50.38],[0,0,1]];
   
    
    PROC main()
    multi_move.left_flag := 0;
    multi_move.right_flag := 0;
    
    WaitTime(5); ! untill mug is registerd

    ! ==== FETCH ====
    multi_move.mug := mug; 
    multi_move.left_flag := 2; ! left hand fect mug
    multi_move.left_in_process := TRUE;
    
    ! ==== TEMP ====
    WaitUntil multi_move.left_in_process = FALSE;
    multi_move.hand_over_pose := [[300,0,200],[0,0,-1]];
    multi_move.left_flag := 1;
    multi_move.right_flag := 1;
    multi_move.left_in_process := TRUE;
    multi_move.right_in_process := TRUE;
    
    ! ==== LEAVE ====
    WaitUntil multi_move.left_in_process = FALSE;
    WaitUntil multi_move.right_in_process = FALSE;
    multi_move.right_flag := 3; ! right hand leavemug
    multi_move.left_flag := 4; ! left hand go home
    multi_move.mug.position := leave_mup_target.trans; 
    multi_move.left_in_process := TRUE;
    multi_move.right_in_process := TRUE;
    
    ! ==== GO HOME ====
    WaitUntil multi_move.left_in_process = FALSE;
    WaitUntil multi_move.right_in_process = FALSE;
    multi_move.right_flag := 4; ! right hand go home
    multi_move.mug.position := leave_mup_target.trans; 
    multi_move.right_in_process := TRUE;
    
    ! ==== STOP PROGRAM ====
    WaitUntil multi_move.right_in_process = FALSE;
    multi_move.left_flag := -1;
    multi_move.right_flag := -1;
    multi_move.left_in_process := TRUE;
    multi_move.right_in_process := TRUE;
    
    
    ENDPROC
        
ENDMODULE