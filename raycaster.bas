REM Simple Raycaster 
REM Based on https://lodev.org/cgtutor/raycasting.html
REM Computation done with 16 bits fixed point arithmetics 

OPTION EXPLICIT ON
OPTION TYPE NARROW
OPTION READ FAST
OPTION TYPE UNSIGNED

DEFINE FONT STANDARD
DEGREE

GLOBAL vblast_address, vblast_data
DIM vblast_address AS ADDRESS
DIM vblast_bin AS BUFFER
vblast_bin := LOAD("raycaster_v2.bin")
vblast_address = VARPTR(vblast_bin)



REM GLOBAL CONSTANTS
GLOBAL CONST map_width = 32
GLOBAL CONST map_height = 24

GLOBAL CONST screen_width = 128
GLOBAL CONST screen_height = 200

GLOBAL CONST move_speed = 128
GLOBAL CONST rot_speed = 359

GLOBAL CONST max_dist = 2048
GLOBAL CONST max_div_4096 = 384


REM GLOBAL VARIABLES
GLOBAL world_map, table_1, table_2, colors, default_color, table_dist, table_div_4096


DIM table_dist(max_dist) AS BYTE
DIM table_div_4096(max_div_4096) AS WORD
DIM world_map(24*32) AS BYTE = # { _
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,1,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,0,1, _
  1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1,0,1,0,2,0,1,0,1, _
  1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,2,0,1,0,1, _
  1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1,0,1,0,2,0,1,0,1, _
  1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,2,5,1,0,1, _
  1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1,0,1,0,2,0,1,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,2,2,1,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,2,2,1,2,2,2,1, _
  1,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,0,3,3,3,1, _
  1,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1, _
  1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,1,1,1,1, _
  1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,1, _
  1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,1,1,0,1, _
  1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,3,3,3,3,0,1,0,0,0,0,0,1,0,1, _
  1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,3,0,0,0,0,1,0,0,1,0,0,1,0,1, _
  1,4,0,4,4,4,4,4,4,0,0,2,2,2,2,2,2,0,3,0,3,0,0,0,0,0,1,0,0,1,0,1, _
  1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,3,0,0,1,0,0,1,0,1,1,0,1, _
  1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,3,0,3,0,0,1,0,0,1,0,0,0,0,1, _
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1  _
} READONLY


GLOBAL line_height_array, color_array
DIM line_height_array(screen_width) AS BYTE
DIM color_array(screen_width) AS BYTE

DIM colors(5) AS BYTE = # { _
 1, 2, 3, 4, 5  _
} READONLY

DIM default_color=YELLOW

REM end of data

REM global vars
GLOBAL pos_x, pos_y, dir_x, dir_y, plane_x, plane_y, map_x, map_y, angle
GLOBAL dir_x0, dir_y0, plane_x0, plane_y0
DIM pos_x AS WORD = 18 * 256
DIM pos_y AS WORD = 12 * 256
DIM dir_x0 AS INT = -256
DIM dir_y0 AS INT = 0
DIM dir_x AS INT = -256
DIM dir_y AS INT = 0
DIM plane_x0 AS INT = 0
DIM plane_y0 AS INT = -128
DIM plane_x AS INT = 0
DIM plane_y AS INT = -128
DIM map_x AS BYTE
DIM map_y AS BYTE
DIM map_z AS WORD
DIM angle AS INT = 0

