; RehaShMS - A single-screen demo for the SEGA Master System
; /Mic, 2009

.DEFINE XPMP_RAM_START $D000

.DEFINE SPRDATA $CF00
.DEFINE SCRSIN  $CD00
.DEFINE BITMAP  $CB00
.DEFINE XLUT_RAM $CA00
.DEFINE YLUT_RAM $C900

.DEFINE USE_STARFIELD
.DEFINE CALC_STARFIELD_ON_THE_FLY

.DEFINE CUBEY 78

.ENUM $C000
text_color db
delta db
pixel db 
tile db
sqrt db
twirl db
updateMusic db
flipflop db
scrollX dw
scL dw
STRPTR dw
curr_str db
counter1 db
counter3 db
counter4 db
barcol db
cnt1 dw
cnt2 dw
cnt3 dw
counter5 db
cnt4 dw
counter6 db
counter7 db
cnt5 dw
counter8 db
cnt6 dw
counter9 db
counter10 db
counter11 db
copper1 db
copper2 db
copper3 db
copofs1 db
copofs2 db
copofs3 db
copdlt1 db
copdlt2 db
copdlt3 db
speed db
newlirq db
linenum db
copcol1 db
hscroll db
framecnt db
.ENDE

.memorymap
    defaultslot 0
    slotsize $4000
    slot 0 0
.endme

.rombanksize $4000
.rombanks 1


.bank 0 
.orga $0000

.include "smsvdp.inc"

.macro draw_ball
    ld a,(counter5)
    add a,<(xylut + 2048 + \1*256)
    ld e,a
    ld a,>(xylut + 2048 + \1*256)
    adc a,0
    ld d,a
    ld a,(de)
    add a,CUBEY
    ld (SPRDATA + 30 + \1),a
    ld a,d
    sub 8
    ld d,a
    ld a,(de)
    ld b,a
    ld a,(counter7)
    add a,b
    ld (SPRDATA + 124 + \1*2),a
    ld a,252-156
    ld (SPRDATA + 125 + \1*2),a
.endm
 
 
di
im  1
ld  sp,$dff0        ; Initialize stack pointer
jp  main


; IRQ handler
.orga $0038
    jp  irq_handler


; NMI handler
.orga $0066
    retn


