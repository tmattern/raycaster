; =============================================
; Raycasting ultra optimisé TO8/TO9 
; Version: 1.0
; Date: 2025-01-21 08:20
; Auteur: tmattern
; =============================================

; Constantes
SCREEN      EQU  $A000  ; Adresse écran
SCREEN_W    EQU  160    ; Largeur en mode 160x200
SCREEN_H    EQU  200    ; Hauteur écran
MAP_W       EQU  32     ; Largeur map
MAP_H       EQU  24     ; Hauteur map
CENTER_Y    EQU  100    ; Centre vertical écran

; Variables page zéro - Section critique
        ORG  $0000
MAP_PTR     RMB  2      ; Pointeur map courant
DIST        RMB  2      ; Distance au mur (8.8)
HEIGHT      RMB  1      ; Hauteur colonne
CURR_COL    RMB  1      ; Colonne courante
MAPX        RMB  1      ; Position map X
MAPY        RMB  1      ; Position map Y
PLAYERX     RMB  2      ; Position joueur X (8.8)
PLAYERY     RMB  2      ; Position joueur Y (8.8)
ANGLE       RMB  1      ; Angle vue (0-255)
STEPX       RMB  1      ; Direction X (-1/+1)
STEPY       RMB  1      ; Direction Y (-1/+1)
SIDEX       RMB  2      ; Distance côté X (8.8)
SIDEY       RMB  2      ; Distance côté Y (8.8)
DELTAX      RMB  2      ; Delta X (8.8)
DELTAY      RMB  2      ; Delta Y (8.8)
SIDE        RMB  1      ; Côté touché (0=X, 1=Y)
BLOCKS      RMB  1      ; Compteur blocs
COL_PTR     RMB  2      ; Pointeur colonne courante
TEMP        RMB  1      ; Variable temporaire

; Variables page zéro - Section rendu optimisé
        ORG  $0040
MAP_LINES   RMB  48     ; 24 pointeurs lignes map

        ORG  $00C0
OFFS_8      RMB  8      ; Table offsets 8 pixels
CODE_SKY    RMB  24     ; Code auto-modifiant ciel
CODE_WALL   RMB  24     ; Code auto-modifiant mur
CODE_FLOOR  RMB  24     ; Code auto-modifiant sol


        ORG  $4200      ; Offsets écran
        ALIGN 256
SCREEN_OFFS                 ; Table offsets écran
        FDB  0,80,160,240,320,400,480,560
        ; ... généré par INIT

; Point d'entrée
        ORG  $5000
START   
        ; Init système
        ORCC #$50      ; Désactive interruptions
        
        ; Passe en mode 160x200x4
        LDA  #$7A
        STA  $E7C3
        
        JSR  INIT      ; Initialisation
        
MAIN_LOOP
        JSR  RAYCAST_FRAME
        BRA  MAIN_LOOP

; Initialisation 
INIT    
        ; Init tables
        JSR  INIT_TABLES
        JSR  INIT_SCREEN_OFFS
        
        ; Position départ joueur
        LDD  #$0800    ; X=8.0
        STD  PLAYERX
        STD  PLAYERY   ; Y=8.0
        CLRA
        STA  ANGLE     ; Angle=0
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
        CLRA
        STA  CURR_COL  ; Débute colonne 0

COL    ; Pour chaque colonne
        JSR  CALC_RAY  ; Calcule direction rayon
        JSR  RAYCAST   ; Lance rayon
        JSR  DRAW_COL  ; Dessine colonne
        
        INC  CURR_COL
        LDA  CURR_COL
        CMPA #SCREEN_W
        BNE  COL
        RTS

CALC_RAY
        LDA  CURR_COL
        SUBA #80       ; Centre écran
        ASRA           ; /2 pour FOV
        ADDA ANGLE     ; + angle joueur
        STA  TEMP      ; Sauvegarde angle dans variable temporaire
        
        LDX  #SINTAB
        LDA  A,X       ; sin(angle)
        STA  DELTAY
        
        LDX  #COSTAB
        LDA  TEMP      ; Récupère angle
        LDA  A,X       ; cos(angle)
        STA  DELTAX
        RTS


; Raycasting DDA optimisé
RAYCAST
        ; Init pointeur map
        LDA  MAPY
        LSLA
        LDX  #MAP_LINES
        LDX  A,X
        LDB  MAPX
        ABX
        STX  MAP_PTR

        ; Init deltas
        LDA  DELTAX
        BPL  POSX
        LDA  #-1
        STA  STEPX
        NEGB
        BRA  SAVEX
POSX    
        LDA  #1
        STA  STEPX
SAVEX   
        STB  SIDEX+1
        CLRA
        STA  SIDEX

        LDA  DELTAY
        BPL  POSY
        LDA  #-1
        STA  STEPY
        NEGB
        BRA  SAVEY
POSY    
        LDA  #1
        STA  STEPY