PROCEDURE event_handler
	DIM new_pos_x, new_pos_y, old_dir_x, old_dir_y, old_plane_x AS INT
	DIM new_map_x, new_map_y AS BYTE
	DIM compute_dir AS BYTE = FALSE
	DIM key AS STRING
	DIM map_pos AS WORD
	
	key = "S"
	IF key = "A" OR key="a" THEN
		IF world_map(map_pos) = 0 THEN
			ADD pos_x, -move_speed
		ENDIF
	ENDIF
	IF key = "Q" OR key="q" THEN
		IF world_map(map_pos) = 0 THEN
			ADD pos_x, move_speed
		ENDIF
	ENDIF
	IF key = "S" OR key="s" THEN
		angle = angle + rot_speed
		angle = angle MOD 360
		compute_dir = TRUE
	ENDIF
	IF key = "D" OR key="d" THEN
		angle = angle - rot_speed
		angle = angle MOD 360
		compute_dir = TRUE
	ENDIF
	
	IF compute_dir = TRUE THEN
		dir_x = ((FLOAT)dir_x0) * COS(angle) - ((FLOAT)dir_y0) * SIN(angle)
		dir_y = ((FLOAT)dir_x0) * SIN(angle) + ((FLOAT)dir_y0) * COS(angle)
		plane_x = ((FLOAT)plane_x0) * COS(angle) - ((FLOAT)plane_y0) * SIN(angle)
		plane_y = ((FLOAT)plane_x0) * SIN(angle) + ((FLOAT)plane_y0) * COS(angle)	
	ENDIF
	  
END PROCEDURE

PROCEDURE raycaster
	

	DIM ray_dir_x, ray_dir_y, delta_dir_x, delta_dir_y  AS INT
	DIM ray_dir_x0, ray_dir_y0 AS INT
	DIM delta_dist_x AS WORD
	DIM delta_dist_y AS WORD
	DIM perp_wall_dist AS WORD
	DIM side_dist_x AS WORD
	DIM side_dist_y AS WORD
	DIM map_pointer, map_pointer_0 AS WORD
	DIM temp_int AS INT
	DIM temp_word AS WORD

	DIM camera_x AS BYTE
	DIM map_X0, map_Y0 AS BYTE
	DIM v1,v2 AS BYTE
	DIM v3 AS WORD
	DIM side AS BYTE = 0
	DIM draw_start AS BYTE
	DIM draw_end AS BYTE
	DIM line_height AS BYTE
	DIM map_item AS BYTE
	DIM color AS BYTE = 0
	DIM step_x, step_y AS WORD

	REM calculate ray position and direction
	
	REM map_x0 = pos_x \ 256
	REM BIG ENDIAN
	map_X0 = PEEK(VARPTR(pos_x))
	
	REM map_y0 = pos_y \ 256
	REM BIG ENDIAN
	map_Y0 = PEEK(VARPTR(pos_y))
	
	map_pointer_0 = VARPTR(world_map) + map_X0+((WORD)map_Y0)**32
	
	delta_dir_x = 0
	delta_dir_y = 0
	ray_dir_x0 = dir_x - plane_x
	ray_dir_y0 = dir_y - plane_y
	
	REM x - coordinate in camera space
	FOR camera_x=0 TO 127
		ray_dir_x = ray_dir_x0 + (delta_dir_x \ 64)
		ray_dir_y = ray_dir_y0 + (delta_dir_y \ 64)
			
		IF ray_dir_x <> 0 THEN
		    REM length of ray from current position to next x or y-side
		    REM calculate step and initial sideDist
			REM  8 bits poids faible de pos_x
			v3 = PEEK(VARPTR(pos_x))
			IF ray_dir_x < 0 THEN
		    	step_x = $FFFF
		    ELSE
		        step_x = $0001
		        v3 = $0100 - v3
		    ENDIF
			v1 = v3 \ 16
		    delta_dist_x = table_div_4096(ABS(ray_dir_x))
			temp_int = delta_dist_x \ 16
			v2 = temp_int
			side_dist_x = v1 * v2
		ELSE
		    delta_dist_x = 0
			side_dist_x = 65535
		ENDIF
			
		IF ray_dir_y <> 0 THEN
		    REM length of ray from current position to next x or y-side
			REM  8 bits poids faible de pos_y
			v3 = PEEK(VARPTR(pos_y))
			IF ray_dir_y < 0 THEN
			    step_y = $FFE0
		    ELSE
		        step_y = $0020
		        v3 = $0100 - v3
			ENDIF
			v1 = v3 \ 16
		    delta_dist_y = table_div_4096(ABS(ray_dir_y))
			temp_int = delta_dist_y \ 16
			v2 = temp_int
			side_dist_y = v1 * v2
		ELSE
		    delta_dist_y = 0
			side_dist_y = 65535
		ENDIF
		
	    REM perform DDA
	    map_pointer = map_pointer_0
	    map_x = map_X0
	    map_y = map_Y0
	    WHILE PEEK(map_pointer) = 0
	    	REM jump to next map square, either in x-direction, or in y-direction
	    	IF side_dist_x < side_dist_y THEN
	        	ADD side_dist_x, delta_dist_x
	        	ADD map_pointer, step_x
	    	    side=0				
	        ELSE
	            ADD side_dist_y, delta_dist_y
	        	ADD map_pointer, step_y
	            side=8
	        ENDIF
	    WEND
	
	
	    REM Calculate distance projected on camera direction (Euclidean distance would give fisheye effect)
	    IF side = 0 THEN
	    	perp_wall_dist = side_dist_x - delta_dist_x
	    ELSE
	        perp_wall_dist = side_dist_y - delta_dist_y
	    ENDIF
	            
	    REM choose wall color
	    REM ColorRGB color;
	    REM map_item = PEEK(map_pointer)
	    map_item = PEEK(map_pointer)
	    
	    IF map_item < 5 THEN
	        color = colors(map_item) + side
	    ELSE
	        color = default_color + side
	    ENDIF
		    
	    line_height_array(camera_x) = table_dist(perp_wall_dist)
	    color_array(camera_x) = color

	
		ADD delta_dir_x, plane_x
		ADD delta_dir_y, plane_y
	
	NEXT
		