main:
    ; Reset scrolling
    VDP_SETREG 8,0
    VDP_SETREG 9,0

    ; Set nametable base address to $0800
    VDP_SETREG 2,14 ;8

    ld  ix,pattern_data
    ld  de,pattern_end-pattern_data
    ld  hl,$2000
    call lzss_decode_vram

    ; Set color data
    VDP_SETCRAMADR $00
    ld  hl,palette
    ld  b,30
    ld  c,VDP_DATA
    otir

    ld  ix,sprites_pattern
    ld  de,sprites_end-sprites_pattern
    ld  hl,$0000
    call lzss_decode_vram

    ld  hl,SCRSIN
    ld  de,sin2562
    ld  b,0
    -:
        ld  a,(de)
        ld  (hl),a
        inc hl
        inc de
        dec b
        jr  nz,-

    ld  hl,SPRDATA
    ld  a,$CF
    ld  b,0
    clear_sprdata:
        ld  (hl),a
        inc hl
        dec b
        jr  nz,clear_sprdata

    ; Clear sprite Y coordinates
    VDP_SETVRAMADR $3F00
    ld  hl,SPRDATA
    ld  b,64
    ld  c,VDP_DATA
    otir

    ; Clear the nametable
    VDP_SETVRAMADR $3800
    ld  de,$100
    ld  bc,$0100
    clear_nt:
        ld  a,c
        out (VDP_DATA),a
        ld  a,b
        out (VDP_DATA),a
        dec e
        jr  nz,clear_nt
        dec d
        jr  nz,clear_nt

    ld  de,$0720
    ld  bc,$019C
    clear_nt2:
        ld  a,c
        out (VDP_DATA),a
        ld  a,b
        out (VDP_DATA),a
        dec e
        jr  nz,clear_nt2
        inc c
        ld  e,$20
        dec d
        jr  nz,clear_nt2

    ld  de,$D20
    ld  bc,$019B
    clear_nt3:
        .IFDEF USE_STARFIELD
        in  a,(H_COUNTER)
        ld  c,a
        in  a,(V_COUNTER)
        add a,c
        ld  c,a
        in  a,(VDP_CTRL)
        add a,c
        xor e
        and 7
        add a,$A4
        .ELSE
        ld  a,c
        ld  b,0
        .ENDIF
        out (VDP_DATA),a
        ld  a,b
        out (VDP_DATA),a
        dec e
        jr  nz,clear_nt3
        ld  e,$20
        dec d
        jr  nz,clear_nt3

    VDP_SETVRAMADR $1360
    ld  d,32
    ld  a,$FF
    copy_pat2:
        out (VDP_DATA),a
        dec d
        jr  nz,copy_pat2

    VDP_SETVRAMADR $1FC0
    ld  b,64
    ld  c,VDP_DATA
    ld  hl,dither
    otir

    ; Display SMSPOWER logo
    ld  hl,$3846
    ld  b,6
    ld  d,0
    yloop:
        ld  c,26
        ld  a,l
        out (VDP_CTRL),a
        ld  a,h
        or  $40
        out (VDP_CTRL),a
        xloop:
            ld  a,d
            cp  155
            jr  z,+
            ld  a,d
            out (VDP_DATA),a
            ld  a,1
            out (VDP_DATA),a
            +:
            inc d
            inc hl
            inc hl
            dec c
            jr  nz,xloop
        ld  a,l
        add a,12
        ld  l,a
        ld  a,h
        adc a,0
        ld  h,a
        dec b
        jr  nz,yloop

    ; Set the line counter reload value to 0
    VDP_SETREG 10,0

    ; Enable the screen (mode 4 / 224 lines), vblank irqs
    VDP_SETREG 0,$34   ;$C4
    VDP_SETREG 1,$60
    VDP_SETREG 3,$FF
    VDP_SETREG 4,$07
    VDP_SETREG 7,$00

    VDP_SETREG 5,$FF
    VDP_SETREG 6,$03


    ld  hl,$00FF
    ld  (scrollX),hl
    ld  a,0
    ld  (curr_str),a
    ld  (counter4),a
    ld  (counter9),a
    ld  (newlirq),a
    ld  (copcol1),a
    ld  (linenum),a
    ld  (hscroll),a
    ld  a,40
    ld  (counter3),a
    ld  hl,szMessage
    ld  (STRPTR),hl
    ld  a,$24
    ld  (barcol),a
    ld  a,1
    ld  (speed),a
    ld  (copdlt1),a
    ld  a,2
    ld  (copdlt2),a
    ld  a,3
    ld  (copdlt2),a


    ; Initialize the music player
    ld  hl,xpmp_song_tbl
    ld  a,1         ; Play the first song
    call xpmp_init

    ld  a,0
    ld  (updateMusic),a

    ei              ; Enable interrupts

    forever:
        check_vblank:
        ld  a,(updateMusic)
        cp  0
        jp  z,wait_irq
        ld  a,0
        ld  (updateMusic),a

        .IFDEF USE_STARFIELD
        .IFNDEF CALC_STARFIELD_ON_THE_FLY
        ld  d,118
        ld  e,74
        update_starfield:
            ld  a,d
            ld  l,a
            ld  h,$CB
            ld  b,(hl)
            and 3
            xor $FF
            add a,b
            ld  (hl),a
            inc d
            dec e
            jr  nz,update_starfield
        .ENDIF
        .ENDIF

        call scroller

        ld  a,(counter6)
        add a,<sincub
        ld  l,a
        ld  a,>sincub
        adc a,0
        ld  h,a
        ld  a,(hl)
        ld  (counter7),a

        ld  a,(counter5)
        ld  c,a
        draw_ball 0
        draw_ball 1
        draw_ball 2
        draw_ball 3
        draw_ball 4
        draw_ball 5
        draw_ball 6
        draw_ball 7

        ld  a,(counter6)
        inc a
        ld  (counter6),a

        ld  a,(counter5)
        ld  b,a
        ld  a,(speed)
        add a,b
        ld  (counter5),a

        ld  a,(counter9)
        dec a
        ld  (counter9),a
        cp  0
        jr  nz,nospeedchg
        ld  a,128
        ld  (counter9),a
        ld  a,(counter8)
        inc a
        and 31
        ld  (counter8),a
        add a,<spin
        ld  l,a
        ld  a,>spin
        adc a,0
        ld  h,a
        ld  a,(hl)
        ld  (speed),a
        nospeedchg:

        wait_irq:
        halt            ; Sit and wait for interrupts
        jp  forever




irq_handler:
    push af

    ; Check if the vblank bit is set
    in  a,(VDP_CTRL)
    bit 7,a
    jp  z,line_irq

    push bc
    push de
    push hl

    call xpmp_update

    ld  a,(flipflop)
    xor 1
    and 1
    ld  (flipflop),a
    cp  1
    jr  z,notwirl
    ld  a,(twirl)
    inc a
    ld  (twirl),a
