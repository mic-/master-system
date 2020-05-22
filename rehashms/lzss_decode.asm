; LZSS decoder for SEGA Master System / Game Gear
; /mic, 2009

; The decoder function itself is 175 bytes in size.
; It uses all RAM from $C000..$D007 while executing.


; Note: The base address must be $C000 for the address masking in the decoder to work.
.DEFINE LZSS_RAM_BASE $C000
.DEFINE LZSS_TEXTBUF LZSS_RAM_BASE
.DEFINE LZSS_CNT LZSS_RAM_BASE+4096
.DEFINE LZSS_SIZE LZSS_CNT+2
.DEFINE LZSS_PTR LZSS_SIZE+2
.DEFINE LZSS_CNT2 LZSS_PTR+2
.DEFINE LZSS_TEXTBUF_P 4078
.DEFINE LZSS_THRESHOLD 4


; Function lzss_decode_vram
;
; Decompress LZSS packed data to VRAM
;
; In:
;  IX = Pointer to compressed data
;  DE = Size of compressed data
;  HL = VRAM base address
; Out:
;  -
;
; Example:
;
;  ld ix,packed_patterns
;  ld de,packed_patterns_end-packed_patterns
;  ld hl,$2000
;  call lzss_decode_vram
;
lzss_decode_vram:
    ; Set the VRAM address
    ld  a,l
    out ($BF),a
    ld  a,h
    or  $40
    out ($BF),a

    ld  hl,LZSS_TEXTBUF+LZSS_TEXTBUF_P
    ld  (LZSS_PTR),hl

    ; Set all entries in textbuf to $20	
    ld  hl,LZSS_TEXTBUF
    ld  bc,LZSS_TEXTBUF_P
_ldv_init_textbuf:
    ld  a,$20
    ld  (hl),a
    inc hl
    dec bc
    ld  a,b
    or  c
    jr  nz,_ldv_init_textbuf
    ld  iy,0
    ld  (LZSS_SIZE),de
_ldv_loop:
    push iy
    pop hl
    ld  de,(LZSS_SIZE)
    and a
    sbc hl,de
    jr  nc,_ldv_done    ; We're done if the counter is >= the compressed size
    ld  c,(ix+0)        ; Read one compressed byte
    inc iy              ; Increase loop counter
    inc ix              ; Increase input stream pointer
    ld  a,8             ; 8 flags per byte
    ld  (LZSS_CNT2),a
_ldv_check_flags:
    srl	c               ; Check if the flag is set
    jr  nc,_ldv_flag_clear
    push iy
    pop hl
    ld  de,(LZSS_SIZE)
    and a
    sbc hl,de
    jr  nc,_ldv_done
    ld  a,(ix+0)        ; Read one compressed byte
    inc iy
    inc ix
    ld  b,1             ; Make sure the jr after output_byte isn't taken
    ld  hl,(LZSS_PTR)
    jr  _ldv_output_byte
_ldv_flag_clear:
    push iy
    pop hl
    ld  de,(LZSS_SIZE)
    and a
    sbc hl,de
    jr  nc,_ldv_done
    ld  e,(ix+0)        ; e = idx
    inc ix
    ld  a,(ix+0)        ; a = j
    inc ix
    inc iy
    inc iy
    ld  d,a
    srl d
    srl d
    srl d
    srl d               ; de = ((j & 0xF0) << 4) | idx
    and 15
    add a,LZSS_THRESHOLD
    ld  b,a             ; b = (j & 0x0F) + THRESHOLD
    ld  a,d
    or  $C0             ; de |= $C000
    ld  d,a
    ld  hl,(LZSS_PTR)
    jr  _ldv_next_string_pos
_ldv_copy_string:
    ld  a,(de)          ; Read from textbuf
    push af
    ; Increase read address and wrap at $1000 ($D000)
    inc de
    ld  a,d
    and $CF
    ld  d,a
    pop af
_ldv_output_byte:
    out	($BE),a         ; Write to VRAM
    ld  (hl),a          ; Write to textbuf
    ; Increase write address and wrap at $1000 ($D000)
    inc hl
    ld  a,h
    and $CF
    ld  h,a
_ldv_next_string_pos:
    dec b
    jr  nz,_ldv_copy_string
    ld  (LZSS_PTR),hl
_ldv_next_flag:
    ld  a,(LZSS_CNT2)
    dec a
    ld  (LZSS_CNT2),a
    jp  z,_ldv_loop
    jr  _ldv_check_flags
_ldv_done:
    ret
