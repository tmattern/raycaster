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
; Variables page directe (avec DP=$64)
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
CODE_SKY    RMB  24     ; Code auto-modifiant ciel
CODE_WALL   RMB  24     ; Code auto-modifiant mur
CODE_FLOOR  RMB  24     ; Code auto-modifiant sol

; --------------- CODE PRINCIPAL ---------------
START   
        ; Init système
        ORCC #$50       ; Désactive interruptions
        
        ; Configure DP=$A0
        LDA  #$A0       ; Correct car les variables sont en $A0xx
        TFR  A,DP
        
        ; Init mode vidéo
        JSR  VIDEO_INIT
        
        JSR  INIT       ; Initialisation
        
MAIN_LOOP
        ; JSR  RAYCAST_FRAME
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
        JSR  CODE_WALL
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
        LDA  #$F0       ; Premier pixel blanc (4 bits de poids fort)
        BRA  MM_PIX0_SET
MM_PIX0_EMPTY
        LDA  #$00       ; Premier pixel noir
MM_PIX0_SET
        LDB  ,X+        ; Second pixel
        BEQ  MM_PIX1_EMPTY
        ORB  #$0F       ; Second pixel blanc (4 bits de poids faible)
        BRA  MM_PIX1_SET
MM_PIX1_EMPTY
        ORB  #$00       ; Second pixel noir
MM_PIX1_SET
        PSHS B         ; Sauve second pixel
        ORA  ,S+       ; Combine les deux pixels dans A
        STA  ,U        ; Écrit dans RAMA
        STA  40,U      ; Double ligne en RAMA
        
        ; Prépare l'octet pour RAMB (pixels 2,3)
        LDA  ,X+        ; Troisième pixel
        BEQ  MM_PIX2_EMPTY
        LDA  #$F0       ; Troisième pixel blanc
        BRA  MM_PIX2_SET
MM_PIX2_EMPTY
        LDA  #$00       ; Troisième pixel noir
MM_PIX2_SET
        LDB  ,X+        ; Quatrième pixel
        BEQ  MM_PIX3_EMPTY
        ORB  #$0F       ; Quatrième pixel blanc
        BRA  MM_PIX3_SET
MM_PIX3_EMPTY
        ORB  #$00       ; Quatrième pixel noir
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
        ; Calcul position X du joueur sur la mini-map
        LDA  <PLAYERX+1  ; Partie entière de X
        LDX  #VIDEO_MEM
        LEAX A,X        ; X + offset = position horizontale
        
        ; Calcul position Y
        LDA  <PLAYERY+1  ; Partie entière de Y
        LDB  #160       ; Largeur ligne = 80 * 2 (2 pixels de haut)
        MUL             ; D = A * B = Y * 160
        LEAX D,X        ; Ajoute offset vertical
        
        ; Test si on doit écrire dans RAMA ou RAMB
        TFR  X,D
        ANDB #1
        BEQ  MM_PLAYER_RAMA

MM_PLAYER_RAMB
        ; Position dans RAMB
        TFR  X,D
        ADDD #RAMB_BASE-VIDEO_MEM
        TFR  D,X
        ; Dessine le joueur en rouge (préserve les pixels pairs)
        LDA  ,X
        ANDA #$F0       ; Masque les pixels impairs
        ORA  #$0F       ; Rouge en pixels impairs
        STA  ,X
        LDA  80,X
        ANDA #$F0
        ORA  #$0F
        STA  80,X
        RTS

MM_PLAYER_RAMA
        ; Position dans RAMA
        ; Dessine le joueur en rouge (préserve les pixels impairs)
        LDA  ,X
        ANDA #$0F       ; Masque les pixels pairs
        ORA  #$F0       ; Rouge en pixels pairs
        STA  ,X
        LDA  80,X
        ANDA #$0F
        ORA  #$F0
        STA  80,X
        RTS

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