SAVEY   
        STB  SIDEY+1
        CLRA
        STA  SIDEY

; Boucle DDA ultra optimisée
DDA_LOOP    
        LDD  SIDEX
        CMPD SIDEY
        BLO  STEPX

STEPY   
        LDX  MAP_PTR
        LDA  STEPY
        BPL  UP
DOWN    
        LEAX -MAP_W,X
        BRA  SAVEY2
UP      
        LEAX MAP_W,X
SAVEY2  
        STX  MAP_PTR
        LDA  ,X
        BNE  HITVERT
        LDD  SIDEY
        ADDD DELTAY
        STD  SIDEY
        BRA  DDA_LOOP

STEPX   
        LDX  MAP_PTR
        LEAX STEPX,X
        STX  MAP_PTR
        LDA  ,X
        BNE  HITHORZ
        LDD  SIDEX
        ADDD DELTAX
        STD  SIDEX
        BRA  DDA_LOOP

HITHORZ
        LDD  SIDEX
        CLR  SIDE
        BRA  DIST
HITVERT
        LDD  SIDEY
        LDA  #1
        STA  SIDE
DIST    
        STD  DIST

        ; Calcul hauteur optimisé
        LDA  #100
        LDB  DIST+1
        MUL
        STA  HEIGHT
        RTS

; Dessin colonne ultra optimisé
DRAW_COL
        ; Init pointeur écran
        LDA  CURR_COL
        LSRA
        LDX  #SCREEN
        LEAX A,X
        STX  COL_PTR

        ; Prépare code auto-modifiant
        LDA  CURR_COL
        ANDA #1
        BNE  PREP_ODD

PREP_EVEN
        LDD  #$F6A7    ; LDA high
        BRA  PREP_DONE
PREP_ODD
        LDD  #$B6A7    ; LDA low
PREP_DONE
        STD  SKY_CODE
        STD  WALL_CODE
        STD  FLOOR_CODE

        ; Génère code 8 pixels
        JSR  GEN_DRAW_CODE

        ; Dessine ciel
        LDA  HEIGHT
        NEGA
        ADDA #CENTER_Y
        LSRA
        LSRA
        LSRA
        STA  BLOCKS
        BEQ  WALL

SKY     
        JSR  CODE_SKY
        LDD  SKY_ADDR
        ADDD #640
        STD  SKY_ADDR
        DEC  BLOCKS
        BNE  SKY

        ; Dessine mur
WALL    
        LDA  HEIGHT
        LSRA
        LSRA
        LSRA
        STA  BLOCKS
        BEQ  REMAIN

WALL8   
        JSR  CODE_WALL
        LDD  WALL_ADDR
        ADDD #640
        STD  WALL_ADDR
        DEC  BLOCKS
        BNE  WALL8

        ; Pixels restants
REMAIN  
        LDA  HEIGHT
        ANDA #7
        BEQ  FLOOR
        STA  BLOCKS

WALL1   
        JSR  WALL_CODE
        LDD  WALL_ADDR
        ADDD #80
        STD  WALL_ADDR
        DEC  BLOCKS
        BNE  WALL1

        ; Dessine sol
FLOOR   
        JSR  CODE_FLOOR
        LDD  FLOOR_ADDR
        ADDD #640
        STD  FLOOR_ADDR
        CMPD #SCREEN+16000
        BLO  FLOOR

        RTS

; Génère code dessin
GEN_DRAW_CODE
        LDX  #CODE_SKY
        LDY  #OFFS_8
        LDB  #8
GEN_LOOP    
        LDD  SKY_CODE
        STD  ,X
        LDA  ,Y+
        STA  2,X
        LEAX 3,X
        DECB
        BNE  GEN_LOOP

        LDX  COL_PTR
        STX  SKY_ADDR
        STX  WALL_ADDR
        STX  FLOOR_ADDR
        RTS

; --------------- TABLES ---------------
        ORG  $F000
; Table sinus - 256 valeurs sur [0,2π]
SINTAB
        FCB  0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45
        FCB  48,51,54,57,59,62,65,67,70,73,75,78,80,82,85,87
        FCB  89,91,94,96,98,100,102,104,106,107,109,111,112,114,115,117
        FCB  118,119,120,121,122,123,124,124,125,126,126,127,127,127,127,127
        FCB  127,127,127,127,127,127,126,126,125,124,124,123,122,121,120,119
        FCB  118,117,115,114,112,111,109,107,106,104,102,100,98,96,94,91
        FCB  89,87,85,82,80,78,75,73,70,67,65,62,59,57,54,51
        FCB  48,45,42,39,36,33,30,27,24,21,18,15,12,9,6,3
        FCB  0,-3,-6,-9,-12,-15,-18,-21,-24,-27,-30,-33,-36,-39,-42,-45
        FCB  -48,-51,-54,-57,-59,-62,-65,-67,-70,-73,-75,-78,-80,-82,-85,-87
        FCB  -89,-91,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-114,-115,-117
        FCB  -118,-119,-120,-121,-122,-123,-124,-124,-125,-126,-126,-127,-127,-127,-127,-127
        FCB  -127,-127,-127,-127,-127,-127,-126,-126,-125,-124,-124,-123,-122,-121,-120,-119
        FCB  -118,-117,-115,-114,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-91
        FCB  -89,-87,-85,-82,-80,-78,-75,-73,-70,-67,-65,-62,-59,-57,-54,-51
        FCB  -48,-45,-42,-39,-36,-33,-30,-27,-24,-21,-18,-15,-12,-9,-6,-3

