; =============================================
; Raycasting ultra optimisé TO8/TO9 
; Version: 1.1
; Date: 2025-01-21 15:57
; Auteur: tmattern
; =============================================

; Constantes
VIDEO_MEM   EQU  $0000  ; Adresse mémoire vidéo (RAMA $0000-$1FFF)
RAMB_BASE   EQU  $2000  ; Adresse RAMB ($2000-$3FFF)
SCREEN_W    EQU  160    ; Largeur en mode 160x200
SCREEN_H    EQU  200    ; Hauteur écran
SCREEN_SIZE EQU  8000   ; 160x200/4 car chaque banque contient la moitié des pixels
MAP_W       EQU  32     ; Largeur map
MAP_H       EQU  24     ; Hauteur map
CENTER_Y    EQU  100    ; Centre vertical écran
RENDER_W    EQU  128    ; Largeur de la fenêtre de rendu
RENDER_X    EQU  32     ; Position X du début du rendu (160-128=32)
CENTER_X    EQU  64     ; Centre horizontal de la fenêtre de rendu (128/2)
; Constantes pour la mini-map
MAP_DISP_W  EQU  32     ; Largeur en pixels de la mini-map
MAP_DISP_H  EQU  48     ; Hauteur en pixels de la mini-map (24*2)

        ORG  $A000
        LBRA  START     ; Saut vers le code principal

; --------------- MAP 32x24 ---------------
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

; --------------- VARIABLES ---------------
        ALIGN 256
; Variables page directe (avec DP=$A4)
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

; Variables pour le code auto-modifiant
SKY_CODE    RMB  2      ; Code pour le ciel
WALL_CODE   RMB  2      ; Code pour le mur 
FLOOR_CODE  RMB  2      ; Code pour le sol
SKY_ADDR    RMB  2      ; Adresse pour le ciel
WALL_ADDR   RMB  2      ; Adresse pour le mur
FLOOR_ADDR  RMB  2      ; Adresse pour le sol

; Tables et buffers 
MAP_LINES   RMB  48     ; 24 pointeurs lignes map
OFFS_8      RMB  8      ; Table offsets 8 pixels


            ALIGN 256                ; Aligné sur 256 octets pour optimisation
CODE_GEN_BUFFER
        ; 8 lignes * 5 octets par instruction = 40 octets min par buffer
        RMB  40                 ; Buffer pour le ciel
        RMB  40                 ; Buffer pour le mur
        RMB  40                 ; Buffer pour le sol
CODE_SKY    EQU  CODE_GEN_BUFFER
CODE_WALL   EQU  CODE_GEN_BUFFER+40
CODE_FLOOR  EQU  CODE_GEN_BUFFER+80


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
        
        ; Position départ joueur
        LDD  #$1000    ; X=16.0
        STD  <PLAYERX
        LDD  #$0C00    ; Y=12.0
        STD  <PLAYERY
        CLRA
        STA  <ANGLE    ; Angle=0
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
        STA  <CURR_COL  ; Débute colonne 0

COL     ; Pour chaque colonne de la fenêtre de rendu
        JSR  CALC_RAY   ; Calcule direction rayon
        JSR  RAYCAST    ; Lance rayon
        JSR  DRAW_COL   ; Dessine colonne
        
        INC  <CURR_COL
        LDA  <CURR_COL
        CMPA #RENDER_W  ; Compare avec 128 au lieu de 160
        BNE  COL
        RTS

CALC_RAY
        LDA  <CURR_COL
        SUBA #CENTER_X  ; Centre de la fenêtre de rendu (64) au lieu de 80
        ASRA           ; /2 pour FOV
        ADDA <ANGLE    ; + angle joueur
        STA  <TEMP     ; Sauvegarde angle
        
        LDX  #SINTAB
        LDA  A,X        ; sin(angle)
        STA  <DELTAY
        
        LDX  #COSTAB
        LDA  <TEMP      ; Récupère angle
        LDA  A,X        ; cos(angle)
        STA  <DELTAX
        RTS

; Raycasting DDA optimisé
RAYCAST
        ; Init pointeur map
        LDA  <MAPY
        LSLA
        LDX  #MAP_LINES
        LDX  A,X
        LDB  <MAPX
        ABX
        STX  <MAP_PTR

        ; Init deltas
        LDA  <DELTAX
        BPL  POSX
        LDA  #-1
        STA  <STEPX
        NEGB
        BRA  SAVEX
POSX    
        LDA  #1
        STA  <STEPX
SAVEX   
        STB  <SIDEX+1
        CLRA
        STA  <SIDEX

        LDA  <DELTAY
        BPL  POSY
        LDA  #-1
        STA  <STEPY
        NEGB
        BRA  SAVEY
POSY    
        LDA  #1
        STA  <STEPY
SAVEY   
        STB  <SIDEY+1
        CLRA
        STA  <SIDEY

; Boucle DDA ultra optimisée
DDA_LOOP    
        LDD  <SIDEX
        CMPD <SIDEY
        BHS  DO_STEPY      ; Si SIDEX >= SIDEY, on va en Y

