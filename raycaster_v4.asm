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
RAY_plane_x_step RMB     2
RAY_plane_y_step RMB     2
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

DC_COLOR      RMB     1      ; Couleur de la colonne (0-15)
DC_POS        RMB     1      ; Position dans le groupe de 4 pixels
DC_PIX_VAL    RMB     1      ; Valeur de l'octet à écrire (masque + couleur)
DC_PIX_MSK    RMB     1      ; Masque pour préserver les autres pixels
DC_END_ADR    RMB     2      ; Adresse de fin selon RAMA/RAMB


; Tables et buffers 
MAP_LINES     RMB    48     ; 24 pointeurs lignes map
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
        JSR  INIT_TABLES
        JSR  INIT_SCREEN_OFFS
        JSR  INIT_RAYCAST
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

; Init tables
INIT_TABLES
        ; Init MAP_LINES
        LDX  #MAP_LINES
        LDY  #MAP
INIT_LINE    
        STY  ,X++
        LEAY MAP_W,Y
        CMPX #MAP_LINES+48
        BNE  INIT_LINE
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

; Boucle raycasting principale
RAYCAST_FRAME
	; map_pointer_0 = VARPTR(world_map) + map_X0+((WORD)map_Y0)**32
	; delta_dir_x = 0
	; delta_dir_y = 0
	; plane_x_step = plane_x ** 4
	; plane_y_step = plane_y ** 4

        ; Get initial map pointer from player position and store it onto U
        LDA     <RAY_pos_x+1  ; High byte = map X
        LDB     <RAY_pos_y+1  ; High byte = map Y
        LDU     #MAP          ; Map base address
        LDA     #MAP_W
        MUL                   ; D = Y * MAP_WIDTH
        LEAU    D,U          ; Add Y offset
        CLRA                 ; Clear A for adding X
        LDB     <RAY_pos_x+1  ; Get X position
        LEAU    D,U          ; Add X offset

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
	STD     <RAY_ddist_x
	STD     <RAY_ddist_y

        STA     <RAY_cam_x  ; Débute colonne 0
COL_LOOP
        ; Pour chaque colonne de la fenêtre de rendu
        JSR  CALC_RAY   ; Calcule direction rayon
        JSR  RAYCAST    ; Lance rayon
        JSR  DRAW_COL   ; Dessine colonne
        
        INC  <RAY_cam_x
        LDA  <RAY_cam_x
        CMPA #RENDER_W  ; Compare avec 128 au lieu de 160
        BNE  COL_LOOP
        RTS

CALC_RAY
        ;delta_dir_x_h = PEEK(VARPTR(delta_dir_x))
        ;ray_dir_x = ray_dir_x0 + delta_dir_x_h
        LDX     <RAY_ray_x0
        LDB     <RAY_ddist_x
        ABX
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
        LDA     <RAY_pos_x    ; High byte of pos
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
        LDB     <RAY_ddist_y
        ABX
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
        LDA     <RAY_pos_y    ; High byte of pos
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
        LDA     #$E0          ; Step X negative
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

        RTS



RAYCAST

DDA_LOOP    

DO_STEPX                ; Cas par défaut : on avance en X 

DO_STEPY   

HITHORZ
        BRA  CONT_DIST

HITVERT
        LDA  #4         ; Couleur 4 (rouge clair) pour murs verticaux
        STA  <RAY_color

CONT_DIST               ; Point de continuation commun
        
DIST_OK

SAVE_HEIGHT
        STA  <RAY_line_h
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
        FDB  0,80,160,240,320,400,480,560,640,720,800
        ; ... généré dynamiquement par INIT_SCREEN_OFFS

; --------------- TABLES ---------------
; Division table for 4096 divided by integers from 0 to 200
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
