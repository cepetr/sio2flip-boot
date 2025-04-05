; ========================================================================
; 
; This file is part of the 8-bit ATAR SIO Emulator for Flipper Zero 
; (https://github.com/cepetr/sio2flip).
; Copyright (c) 2025
; 
; This program is free software: you can redistribute it and/or modify  
; it under the terms of the GNU General Public License as published by  
; the Free Software Foundation, version 3.
;
; This program is distributed in the hope that it will be useful, but 
; WITHOUT ANY WARRANTY; without even the implied warranty of 
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License 
; along with this program. If not, see <http://www.gnu.org/licenses/>.
;
; ========================================================================


            .include "atari.inc"

            .macpack generic
            .macpack longbranch

            CHUNK_SIZE = 1024
            HEADER_SIZE = 4
          
; ========================================================================
            .zeropage

blk_addr:   .word   0
blk_size:   .word   0


; ========================================================================
            .segment "CASHDR"

            .export _cas_hdr

_cas_hdr:   .byte   0
            .byte   ((end - start) + 6 + 127) / 128
            .word   _cas_hdr
            .word   init

; ========================================================================
            .code

start:
            clc                     ; success
            rts

error:                              ; print E character
            lda     #37
            sta     40000
            jmp     error

init:
            lda     #$31            ; set device D1:
            sta     DDEVIC
            lda     #1
            sta     DUNIT
            lda     #5
            sta     DTIMLO

            lda     #$00            ; initialize block index
            sta     DAUX1

read_block:
            lda     #$00            ; initialize chunk index
            sta     DAUX2

            lda     #$F0            ; set command <- 0xF0
            sta     DCOMND

            lda     #<blk_addr      ; set block header address
            sta     DBUFLO
            lda     #>blk_addr
            sta     DBUFHI

            lda     #<HEADER_SIZE   ; set buffer size
            sta     DBYTLO
            lda     #>HEADER_SIZE   
            sta     DBYTHI          

            lda     #$40            ; set direction to read
            sta     DSTATS

            jsr     SIOV            ; receive a header
            jmi     error
            
            lda     #<start        ; set INITAD to do nothing
            sta     INITAD
            lda     #>start
            sta     INITAD + 1
            lda     #<start        ; set INITAD to do nothing
            sta     RUNAD
            lda     #>start
            sta     RUNAD + 1


read_chunk:
            lda     #<CHUNK_SIZE    ; calculate chunk size
            sta     DBYTLO          
            sub     blk_size
            lda     #>CHUNK_SIZE
            sta     DBYTHI
            sbc     blk_size + 1

            bcc     copy_full       ; full sized chunk?

            lda     blk_size        ; just few bytes left
            sta     DBYTLO
            lda     blk_size + 1
            sta     DBYTHI

copy_full:
            lda     #$F1            ; set command <- 0xF1
            sta     DCOMND
            lda     blk_addr        ; set buffer address
            sta     DBUFLO
            lda     blk_addr + 1
            sta     DBUFHI
            lda     #$40            ; set direction to read
            sta     DSTATS

            jsr     SIOV            ; receive a chunk of data
            jmi     error

            inc     DAUX2           ; increment chunk index

            lda     blk_addr        ; advance block address
            add     DBYTLO
            sta     blk_addr
            lda     blk_addr + 1
            adc     DBYTHI
            sta     blk_addr + 1

            lda     blk_size        ; adjust remaining block size
            sub     DBYTLO
            sta     blk_size
            lda     blk_size + 1
            sbc     DBYTHI
            sta     blk_size + 1

            cmp     #0
            jne     read_chunk      ; read next chunk if not done
            lda     blk_size
            cmp     #0
            jne     read_chunk

            jsr     init_block
            jsr     run_block

            inc     DAUX1           ; increment block index

            jmp     read_block      ; read next block

init_block:
            jmp     (INITAD)

run_block:
            jmp     (RUNAD)

rts_addr:
            rts

end:
