; =============================================
; Raycasting ultra optimisé TO8/TO9 
; Version: 1.1
; Date: 2025-01-21 08:27
; Auteur: tmattern
; =============================================

; Constantes
VIDEO_MEM   EQU  $0000  ; Adresse mémoire vidéo (RAMA $0000-$1FFF)
RAMB_BASE   EQU  $2000  ; Adresse RAMB ($2000-$3FFF)
SCREEN_W    EQU  160    ; Largeur en mode 160x200
SCREEN_H    EQU  200    ; Hauteur écran
MAP_W       EQU  32     ; Largeur map
MAP_H       EQU  24     ; Hauteur map
CENTER_Y    EQU  100    ; Centre vertical écran
RENDER_W    EQU  128    ; Largeur de la fenêtre de rendu
RENDER_X    EQU  32     ; Position X du début du rendu (160-128=32)
CENTER_X    EQU  64     ; Centre horizontal de la fenêtre de rendu (128/2)
; Constantes pour la mini-map
MAP_DISP_W  EQU  32     ; Largeur en pixels de la mini-map
MAP_DISP_H  EQU  48     ; Hauteur en pixels de la mini-map (24*2)


; Organisation mémoire à partir de $A000
        ORG  $A000

; Variables page directe (avec DP=$A0)
MAP_PTR     RMB  2      ; $A000-$A001 Pointeur map courant
DIST        RMB  2      ; $A002-$A003 Distance au mur (8.8)
HEIGHT      RMB  1      ; $A004 Hauteur colonne
CURR_COL    RMB  1      ; $A005 Colonne courante
MAPX        RMB  1      ; $A006 Position map X
MAPY        RMB  1      ; $A007 Position map Y
PLAYERX     RMB  2      ; $A008-$A009 Position joueur X (8.8)
PLAYERY     RMB  2      ; $A00A-$A00B Position joueur Y (8.8)
ANGLE       RMB  1      ; $A00C Angle vue (0-255)
STEPX       RMB  1      ; $A00D Direction X (-1/+1)
STEPY       RMB  1      ; $A00E Direction Y (-1/+1)
SIDEX       RMB  2      ; $A00F-$A010 Distance côté X (8.8)
SIDEY       RMB  2      ; $A011-$A012 Distance côté Y (8.8)
DELTAX      RMB  2      ; $A013-$A014 Delta X (8.8)
DELTAY      RMB  2      ; $A015-$A016 Delta Y (8.8)
SIDE        RMB  1      ; $A017 Côté touché (0=X, 1=Y)
BLOCKS      RMB  1      ; $A018 Compteur blocs
COL_PTR     RMB  2      ; $A019-$A01A Pointeur colonne courante
TEMP        RMB  1      ; $A01B Variable temporaire

; Tables et buffers
MAP_LINES   RMB  48     ; $A01C-$A04B 24 pointeurs lignes map
OFFS_8      RMB  8      ; $A04C-$A053 Table offsets 8 pixels
CODE_SKY    RMB  24     ; $A054-$A06B Code auto-modifiant ciel
CODE_WALL   RMB  24     ; $A06C-$A083 Code auto-modifiant mur
CODE_FLOOR  RMB  24     ; $A084-$A09B Code auto-modifiant sol

; Code principal
START   
        ; Init système
        ORCC #$50       ; Désactive interruptions
        
        ; Configure DP=$A0
        LDA  #$A0
        TFR  A,DP
        
        ; Init mode vidéo
        JSR  VIDEO_INIT ; appel init vidéo
        
        JSR  INIT       ; Initialisation
        
MAIN_LOOP
        JSR  RAYCAST_FRAME
        JSR  DRAW_MINIMAP
        BRA  MAIN_LOOP


; Initialisation 
INIT    
        ; Init tables
        JSR  INIT_TABLES
        JSR  INIT_SCREEN_OFFS
        
        ; Position départ joueur
        LDD  #$0800    ; X=8.0
        STD  <PLAYERX
        STD  <PLAYERY  ; Y=8.0
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
        BLO  STEPX

