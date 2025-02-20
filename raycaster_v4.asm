; =============================================
; Raycasting ultra optimisé TO8/TO9 
; Version: 1.1
; Date: 2025-01-21 15:57
; Auteur: tmattern
; =============================================

; Constantes
VIDEO_MEM     EQU  $0000     ; Adresse mémoire vidéo (RAMA $0000-$1FFF)
RAMB_BASE     EQU  $2000     ; Adresse RAMB ($2000-$3FFF)
SCREEN_W      EQU  160       ; Largeur en mode 160x200
SCREEN_H      EQU  200       ; Hauteur écran
SCREEN_SIZE   EQU  8000      ; 160x200/4 car chaque banque contient la moitié des pixels
MAP_W         EQU  32        ; Largeur map
MAP_H         EQU  24        ; Hauteur map
CENTER_Y      EQU  100       ; Centre vertical écran
RENDER_W      EQU  128       ; Largeur de la fenêtre de rendu
RENDER_X      EQU  32        ; Position X du début du rendu (160-128=32)
CENTER_X      EQU  64        ; Centre horizontal de la fenêtre de rendu (128/2)
RAY_POS_X0    EQU  18*256+63 ; Position initiale joueur X
RAY_POS_Y0    EQU  9*256+63  ; Position initiale joueur Y
RAY_DIR_X0    EQU  -128
RAY_DIR_Y0    EQU  0
RAY_PLANE_X0  EQU  0
RAY_PLANE_Y0  EQU  -63

; Constantes pour la mini-map
MAP_DISP_W  EQU  32     ; Largeur en pixels de la mini-map
MAP_DISP_H  EQU  48     ; Hauteur en pixels de la mini-map (24*2)

        ORG  $A000
        LBRA  START     ; Saut vers le code principal

; --------------- MAP 32x24 ---------------
        ALIGN 256
MAP     
        FCB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        FCB     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,1,2,1,7,6,5,4,3,2,1,7,6,5,4,3,2,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,1,5,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        FCB     1,0,0,1,6,6,7,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1
        FCB     1,0,0,1,1,6,5,4,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,1
        FCB     1,0,0,1,1,7,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1
        FCB     1,0,0,1,1,5,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,1,1,1
        FCB     1,0,0,1,1,5,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,1,5,4,4,4,4,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,1,5,4,4,4,4,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,1,5,5,5,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1
        FCB     1,0,0,0,1,1,1,0,0,0,0,0,3,3,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1
        FCB     1,0,0,0,1,1,1,0,0,0,0,0,3,3,0,0,0,1,1,1,1,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1
        FCB     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; --------------- VARIABLES ---------------
        ALIGN 256
; Variables page directe (avec DP=$A4)
RAY_pos_x     RMB     2       ; Fixed point 8.8
RAY_pos_y     RMB     2       ; Fixed point 8.8
RAY_dir_x     RMB     2       ; Direction vector
RAY_dir_y     RMB     2
RAY_plane_x   RMB     2       ; Camera plane
RAY_plane_y   RMB     2
RAY_ray_x     RMB     2       ; Current ray direction
RAY_ray_y     RMB     2
RAY_ray_x0    RMB     2
RAY_ray_y0    RMB     2
RAY_plane_x_step RMB  2
RAY_plane_y_step RMB  2
RAY_ray_x_delta RMB   2
RAY_ray_y_delta RMB   2
RAY_ddist_x   RMB     2       ; Delta distance
RAY_ddist_y   RMB     2
RAY_sdist_x   RMB     2       ; Side distance
RAY_sdist_y   RMB     2
RAY_step_x    RMB     1       ; Step values ($FF or $01)
RAY_step_y    RMB     1       ; Step values ($E0 or $20)
RAY_cam_x     RMB     1       ; Screen x coordinate
RAY_side      RMB     1       ; Wall side hit (0=NS, 1=EW)
RAY_color     RMB     1       ; Current wall color
RAY_line_h    RMB     1       ; Line height for current ray
RAY_perp_dist RMB     2       ; Perpendicular wall distance
RAY_tmp       RMB     2
RAY_tmp2      RMB     2
RAY_map_pointer RMB   2

DC_COLOR      RMB     1      ; Couleur de la colonne (0-15)
DC_POS        RMB     1      ; Position dans le groupe de 4 pixels
DC_PIX_VAL    RMB     1      ; Valeur de l'octet à écrire (masque + couleur)
DC_PIX_MSK    RMB     1      ; Masque pour préserver les autres pixels
DC_END_ADR    RMB     2      ; Adresse de fin selon RAMA/RAMB


; Tables et buffers 
OFFS_8        RMB     8      ; Table offsets 8 pixels



; --------------- CODE PRINCIPAL ---------------
START   
        ; Init système
        ORCC #$50       ; Désactive interruptions
        
        ; Configure DP=$A4
        LDA  #$A4       ; Correct car les variables sont en $A4xx
        TFR  A,DP
        
        ; Init mode vidéo
        JSR  VIDEO_INIT
        
        JSR  INIT       ; Initialisation
        JSR  DRAW_MINIMAP
        
MAIN_LOOP
        JSR  RAYCAST_FRAME
        BRA  MAIN_LOOP

; Initialisation 
INIT    
        ; Init tables
        JSR  INIT_SCREEN_OFFS
        JSR  INIT_RAYCAST
        JSR  INIT_MAP_POINTER
        RTS

; Initialize ray casting
INIT_RAYCAST    
        ; Load initial position
        LDD     #RAY_POS_X0   ; Starting X
        STD     <RAY_pos_x
        LDD     #RAY_POS_Y0   ; Starting Y  
        STD     <RAY_pos_y

        ; Initial direction
        LDD     #RAY_DIR_X0
        STD     <RAY_dir_x
        LDD     #RAY_DIR_Y0
        STD     <RAY_dir_y

        ; Initial plane (0,-0.25)
        LDD     #RAY_PLANE_Y0
        STD     <RAY_plane_x
        LDD     #RAY_PLANE_Y0
        STD     <RAY_plane_y
        RTS

; Init table offsets écran
INIT_SCREEN_OFFS
        LDX  #SCREEN_OFFS
        LDD  #0
OFFS_LOOP
        STD  ,X++
        ADDD #80
        CMPX #SCREEN_OFFS+400
        BNE  OFFS_LOOP
        RTS

INIT_MAP_POINTER
	; map_pointer_0 = VARPTR(world_map) + map_X0+((WORD)map_Y0)**32
        LDA     <RAY_pos_y    ; High byte = map Y
        LDB     #32
        MUL
        ADDB    <RAY_pos_x
        ADCA    #0
        ADDD    #MAP
        STD     <RAY_map_pointer
        RTS

; Boucle raycasting principale
RAYCAST_FRAME
	; map_pointer_0 = VARPTR(world_map) + map_X0+((WORD)map_Y0)**32
	; delta_dir_x = 0
	; delta_dir_y = 0
	; plane_x_step = plane_x ** 4
	; plane_y_step = plane_y ** 4

        ; Calculate ray direction
        LDD     <RAY_dir_x
        SUBD    <RAY_plane_x
        STD     <RAY_ray_x0
        LDD     <RAY_dir_y
        SUBD    <RAY_plane_y
        STD     <RAY_ray_y0

        ; Calculate camera plane steps
	; plane_x_step = plane_x * 4
	; plane_y_step = plane_y * 4
        LDD     <RAY_plane_x
        LSLB
        ROLA
        LSLB
        ROLA
        STD     <RAY_plane_x_step
        LDD     <RAY_plane_y
        LSLB
        ROLA
        LSLB
        ROLA
        STD     <RAY_plane_y_step

        LDD     #0
	STD     <RAY_ray_x_delta
	STD     <RAY_ray_y_delta

        STA     <RAY_cam_x  ; Débute colonne 0
COL_LOOP
        ; Pour chaque colonne de la fenêtre de rendu
        JSR  CALC_RAY   ; Calcule direction rayon, et lance le rayon
        JSR  DRAW_COL   ; Dessine colonne

	LDD     <RAY_ray_x_delta
        ADDD    <RAY_plane_x_step
	STD     <RAY_ray_x_delta

	LDD     <RAY_ray_y_delta
        ADDD    <RAY_plane_y_step
	STD     <RAY_ray_y_delta

        INC  <RAY_cam_x  ; 128 colonnes
        BPL  COL_LOOP
        RTS

CALC_RAY
        ;delta_dir_x_h = PEEK(VARPTR(delta_dir_x))
        ;ray_dir_x = ray_dir_x0 + delta_dir_x_h
        LDX     <RAY_ray_x0
        LDB     <RAY_ray_x_delta
        LEAX    B,X
        STX     <RAY_ray_x

        ;REM length of ray from current position to next x or y-side
        ;v1 = pos_x
        ;IF ray_dir_x < 0 THEN
        ;        step_x = $FFFF
        ;        delta_dist_x = table_div_4096(-ray_dir_x)
        ;ELSE
        ;        step_x = $0001
        ;        v1 = 255 - v1
        ;        delta_dist_x = table_div_4096(ray_dir_x)
        ;ENDIF
        ; Calculate step and initial side dist
        BMI     CALC_RAY_NEG_X
        LDA     #$01          ; Step X positive
        STA     <RAY_step_x
        LDA     <RAY_pos_x+1  ; Low byte of pos
        COMA                  ; 255 - pos_x
        STA     <RAY_tmp

        TFR     X,D
        LSLB                  ; each table entry is 2 bytes
        ROLA
        LDX     #DIV_TABLE_4096
        LDX     D,X
        STX     <RAY_ddist_x
        BRA     CALC_RAY_CONT_X

