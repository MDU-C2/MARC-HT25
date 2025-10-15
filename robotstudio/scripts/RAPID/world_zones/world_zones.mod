MODULE world_zones
        
    VAR wztemporary floor;
    VAR shapedata floor_mech;
    CONST pos corner1:=[-600,-600,100]; 
    CONST pos corner2:=[600,600,-400];
    
    
    PROC init_world_zones()

        !CREATE FLOOR WORLD ZONE
        WZBoxDef \Inside, floor_mech, corner1, corner2; ! floor box
        WZDOSet \Temp, floor \Inside, floor_mech, HIT_FLOOR_OUT,1 ;
         
    ENDPROC

ENDMODULE