notwirl:
    ; Cycle text color
    ld 	a,(counter3)
    dec a
    ld 	(counter3),a
    cp  0
    jr  nz,c3nz
    ld  a,50
    ld  (counter3),a
    ld  a,(counter4)
    add a,2
    cp  12
    jr  nz,c4ok
    ld  a,0
c4ok:
    ld  (counter4),a
    add a,a
    add a,<colcycle
    ld  e,a
    ld  a,>colcycle
    adc a,0
    ld  d,a
    VDP_SETCRAMADR $11
    ld  a,(de)
    out ($BE),a
    inc de
    ld  a,(de)
    out ($BE),a
    ld  a,$3F
    out ($BE),a
c3nz:

    ; Copy sprite Y coordinates
    VDP_SETVRAMADR $3F00
    ld  hl,SPRDATA
    ld  b,64
    ld  c,VDP_DATA
    otir

    ; Copy sprite X coordinates and tile IDs
    VDP_SETVRAMADR $3F80
    ld  hl,SPRDATA+64
    ld  b,92
    otir

    ; Update volume bars
    ld  a,33
    ld  (SPRDATA + 38 + 0),a
    ld  (SPRDATA + 38 + 2),a
    ld  (SPRDATA + 38 + 4),a
    ld  (SPRDATA + 38 + 6),a
    ld  a,41
    ld  (SPRDATA + 38 + 1),a
    ld  (SPRDATA + 38 + 3),a
    ld  (SPRDATA + 38 + 5),a
    ld  (SPRDATA + 38 + 7),a
    ld  a,12
    ld  (SPRDATA + 140 + 0),a
    ld  (SPRDATA + 140 + 2),a
    ld  a,21
    ld  (SPRDATA + 140 + 4),a
    ld  (SPRDATA + 140 + 6),a
    ld  a,235
    ld  (SPRDATA + 140 + 8),a
    ld  (SPRDATA + 140 + 10),a
    ld  a,244
    ld  (SPRDATA + 140 + 12),a
    ld  (SPRDATA + 140 + 14),a
    ld  a,(xpmp_channel0.volume)
    add a,a
    add a,100
    ld  (SPRDATA + 140 + 1),a
    inc a
    ld  (SPRDATA + 140 + 3),a
    ld  a,(xpmp_channel1.volume)
    add a,a
    add a,100
    ld  (SPRDATA + 140 + 5),a
    inc a
    ld  (SPRDATA + 140 + 7),a
    ld  a,(xpmp_channel2.volume)
    add a,a
    add a,100
    ld  (SPRDATA + 140 + 9),a
    inc a
    ld  (SPRDATA + 140 + 11),a
    ld  a,(xpmp_channel3.volume)
    add a,a
    add a,100
    ld  (SPRDATA + 140 + 13),a
    inc a
    ld  (SPRDATA + 140 + 15),a

    ld  a,1
    ld  (updateMusic),a

    jp  irq_handler_done


line_irq:
    in  a,(V_COUNTER)
    cp  200
    jr  nc,irq_handler_done_2

    push bc
    ld  c,a

    cp  40
    jr  nc,noscroll
    push de
    ld  a,(twirl)
    add a,c
    and $3F
    add a,<sin_64_12
    ld  e,a
    ld  a,>sin_64_12
    adc a,0
    ld  d,a
    ld  a,(de)
    out (VDP_CTRL),a
    ld  a,$88
    out (VDP_CTRL),a
    pop de
    pop bc
    pop af
    ei
    reti

noscroll:
    cp  117
    jr  c,noscroll2
    cp  192
    jr  nc,irq_handler_done_3
    .IFDEF USE_STARFIELD
    .IFDEF CALC_STARFIELD_ON_THE_FLY
    push hl
    ld  l,a
    ld  h,$CB
    ld  b,(hl)
    and 3
    xor $FF
    add a,b
    ld  (hl),a
    out (VDP_CTRL),a
    ld  a,$88
    out (VDP_CTRL),a
    pop hl
    pop bc
    pop af
    ei
    reti
    .ELSE
    push de
    ld  e,a
    ld  d,$CB
    ld a,(de)
    out (VDP_CTRL),a
    ld  a,$88
    out (VDP_CTRL),a
    pop de
    pop bc
    pop af
    ei
    reti
    .ENDIF
    .ENDIF

    noscroll2:
    VDP_SETREG 8,0
    pop bc
    pop af
    ei
    reti
        
    irq_handler_done:
    pop hl
    pop de
    irq_handler_done_3:
    pop bc
    irq_handler_done_2:
    pop af
    ei
    reti