CALC_RAY_NEG_X
        LDA     #$FF          ; Step X negative
        STA     <RAY_step_x
        LDA     <RAY_pos_x
        STA     <RAY_tmp

        TFR     X,D
        COMA                  ; -ray_dir_x
        COMB
        ADDD    #1

        LSLB                  ; each table entry is 2 bytes
        ROLA
        LDX     #DIV_TABLE_4096
        LDX     D,X
        STX     <RAY_ddist_x

CALC_RAY_CONT_X
        ; 16 bits * 8 bits
        ; side_dist_x = (delta_dist_x * v1) \ 256
        LDA     <RAY_tmp
        LDB     <RAY_ddist_x+1
        MUL
        STA     <RAY_tmp2
        LDA     <RAY_tmp
        LDB     <RAY_ddist_x
        MUL
        ADDB    <RAY_tmp2
        ADCA    #0
        STD     <RAY_sdist_x

CALC_RAY_Y
        ;delta_dir_y_h = PEEK(VARPTR(delta_dir_y))
        ;ray_dir_y = ray_dir_y0 + delta_dir_y_h
        LDX     <RAY_ray_y0
        LDB     <RAY_ray_y_delta
        LEAX    B,X
        STX     <RAY_ray_y

        ;REM length of ray from current position to next x or y-side
        ;v1 = pos_x
        ;IF ray_dir_x < 0 THEN
        ;        step_x = $FFFF
        ;        delta_dist_x = table_div_4096(-ray_dir_x)
        ;ELSE
        ;        step_x = $0001
        ;        v1 = 255 - v1
        ;        delta_dist_x = table_div_4096(ray_dir_x)
        ;ENDIF
        ; Calculate step and initial side dist
        BMI     CALC_RAY_NEG_Y
        LDA     #$20          ; Step Y positive
        STA     <RAY_step_y
        LDA     <RAY_pos_y+1  ; Low byte of pos
        COMA                  ; 255 - pos_y
        STA     <RAY_tmp

        TFR     X,D
        LSLB                  ; each table entry is 2 bytes
        ROLA
        LDX     #DIV_TABLE_4096
        LDX     D,X
        STX     <RAY_ddist_y
        BRA     CALC_RAY_CONT_Y

CALC_RAY_NEG_Y
        LDA     #$E0          ; Step Y negative
        STA     <RAY_step_y
        LDA     <RAY_pos_y
        STA     <RAY_tmp

        TFR     X,D
        COMA                  ; -ray_dir_y
        COMB
        ADDD    #1

        LSLB                  ; each table entry is 2 bytes
        ROLA
        LDX     #DIV_TABLE_4096
        LDX     D,X
        STX     <RAY_ddist_y

CALC_RAY_CONT_Y
        ; 16 bits * 8 bits
        ; side_dist_x = (delta_dist_x * v1) \ 256
        LDA     <RAY_tmp
        LDB     <RAY_ddist_y+1
        MUL
        STA     <RAY_tmp2
        LDA     <RAY_tmp
        LDB     <RAY_ddist_y
        MUL
        ADDB    <RAY_tmp2
        ADCA    #0
        STD     <RAY_sdist_y

; DDA Loop - U register holds current map pointer
        LDU     <RAY_map_pointer

RAY_DDALoop
        ; Compare side distances
        LDD     <RAY_sdist_x
        CMPD    <RAY_sdist_y
        BHS     RAY_StepY

        ; Step in X direction
        ADDD    <RAY_ddist_x
        STD     <RAY_sdist_x
        LDA     <RAY_step_x
        LEAU    A,U           ; Add X step directly to pointer
        LDA     ,U            ; Get map cell
        BEQ     RAY_DDALoop   ; Continue if empty
        LSLA
        STA     <RAY_color
        LDD     <RAY_sdist_x
        STD     <RAY_perp_dist ; Store perp dist from sdist_x
        CLR     <RAY_side     ; Hit NS wall
        BRA     RAY_HitWall

RAY_StepY
        LDD     <RAY_sdist_y
        ADDD    <RAY_ddist_y
        STD     <RAY_sdist_y
        LDA     <RAY_step_y
        LEAU    A,U           ; Add Y step directly to pointer
        LDA     ,U            ; Get map cell
        BEQ     RAY_DDALoop   ; Continue if empty
        LSLA
        INCA
        STA     <RAY_color
        LDD     <RAY_sdist_y
        STD     <RAY_perp_dist ; Store perp dist from sdist_y
        LDA     #1
        STA     <RAY_side     ; Hit EW wall

RAY_HitWall
        LDD     <RAY_perp_dist ; Store perp dist from sdist_y
        CMPD    #68
        BLO     RAY_HEIGHT_MAX
        CMPD    #4095
        BHI     RAY_HEIGHT_MIN

        ; we want an index between 68/4=17 and 4095/4=1023. 
        LSRA                   ; each table entry is 2 bytes.
        RORB                   ; index=(RAY_perp_dist/4)*2=RAY_perp_dist/2
        LDX     #DIV_TABLE_4096
        LDD     D,X
        BRA     RAY_SAVE_HEIGHT

RAY_HEIGHT_MIN
        LDB     #2
        BRA     RAY_SAVE_HEIGHT

RAY_HEIGHT_MAX
        LDB     #100

RAY_SAVE_HEIGHT
        STB  <RAY_line_h
        RTS

DRAW_COL
        ; Vérifie si on a une hauteur valide
        LDA  <RAY_line_h
        BNE  DC_START   ; Si RAY_line_h != 0, continue
        RTS             ; Sinon, sort immédiatement
DC_START
        ; 1. Calcule l'adresse de base de la colonne (X = RAY_cam_x + 32)
        LDA  <RAY_cam_x     ; 0-127
        ADDA #RENDER_X     ; +32 -> 32-159
        
        ; Calcule l'octet de base (X/4) et la position dans l'octet (X%4)
        PSHS A             ; Sauvegarde X pour calcul position
        LSRA              ; X/4 pour avoir l'octet
        LSRA
        LDX  #VIDEO_MEM
        LEAX A,X          ; Base + X/4
        
        ; Détermine RAMA/RAMB selon bit 1 de la position
        PULS A            ; Récupère X
        ANDA #3           ; Position 0-3
        PSHS A            ; Sauvegarde la position pour plus tard
        CMPA #2
        BLO  DC_RAMA      ; Si < 2, reste en RAMA

DC_RAMB
        LEAX RAMB_BASE,X   ; Passe en RAMB
        LDD  #VIDEO_MEM+RAMB_BASE+8000  ; Limite pour RAMB
        STD  <DC_END_ADR   
        PULS A            ; Récupère la position
        SUBA #2           ; Ramène à 0-1 pour position dans l'octet
        BRA  DC_SET_POS

DC_RAMA
        LDD  #VIDEO_MEM+8000            ; Limite pour RAMA
        STD  <DC_END_ADR
        PULS A            ; Récupère la position

DC_SET_POS
        ANDA #1            ; Test position dans l'octet
        BNE  DC_POS_LOW    ; Si 1 -> poids faible
        
DC_POS_HIGH               ; Position 0 ou 2 (poids fort)
        LDA  #$0F          ; Masque pour préserver poids faible
        STA  <DC_PIX_MSK   
        LDA  #11*16        ; Couleur du ciel en position haute
        BRA  DC_START_DRAW
        
DC_POS_LOW               ; Position 1 ou 3 (poids faible)
        LDA  #$F0          ; Masque pour préserver poids fort
        STA  <DC_PIX_MSK
        LDA  #11           ; Couleur du ciel en position basse

DC_START_DRAW
        STA  <DC_PIX_VAL   ; Sauvegarde la valeur initiale du pixel

        ; 3. Calcule les hauteurs
        LDA  <RAY_line_h      ; D'abord empiler la hauteur du mur
        PSHS A            ; car on la dépilera en dernier
        
        LDA  #SCREEN_H    ; Utilise la constante pour la hauteur totale
        SUBA <RAY_line_h      ; Soustrait la hauteur du mur
        LSRA             ; Division logique par 2 (pas arithmétique)
        PSHS A            ; Sauve hauteur ciel (sera dépilée en premier)

        ; 4. Dessine la colonne complète
        ; Ciel
        LDA  ,S+           ; Hauteur ciel
        BEQ  DC_WALL       ; Si pas de ciel, passe au mur

DC_SKY_LOOP
        LDB  ,X            ; Lit l'octet
        ANDB <DC_PIX_MSK   ; Masque
        ORB  <DC_PIX_VAL   ; Ajoute pixel
        STB  ,X            ; Écrit
        
        LEAX 40,X          ; Ligne suivante
        DECA               ; Hauteur--
        BNE  DC_SKY_LOOP

        ; Mur
