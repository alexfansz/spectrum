interrupt:
 di              ; 4     4
 push hl         ; 11    15
 push de         ; 11    26
 push bc         ; 11    37
 push af         ; 11    48

 ld bc,538       ; 10    58
loop:            ; contents 26
 dec bc          ; 6     64
 ld a,b          ; 4     68
 or c            ; 4     72
 jr nz,loop      ; 13969 14041

 ld de,fillerdata; 10    14051
 ld a,0          ; 7     14058
 call filler     ; 17    14075

 pop af 
 pop bc 
 pop de 
 pop hl 
 ei
 ret 

fillerdata:
db $0b, $2e, $3e, $2b, $08, $08, $09, $19
db $1b, $2b, $2d, $3d, $3f, $2f, $2d, $1d
db $1b, $0b, $09, $01, $01, $25, $37, $3e
db $2c, $08, $01, $13, $25, $37, $01, $02
db $03, $04, $05, $06, $07, $06, $05, $04
db $03, $02, $01, $07, $35, $23, $11, $00
db $15, $37, $3e, $2a, $03, $03, $1e, $1e
db $37, $37, $3f, $37, $36, $1e, $1b, $03

;; The first line where this routine is relevant is the line 64, but we need
;; to start during line 63, which starts 62*228-24 = 14112 T states after
;; interrupt. The first run from "ld l,h" until "out ($fe),a" takes 183
;; T states and our line is 24+128+24 = 176 T states long, plus we need to do
;; the timing based on the second "out ($fe),a" because that is when contended
;; memory starts The earliest time the second out can happen is 14112+176 =
;; 14288 T states after interrupt, and the latest is 63*228-24 = 14340 T
;; states after interrupt.
;;
;; Because we have 183 T states between the first two out instructions and our
;; first out instruction is 11 T states and our ld instruction is 7 T states,
;; we should start running this routine between 14087 and 14139 T states after
;; interrupt. Handling contended memory makes our routine very unstable and
;; even interrupt handler can vary -+3 T states, so we should aim to the
;; middle, which is 14113 T states.
;;
;; Further runs of this routine should always be exactly 2*228 = 456 T states
;; long, because our handling of contended memory should always add exactly 84
;; extra T states to the loop.
;;
;; On Spectrum +2A and +3 we seem to have problems if the routine starts at
;; 14113 T states, but we can tune it down to 14109 T states and things work
;; much nicer on all 128K platforms, this seems to be a glitch with a
;; different contended memory delay pattern that can be fixed by being early.

genfiller MACRO address, rows
LOCAL _idx
idx DEFL 0
REPT rows
 LOCAL fillloop
 ld b,4
fillloop DEFL $
 out ($fe),a
 ld a,(de)
 ld h,a
 ld l,a
 and %00111000
 rrca
 rrca
 rrca
 inc de
 nop
 ld (address+idx*$20+$00),hl
 ld (address+idx*$20+$02),hl
 ld (address+idx*$20+$04),hl
 ld (address+idx*$20+$06),hl
 ld (address+idx*$20+$08),hl
 ld (address+idx*$20+$0A),hl
 ld (address+idx*$20+$0C),hl
 ld (address+idx*$20+$0E),hl
 out ($fe),a
 ld (address+idx*$20+$10),hl
 ld (address+idx*$20+$12),hl
 ld (address+idx*$20+$14),hl
 ld (address+idx*$20+$16),hl
 ld (address+idx*$20+$18),hl
 ld (address+idx*$20+$1A),hl
 ld (address+idx*$20+$1C),hl
 ld (address+idx*$20+$1E),hl
 nop
 nop
 nop
 nop
 ld a,l 
 and %00000111
 dec b
 jr z,$+4       ; if zero, then 12 T states
 jr fillloop    ; otherwise 12+7 T states
idx DEFL idx + 1
ENDM
 ld b,0
 out ($fe),a    ; last line, nothing to do
 ld b,15
 djnz $
 nop
 nop
 nop
 nop
 xor a
 out ($fe),a    ; change border back to black
ENDM

org $a000
filler:
 genfiller $5800, 16
 ret