;------------------------
;  Handle sine scroller
;------------------------
scroller:
    ld  hl,(scrollX)
    ld  bc,(STRPTR)
    ld  ix,SPRDATA
    ld  iy,SPRDATA+64
    ld  de,SCRSIN

scr_loop:
    ld  a,(bc)
    inc bc
    cp  0
    jr  z,scr_done

    sub 32
    jr  z,not_visible
    ld  (iy+1),a

    bit 0,h
    jr  nz,not_visible

    ld  e,l
    ld  (iy+0),l
    ld  a,(de)
    ld  (ix+0),a
    jr  visible

not_visible:
    ld  (iy+0),$CF
    ld  (ix+0),$CF

visible:
    ; Update horizontal position. I use 9 pixels between each character.
    ld  a,l
    add a,9
    ld  l,a
    ld  a,h
    adc a,0
    ld  h,a

    inc ix
    inc iy
    inc iy

    jr 	scr_loop
scr_done:

    ; "Move" the scroller one pixel left
    ld  hl,(scrollX)
    dec hl
    ld  (scrollX),hl

    ; Check if we've reached the final position of the current string
    ld  a,h
    cp  $FF
    jr  nz,no_str_change

    ld  a,(curr_str)
    add a,<strstop
    ld  e,a
    ld  a,>strstop
    adc a,0
    ld  d,a
    ld  a,(de)
    cp  l
    jr  nz,no_str_change

    ld  a,(curr_str)
    inc a
    cp  13
    jr  nz,not_maxxed
    ld  a,0
not_maxxed:
    ld  (curr_str),a
    add a,a
    add a,<strtable
    ld  e,a
    ld  a,>strtable
    adc a,0
    ld  d,a
    ld  a,(de)
    ld  (STRPTR),a
    inc de
    ld  a,(de)
    ld  (STRPTR+1),a

    ld  hl,$00FF
    ld  (scrollX),hl
no_str_change:
    ret


colcycle:
.db $25,$3A, $21,$32, $26,$3B, $12,$23, $16,$2B, $06,$0B, $1A,$2F, $09,$0E
.db $19,$2E, $18,$2C, $29,$3E, $24,$38


; Rotation speeds for the cube
spin:
    .db 1,2,1,2,3,4,3,2,1,4,4,3,2,1,-1,1
    .db -1,-2,-4,-2,-3,2,3,2,1,2,1,-1,1,2,1,1


; Skip to next string when the current position is $FFnn, where
; nn comes from this table
strstop:
    .db 20,3,40,52, 90,60,60,5, 1,10,60,30, 194

szMessage: 
    .db "            mic presents:"
     .db 0
szMessage2:
    .db "The SMSPOWER 2009 compo demo"
    .db 0
szMessage3:
    .db "'RehaShMS'"
    .db 0
szMessage4:
    .db "This is actually a port"
    .db 0
szMessage5:
    .db "of an old NES intro"
    .db 0
szMessage6:
    .db "that I wrote in 2005 :P "
    .db 0
szMessage7:
    .db "I composed a new tune.. "
    .db 0
szMessage8:
    .db "changed the logo.. "
    .db 0
szMessage9:
    .db "rewrote the code obviously :P"
    .db 0
szMessage10:
    .db "I think it turned out ok.."
    .db 0
szMessage11:
    .db "for a fastprod :P"
    .db 0
szMessage12:
    .db "Happy birthday SMSPOWER "
    .db 0
szMessage13:
    .db "<WRAP>"
    .db 0


strtable:
    .dw szMessage
    .dw szMessage2
    .dw szMessage3
    .dw szMessage4
    .dw szMessage5
    .dw szMessage6
    .dw szMessage7
    .dw szMessage8
    .dw szMessage9
    .dw szMessage10
    .dw szMessage11
    .dw szMessage12
    .dw szMessage13


.include "lzss_decode.asm"

; Include the song data
.include "resources/smsmusic.asm"

; Include the music player
.include "xpmp_sms.asm"

pattern_data:
    .incbin "resources/bg.lzs"
pattern_end:

sprites_pattern:
    .incbin "resources/sprites.lzs"
sprites_end:

palette:
    .db $00,$20,$20,$30,$35,$3A,$3F,$14,$28,$38,$24,$15,$2A,$29,$3E,$00
    .db $00,$10,$20,$30,$21,$22,$37,$3B,$3F,$3B,$3B,$3B,$3B,$3B
    
