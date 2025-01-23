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

DC_COLOR    RMB  1      ; Couleur de la colonne (0-15)
DC_POS      RMB  1      ; Position dans le groupe de 4 pixels
DC_PIX_VAL  RMB  1      ; Valeur de l'octet à écrire (masque + couleur)
DC_PIX_MSK  RMB  1      ; Masque pour préserver les autres pixels
DC_END_ADR  RMB  2      ; Adresse de fin selon RAMA/RAMB


; Tables et buffers 
MAP_LINES   RMB  48     ; 24 pointeurs lignes map
OFFS_8      RMB  8      ; Table offsets 8 pixels



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
        SUBA #CENTER_X  ; Centre de la fenêtre
        ASRA           ; /2 pour FOV
        ADDA <ANGLE    ; + angle joueur
        STA  <TEMP     ; Sauvegarde angle
        
        ; DELTAY = sin(angle) en format 8.8
        LDX  #SINTAB
        LDA  A,X       ; A = sin(angle) = partie entière
        STA  <DELTAY   ; Partie entière
        CLRB           ; B = 0 = partie fractionnaire
        STB  <DELTAY+1
        
        ; DELTAX = cos(angle) en format 8.8
        LDX  #COSTAB
        LDA  <TEMP     ; Récupère angle
        LDA  A,X       ; A = cos(angle) = partie entière
        STA  <DELTAX   ; Partie entière
        CLRB           ; B = 0 = partie fractionnaire
        STB  <DELTAX+1
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
        ; Pour DELTAX/DELTAY:
        ; - Octet haut (A) = partie entière (valeur de sin/cos)
        ; - Octet bas (B) = partie fractionnaire (0 dans notre cas)
        
        LDA  <DELTAX
        BPL  POSX
        LDA  #-1        ; STEPX = -1
        STA  <STEPX
        ; Négation 16 bits pour le delta
        LDD  <DELTAX    ; D = partie_entiere.partie_fract
        COMA            ; Inverse les bits de A
        COMB            ; Inverse les bits de B
        ADDD #1        ; +1 pour compléter la négation
        BRA  SAVEX
POSX    
        LDA  #1         ; STEPX = 1
        STA  <STEPX
        LDD  <DELTAX    ; Charge tel quel
SAVEX   
        STD  <SIDEX     ; Sauvegarde en format 8.8

        LDA  <DELTAY
        BPL  POSY
        LDA  #-1        ; STEPY = -1
        STA  <STEPY
        ; Négation 16 bits pour le delta
        LDD  <DELTAY    ; D = partie_entiere.partie_fract
        COMA            ; Inverse les bits de A
        COMB            ; Inverse les bits de B
        ADDD #1        ; +1 pour compléter la négation
        BRA  SAVEY
POSY    
        LDA  #1         ; STEPY = 1
        STA  <STEPY
        LDD  <DELTAY    ; Charge tel quel
SAVEY   
        STD  <SIDEY     ; Sauvegarde en format 8.8

; Boucle DDA optimisée
DDA_LOOP    
        LDD  <SIDEX
        CMPD <SIDEY    ; Compare les distances en format 8.8
        BHS  DO_STEPY   ; Si SIDEX >= SIDEY, on avance en Y

DO_STEPX                ; Cas par défaut : on avance en X
        LDX  <MAP_PTR
        LEAX STEPX,X    ; Avance dans la direction X
        STX  <MAP_PTR
        LDA  ,X         ; Lit la case
        BNE  HITHORZ    ; Si mur, collision horizontale
        LDD  <SIDEX
        ADDD <DELTAX    ; Ajoute DELTAX (en 8.8)
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
        LDA  ,X         ; Lit la case
        BNE  HITVERT    ; Si mur, collision verticale
        LDD  <SIDEY
        ADDD <DELTAY    ; Ajoute DELTAY (en 8.8)
        STD  <SIDEY
        BRA  DDA_LOOP

HITHORZ
        LDD  <SIDEX     ; Distance en format 8.8
        CLR  <SIDE
        BRA  CALC_DIST
HITVERT
        LDD  <SIDEY     ; Distance en format 8.8
        LDA  #1
        STA  <SIDE

CALC_DIST    
        STD  <DIST         ; Sauvegarde la distance (8.8)

        ; Debug - Affiche DIST sur les 2 premiers pixels
        PSHS D            ; Sauvegarde DIST
        LDX  #VIDEO_MEM
        TFR  A,B          ; Partie entière dans B
        ORB  #$20         ; Vert
        STB  ,X           ; Affiche partie entière en vert
        PULS A,B
        ORB  #$40         ; Rouge
        STB  1,X          ; Affiche partie fractionnaire en rouge
        
        ; Si DIST = 0, force hauteur max
        BNE  DIST_OK
        LDA  #200
        BRA  SAVE_HEIGHT

DIST_OK
        ; Nouvelle méthode de calcul de la hauteur
        ; On ne prend que la partie entière de DIST pour commencer
        LDA  <DIST        ; Partie entière de la distance
        BEQ  FORCE_MAX    ; Si 0, force maximum
        
        ; Calcul HEIGHT = 100 / partie_entiere(DIST)
        LDB  #100         ; Hauteur de base
        ; Division 8 bits de B par A, résultat dans B
        PSHS A            ; Sauvegarde diviseur
        LDA  #0          ; Initialise quotient
        ; Boucle de division 8 bits
DIV_LOOP
        SUBB ,S          ; Soustrait diviseur
        BCS  DIV_END     ; Si carry, fin de division
        INCA             ; Incrémente quotient
        BRA  DIV_LOOP
DIV_END
        PULS B           ; Nettoie la pile
        
        ; A contient maintenant la hauteur
        CMPA #200        ; Compare avec hauteur max
        BHS  FORCE_MAX
        
        ; Debug - Affiche hauteur calculée
        PSHS A
        ORA  #$10        ; Bleu
        STA  2,X         ; Affiche hauteur en bleu
        PULS A
        BRA  SAVE_HEIGHT

FORCE_MAX
        LDA  #200

SAVE_HEIGHT
        STA  <HEIGHT
        RTS
        
; Le code principal
; Dessine une colonne de pixels
; Le code principal
; Dessine une colonne de pixels
DRAW_COL
        ; 1. Calcule l'adresse de base de la colonne (X = CURR_COL + 32)
        LDA  <CURR_COL     ; 0-127
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
        LDA  <HEIGHT
        NEGA
        ADDA #CENTER_Y     ; Hauteur du ciel
        PSHS A             ; Sauve hauteur ciel
        LDA  <HEIGHT       ; Hauteur du mur
        PSHS A             ; Sauve hauteur mur

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