DC_WALL
        LDA  ,S+           ; Hauteur mur
        BEQ  DC_FLOOR      ; Si pas de mur, passe au sol
        
        ; Prépare couleur mur (3)
        TST  <DC_PIX_MSK    ; Test si on est en poids fort
        BMI  DC_WALL_LOW    ; Si masque = $F0, position basse
        LDB  #3*16          ; Couleur en position haute
        BRA  DC_WALL_SET
DC_WALL_LOW
        LDB  #3            ; Couleur en position basse
DC_WALL_SET
        STB  <DC_PIX_VAL

DC_WALL_LOOP
        LDB  ,X            ; Lit l'octet
        ANDB <DC_PIX_MSK   ; Masque
        ORB  <DC_PIX_VAL   ; Ajoute pixel
        STB  ,X            ; Écrit
        
        LEAX 40,X          ; Ligne suivante
        DECA               ; Hauteur--
        BNE  DC_WALL_LOOP

        ; Sol (jusqu'en bas de l'écran)
DC_FLOOR
        ; Prépare couleur sol (6)
        TST  <DC_PIX_MSK    ; Test si on est en poids fort
        BMI  DC_FLOOR_LOW   ; Si masque = $F0, position basse
        LDB  #6*16         ; Couleur en position haute
        BRA  DC_FLOOR_SET
DC_FLOOR_LOW
        LDB  #6           ; Couleur en position basse
DC_FLOOR_SET
        STB  <DC_PIX_VAL

DC_FLOOR_LOOP
        CMPX <DC_END_ADR   ; Compare avec la bonne limite
        BHS  DC_END
        
        LDB  ,X            ; Lit l'octet
        ANDB <DC_PIX_MSK   ; Masque
        ORB  <DC_PIX_VAL   ; Ajoute pixel
        STB  ,X            ; Écrit
        
        LEAX 40,X          ; Ligne suivante
        BRA  DC_FLOOR_LOOP

DC_END
        RTS

; Routine d'affichage de la mini-map
DRAW_MINIMAP
        ; Pointeur vers début de la map
        LDX  #MAP
        ; Pointeur écran de base RAMA
        LDU  #VIDEO_MEM
        
        ; Pour chaque ligne de la map
        LDB  #MAP_H     ; 24 lignes
MM_LOOP
        PSHS B,U        ; Sauve compteur de lignes et pointeur base
        
        ; Pour chaque groupe de 4 pixels (2 octets: 1 RAMA + 1 RAMB)
        LDB  #8         ; 32 pixels = 8 groupes de 4 pixels
MM_COL
        PSHS B          ; Sauve compteur
        
        ; Prépare l'octet pour RAMA (pixels 0,1)
        LDA  ,X+        ; Premier pixel
        BEQ  MM_PIX0_EMPTY
        LDA  #$C0       ; Premier pixel blanc (4 bits de poids fort)
        BRA  MM_PIX0_SET
MM_PIX0_EMPTY
        LDA  #$00       ; Premier pixel noir
MM_PIX0_SET
        LDB  ,X+        ; Second pixel
        BEQ  MM_PIX1_EMPTY
        LDB  #$0C       ; Second pixel blanc (4 bits de poids faible)
        BRA  MM_PIX1_SET
MM_PIX1_EMPTY
        LDB  #$00       ; Second pixel noir
MM_PIX1_SET
        PSHS B         ; Sauve second pixel
        ORA  ,S+       ; Combine les deux pixels dans A
        STA  ,U        ; Écrit dans RAMA
        STA  40,U      ; Double ligne en RAMA
        
        ; Prépare l'octet pour RAMB (pixels 2,3)
        LDA  ,X+        ; Troisième pixel
        BEQ  MM_PIX2_EMPTY
        LDA  #$C0       ; Troisième pixel blanc
        BRA  MM_PIX2_SET
MM_PIX2_EMPTY
        LDA  #$00       ; Troisième pixel noir
MM_PIX2_SET
        LDB  ,X+        ; Quatrième pixel
        BEQ  MM_PIX3_EMPTY
        LDB  #$0C       ; Quatrième pixel blanc
        BRA  MM_PIX3_SET
MM_PIX3_EMPTY
        LDB  #$00       ; Quatrième pixel noir
MM_PIX3_SET
        PSHS B         ; Sauve quatrième pixel
        ORA  ,S+       ; Combine les pixels dans A
        
        ; Écrit dans RAMB
        PSHS U,A       ; Sauve pointeur et valeur
        TFR  U,D
        ADDD #RAMB_BASE-VIDEO_MEM
        TFR  D,U
        PULS A
        STA  ,U        ; Écrit dans RAMB
        STA  40,U      ; Double ligne en RAMB
        PULS U         ; Restaure pointeur RAMA
        
        ; Passe au prochain octet
        LEAU 1,U
        
        PULS B         ; Récupère compteur
        DECB           ; Décrémente compteur
        BNE  MM_COL    ; Continue si pas fini
        
        ; Passe à la ligne suivante
        PULS U,B       ; Récupère pointeur base et compteur lignes
        LEAU 80,U      ; Avance d'une ligne (80 octets)
        DECB           ; Ligne suivante
        BNE  MM_LOOP   ; Continue si pas fini
        
        ; Affiche position joueur
        JSR  DRAW_PLAYER
        RTS
    
; Routine pour afficher la position du joueur sur la mini-map
DRAW_PLAYER
        ; Calcul de la position écran du joueur
        ; U contiendra l'adresse de base
        LDU  #VIDEO_MEM
        
        ; Calcul offset Y (Y * 40 car 40 octets par ligne)
        LDA  <RAY_pos_y    ; En big-endian, la partie entière est dans le premier octet
        LDB  #80         ; 40 octets par ligne x 2
        MUL
        LEAU D,U        ; Ajoute à l'adresse de base
        
        ; Calcul offset X
        LDA  <RAY_pos_x    ; Position X
        LSRA            ; Divise par 4 car 4 pixels par octet
        LSRA
        LEAU A,U        ; Ajoute à l'adresse de base
        
        ; Détermine le pixel dans l'octet
        LDA  <RAY_pos_x    
        ANDA #3          ; Modulo 4 pour savoir quel pixel dans l'octet
        
        CMPA #2          ; Compare avec 2 pour savoir si RAMA ou RAMB
        BHS  MM_PLAYER_RAMB  ; Si >= 2, alors RAMB
        
        ; RAMA (pixels 0 et 1)
        CMPA #1          ; Test si pixel 0 ou 1
        BNE  MM_PLAYER_RAMA_HIGH
        
MM_PLAYER_RAMA_LOW     ; Pixel 1 (poids faible)
        LDA  ,U
        ANDA #$F0       ; Préserve poids fort
        ORA  #2         ; Indice 2 (rouge moyen) en poids faible
        STA  ,U
        LDA  40,U       ; 40 octets par ligne
        ANDA #$F0
        ORA  #2
        STA  40,U
        RTS

MM_PLAYER_RAMA_HIGH    ; Pixel 0 (poids fort)
        LDA  ,U
        ANDA #$0F       ; Préserve poids faible
        ORA  #$20       ; Indice 2 (rouge moyen) en poids fort
        STA  ,U
        LDA  40,U       ; 40 octets par ligne
        ANDA #$0F
        ORA  #$20
        STA  40,U
        RTS

MM_PLAYER_RAMB        ; RAMB (pixels 2 et 3)
        PSHS U         ; Sauve pointeur RAMA
        TFR  U,D
        ADDD #RAMB_BASE-VIDEO_MEM
        TFR  D,U       ; U pointe maintenant sur RAMB
        
        CMPA #3        ; Test si pixel 2 ou 3
        BEQ  MM_PLAYER_RAMB_LOW

MM_PLAYER_RAMB_HIGH   ; Pixel 2 (poids fort)
        LDA  ,U
        ANDA #$0F      ; Préserve poids faible
        ORA  #$20      ; Indice 2 (rouge moyen) en poids fort
        STA  ,U
        LDA  40,U      ; 40 octets par ligne
        ANDA #$0F
        ORA  #$20
        STA  40,U
        PULS U,PC

MM_PLAYER_RAMB_LOW    ; Pixel 3 (poids faible)
        LDA  ,U
        ANDA #$F0      ; Préserve poids fort
        ORA  #2        ; Indice 2 (rouge moyen) en poids faible
        STA  ,U
        LDA  40,U      ; 40 octets par ligne
        ANDA #$F0
        ORA  #2
        STA  40,U
        PULS U,PC
        
VIDEO_INIT
        ; Désactive les interruptions
        ORCC #$50       

        ; Map video RAM to $0000
        LDA  #%01100000  ; D7=0, D6=1 (écriture), D5=1 (RAM active), D4-D0=00000 (page 0)
        STA  $E7E6       ; Mappe la page 0 en $0000

        ; Passage en mode 160x200x16
        LDA  #%01111011  ; Mode bitmap 160x200 16 couleurs
        STA  $E7DC       ; Registre mode écran
        
        ; Configuration Gate Array
        LDA  #%00000000  ; Couleur tour ecran
        STA  $E7DD       ; Registre systeme 2
                
        ; Initialisation de la palette
        ; Écrit les 32 octets de la palette
        CLR  $E7DB      ; Position 0
        LDX  #PALETTE   ; Source
        LDB  #32        ; 32 octets à copier