; Table cosinus (sinus décalé de 64)
COSTAB
        FCB  127,127,127,127,127,127,126,126,125,124,124,123,122,121,120,119
        FCB  118,117,115,114,112,111,109,107,106,104,102,100,98,96,94,91
        FCB  89,87,85,82,80,78,75,73,70,67,65,62,59,57,54,51
        FCB  48,45,42,39,36,33,30,27,24,21,18,15,12,9,6,3
        FCB  0,-3,-6,-9,-12,-15,-18,-21,-24,-27,-30,-33,-36,-39,-42,-45
        FCB  -48,-51,-54,-57,-59,-62,-65,-67,-70,-73,-75,-78,-80,-82,-85,-87
        FCB  -89,-91,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-114,-115,-117
        FCB  -118,-119,-120,-121,-122,-123,-124,-124,-125,-126,-126,-127,-127,-127,-127,-127
        FCB  -127,-127,-127,-127,-127,-127,-126,-126,-125,-124,-124,-123,-122,-121,-120,-119
        FCB  -118,-117,-115,-114,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-91
        FCB  -89,-87,-85,-82,-80,-78,-75,-73,-70,-67,-65,-62,-59,-57,-54,-51
        FCB  -48,-45,-42,-39,-36,-33,-30,-27,-24,-21,-18,-15,-12,-9,-6,-3
        FCB  0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45
        FCB  48,51,54,57,59,62,65,67,70,73,75,78,80,82,85,87
        FCB  89,91,94,96,98,100,102,104,106,107,109,111,112,114,115,117
        FCB  118,119,120,121,122,123,124,124,125,126,126,127,127,127,127,127

; --------------- MAP 32x24 ---------------
; Map 32x24
        ORG  $6000
        ALIGN 256
MAP     
        FCB  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1  ; Ligne 1
        FCB  1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1  ; Ligne 2
        FCB  1,0,0,2,2,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,3,3,0,0,1  ; Ligne 3
        FCB  1,0,2,2,2,2,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,3,3,3,3,0,1  ; Ligne 4
        FCB  1,0,2,2,2,2,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,3,3,3,3,0,1  ; Ligne 5
        FCB  1,0,0,2,2,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,3,3,0,0,1  ; Ligne 6
        FCB  1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1  ; Ligne 7
        FCB  1,1,1,0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,1,1,1  ; Ligne 8
        FCB  1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1  ; Ligne 9
        FCB  1,0,0,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0,1  ; Ligne 10
        FCB  1,0,4,4,4,4,0,1,1,0,0,7,7,7,0,0,0,0,7,7,7,0,0,1,1,0,5,5,5,5,0,1  ; Ligne 11
        FCB  1,0,4,4,4,4,0,1,1,0,0,7,0,0,0,0,0,0,0,0,7,0,0,1,1,0,5,5,5,5,0,1  ; Ligne 12
        FCB  1,0,4,4,4,4,0,0,0,0,0,7,0,0,0,0,0,0,0,0,7,0,0,0,0,0,5,5,5,5,0,1  ; Ligne 13
        FCB  1,0,4,4,4,4,0,1,1,0,0,7,0,0,0,0,0,0,0,0,7,0,0,1,1,0,5,5,5,5,0,1  ; Ligne 14
        FCB  1,0,0,4,4,0,0,1,1,0,0,7,0,0,0,0,0,0,0,0,7,0,0,1,1,0,0,5,5,0,0,1  ; Ligne 15
        FCB  1,0,0,0,0,0,0,1,1,0,0,7,0,0,0,0,0,0,0,0,7,0,0,1,1,0,0,0,0,0,0,1  ; Ligne 16
        FCB  1,1,1,0,0,1,1,1,1,0,0,7,7,7,0,0,0,0,7,7,7,0,0,1,1,1,1,0,0,1,1,1  ; Ligne 17
        FCB  1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1  ; Ligne 18
        FCB  1,0,0,6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,1  ; Ligne 19
        FCB  1,0,6,6,6,6,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,3,3,3,3,0,1  ; Ligne 20
        FCB  1,0,6,6,6,6,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,3,3,3,3,0,1  ; Ligne 21
        FCB  1,0,0,6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,1  ; Ligne 22
        FCB  1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1  ; Ligne 23
        FCB  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1  ; Ligne 24

        END  START        