STEPY   
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

STEPX   
        LDX  <MAP_PTR
        LEAX STEPX,X
        STX  <MAP_PTR
        LDA  ,X
        BNE  HITHORZ
        LDD  <SIDEX
        ADDD <DELTAX
        STD  <SIDEX
        BRA  DDA_LOOP

HITHORZ
        LDD  <SIDEX
        CLR  <SIDE
        BRA  DIST
HITVERT
        LDD  <SIDEY
        LDA  #1
        STA  <SIDE
DIST    
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
        ADDA #RENDER_X  ; Ajoute offset pour alignement à droite
        LSRA           ; Divise par 2 car 4 pixels par octet
        LDX  #VIDEO_MEM 
        LEAX A,X       

        ; Test si pixels dans RAMA ou RAMB
        LDA  <CURR_COL
        ANDA #1        ; Test bit 0 de la colonne
        BNE  PREP_ODD

PREP_EVEN             ; Pixels 0,1 dans RAMA
        STX  <COL_PTR  ; Sauvegarde pointeur RAMA
        LDD  #$F6A7    ; LDA high
        BRA  PREP_DONE
        
PREP_ODD              ; Pixels 2,3 dans RAMB
        LEAX RAMB_BASE-VIDEO_MEM,X  ; Ajuste pointeur pour RAMB
        STX  <COL_PTR   ; Sauvegarde pointeur RAMB
        LDD  #$B6A7     ; LDA low

PREP_DONE
        STD  SKY_CODE
        STD  WALL_CODE
        STD  FLOOR_CODE

        ; Génère code 8 pixels
        JSR  GEN_DRAW_CODE

        ; Dessine ciel
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
        LDD  SKY_ADDR
        ADDD #640
        STD  SKY_ADDR
        DEC  <BLOCKS
        BNE  SKY

        ; Dessine mur
WALL    
        LDA  <HEIGHT
        LSRA
        LSRA
        LSRA
        STA  <BLOCKS
        BEQ  REMAIN

WALL8   
        JSR  CODE_WALL
        LDD  WALL_ADDR
        ADDD #640
        STD  WALL_ADDR
        DEC  <BLOCKS
        BNE  WALL8

        ; Pixels restants
REMAIN  
        LDA  <HEIGHT
        ANDA #7
        BEQ  FLOOR
        STA  <BLOCKS

WALL1   
        JSR  WALL_CODE
        LDD  WALL_ADDR
        ADDD #80
        STD  WALL_ADDR
        DEC  <BLOCKS
        BNE  WALL1

        ; Dessine sol
FLOOR   
        JSR  CODE_FLOOR
        LDD  FLOOR_ADDR
        ADDD #640
        STD  FLOOR_ADDR
        CMPD #VIDEO_MEM+16000
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

        LDX  <COL_PTR
        STX  SKY_ADDR
        STX  WALL_ADDR
        STX  FLOOR_ADDR
        RTS