END PROCEDURE

PROCEDURE render_view_v1
	DIM middle, line_height, color, draw_start, draw_end, screen_x, x AS BYTE
	middle = screen_height \ 2

    screen_x = (160 - screen_width) 
	FOR x = 0 TO screen_width-1
		line_height = line_height_array(x)
		color = color_array(x)
	    REM draw the pixels of the stripe as a vertical line
	    IF line_height >= middle THEN
		    LINE screen_x, 0 TO screen_x, screen_height-1, color
	    ELSE
		    draw_start = middle - line_height
		    draw_end = middle + line_height - 1
		    LINE screen_x, 0 TO screen_x, draw_start-1, BLUE
		    LINE TO screen_x, draw_end, color
		    LINE TO screen_x, screen_height-1, BROWN
		ENDIF
		INC screen_x
	NEXT
END PROCEDURE

PROCEDURE render_view_v2
	
	DIM middle, line_height1, line_height2, color1, color2, draw_start1, draw_start2, draw_end1, draw_end2, x, y, ram_a, ram_b AS BYTE
	DIM sky_height, one_pix_height, two_pix_height AS BYTE
	DIM segment_sky, segment_floor, segment_one_pix_sky, segment_one_pix_floor, segment_two_pix AS BYTE
	DIM bitmap_address AS ADDRESS
	DIM ram_s AS BYTE
	DIM color1_hi, color2_hi, sky_hi, floor_hi AS BYTE

	middle = screen_height \ 2
	sky_hi = BLUE ** 16
	floor_hi = BROWN ** 16
	segment_sky = sky_hi + BLUE
	segment_floor = floor_hi + BROWN

	ram_a = PEEK($E7C3) OR $01
	ram_b = PEEK($E7C3) AND $FE
	ram_s = 0

	FOR x = 0 TO screen_width-1 STEP 2
		bitmap_address = $4008 + x \ 4
		
		IF ram_s = 0 THEN
			POKE $E7C3, ram_a
			ram_s = 1
		ELSE
			POKE $E7C3, ram_b
			ram_s = 0
		ENDIF
		
		line_height1 = line_height_array(x)
		color1 = color_array(x) ** 16
		line_height2 = line_height_array(x+1)
		color2 = color_array(x+1)
	    
	    IF line_height1 > line_height2 THEN
			sky_height = middle - line_height1
			one_pix_height = line_height1 - line_height2
			two_pix_height = line_height2 ** 2
			segment_one_pix_sky = color1 + BLUE
			segment_one_pix_floor = color1 + BROWN
	    ELSE
			sky_height = middle - line_height2
			one_pix_height = line_height2 - line_height1
			two_pix_height = line_height1 ** 2
			segment_one_pix_sky = sky_hi + color2
			segment_one_pix_floor = floor_hi + color2
	    ENDIF
	    segment_two_pix = color1 + color2

	    FOR address=1 TO sky_height
	    	POKE bitmap_address, segment_sky
	    	ADD bitmap_address, 40
	    NEXT
	    FOR y=1 TO one_pix_height
	    	POKE bitmap_address, segment_one_pix_sky
	    	ADD bitmap_address, 40
	    NEXT
	    FOR y=1 TO two_pix_height
	    	POKE bitmap_address, segment_two_pix
	    	ADD bitmap_address, 40
	    NEXT
	    FOR y=1 TO one_pix_height
	    	POKE bitmap_address, segment_one_pix_floor
	    	ADD bitmap_address, 40
	    NEXT
	    FOR y=1 TO sky_height
	    	POKE bitmap_address, segment_floor
	    	ADD bitmap_address, 40
	    NEXT	    
	NEXT