VI_PAL_LOOP
        LDA  ,X+        ; Charge octet
        STA  $E7DA      ; Écrit dans la palette
        DECB
        BNE  VI_PAL_LOOP

        ; Nettoyage de l'écran - Version corrigée
        ; RAMA ($0000-$1FFF) - Contient les pixels pairs
        LDX  #VIDEO_MEM
        LDD  #0         ; Couleur noire
VI_CLEAR_RAMA
        STD  ,X++       ; Écrit 2 octets
        CMPX #VIDEO_MEM+SCREEN_SIZE
        BLO  VI_CLEAR_RAMA

        ; RAMB ($2000-$3FFF) - Contient les pixels impairs
        LDX  #VIDEO_MEM+RAMB_BASE
        LDD  #0         ; Couleur noire
VI_CLEAR_RAMB
        STD  ,X++       ; Écrit 2 octets
        CMPX #VIDEO_MEM+RAMB_BASE+SCREEN_SIZE
        BLO  VI_CLEAR_RAMB
        
        RTS

; --------------- DONNÉES ---------------
; Palette 16 couleurs pour le raycasting
        ALIGN 256
PALETTE
        ; Format: 16 mots de 2 octets (GR,B)
        ; Premier octet - GR: Bits 7-4: Vert, Bits 3-0: Rouge
        ; Second octet - B: Bits 3-0: Bleu (bits 7-4 ignorés)
        FDB  $0000      ; 0: Noir
        FDB  $0400      ; 1: Rouge foncé pour murs lointains (V=0,R=4)
        FDB  $0600      ; 2: Rouge moyen (V=0,R=6)
        FDB  $0800      ; 3: Rouge vif pour murs proches (V=0,R=8)
        FDB  $0A00      ; 4: Rouge très vif (V=0,R=A)
        FDB  $3000      ; 5: Vert foncé pour sol lointain (V=3,R=0)
        FDB  $5000      ; 6: Vert moyen pour sol (V=5,R=0)
        FDB  $7000      ; 7: Vert clair pour sol proche (V=7,R=0)
        FDB  $2202      ; 8: Gris très foncé pour plafond (V=2,R=2)
        FDB  $4404      ; 9: Gris foncé pour plafond (V=4,R=4)
        FDB  $6606      ; 10: Gris moyen pour plafond (V=6,R=6)
        FDB  $8808      ; 11: Gris clair pour plafond (V=8,R=8)
        FDB  $FF0F      ; 12: Blanc (V=F,R=F)
        FDB  $0F00      ; 13: Rouge clair UI (V=0,R=F)
        FDB  $F000      ; 14: Vert clair UI (V=F,R=0)
        FDB  $FF0F      ; 15: Blanc brillant UI (V=F,R=F)

; Table des offsets écran
        ALIGN 256
SCREEN_OFFS
        RMB  400