; Routine d'affichage de la mini-map
DRAW_MINIMAP
        ; Pointeur vers début de la map
        LDX  #MAP
        ; Pointeur écran (début de l'écran)
        LDY  #VIDEO_MEM
        
        ; Pour chaque ligne de la map
        LDB  #MAP_H     ; 24 lignes
DMAP_LOOP
        PSHS B          ; Sauve compteur de lignes
        
        ; Pour chaque colonne
        LDA  #MAP_W     ; 32 colonnes
DMAP_COL
        ; Lecture de la valeur de la map
        LDB  ,X+        
        BEQ  DMAP_EMPTY ; Si case vide (0)
        
        ; Case pleine : dessiner un point blanc
        LDB  #$FF       ; Couleur blanche
        BRA  DMAP_DRAW
        
DMAP_EMPTY
        LDB  #$00       ; Case vide en noir
        
DMAP_DRAW
        ; Dessine 2 pixels verticaux
        STB  ,Y         ; Pixel ligne 1
        STB  80,Y       ; Pixel ligne 2 (Y+80)
        
        LEAY 1,Y        ; Pixel suivant
        DECA            ; Décrémente compteur colonnes
        BNE  DMAP_COL   ; Continue si pas fini la ligne
        
        ; Passe à la ligne suivante
        LEAY 80+48,Y    ; Saute une ligne (80) + reste de la ligne (48)
        
        PULS B          ; Récupère compteur de lignes
        DECB            ; Ligne suivante
        BNE  DMAP_LOOP  ; Continue si pas fini toutes les lignes
        
        ; Affiche position joueur
        JSR  DRAW_PLAYER
        RTS

; Routine pour afficher la position du joueur sur la mini-map
DRAW_PLAYER
        ; Calcul position X du joueur sur la mini-map
        LDA  <PLAYERX+1  ; Partie entière de X
        LDX  #VIDEO_MEM
        LEAX A,X        ; X + offset = position horizontale
        
        ; Calcul position Y
        LDA  <PLAYERY+1  ; Partie entière de Y
        LDB  #160       ; Largeur ligne = 80 * 2 (2 pixels de haut)
        MUL             ; D = A * B = Y * 160
        LEAX D,X        ; Ajoute offset vertical
        
        ; Dessine le joueur en rouge
        LDA  #$F0       ; Rouge vif
        STA  ,X         ; Position joueur
        STA  80,X       ; Pixel du dessous
        RTS

VIDEO_INIT
        ; Map video RAM to $0000
        LDA  #%01100000  ; D7=0, D6=1 (écriture autorisée), D5=1 (RAM active), D4-D0=00000 (page 0)
        STA  $E7E6       ; Mappe la page 0 en $0000

        ; Passage en mode bitmap
        LDA  #$7A       ; Mode bitmap 160x200 16 couleurs
        STA  $E7C3      ; Registre mode écran
        
        ; Configuration GATE ARRAY
        LDA  #$00       
        STA  $E7DC      ; Sélection registre 0
        LDA  #$71       ; Mode 160x200, 16 couleurs
        STA  $E7DD      ; Configuration vidéo
        
        ; Initialisation palette 
        LDX  #$E7DA     ; Registre sélection couleur
        LDY  #PALETTE   ; Pointeur sur la palette
        LDB  #16        ; 16 couleurs à initialiser
INIT_PAL_LOOP   
        STB  ,X         ; Sélectionne l'index couleur
        LDD  ,Y++       ; Charge la valeur RGB (2 octets)
        STA  1,X        ; Stocke octet fort (Rouge-Vert)
        STB  1,X        ; Stocke octet faible (Bleu)
        DECB
        BNE  INIT_PAL_LOOP
        RTS

; Palette 16 couleurs pour le raycasting
PALETTE
        FDB  $000       ; 0  Noir (ciel)
        FDB  $444       ; 1  Gris foncé
        FDB  $666       ; 2  Gris
        FDB  $888       ; 3  Gris moyen
        FDB  $AAA       ; 4  Gris clair
        FDB  $CCC       ; 5  Gris très clair
        FDB  $F00       ; 6  Rouge pour murs
        FDB  $0F0       ; 7  Vert pour murs
        FDB  $00F       ; 8  Bleu pour murs
        FDB  $FF0       ; 9  Jaune pour murs
        FDB  $F0F       ; 10 Magenta pour murs
        FDB  $0FF       ; 11 Cyan pour murs
        FDB  $B44       ; 12 Rouge foncé
        FDB  $4B4       ; 13 Vert foncé
        FDB  $44B       ; 14 Bleu foncé
        FDB  $FFF       ; 15 Blanc

; Table des offsets écran
        ALIGN 256
SCREEN_OFFS
        FDB  0,80,160,240,320,400,480,560,640,720,800
        ; ... généré dynamiquement par INIT_SCREEN_OFFS

; --------------- TABLES ---------------
        ORG  $AE00     ; Tables à la fin du programme
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