DO_STEPX                   ; Cas par défaut : on avance en X
        LDX  <MAP_PTR
        LEAX STEPX,X
        STX  <MAP_PTR
        LDA  ,X
        BNE  HITHORZ
        LDD  <SIDEX
        ADDD <DELTAX
        STD  <SIDEX
        BRA  DDA_LOOP

DO_STEPY   
        LDX  <MAP_PTR
        LDA  <STEPY
        BPL  UP
DOWN    
        LEAX -MAP_W,X
        BRA  SAVEY2
UP      
        LEAX MAP_W,X
SAVEY2  
        STX  <MAP_PTR
        LDA  ,X
        BNE  HITVERT
        LDD  <SIDEY
        ADDD <DELTAY
        STD  <SIDEY
        BRA  DDA_LOOP

HITHORZ
        LDD  <SIDEX
        CLR  <SIDE
        BRA  CALC_DIST
HITVERT
        LDD  <SIDEY
        LDA  #1
        STA  <SIDE
CALC_DIST    
        STD  <DIST

        ; Calcul hauteur optimisé
        LDA  #100
        LDB  <DIST+1
        MUL
        STA  <HEIGHT
        RTS

DRAW_COL
        ; Init pointeur écran
        LDA  <CURR_COL
        ADDA #RENDER_X  ; Ajoute offset pour alignement à droite (32)
        LSRA           ; Divise par 4 car 4 pixels par octet
        LSRA           ; (2 LSRA au lieu d'un)
        LDX  #VIDEO_MEM 
        LEAX A,X       ; X pointe maintenant sur le bon octet

        ; Test position du pixel dans l'octet (0-3)
        LDA  <CURR_COL
        ADDA #RENDER_X  ; Réajoute offset
        ANDA #3        ; Modulo 4 pour savoir quel pixel dans l'octet
        CMPA #2        ; Compare avec 2 pour savoir si RAMA ou RAMB
        BHS  PREP_RAMB ; Si >= 2 alors RAMB

        ; RAMA (pixels 0 et 1)
        CMPA #1        ; Test si pixel 0 ou 1
        BNE  PREP_RAMA_HIGH

PREP_RAMA_LOW        ; Pixel 1 (poids faible)
        STX  <COL_PTR
        LDD  #$F6A7    ; LDA pour poids faible
        BRA  PREP_DONE
        
PREP_RAMA_HIGH      ; Pixel 0 (poids fort)
        STX  <COL_PTR
        LDD  #$B6A7    ; LDA pour poids fort
        BRA  PREP_DONE

PREP_RAMB          ; RAMB (pixels 2 et 3)
        PSHS X
        TFR  X,D
        ADDD #RAMB_BASE-VIDEO_MEM
        TFR  D,X
        STX  <COL_PTR
        PULS X
        
        CMPA #3        ; Test si pixel 2 ou 3
        BEQ  PREP_RAMB_LOW

PREP_RAMB_HIGH     ; Pixel 2 (poids fort)
        LDD  #$B6A7    ; LDA pour poids fort
        BRA  PREP_DONE

PREP_RAMB_LOW      ; Pixel 3 (poids faible)
        LDD  #$F6A7    ; LDA pour poids faible

PREP_DONE
        STD  SKY_CODE
        STD  WALL_CODE
        STD  FLOOR_CODE

        ; Met à jour le pointeur colonne
        LDX  <COL_PTR
        STX  SKY_ADDR
        STX  WALL_ADDR
        STX  FLOOR_ADDR

        ; Génère directement le code ici 
        LDX  #CODE_SKY   
        LDY  #OFFS_8    
        LDB  #8         

DRAW_GEN_LOOP
        ; Copie le code LDA/LDB de base
        LDD  SKY_CODE    
        STD  ,X          

        ; Ajoute l'offset
        LDA  ,Y+         
        STA  2,X         

        ; Détermine le masque selon la position
        LDA  <CURR_COL
        ADDA #RENDER_X
        ANDA #3         
        ANDA #1         
        BNE  DRAW_GEN_LOW

DRAW_GEN_HIGH
        LDA  #$F0       
        BRA  DRAW_GEN_MASK

DRAW_GEN_LOW
        LDA  #$0F       

DRAW_GEN_MASK
        STA  4,X        

        LEAX 5,X        
        DECB
        BNE  DRAW_GEN_LOOP

        ; Continue avec le dessin du ciel
        LDA  <HEIGHT
        NEGA
        ADDA #CENTER_Y
        LSRA
        LSRA
        LSRA
        STA  <BLOCKS
        BEQ  WALL

SKY     
        JSR  CODE_SKY
        LDX  SKY_ADDR
        LEAX 40,X        ; +40 octets = ligne suivante
        STX  SKY_ADDR
        DEC  <BLOCKS
        BNE  SKY

; Dessine mur
WALL    
        LDA  <HEIGHT     ; Hauteur totale du mur
        LSRA            ; Divise par 8 pour avoir nombre de blocs
        LSRA
        LSRA
        STA  <BLOCKS     ; Sauvegarde nombre de blocs de 8 pixels
        BEQ  REMAIN      ; Si pas de blocs complets, va aux pixels restants

WALL8   
        JSR  CODE_WALL   ; Dessine bloc de 8 pixels
        LDX  WALL_ADDR
        LEAX 40,X        ; Passe à la ligne suivante (+40 octets)
        STX  WALL_ADDR
        DEC  <BLOCKS
        BNE  WALL8

        ; Gère les pixels restants (0-7)
REMAIN  
        LDA  <HEIGHT
        ANDA #7          ; Garde les 3 bits de poids faible (reste division par 8)
        BEQ  FLOOR       ; Si pas de pixels restants, passe au sol
        STA  <BLOCKS     ; Nombre de pixels individuels à dessiner

WALL1   
        JSR  CODE_WALL   ; Dessine pixel individuel
        LDX  WALL_ADDR   
        LEAX 40,X        ; Ligne suivante
        STX  WALL_ADDR
        DEC  <BLOCKS
        BNE  WALL1

FLOOR   
        JSR  CODE_FLOOR
        LDX  FLOOR_ADDR
        LEAX 40,X        ; +40 octets = ligne suivante
        STX  FLOOR_ADDR
        CMPX #VIDEO_MEM+8000 ; Fin de l'écran
        BLO  FLOOR

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
        LDA  <PLAYERY    ; En big-endian, la partie entière est dans le premier octet
        LDB  #80         ; 40 octets par ligne x 2
        MUL
        LEAU D,U        ; Ajoute à l'adresse de base
        
        ; Calcul offset X
        LDA  <PLAYERX    ; Position X
        LSRA            ; Divise par 4 car 4 pixels par octet
        LSRA
        LEAU A,U        ; Ajoute à l'adresse de base
        
        ; Détermine le pixel dans l'octet
        LDA  <PLAYERX    
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
        CLR  $E7DB      ; Désactive la palette

        ; Boucle d'initialisation des 16 couleurs
        LDB  #$0F       ; Commence par la couleur 15
VI_PAL_LOOP
        STB  $E7DA      ; Sélectionne l'index de couleur (0-15)
        LDX  #PALETTE   ; Charge l'adresse de base de la palette
        LDA  B,X        ; Charge RG depuis PALETTE+B
        STA  $E7DB      ; Écrit RG
        LDX  #PALETTE+16 ; Charge l'adresse de la partie bleue
        LDA  B,X        ; Charge B depuis PALETTE+16+B
        STA  $E7DB      ; Écrit B
        DECB            ; Couleur suivante
        BPL  VI_PAL_LOOP ; Continue jusqu'à ce que B devienne négatif

        ; Active la palette
        LDA  #$39
        STA  $E7DB

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
        ; Format: 16 octets RG suivis de 16 octets B
        ; RG - Bits 7-4: Rouge, Bits 3-0: Vert
        FCB  $00        ; 0: Noir
        FCB  $44        ; 1: Rouge foncé pour murs lointains
        FCB  $66        ; 2: Rouge moyen
        FCB  $88        ; 3: Rouge vif pour murs proches
        FCB  $AA        ; 4: Rouge très vif
        FCB  $03        ; 5: Vert foncé pour sol lointain
        FCB  $05        ; 6: Vert moyen pour sol
        FCB  $07        ; 7: Vert clair pour sol proche
        FCB  $22        ; 8: Gris très foncé pour plafond
        FCB  $44        ; 9: Gris foncé pour plafond
        FCB  $66        ; 10: Gris moyen pour plafond
        FCB  $88        ; 11: Gris clair pour plafond
        FCB  $FF        ; 12: Blanc
        FCB  $F0        ; 13: Rouge clair (UI)
        FCB  $0F        ; 14: Vert clair (UI)
        FCB  $FF        ; 15: Blanc brillant (UI)

        ; Composante Bleue
        FCB  $0         ; 0: Noir
        FCB  $0         ; 1: Pas de bleu (mur lointain)
        FCB  $0         ; 2: Pas de bleu
        FCB  $0         ; 3: Pas de bleu
        FCB  $0         ; 4: Pas de bleu (mur proche)
        FCB  $0         ; 5: Sol lointain
        FCB  $0         ; 6: Sol
        FCB  $0         ; 7: Sol proche
        FCB  $2         ; 8: Plafond très loin
        FCB  $4         ; 9: Plafond loin
        FCB  $6         ; 10: Plafond moyen
        FCB  $8         ; 11: Plafond proche
        FCB  $F         ; 12: Blanc
        FCB  $0         ; 13: UI rouge
        FCB  $0         ; 14: UI vert
        FCB  $F         ; 15: UI blanc

; Table des offsets écran
        ALIGN 256
SCREEN_OFFS
        FDB  0,80,160,240,320,400,480,560,640,720,800
        ; ... généré dynamiquement par INIT_SCREEN_OFFS

; --------------- TABLES ---------------
        ALIGN 256
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

        END  START