; --------------- TABLES ---------------
; Division table for 4096 divided by integers from 0 to 1023
; Precomputed values
DIV_TABLE_4096
        FDB     4096    ; 4096 / 0
        FDB     4096    ; 4096 / 1
        FDB     2048    ; 4096 / 2
        FDB     1365    ; 4096 / 3
        FDB     1024    ; 4096 / 4
        FDB     819    ; 4096 / 5
        FDB     682    ; 4096 / 6
        FDB     585    ; 4096 / 7
        FDB     512    ; 4096 / 8
        FDB     455    ; 4096 / 9
        FDB     409    ; 4096 / 10
        FDB     372    ; 4096 / 11
        FDB     341    ; 4096 / 12
        FDB     315    ; 4096 / 13
        FDB     292    ; 4096 / 14
        FDB     273    ; 4096 / 15
        FDB     256    ; 4096 / 16
        FDB     240    ; 4096 / 17
        FDB     227    ; 4096 / 18
        FDB     215    ; 4096 / 19
        FDB     204    ; 4096 / 20
        FDB     195    ; 4096 / 21
        FDB     186    ; 4096 / 22
        FDB     178    ; 4096 / 23
        FDB     170    ; 4096 / 24
        FDB     163    ; 4096 / 25
        FDB     157    ; 4096 / 26
        FDB     151    ; 4096 / 27
        FDB     146    ; 4096 / 28
        FDB     141    ; 4096 / 29
        FDB     136    ; 4096 / 30
        FDB     132    ; 4096 / 31
        FDB     128    ; 4096 / 32
        FDB     124    ; 4096 / 33
        FDB     120    ; 4096 / 34
        FDB     117    ; 4096 / 35
        FDB     113    ; 4096 / 36
        FDB     110    ; 4096 / 37
        FDB     107    ; 4096 / 38
        FDB     105    ; 4096 / 39
        FDB     102    ; 4096 / 40
        FDB     99    ; 4096 / 41
        FDB     97    ; 4096 / 42
        FDB     95    ; 4096 / 43
        FDB     93    ; 4096 / 44
        FDB     91    ; 4096 / 45
        FDB     89    ; 4096 / 46
        FDB     87    ; 4096 / 47
        FDB     85    ; 4096 / 48
        FDB     83    ; 4096 / 49
        FDB     81    ; 4096 / 50
        FDB     80    ; 4096 / 51
        FDB     78    ; 4096 / 52
        FDB     77    ; 4096 / 53
        FDB     75    ; 4096 / 54
        FDB     74    ; 4096 / 55
        FDB     73    ; 4096 / 56
        FDB     71    ; 4096 / 57
        FDB     70    ; 4096 / 58
        FDB     69    ; 4096 / 59
        FDB     68    ; 4096 / 60
        FDB     67    ; 4096 / 61
        FDB     66    ; 4096 / 62
        FDB     65    ; 4096 / 63
        FDB     64    ; 4096 / 64
        FDB     63    ; 4096 / 65
        FDB     62    ; 4096 / 66
        FDB     61    ; 4096 / 67
        FDB     60    ; 4096 / 68
        FDB     59    ; 4096 / 69
        FDB     58    ; 4096 / 70
        FDB     57    ; 4096 / 71
        FDB     56    ; 4096 / 72
        FDB     56    ; 4096 / 73
        FDB     55    ; 4096 / 74
        FDB     54    ; 4096 / 75
        FDB     53    ; 4096 / 76
        FDB     53    ; 4096 / 77
        FDB     52    ; 4096 / 78
        FDB     51    ; 4096 / 79
        FDB     51    ; 4096 / 80
        FDB     50    ; 4096 / 81
        FDB     49    ; 4096 / 82
        FDB     49    ; 4096 / 83
        FDB     48    ; 4096 / 84
        FDB     48    ; 4096 / 85
        FDB     47    ; 4096 / 86
        FDB     47    ; 4096 / 87
        FDB     46    ; 4096 / 88
        FDB     46    ; 4096 / 89
        FDB     45    ; 4096 / 90
        FDB     45    ; 4096 / 91
        FDB     44    ; 4096 / 92
        FDB     44    ; 4096 / 93
        FDB     43    ; 4096 / 94
        FDB     43    ; 4096 / 95
        FDB     42    ; 4096 / 96
        FDB     42    ; 4096 / 97
        FDB     41    ; 4096 / 98
        FDB     41    ; 4096 / 99
        FDB     40    ; 4096 / 100
        FDB     40    ; 4096 / 101
        FDB     40    ; 4096 / 102
        FDB     39    ; 4096 / 103
        FDB     39    ; 4096 / 104
        FDB     39    ; 4096 / 105
        FDB     38    ; 4096 / 106
        FDB     38    ; 4096 / 107
        FDB     37    ; 4096 / 108
        FDB     37    ; 4096 / 109
        FDB     37    ; 4096 / 110
        FDB     36    ; 4096 / 111
        FDB     36    ; 4096 / 112
        FDB     36    ; 4096 / 113
        FDB     35    ; 4096 / 114
        FDB     35    ; 4096 / 115
        FDB     35    ; 4096 / 116
        FDB     35    ; 4096 / 117
        FDB     34    ; 4096 / 118
        FDB     34    ; 4096 / 119
        FDB     34    ; 4096 / 120
        FDB     33    ; 4096 / 121
        FDB     33    ; 4096 / 122
        FDB     33    ; 4096 / 123
        FDB     33    ; 4096 / 124
        FDB     32    ; 4096 / 125
        FDB     32    ; 4096 / 126
        FDB     32    ; 4096 / 127
        FDB     32    ; 4096 / 128
        FDB     31    ; 4096 / 129
        FDB     31    ; 4096 / 130
        FDB     31    ; 4096 / 131
        FDB     31    ; 4096 / 132
        FDB     30    ; 4096 / 133
        FDB     30    ; 4096 / 134
        FDB     30    ; 4096 / 135
        FDB     30    ; 4096 / 136
        FDB     29    ; 4096 / 137
        FDB     29    ; 4096 / 138
        FDB     29    ; 4096 / 139
        FDB     29    ; 4096 / 140
        FDB     29    ; 4096 / 141
        FDB     28    ; 4096 / 142
        FDB     28    ; 4096 / 143
        FDB     28    ; 4096 / 144
        FDB     28    ; 4096 / 145
        FDB     28    ; 4096 / 146
        FDB     27    ; 4096 / 147
        FDB     27    ; 4096 / 148
        FDB     27    ; 4096 / 149
        FDB     27    ; 4096 / 150
        FDB     27    ; 4096 / 151
        FDB     26    ; 4096 / 152
        FDB     26    ; 4096 / 153
        FDB     26    ; 4096 / 154
        FDB     26    ; 4096 / 155
        FDB     26    ; 4096 / 156
        FDB     26    ; 4096 / 157
        FDB     25    ; 4096 / 158
        FDB     25    ; 4096 / 159
        FDB     25    ; 4096 / 160
        FDB     25    ; 4096 / 161
        FDB     25    ; 4096 / 162
        FDB     25    ; 4096 / 163
        FDB     24    ; 4096 / 164
        FDB     24    ; 4096 / 165
        FDB     24    ; 4096 / 166
        FDB     24    ; 4096 / 167
        FDB     24    ; 4096 / 168
        FDB     24    ; 4096 / 169
        FDB     24    ; 4096 / 170
        FDB     23    ; 4096 / 171
        FDB     23    ; 4096 / 172
        FDB     23    ; 4096 / 173
        FDB     23    ; 4096 / 174
        FDB     23    ; 4096 / 175
        FDB     23    ; 4096 / 176
        FDB     23    ; 4096 / 177
        FDB     23    ; 4096 / 178
        FDB     22    ; 4096 / 179
        FDB     22    ; 4096 / 180
        FDB     22    ; 4096 / 181
        FDB     22    ; 4096 / 182
        FDB     22    ; 4096 / 183
        FDB     22    ; 4096 / 184
        FDB     22    ; 4096 / 185
        FDB     22    ; 4096 / 186
        FDB     21    ; 4096 / 187
        FDB     21    ; 4096 / 188
        FDB     21    ; 4096 / 189
        FDB     21    ; 4096 / 190
        FDB     21    ; 4096 / 191
        FDB     21    ; 4096 / 192
        FDB     21    ; 4096 / 193
        FDB     21    ; 4096 / 194
        FDB     21    ; 4096 / 195
        FDB     20    ; 4096 / 196
        FDB     20    ; 4096 / 197
        FDB     20    ; 4096 / 198
        FDB     20    ; 4096 / 199
        FDB     20    ; 4096 / 200
        FDB     20    ; 4096 / 201
        FDB     20    ; 4096 / 202
        FDB     20    ; 4096 / 203
        FDB     20    ; 4096 / 204
        FDB     19    ; 4096 / 205
        FDB     19    ; 4096 / 206
        FDB     19    ; 4096 / 207
        FDB     19    ; 4096 / 208
        FDB     19    ; 4096 / 209
        FDB     19    ; 4096 / 210
        FDB     19    ; 4096 / 211
        FDB     19    ; 4096 / 212
        FDB     19    ; 4096 / 213
        FDB     19    ; 4096 / 214
        FDB     19    ; 4096 / 215
        FDB     18    ; 4096 / 216
        FDB     18    ; 4096 / 217
        FDB     18    ; 4096 / 218
        FDB     18    ; 4096 / 219
        FDB     18    ; 4096 / 220
        FDB     18    ; 4096 / 221
        FDB     18    ; 4096 / 222
        FDB     18    ; 4096 / 223
        FDB     18    ; 4096 / 224
        FDB     18    ; 4096 / 225
        FDB     18    ; 4096 / 226
        FDB     18    ; 4096 / 227
        FDB     17    ; 4096 / 228
        FDB     17    ; 4096 / 229
        FDB     17    ; 4096 / 230
        FDB     17    ; 4096 / 231
        FDB     17    ; 4096 / 232
        FDB     17    ; 4096 / 233
        FDB     17    ; 4096 / 234
        FDB     17    ; 4096 / 235
        FDB     17    ; 4096 / 236
        FDB     17    ; 4096 / 237
        FDB     17    ; 4096 / 238
        FDB     17    ; 4096 / 239
        FDB     17    ; 4096 / 240
        FDB     16    ; 4096 / 241
        FDB     16    ; 4096 / 242
        FDB     16    ; 4096 / 243
        FDB     16    ; 4096 / 244
        FDB     16    ; 4096 / 245
        FDB     16    ; 4096 / 246
        FDB     16    ; 4096 / 247
        FDB     16    ; 4096 / 248
        FDB     16    ; 4096 / 249
        FDB     16    ; 4096 / 250
        FDB     16    ; 4096 / 251
        FDB     16    ; 4096 / 252
        FDB     16    ; 4096 / 253
        FDB     16    ; 4096 / 254
        FDB     16    ; 4096 / 255
        FDB     16    ; 4096 / 256
        FDB     15    ; 4096 / 257
        FDB     15    ; 4096 / 258
        FDB     15    ; 4096 / 259
        FDB     15    ; 4096 / 260
        FDB     15    ; 4096 / 261
        FDB     15    ; 4096 / 262
        FDB     15    ; 4096 / 263
        FDB     15    ; 4096 / 264
        FDB     15    ; 4096 / 265
        FDB     15    ; 4096 / 266
        FDB     15    ; 4096 / 267
        FDB     15    ; 4096 / 268
        FDB     15    ; 4096 / 269
        FDB     15    ; 4096 / 270
        FDB     15    ; 4096 / 271
        FDB     15    ; 4096 / 272
        FDB     15    ; 4096 / 273
        FDB     14    ; 4096 / 274
        FDB     14    ; 4096 / 275
        FDB     14    ; 4096 / 276
        FDB     14    ; 4096 / 277
        FDB     14    ; 4096 / 278
        FDB     14    ; 4096 / 279
        FDB     14    ; 4096 / 280
        FDB     14    ; 4096 / 281
        FDB     14    ; 4096 / 282
        FDB     14    ; 4096 / 283
        FDB     14    ; 4096 / 284
        FDB     14    ; 4096 / 285
        FDB     14    ; 4096 / 286
        FDB     14    ; 4096 / 287
        FDB     14    ; 4096 / 288
        FDB     14    ; 4096 / 289
        FDB     14    ; 4096 / 290
        FDB     14    ; 4096 / 291
        FDB     14    ; 4096 / 292
        FDB     13    ; 4096 / 293
        FDB     13    ; 4096 / 294
        FDB     13    ; 4096 / 295
        FDB     13    ; 4096 / 296
        FDB     13    ; 4096 / 297
        FDB     13    ; 4096 / 298
        FDB     13    ; 4096 / 299
        FDB     13    ; 4096 / 300
        FDB     13    ; 4096 / 301
        FDB     13    ; 4096 / 302
        FDB     13    ; 4096 / 303
        FDB     13    ; 4096 / 304
        FDB     13    ; 4096 / 305
        FDB     13    ; 4096 / 306
        FDB     13    ; 4096 / 307
        FDB     13    ; 4096 / 308
        FDB     13    ; 4096 / 309
        FDB     13    ; 4096 / 310
        FDB     13    ; 4096 / 311
        FDB     13    ; 4096 / 312
        FDB     13    ; 4096 / 313
        FDB     13    ; 4096 / 314
        FDB     13    ; 4096 / 315
        FDB     12    ; 4096 / 316
        FDB     12    ; 4096 / 317
        FDB     12    ; 4096 / 318
        FDB     12    ; 4096 / 319
        FDB     12    ; 4096 / 320
        FDB     12    ; 4096 / 321
        FDB     12    ; 4096 / 322
        FDB     12    ; 4096 / 323
        FDB     12    ; 4096 / 324
        FDB     12    ; 4096 / 325
        FDB     12    ; 4096 / 326
        FDB     12    ; 4096 / 327
        FDB     12    ; 4096 / 328
        FDB     12    ; 4096 / 329
        FDB     12    ; 4096 / 330
        FDB     12    ; 4096 / 331
        FDB     12    ; 4096 / 332
        FDB     12    ; 4096 / 333
        FDB     12    ; 4096 / 334
        FDB     12    ; 4096 / 335
        FDB     12    ; 4096 / 336
        FDB     12    ; 4096 / 337
        FDB     12    ; 4096 / 338
        FDB     12    ; 4096 / 339
        FDB     12    ; 4096 / 340
        FDB     12    ; 4096 / 341
        FDB     11    ; 4096 / 342
        FDB     11    ; 4096 / 343
        FDB     11    ; 4096 / 344
        FDB     11    ; 4096 / 345
        FDB     11    ; 4096 / 346
        FDB     11    ; 4096 / 347
        FDB     11    ; 4096 / 348
        FDB     11    ; 4096 / 349
        FDB     11    ; 4096 / 350
        FDB     11    ; 4096 / 351
        FDB     11    ; 4096 / 352
        FDB     11    ; 4096 / 353
        FDB     11    ; 4096 / 354
        FDB     11    ; 4096 / 355
        FDB     11    ; 4096 / 356
        FDB     11    ; 4096 / 357
        FDB     11    ; 4096 / 358
        FDB     11    ; 4096 / 359
        FDB     11    ; 4096 / 360
        FDB     11    ; 4096 / 361
        FDB     11    ; 4096 / 362
        FDB     11    ; 4096 / 363
        FDB     11    ; 4096 / 364
        FDB     11    ; 4096 / 365
        FDB     11    ; 4096 / 366
        FDB     11    ; 4096 / 367
        FDB     11    ; 4096 / 368
        FDB     11    ; 4096 / 369
        FDB     11    ; 4096 / 370
        FDB     11    ; 4096 / 371
        FDB     11    ; 4096 / 372
        FDB     10    ; 4096 / 373
        FDB     10    ; 4096 / 374
        FDB     10    ; 4096 / 375
        FDB     10    ; 4096 / 376
        FDB     10    ; 4096 / 377
        FDB     10    ; 4096 / 378
        FDB     10    ; 4096 / 379
        FDB     10    ; 4096 / 380
        FDB     10    ; 4096 / 381
        FDB     10    ; 4096 / 382
        FDB     10    ; 4096 / 383
        FDB     10    ; 4096 / 384
        FDB     10    ; 4096 / 385
        FDB     10    ; 4096 / 386
        FDB     10    ; 4096 / 387
        FDB     10    ; 4096 / 388
        FDB     10    ; 4096 / 389
        FDB     10    ; 4096 / 390
        FDB     10    ; 4096 / 391
        FDB     10    ; 4096 / 392
        FDB     10    ; 4096 / 393
        FDB     10    ; 4096 / 394
        FDB     10    ; 4096 / 395
        FDB     10    ; 4096 / 396
        FDB     10    ; 4096 / 397
        FDB     10    ; 4096 / 398
        FDB     10    ; 4096 / 399
        FDB     10    ; 4096 / 400
        FDB     10    ; 4096 / 401
        FDB     10    ; 4096 / 402
        FDB     10    ; 4096 / 403
        FDB     10    ; 4096 / 404
        FDB     10    ; 4096 / 405
        FDB     10    ; 4096 / 406
        FDB     10    ; 4096 / 407
        FDB     10    ; 4096 / 408
        FDB     10    ; 4096 / 409
        FDB     9    ; 4096 / 410
        FDB     9    ; 4096 / 411
        FDB     9    ; 4096 / 412
        FDB     9    ; 4096 / 413
        FDB     9    ; 4096 / 414
        FDB     9    ; 4096 / 415
        FDB     9    ; 4096 / 416
        FDB     9    ; 4096 / 417
        FDB     9    ; 4096 / 418
        FDB     9    ; 4096 / 419
        FDB     9    ; 4096 / 420
        FDB     9    ; 4096 / 421
        FDB     9    ; 4096 / 422
        FDB     9    ; 4096 / 423
        FDB     9    ; 4096 / 424
        FDB     9    ; 4096 / 425
        FDB     9    ; 4096 / 426
        FDB     9    ; 4096 / 427
        FDB     9    ; 4096 / 428
        FDB     9    ; 4096 / 429
        FDB     9    ; 4096 / 430
        FDB     9    ; 4096 / 431
        FDB     9    ; 4096 / 432
        FDB     9    ; 4096 / 433
        FDB     9    ; 4096 / 434
        FDB     9    ; 4096 / 435
        FDB     9    ; 4096 / 436
        FDB     9    ; 4096 / 437
        FDB     9    ; 4096 / 438
        FDB     9    ; 4096 / 439
        FDB     9    ; 4096 / 440
        FDB     9    ; 4096 / 441
        FDB     9    ; 4096 / 442
        FDB     9    ; 4096 / 443
        FDB     9    ; 4096 / 444
        FDB     9    ; 4096 / 445
        FDB     9    ; 4096 / 446
        FDB     9    ; 4096 / 447
        FDB     9    ; 4096 / 448
        FDB     9    ; 4096 / 449
        FDB     9    ; 4096 / 450
        FDB     9    ; 4096 / 451
        FDB     9    ; 4096 / 452
        FDB     9    ; 4096 / 453
        FDB     9    ; 4096 / 454
        FDB     9    ; 4096 / 455
        FDB     8    ; 4096 / 456
        FDB     8    ; 4096 / 457
        FDB     8    ; 4096 / 458
        FDB     8    ; 4096 / 459
        FDB     8    ; 4096 / 460
        FDB     8    ; 4096 / 461
        FDB     8    ; 4096 / 462
        FDB     8    ; 4096 / 463
        FDB     8    ; 4096 / 464
        FDB     8    ; 4096 / 465
        FDB     8    ; 4096 / 466
        FDB     8    ; 4096 / 467
        FDB     8    ; 4096 / 468
        FDB     8    ; 4096 / 469
        FDB     8    ; 4096 / 470
        FDB     8    ; 4096 / 471
        FDB     8    ; 4096 / 472
        FDB     8    ; 4096 / 473
        FDB     8    ; 4096 / 474
        FDB     8    ; 4096 / 475
        FDB     8    ; 4096 / 476
        FDB     8    ; 4096 / 477
        FDB     8    ; 4096 / 478
        FDB     8    ; 4096 / 479
        FDB     8    ; 4096 / 480
        FDB     8    ; 4096 / 481
        FDB     8    ; 4096 / 482
        FDB     8    ; 4096 / 483
        FDB     8    ; 4096 / 484
        FDB     8    ; 4096 / 485
        FDB     8    ; 4096 / 486
        FDB     8    ; 4096 / 487
        FDB     8    ; 4096 / 488
        FDB     8    ; 4096 / 489
        FDB     8    ; 4096 / 490
        FDB     8    ; 4096 / 491
        FDB     8    ; 4096 / 492
        FDB     8    ; 4096 / 493
        FDB     8    ; 4096 / 494
        FDB     8    ; 4096 / 495
        FDB     8    ; 4096 / 496
        FDB     8    ; 4096 / 497
        FDB     8    ; 4096 / 498
        FDB     8    ; 4096 / 499
        FDB     8    ; 4096 / 500
        FDB     8    ; 4096 / 501
        FDB     8    ; 4096 / 502
        FDB     8    ; 4096 / 503
        FDB     8    ; 4096 / 504
        FDB     8    ; 4096 / 505
        FDB     8    ; 4096 / 506
        FDB     8    ; 4096 / 507
        FDB     8    ; 4096 / 508
        FDB     8    ; 4096 / 509
        FDB     8    ; 4096 / 510
        FDB     8    ; 4096 / 511
        FDB     8    ; 4096 / 512
        FDB     7    ; 4096 / 513
        FDB     7    ; 4096 / 514
        FDB     7    ; 4096 / 515
        FDB     7    ; 4096 / 516
        FDB     7    ; 4096 / 517
        FDB     7    ; 4096 / 518
        FDB     7    ; 4096 / 519
        FDB     7    ; 4096 / 520
        FDB     7    ; 4096 / 521
        FDB     7    ; 4096 / 522
        FDB     7    ; 4096 / 523
        FDB     7    ; 4096 / 524
        FDB     7    ; 4096 / 525
        FDB     7    ; 4096 / 526
        FDB     7    ; 4096 / 527
        FDB     7    ; 4096 / 528
        FDB     7    ; 4096 / 529
        FDB     7    ; 4096 / 530
        FDB     7    ; 4096 / 531
        FDB     7    ; 4096 / 532
        FDB     7    ; 4096 / 533
        FDB     7    ; 4096 / 534
        FDB     7    ; 4096 / 535
        FDB     7    ; 4096 / 536
        FDB     7    ; 4096 / 537
        FDB     7    ; 4096 / 538
        FDB     7    ; 4096 / 539
        FDB     7    ; 4096 / 540
        FDB     7    ; 4096 / 541
        FDB     7    ; 4096 / 542
        FDB     7    ; 4096 / 543
        FDB     7    ; 4096 / 544
        FDB     7    ; 4096 / 545
        FDB     7    ; 4096 / 546
        FDB     7    ; 4096 / 547
        FDB     7    ; 4096 / 548
        FDB     7    ; 4096 / 549
        FDB     7    ; 4096 / 550
        FDB     7    ; 4096 / 551
        FDB     7    ; 4096 / 552
        FDB     7    ; 4096 / 553
        FDB     7    ; 4096 / 554
        FDB     7    ; 4096 / 555
        FDB     7    ; 4096 / 556
        FDB     7    ; 4096 / 557
        FDB     7    ; 4096 / 558
        FDB     7    ; 4096 / 559
        FDB     7    ; 4096 / 560
        FDB     7    ; 4096 / 561
        FDB     7    ; 4096 / 562
        FDB     7    ; 4096 / 563
        FDB     7    ; 4096 / 564
        FDB     7    ; 4096 / 565
        FDB     7    ; 4096 / 566
        FDB     7    ; 4096 / 567
        FDB     7    ; 4096 / 568
        FDB     7    ; 4096 / 569
        FDB     7    ; 4096 / 570
        FDB     7    ; 4096 / 571
        FDB     7    ; 4096 / 572
        FDB     7    ; 4096 / 573
        FDB     7    ; 4096 / 574
        FDB     7    ; 4096 / 575
        FDB     7    ; 4096 / 576
        FDB     7    ; 4096 / 577
        FDB     7    ; 4096 / 578
        FDB     7    ; 4096 / 579
        FDB     7    ; 4096 / 580
        FDB     7    ; 4096 / 581
        FDB     7    ; 4096 / 582
        FDB     7    ; 4096 / 583
        FDB     7    ; 4096 / 584
        FDB     7    ; 4096 / 585
        FDB     6    ; 4096 / 586
        FDB     6    ; 4096 / 587
        FDB     6    ; 4096 / 588
        FDB     6    ; 4096 / 589
        FDB     6    ; 4096 / 590
        FDB     6    ; 4096 / 591
        FDB     6    ; 4096 / 592
        FDB     6    ; 4096 / 593
        FDB     6    ; 4096 / 594
        FDB     6    ; 4096 / 595
        FDB     6    ; 4096 / 596
        FDB     6    ; 4096 / 597
        FDB     6    ; 4096 / 598
        FDB     6    ; 4096 / 599
        FDB     6    ; 4096 / 600
        FDB     6    ; 4096 / 601
        FDB     6    ; 4096 / 602
        FDB     6    ; 4096 / 603
        FDB     6    ; 4096 / 604
        FDB     6    ; 4096 / 605
        FDB     6    ; 4096 / 606
        FDB     6    ; 4096 / 607
        FDB     6    ; 4096 / 608
        FDB     6    ; 4096 / 609
        FDB     6    ; 4096 / 610
        FDB     6    ; 4096 / 611
        FDB     6    ; 4096 / 612
        FDB     6    ; 4096 / 613
        FDB     6    ; 4096 / 614
        FDB     6    ; 4096 / 615
        FDB     6    ; 4096 / 616
        FDB     6    ; 4096 / 617
        FDB     6    ; 4096 / 618
        FDB     6    ; 4096 / 619
        FDB     6    ; 4096 / 620
        FDB     6    ; 4096 / 621
        FDB     6    ; 4096 / 622
        FDB     6    ; 4096 / 623
        FDB     6    ; 4096 / 624
        FDB     6    ; 4096 / 625
        FDB     6    ; 4096 / 626
        FDB     6    ; 4096 / 627
        FDB     6    ; 4096 / 628
        FDB     6    ; 4096 / 629
        FDB     6    ; 4096 / 630
        FDB     6    ; 4096 / 631
        FDB     6    ; 4096 / 632
        FDB     6    ; 4096 / 633
        FDB     6    ; 4096 / 634
        FDB     6    ; 4096 / 635
        FDB     6    ; 4096 / 636
        FDB     6    ; 4096 / 637
        FDB     6    ; 4096 / 638
        FDB     6    ; 4096 / 639
        FDB     6    ; 4096 / 640
        FDB     6    ; 4096 / 641
        FDB     6    ; 4096 / 642
        FDB     6    ; 4096 / 643
        FDB     6    ; 4096 / 644
        FDB     6    ; 4096 / 645
        FDB     6    ; 4096 / 646
        FDB     6    ; 4096 / 647
        FDB     6    ; 4096 / 648
        FDB     6    ; 4096 / 649
        FDB     6    ; 4096 / 650
        FDB     6    ; 4096 / 651
        FDB     6    ; 4096 / 652
        FDB     6    ; 4096 / 653
        FDB     6    ; 4096 / 654
        FDB     6    ; 4096 / 655
        FDB     6    ; 4096 / 656
        FDB     6    ; 4096 / 657
        FDB     6    ; 4096 / 658
        FDB     6    ; 4096 / 659
        FDB     6    ; 4096 / 660
        FDB     6    ; 4096 / 661
        FDB     6    ; 4096 / 662
        FDB     6    ; 4096 / 663
        FDB     6    ; 4096 / 664
        FDB     6    ; 4096 / 665
        FDB     6    ; 4096 / 666
        FDB     6    ; 4096 / 667
        FDB     6    ; 4096 / 668
        FDB     6    ; 4096 / 669
        FDB     6    ; 4096 / 670
        FDB     6    ; 4096 / 671
        FDB     6    ; 4096 / 672
        FDB     6    ; 4096 / 673
        FDB     6    ; 4096 / 674
        FDB     6    ; 4096 / 675
        FDB     6    ; 4096 / 676
        FDB     6    ; 4096 / 677
        FDB     6    ; 4096 / 678
        FDB     6    ; 4096 / 679
        FDB     6    ; 4096 / 680
        FDB     6    ; 4096 / 681
        FDB     6    ; 4096 / 682
        FDB     5    ; 4096 / 683
        FDB     5    ; 4096 / 684
        FDB     5    ; 4096 / 685
        FDB     5    ; 4096 / 686
        FDB     5    ; 4096 / 687
        FDB     5    ; 4096 / 688
        FDB     5    ; 4096 / 689
        FDB     5    ; 4096 / 690
        FDB     5    ; 4096 / 691
        FDB     5    ; 4096 / 692
        FDB     5    ; 4096 / 693
        FDB     5    ; 4096 / 694
        FDB     5    ; 4096 / 695
        FDB     5    ; 4096 / 696
        FDB     5    ; 4096 / 697
        FDB     5    ; 4096 / 698
        FDB     5    ; 4096 / 699
        FDB     5    ; 4096 / 700
        FDB     5    ; 4096 / 701
        FDB     5    ; 4096 / 702
        FDB     5    ; 4096 / 703
        FDB     5    ; 4096 / 704
        FDB     5    ; 4096 / 705
        FDB     5    ; 4096 / 706
        FDB     5    ; 4096 / 707
        FDB     5    ; 4096 / 708
        FDB     5    ; 4096 / 709
        FDB     5    ; 4096 / 710
        FDB     5    ; 4096 / 711
        FDB     5    ; 4096 / 712
        FDB     5    ; 4096 / 713
        FDB     5    ; 4096 / 714
        FDB     5    ; 4096 / 715
        FDB     5    ; 4096 / 716
        FDB     5    ; 4096 / 717
        FDB     5    ; 4096 / 718
        FDB     5    ; 4096 / 719
        FDB     5    ; 4096 / 720
        FDB     5    ; 4096 / 721
        FDB     5    ; 4096 / 722
        FDB     5    ; 4096 / 723
        FDB     5    ; 4096 / 724
        FDB     5    ; 4096 / 725
        FDB     5    ; 4096 / 726
        FDB     5    ; 4096 / 727
        FDB     5    ; 4096 / 728
        FDB     5    ; 4096 / 729
        FDB     5    ; 4096 / 730
        FDB     5    ; 4096 / 731
        FDB     5    ; 4096 / 732
        FDB     5    ; 4096 / 733
        FDB     5    ; 4096 / 734
        FDB     5    ; 4096 / 735
        FDB     5    ; 4096 / 736
        FDB     5    ; 4096 / 737
        FDB     5    ; 4096 / 738
        FDB     5    ; 4096 / 739
        FDB     5    ; 4096 / 740
        FDB     5    ; 4096 / 741
        FDB     5    ; 4096 / 742
        FDB     5    ; 4096 / 743
        FDB     5    ; 4096 / 744
        FDB     5    ; 4096 / 745
        FDB     5    ; 4096 / 746
        FDB     5    ; 4096 / 747
        FDB     5    ; 4096 / 748
        FDB     5    ; 4096 / 749
        FDB     5    ; 4096 / 750
        FDB     5    ; 4096 / 751
        FDB     5    ; 4096 / 752
        FDB     5    ; 4096 / 753
        FDB     5    ; 4096 / 754
        FDB     5    ; 4096 / 755
        FDB     5    ; 4096 / 756
        FDB     5    ; 4096 / 757
        FDB     5    ; 4096 / 758
        FDB     5    ; 4096 / 759
        FDB     5    ; 4096 / 760
        FDB     5    ; 4096 / 761
        FDB     5    ; 4096 / 762
        FDB     5    ; 4096 / 763
        FDB     5    ; 4096 / 764
        FDB     5    ; 4096 / 765
        FDB     5    ; 4096 / 766
        FDB     5    ; 4096 / 767
        FDB     5    ; 4096 / 768
        FDB     5    ; 4096 / 769
        FDB     5    ; 4096 / 770
        FDB     5    ; 4096 / 771
        FDB     5    ; 4096 / 772
        FDB     5    ; 4096 / 773
        FDB     5    ; 4096 / 774
        FDB     5    ; 4096 / 775
        FDB     5    ; 4096 / 776
        FDB     5    ; 4096 / 777
        FDB     5    ; 4096 / 778
        FDB     5    ; 4096 / 779
        FDB     5    ; 4096 / 780
        FDB     5    ; 4096 / 781
        FDB     5    ; 4096 / 782
        FDB     5    ; 4096 / 783
        FDB     5    ; 4096 / 784
        FDB     5    ; 4096 / 785
        FDB     5    ; 4096 / 786
        FDB     5    ; 4096 / 787
        FDB     5    ; 4096 / 788
        FDB     5    ; 4096 / 789
        FDB     5    ; 4096 / 790
        FDB     5    ; 4096 / 791
        FDB     5    ; 4096 / 792
        FDB     5    ; 4096 / 793
        FDB     5    ; 4096 / 794
        FDB     5    ; 4096 / 795
        FDB     5    ; 4096 / 796
        FDB     5    ; 4096 / 797
        FDB     5    ; 4096 / 798
        FDB     5    ; 4096 / 799
        FDB     5    ; 4096 / 800
        FDB     5    ; 4096 / 801
        FDB     5    ; 4096 / 802
        FDB     5    ; 4096 / 803
        FDB     5    ; 4096 / 804
        FDB     5    ; 4096 / 805
        FDB     5    ; 4096 / 806
        FDB     5    ; 4096 / 807
        FDB     5    ; 4096 / 808
        FDB     5    ; 4096 / 809
        FDB     5    ; 4096 / 810
        FDB     5    ; 4096 / 811
        FDB     5    ; 4096 / 812
        FDB     5    ; 4096 / 813
        FDB     5    ; 4096 / 814
        FDB     5    ; 4096 / 815
        FDB     5    ; 4096 / 816
        FDB     5    ; 4096 / 817
        FDB     5    ; 4096 / 818
        FDB     5    ; 4096 / 819
        FDB     4    ; 4096 / 820
        FDB     4    ; 4096 / 821
        FDB     4    ; 4096 / 822
        FDB     4    ; 4096 / 823
        FDB     4    ; 4096 / 824
        FDB     4    ; 4096 / 825
        FDB     4    ; 4096 / 826
        FDB     4    ; 4096 / 827
        FDB     4    ; 4096 / 828
        FDB     4    ; 4096 / 829
        FDB     4    ; 4096 / 830
        FDB     4    ; 4096 / 831
        FDB     4    ; 4096 / 832
        FDB     4    ; 4096 / 833
        FDB     4    ; 4096 / 834
        FDB     4    ; 4096 / 835
        FDB     4    ; 4096 / 836
        FDB     4    ; 4096 / 837
        FDB     4    ; 4096 / 838
        FDB     4    ; 4096 / 839
        FDB     4    ; 4096 / 840
        FDB     4    ; 4096 / 841
        FDB     4    ; 4096 / 842
        FDB     4    ; 4096 / 843
        FDB     4    ; 4096 / 844
        FDB     4    ; 4096 / 845
        FDB     4    ; 4096 / 846
        FDB     4    ; 4096 / 847
        FDB     4    ; 4096 / 848
        FDB     4    ; 4096 / 849
        FDB     4    ; 4096 / 850
        FDB     4    ; 4096 / 851
        FDB     4    ; 4096 / 852
        FDB     4    ; 4096 / 853
        FDB     4    ; 4096 / 854
        FDB     4    ; 4096 / 855
        FDB     4    ; 4096 / 856
        FDB     4    ; 4096 / 857
        FDB     4    ; 4096 / 858
        FDB     4    ; 4096 / 859
        FDB     4    ; 4096 / 860
        FDB     4    ; 4096 / 861
        FDB     4    ; 4096 / 862
        FDB     4    ; 4096 / 863
        FDB     4    ; 4096 / 864
        FDB     4    ; 4096 / 865
        FDB     4    ; 4096 / 866
        FDB     4    ; 4096 / 867
        FDB     4    ; 4096 / 868
        FDB     4    ; 4096 / 869
        FDB     4    ; 4096 / 870
        FDB     4    ; 4096 / 871
        FDB     4    ; 4096 / 872
        FDB     4    ; 4096 / 873
        FDB     4    ; 4096 / 874
        FDB     4    ; 4096 / 875
        FDB     4    ; 4096 / 876
        FDB     4    ; 4096 / 877
        FDB     4    ; 4096 / 878
        FDB     4    ; 4096 / 879
        FDB     4    ; 4096 / 880
        FDB     4    ; 4096 / 881
        FDB     4    ; 4096 / 882
        FDB     4    ; 4096 / 883
        FDB     4    ; 4096 / 884
        FDB     4    ; 4096 / 885
        FDB     4    ; 4096 / 886
        FDB     4    ; 4096 / 887
        FDB     4    ; 4096 / 888
        FDB     4    ; 4096 / 889
        FDB     4    ; 4096 / 890
        FDB     4    ; 4096 / 891
        FDB     4    ; 4096 / 892
        FDB     4    ; 4096 / 893
        FDB     4    ; 4096 / 894
        FDB     4    ; 4096 / 895
        FDB     4    ; 4096 / 896
        FDB     4    ; 4096 / 897
        FDB     4    ; 4096 / 898
        FDB     4    ; 4096 / 899
        FDB     4    ; 4096 / 900
        FDB     4    ; 4096 / 901
        FDB     4    ; 4096 / 902
        FDB     4    ; 4096 / 903
        FDB     4    ; 4096 / 904
        FDB     4    ; 4096 / 905
        FDB     4    ; 4096 / 906
        FDB     4    ; 4096 / 907
        FDB     4    ; 4096 / 908
        FDB     4    ; 4096 / 909
        FDB     4    ; 4096 / 910
        FDB     4    ; 4096 / 911
        FDB     4    ; 4096 / 912
        FDB     4    ; 4096 / 913
        FDB     4    ; 4096 / 914
        FDB     4    ; 4096 / 915
        FDB     4    ; 4096 / 916
        FDB     4    ; 4096 / 917
        FDB     4    ; 4096 / 918
        FDB     4    ; 4096 / 919
        FDB     4    ; 4096 / 920
        FDB     4    ; 4096 / 921
        FDB     4    ; 4096 / 922
        FDB     4    ; 4096 / 923
        FDB     4    ; 4096 / 924
        FDB     4    ; 4096 / 925
        FDB     4    ; 4096 / 926
        FDB     4    ; 4096 / 927
        FDB     4    ; 4096 / 928
        FDB     4    ; 4096 / 929
        FDB     4    ; 4096 / 930
        FDB     4    ; 4096 / 931
        FDB     4    ; 4096 / 932
        FDB     4    ; 4096 / 933
        FDB     4    ; 4096 / 934
        FDB     4    ; 4096 / 935
        FDB     4    ; 4096 / 936
        FDB     4    ; 4096 / 937
        FDB     4    ; 4096 / 938
        FDB     4    ; 4096 / 939
        FDB     4    ; 4096 / 940
        FDB     4    ; 4096 / 941
        FDB     4    ; 4096 / 942
        FDB     4    ; 4096 / 943
        FDB     4    ; 4096 / 944
        FDB     4    ; 4096 / 945
        FDB     4    ; 4096 / 946
        FDB     4    ; 4096 / 947
        FDB     4    ; 4096 / 948
        FDB     4    ; 4096 / 949
        FDB     4    ; 4096 / 950
        FDB     4    ; 4096 / 951
        FDB     4    ; 4096 / 952
        FDB     4    ; 4096 / 953
        FDB     4    ; 4096 / 954
        FDB     4    ; 4096 / 955
        FDB     4    ; 4096 / 956
        FDB     4    ; 4096 / 957
        FDB     4    ; 4096 / 958
        FDB     4    ; 4096 / 959
        FDB     4    ; 4096 / 960
        FDB     4    ; 4096 / 961
        FDB     4    ; 4096 / 962
        FDB     4    ; 4096 / 963
        FDB     4    ; 4096 / 964
        FDB     4    ; 4096 / 965
        FDB     4    ; 4096 / 966
        FDB     4    ; 4096 / 967
        FDB     4    ; 4096 / 968
        FDB     4    ; 4096 / 969
        FDB     4    ; 4096 / 970
        FDB     4    ; 4096 / 971
        FDB     4    ; 4096 / 972
        FDB     4    ; 4096 / 973
        FDB     4    ; 4096 / 974
        FDB     4    ; 4096 / 975
        FDB     4    ; 4096 / 976
        FDB     4    ; 4096 / 977
        FDB     4    ; 4096 / 978
        FDB     4    ; 4096 / 979
        FDB     4    ; 4096 / 980
        FDB     4    ; 4096 / 981
        FDB     4    ; 4096 / 982
        FDB     4    ; 4096 / 983
        FDB     4    ; 4096 / 984
        FDB     4    ; 4096 / 985
        FDB     4    ; 4096 / 986
        FDB     4    ; 4096 / 987
        FDB     4    ; 4096 / 988
        FDB     4    ; 4096 / 989
        FDB     4    ; 4096 / 990
        FDB     4    ; 4096 / 991
        FDB     4    ; 4096 / 992
        FDB     4    ; 4096 / 993
        FDB     4    ; 4096 / 994
        FDB     4    ; 4096 / 995
        FDB     4    ; 4096 / 996
        FDB     4    ; 4096 / 997
        FDB     4    ; 4096 / 998
        FDB     4    ; 4096 / 999
        FDB     4    ; 4096 / 1000
        FDB     4    ; 4096 / 1001
        FDB     4    ; 4096 / 1002
        FDB     4    ; 4096 / 1003
        FDB     4    ; 4096 / 1004
        FDB     4    ; 4096 / 1005
        FDB     4    ; 4096 / 1006
        FDB     4    ; 4096 / 1007
        FDB     4    ; 4096 / 1008
        FDB     4    ; 4096 / 1009
        FDB     4    ; 4096 / 1010
        FDB     4    ; 4096 / 1011
        FDB     4    ; 4096 / 1012
        FDB     4    ; 4096 / 1013
        FDB     4    ; 4096 / 1014
        FDB     4    ; 4096 / 1015
        FDB     4    ; 4096 / 1016
        FDB     4    ; 4096 / 1017
        FDB     4    ; 4096 / 1018
        FDB     4    ; 4096 / 1019
        FDB     4    ; 4096 / 1020
        FDB     4    ; 4096 / 1021
        FDB     4    ; 4096 / 1022
        FDB     4    ; 4096 / 1023