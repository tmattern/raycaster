;	SYS vblast_address WITH REG(X)=VARPTR(line_height_array), REG(Y)=PEEK(VARPTR(color_array), REG(U)=PEEK(VARPTR(vblast_target))
                LBRA DRAW_ALL


; constants
SCREEN_HEIGHT   EQU 200      ; const screen height
SCREEN_WIDTH    EQU 128      ; const screen height
SKY_COLOR       EQU 14
SKY_COLOR_HI    EQU SKY_COLOR*16
SKY_COLOR_LO    EQU SKY_COLOR
SKY_COLOR_HL    EQU SKY_COLOR_HI+SKY_COLOR_LO
FLOOR_COLOR     EQU 15
FLOOR_COLOR_HI  EQU FLOOR_COLOR*16
FLOOR_COLOR_LO  EQU FLOOR_COLOR
FLOOR_COLOR_HL  EQU FLOOR_COLOR_HI+FLOOR_COLOR_LO

PLOTVBASE       fdb $0000, $0028, $0050, $0078, $00A0, $00C8, $00F0, $0118, $0140, $0168
                fdb $0190, $01B8, $01E0, $0208, $0230, $0258, $0280, $02A8, $02D0, $02F8
                fdb $0320, $0348, $0370, $0398, $03C0, $03E8, $0410, $0438, $0460, $0488
                fdb $04B0, $04D8, $0500, $0528, $0550, $0578, $05A0, $05C8, $05F0, $0618
                fdb $0640, $0668, $0690, $06B8, $06E0, $0708, $0730, $0758, $0780, $07A8
                fdb $07D0, $07F8, $0820, $0848, $0870, $0898, $08C0, $08E8, $0910, $0938
                fdb $0960, $0988, $09B0, $09D8, $0A00, $0A28, $0A50, $0A78, $0AA0, $0AC8
                fdb $0AF0, $0B18, $0B40, $0B68, $0B90, $0BB8, $0BE0, $0C08, $0C30, $0C58
                fdb $0C80, $0CA8, $0CD0, $0CF8, $0D20, $0D48, $0D70, $0D98, $0DC0, $0DE8
                fdb $0E10, $0E38, $0E60, $0E88, $0EB0, $0ED8, $0F00, $0F28, $0F50, $0F78
                fdb $0FA0, $0FC8, $0FF0, $1018, $1040, $1068, $1090, $10B8, $10E0, $1108
                fdb $1130, $1158, $1180, $11A8, $11D0, $11F8, $1220, $1248, $1270, $1298
                fdb $12C0, $12E8, $1310, $1338, $1360, $1388, $13B0, $13D8, $1400, $1428
                fdb $1450, $1478, $14A0, $14C8, $14F0, $1518, $1540, $1568, $1590, $15B8
                fdb $15E0, $1608, $1630, $1658, $1680, $16A8, $16D0, $16F8, $1720, $1748
                fdb $1770, $1798, $17C0, $17E8, $1810, $1838, $1860, $1888, $18B0, $18D8
                fdb $1900, $1928, $1950, $1978, $19A0, $19C8, $19F0, $1A18, $1A40, $1A68
                fdb $1A90, $1AB8, $1AE0, $1B08, $1B30, $1B58, $1B80, $1BA8, $1BD0, $1BF8
                fdb $1C20, $1C48, $1C70, $1C98, $1CC0, $1CE8, $1D10, $1D38, $1D60, $1D88
                fdb $1DB0, $1DD8, $1E00, $1E28, $1E50, $1E78, $1EA0, $1EC8, $1EF0, $1F18


; input
HEIGHT_ARRAY    FDB $0000    ; const line height array pointer
COLOR_ARRAY     FDB $0000    ; const line color array pointer
SCREEN_START    FDB $4008    ; const screen pointer

; variables
HEIGHT_ARRAY_P  FDB $0000
HEIGHT_ARRAY_P2 FDB $0000
HEIGHT_VAL      FCB $00
COLOR_ARRAY_P   FDB $0000
COLOR_ARRAY_P2  FDB $0000
COLOR_VAL       FCB $00
PREV_SKY_HEIGHT FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                FCB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


                ; activate RAMA or RAMB
                ; pixels 0,1 in RAMA, pixels 2,3 in RAMB
DRAW_ALL        PSHS A,B,X,Y,U
                STX HEIGHT_ARRAY,PCR             ; backup param bbb
                STY COLOR_ARRAY,PCR              ; backup param
                STU SCREEN_START,PCR             ; backup param

RAMA            LDA $E7C3
                ORA #01
                STA $E7C3
LOOP_EVEN_INIT  LDB #0
LOOP_EVEN       BSR DRAW_COL       ; (B: col id)
                ADDB #4
                CMPB #SCREEN_WIDTH
                BLO LOOP_EVEN

RAMB            LDA $E7C3
                ANDA #$FE
                STA $E7C3
LOOP_ODD_INIT   LDB #2
LOOP_ODD        BSR DRAW_COL       ; (B: col id)
                ADDB #4
                CMPB #SCREEN_WIDTH+2
                BLO LOOP_ODD

DRAW_ALL_END    PULS U,Y,X,B,A,PC         ; cleanup and RTS

                
                ; input:
                ;   B: col_id

                ; compare current column with previous frame
                ; 
DRAW_COL        PSHS A,B,X,Y
                LDX HEIGHT_ARRAY,PCR
                ABX
                LEAU ,X

                LDX COLOR_ARRAY,PCR
                ABX
                LEAY ,X

                ; compute first pixel address   4 pixels per octet => base_address + col_id / 4
                LDX SCREEN_START,PCR

                LSRB                    ; divide col_id by 4
                LSRB
                ABX                     ; X contains the address of the first column pixel

                ; check if the height of row1 is higher than the height of row2
                LDB ,U
                CMPB 1,U
                BLO DRAW_COL_H2

DRAW_COL_H1     ; segment 1 : count = sky_height=middle - line_height1, color = sky, sky

                LDB #SCREEN_HEIGHT
                LSRB                    ; middle = screen_height / 2
                SUBB ,U
                PSHS B                  ; backup B

                LDA 2,S                 ; get column id

                PSHS Y                  ; backup Y
                LEAY PREV_SKY_HEIGHT,PCR
                LEAY A,Y
                CMPB ,Y                 ; compare B with previous sky height
                BHI SKY_H1_HI
SKY_H1_LS       BSR VBLAST_SKIP         ; skip current height
                BRA STORE_SKY_H1    
SKY_H1_HI       LDB ,Y                  ; skip previous sky height
                BSR VBLAST_SKIP         ; 
                LDB 2,S                 ; restore B, and draw remaining pixels
                SUBB ,Y
                PSHS B                  ; backup B, reuse it in segment 5 
                LDA #SKY_COLOR_HL
                BSR VBLAST
STORE_SKY_H1    STB ,Y                  ; store sky height
                PULS Y                  ; restore Y

                ; segment 2 : count = line_height1 - line_height2, color = color1, sky
                LDB ,U
                SUBB 1,U
                LDA ,Y
                LSLA                     ; color pixel1 * 16
                LSLA
                LSLA
                LSLA
                ADDA #SKY_COLOR_LO
                PSHS A,B                 ; backup A, B
                BSR VBLAST

                ; segment 3 : count = line_height2 * 2, color = color1, color2
                LDB 1,U
                LSLB                    ; line_height2 * 2
                ANDA #$F0
                ADDA 1,Y
                BSR VBLAST            

                ; segment 4 : count = line_height1 - line_height2, color = color1, floor
                PULS A,B                 ; restore A, B saved during segment2
                ANDA #$F0
                ADDA #FLOOR_COLOR_LO
                BSR VBLAST

                ; segment 5 : count = count = sky_height=middle - line_height1, color = floor, floor
                PULS B
                LDA #FLOOR_COLOR_HL
                BSR VBLAST
                PULS B                  ; skip 
                BRA DRAW_COL_END

DRAW_COL_H2     ; segment 1 : count = sky_height=middle - line_height2, color = sky, sky
                LDB #SCREEN_HEIGHT
                LSRB                    ; middle = screen_height / 2
                SUBB 1,U
                PSHS B                  ; backup B
                LDA #SKY_COLOR_HL
                BSR VBLAST

                ; segment 2 : count = line_height2 - line_height1, color = sky, color2
                LDB 1,U
                SUBB ,U
                LDA 1,Y
                ADDA #SKY_COLOR_HI
                PSHS B                 ; backup B
                BSR VBLAST

                ; segment 3 : count = line_height1 * 2, color = color1, color2
                LDB ,U
                LSLB                    ; line_height2 * 2
                LDA ,Y
                LSLA                    ; color pixel1 * 16
                LSLA
                LSLA
                LSLA
                ADDA 1,Y
                BSR VBLAST

                ; segment 4 : count = line_height1 - line_height2, color = color1, floor
                PULS B                  ; restore B saved during segment2
                LDA 1,Y
                ADDA #FLOOR_COLOR_HI
                BSR VBLAST

                ; segment 5 : count = count = sky_height=middle - line_height2, color = floor, floor
                PULS B                  ; restore B saved during segment1
                LDA #FLOOR_COLOR_HL
                BSR VBLAST

DRAW_COL_END    PULS A,B,X,Y, PC  ; cleanup and RTS

VBLAST_SKIP     ; input:
                ;   B: count
                ;   X: target address
                ; output:
                ;   X: next target address
                PSHS U, B, A
                CLRA
                LDB 1,S                ; table index = pixel count * 2
                LSLB
                LEAU PLOTVBASE,PCR     ; table base address
                LDD D,U                ; get offset from table  (using D because addressing offset is signed)
                LEAX D,X               ; add offset to X 

                PULS A, B, U, PC       ; cleanup and RTS

VBLAST          ; input:
                ;   B: count
                ;   A: data
                ;   X: target address
                ; output:
                ;   X: next target address

                PSHS U, B, A
                CLRA                   ; compute LBRA target (4 bytes per pixel, 100 pixels max)
                                       ; target=(100-pixel count) * 4
                NEGB                   ; D=100-pixel count
                ADDB #100
                LSLB                   ; multiply D by 4 (each STA $xxxx takes 4 bytes)
                ROLA
                LSLB
                ROLA
                STD VBLAST_GOTO+1,PCR    ; self modifying code : rewrite LBRA target

                LDA ,S                 ; get vblast_byte
VBLAST_GOTO     LBRA $8000             ; fake 16bits value, dynamically replaced by computed target
VBLAST_PIXELS   STA 3960,X
                STA 3920,X
                STA 3880,X
                STA 3840,X
                STA 3800,X
                STA 3760,X
                STA 3720,X
                STA 3680,X
                STA 3640,X
                STA 3600,X
                STA 3560,X
                STA 3520,X
                STA 3480,X
                STA 3440,X
                STA 3400,X
                STA 3360,X
                STA 3320,X
                STA 3280,X
                STA 3240,X
                STA 3200,X
                STA 3160,X
                STA 3120,X
                STA 3080,X
                STA 3040,X
                STA 3000,X
                STA 2960,X
                STA 2920,X
                STA 2880,X
                STA 2840,X
                STA 2800,X
                STA 2760,X
                STA 2720,X
                STA 2680,X
                STA 2640,X
                STA 2600,X
                STA 2560,X
                STA 2520,X
                STA 2480,X
                STA 2440,X
                STA 2400,X
                STA 2360,X
                STA 2320,X
                STA 2280,X
                STA 2240,X
                STA 2200,X
                STA 2160,X
                STA 2120,X
                STA 2080,X
                STA 2040,X
                STA 2000,X
                STA 1960,X
                STA 1920,X
                STA 1880,X
                STA 1840,X
                STA 1800,X
                STA 1760,X
                STA 1720,X
                STA 1680,X
                STA 1640,X
                STA 1600,X
                STA 1560,X
                STA 1520,X
                STA 1480,X
                STA 1440,X
                STA 1400,X
                STA 1360,X
                STA 1320,X
                STA 1280,X
                STA 1240,X
                STA 1200,X
                STA 1160,X
                STA 1120,X
                STA 1080,X
                STA 1040,X
                STA 1000,X
                STA 960,X
                STA 920,X
                STA 880,X
                STA 840,X
                STA 800,X
                STA 760,X
                STA 720,X
                STA 680,X
                STA 640,X
                STA 600,X
                STA 560,X
                STA 520,X
                STA 480,X
                STA 440,X
                STA 400,X
                STA 360,X
                STA 320,X
                STA 280,X
                STA 240,X
                STA 200,X
                STA 160,X
                STA >120,X             ; force 16 bits increment
                STA >80,X              ; force 16 bits increment
                STA >40,X              ; force 16 bits increment
                STA >0,X               ; force 16 bits increment

                CLRA
                LDB 1,S                ; table index = pixel count * 2
                LSLB
                LEAU PLOTVBASE,PCR     ; table base address
                LDD D,U                ; get offset from table  (using D because addressing offset is signed)
                LEAX D,X               ; add offset to X 

                PULS U, B, A, PC       ; cleanup and RTS

                END