dither:
.db 0,$44,0,$44
.db 0,$22,0,$22
.db 0,$44,0,$44
.db 0,$22,0,$22
.db 0,$44,0,$44
.db 0,$22,0,$22
.db 0,$44,0,$44
.db 0,$22,0,$22
.db 0,$AA,0,$AA
.db 0,$55,0,$55
.db 0,$AA,0,$AA
.db 0,$55,0,$55
.db 0,$AA,0,$AA
.db 0,$55,0,$55
.db 0,$AA,0,$AA
.db 0,$55,0,$55



; Used for moving the cube horizontally
sincub:
    .db 128,129,130,132,133,135,136,138,139,141,142,144,145,146,148,149
    .db 150,152,153,154,156,157,158,160,161,162,163,164,166,167,168,169
    .db 170,171,172,173,174,175,176,177,177,178,179,180,180,181,182,182
    .db 183,183,184,184,185,185,186,186,186,187,187,187,187,187,187,187
    .db 187,187,187,187,187,187,187,187,186,186,186,185,185,184,184,183
    .db 183,182,182,181,180,180,179,178,177,177,176,175,174,173,172,171
    .db 170,169,168,167,166,164,163,162,161,160,158,157,156,154,153,152
    .db 150,149,148,146,145,144,142,141,139,138,136,135,133,132,130,129
    .db 128,126,125,123,122,120,119,117,116,114,113,111,110,109,107,106
    .db 105,103,102,101,99,98,97,95,94,93,92,91,89,88,87,86
    .db 85,84,83,82,81,80,79,78,78,77,76,75,75,74,73,73
    .db 72,72,71,71,70,70,69,69,69,68,68,68,68,68,68,68
    .db 68,68,68,68,68,68,68,68,69,69,69,70,70,71,71,72
    .db 72,73,73,74,75,75,76,77,78,78,79,80,81,82,83,84
    .db 85,86,87,88,89,91,92,93,94,95,97,98,99,101,102,103
    .db 105,106,107,109,110,111,113,114,116,117,119,120,122,123,125,126


sin2562:
    .db 145,145,146,147,148,148,149,150,151,151,152,153,153,154,155,156
    .db 156,157,158,158,159,160,160,161,162,162,163,164,164,165,165,166
    .db 166,167,167,168,168,169,169,170,170,171,171,171,172,172,173,173
    .db 173,173,174,174,174,174,175,175,175,175,175,175,175,175,175,175
    .db 176,175,175,175,175,175,175,175,175,175,175,174,174,174,174,173
    .db 173,173,173,172,172,171,171,171,170,170,169,169,168,168,167,167
    .db 166,166,165,165,164,164,163,162,162,161,160,160,159,158,158,157
    .db 156,156,155,154,153,153,152,151,151,150,149,148,148,147,146,145
    .db 145,144,143,142,141,141,140,139,138,138,137,136,136,135,134,133
    .db 133,132,131,131,130,129,129,128,127,127,126,125,125,124,124,123
    .db 123,122,122,121,121,120,120,119,119,118,118,118,117,117,116,116
    .db 116,116,115,115,115,115,114,114,114,114,114,114,114,114,114,114
    .db 114,114,114,114,114,114,114,114,114,114,114,115,115,115,115,116
    .db 116,116,116,117,117,118,118,118,119,119,120,120,121,121,122,122
    .db 123,123,124,124,125,125,126,127,127,128,129,129,130,131,131,132
    .db 133,133,134,135,136,136,137,138,138,139,140,141,141,142,143,144


; Look-up tables for the cube..
xylut:
    .incbin "resources/cubexy.bin"


; Distortion table for the logo
sin_64_12:
.db 1,1,2,2,3,3,4,4,5,5,6,6,5,5,5,6
.db 6,6,6,5,5,4,4,5,5,6,6,5,5,4,4,3
.db 3,2,2,1,1,2,2,3,3,3,2,2,1,1,1,2
.db 2,2,3,3,3,3,2,2,2,1,1,1,1,2,2,2


rom_title:
.db "RehaShMS"
.db 0

.orga $3fe0
.db "SDSC"
.db $00         ; Major ver
.db $01         ; Minor ver
.db $30         ; Day
.db $03         ; Month
.db $09, $20    ; Year

.orga $3fec
.dw rom_title
.db $FF,$FF     ; Release notes pointer

.orga $3ffe
.dw 0