END PROCEDURE

PROCEDURE render_view_v3
	DIM vblast_target AS WORD

	DIM middle, line_height1, line_height2, color1, color2, draw_start1, draw_start2, draw_end1, draw_end2, x, y, ram_a, ram_b AS BYTE
	DIM sky_height, one_pix_height, two_pix_height AS BYTE
	DIM segment_sky, segment_floor, segment_one_pix_sky, segment_one_pix_floor, segment_two_pix AS BYTE
	DIM ram_s AS BYTE
	DIM color1_hi, color2_hi, sky_hi, floor_hi AS BYTE

	middle = screen_height \ 2
	sky_hi = BLUE ** 16
	floor_hi = BROWN ** 16
	POKE VARPTR(segment_sky), sky_hi + BLUE
	POKE VARPTR(segment_floor), floor_hi + BROWN

	ram_a = PEEK($E7C3) OR $01
	ram_b = PEEK($E7C3) AND $FE
	ram_s = 0

	FOR x = 0 TO screen_width-1 STEP 2
		POKEW VARPTR(vblast_target), $4008 + x \ 4
		
		IF ram_s = 0 THEN
			POKE $E7C3, ram_a
			ram_s = 1
		ELSE
			POKE $E7C3, ram_b
			ram_s = 0
		ENDIF
		
		line_height1 = line_height_array(x)
		color1 = color_array(x) ** 16
		line_height2 = line_height_array(x+1)
		color2 = color_array(x+1)
		
	    IF line_height1 > line_height2 THEN
	    	POKE VARPTR(sky_height), middle - line_height1
			POKE VARPTR(one_pix_height), line_height1 - line_height2
			POKE VARPTR(two_pix_height), line_height2 ** 2
			POKE VARPTR(segment_one_pix_sky), color1 + BLUE
			POKE VARPTR(segment_one_pix_floor), color1 + BROWN
	    ELSE
	    	POKE VARPTR(sky_height), middle - line_height2
			POKE VARPTR(one_pix_height), line_height2 - line_height1
			POKE VARPTR(two_pix_height), line_height1 ** 2
			POKE VARPTR(segment_one_pix_sky), sky_hi + color2
			POKE VARPTR(segment_one_pix_floor), floor_hi + color2
	    ENDIF

	    segment_two_pix = color1 + color2

		SYS vblast_address WITH REG(X)=PEEKW(VARPTR(vblast_target)), REG(B)=PEEK(VARPTR(sky_height)), REG(A)=PEEK(VARPTR(segment_sky))
		POKEW VARPTR(vblast_target), PEEKW(VARPTR(vblast_target))+40*PEEK(VARPTR(sky_height))
		
		SYS vblast_address WITH REG(X)=PEEKW(VARPTR(vblast_target)), REG(B)=PEEK(VARPTR(one_pix_height)), REG(A)=PEEK(VARPTR(segment_one_pix_sky))
		POKEW VARPTR(vblast_target), PEEKW(VARPTR(vblast_target))+40*PEEK(VARPTR(one_pix_height))
		
		SYS vblast_address WITH REG(X)=PEEKW(VARPTR(vblast_target)), REG(B)=PEEK(VARPTR(two_pix_height)), REG(A)=PEEK(VARPTR(segment_two_pix))
		POKEW VARPTR(vblast_target), PEEKW(VARPTR(vblast_target))+40*PEEK(VARPTR(two_pix_height))
		
		SYS vblast_address WITH REG(X)=PEEKW(VARPTR(vblast_target)), REG(B)=PEEK(VARPTR(one_pix_height)), REG(A)=PEEK(VARPTR(segment_one_pix_floor))
		POKEW VARPTR(vblast_target), PEEKW(VARPTR(vblast_target))+40*PEEK(VARPTR(one_pix_height))
		
		SYS vblast_address WITH REG(X)=PEEKW(VARPTR(vblast_target)), REG(B)=PEEK(VARPTR(sky_height)), REG(A)=PEEK(VARPTR(segment_floor))
	    
	NEXT

END PROCEDURE

PROCEDURE render_view_v4
	DIM vblast_target AS WORD

	POKEW VARPTR(vblast_target), $4008
	SYS vblast_address WITH REG(X)=VARPTR(line_height_array), _
	                        REG(Y)=VARPTR(color_array), _
	                        REG(U)=PEEKW(VARPTR(vblast_target))
END PROCEDURE




PROCEDURE render_map
	DIM x,y AS BYTE 
	DIM ptr AS WORD
	
	ptr = VARPTR(world_map)
	FOR y = 0 TO map_height-1
		FOR x = 0 TO map_width-1
			PLOT x, y**2, PEEK(ptr)
			PLOT x, y**2+1, PEEK(ptr)
			INC ptr
		NEXT
	NEXT
	PLOT PEEK(VARPTR(pos_x)),PEEK(VARPTR(pos_y))**2, BLUE
	PLOT PEEK(VARPTR(pos_x)),PEEK(VARPTR(pos_y))**2+1, BLUE
END PROCEDURE

PROCEDURE build_table_dist
	DIM dist, line_height AS WORD
	table_dist(0) = screen_height \ 2
	FOR dist = 1 TO max_dist-1
		line_height = screen_height
		line_height = line_height ** 16
		line_height = line_height / dist
		
		IF line_height > 100 THEN
            line_height = 100
		ENDIF
		table_dist(dist) = (BYTE)line_height
	NEXT
	PRINT "TA"
END PROCEDURE

PROCEDURE build_table_div_4096
	DIM i, res AS WORD
	table_div_4096(0) = 65535
	FOR i = 1 TO max_div_4096-1
		res = 4096
		res = res / i
		table_div_4096(i) = res
	NEXT
	PRINT "TB"
END PROCEDURE

REM Init
BITMAP ENABLE (160,200,16)
CLS
PRINT "Init"
build_table_dist[]
build_table_div_4096[]

render_map[]
raycaster[]

DIM go AS STRING
PRINT "GO "
INPUT go
DIM i AS INT
FOR i=1 TO 1000
	render_view_v4[]
	PLOT 0,0, i MOD 16
NEXT

PRINT "END"
