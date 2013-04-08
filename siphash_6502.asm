//======================================================================
//
// siphash_6502.asm
// ----------------
// Implementation of the SipHash_2_4 function in MOS 6502 asembler.
// Why? Because we can.
//
// Build:
// java -jar KickAss.jar siphash_6502.asm
//
//
// Copyright (c) 2013, Secworks Sweden AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

//------------------------------------------------------------------
// Include KickAssembler Basic uppstart code.
//------------------------------------------------------------------
.pc =$0801 "Basic Upstart Program"
:BasicUpstart($4000)

//------------------------------------------------------------------
// SipHash Test
//
// Test of the siphash-2-4 functionality using the two block 
// message in appendix A of the SipHash paper by Aumasson and DJB.
//
// Basically, we load the keys, perform initialization, 
// compression of the two blocks and finalization.
//------------------------------------------------------------------
.pc = $4000 "SipHash Test"
                        :mov64(k0, test_k0)
                        :mov64(k1, test_k1)
                        jsr initialization

                        :mov64(m, m0)
                        jsr compression

                        :mov64(m, m1)
                        jsr compression

                        jsr finalization
                        rts

//------------------------------------------------------------------
// initialization
//
// The initialization function of siphash.
//------------------------------------------------------------------
.pc = $6000 "SipHash Code"
initialization:         :mov64(v0, v0_initval)
                        :mov64(v1, v1_initval)
                        :mov64(v2, v2_initval)
                        :mov64(v3, v3_initval)
                        :xor64(v0, k0)
                        :xor64(v1, k1)
                        :xor64(v2, k0)
                        :xor64(v3, k1)
                        rts

//------------------------------------------------------------------
// compression
//
// The compression funnction of siphash.
//------------------------------------------------------------------
compression:            :xor64(v3, m)
                        jsr siphash_round
                        jsr siphash_round
                        :xor64(v0, m)
                        rts

//------------------------------------------------------------------
// finalization
//
// The finalization funnction of siphash.
//------------------------------------------------------------------
finalization:           :xor64(v2, v2_xor)
                        jsr siphash_round
                        jsr siphash_round
                        jsr siphash_round
                        jsr siphash_round
                        :xor64(v0, v1)
                        :xor64(v0, v2)
                        :xor64(v0, v3)
                        rts

//------------------------------------------------------------------
// siphash_round
//
// Performs one SipHash round using the internal variables v0..v3.
//------------------------------------------------------------------
siphash_round:          :add64(v0, v1)
                        :rol13(v1)
                        :add64(v2, v3)
                        :rol16(v3)
                        
                        :xor64(v1, v0)
                        :rol32(v0)
                        :xor64(v3, v2)

                        :add64(v2, v1)
                        :rol17(v1)
                        :add64(v0, v3)
                        :rol21(v3)

                        :xor64(v1, v2)
                        :rol32(v2)
                        :xor64(v3, v0)
                        rts

//------------------------------------------------------------------
// rol64bits(addr, bits)
// 
// Macro to rotate 64 bit word, bits number of steps.
//
//------------------------------------------------------------------
.macro rol64bits(addr, bits)
{
                        ldy #bits
rol64_1:                lda addr
                        rol
                        rol addr + 7
                        rol addr + 6
                        rol addr + 5
                        rol addr + 4
                        rol addr + 3
                        rol addr + 2
                        rol addr + 1
                        rol addr
                        dey
                        bne rol64_1
}

//------------------------------------------------------------------
// ror64bits(addr, bits)
// 
// Macro to rotate a 64 bit word, bits number of steps right.
//------------------------------------------------------------------
.macro ror64bits(addr, bits)
{
                        ldy #bits
ror64_1:                lda addr + 7
                        ror                 
                        ror addr
                        ror addr + 1
                        ror addr + 2
                        ror addr + 3
                        ror addr + 4
                        ror addr + 5
                        ror addr + 6
                        ror addr + 7
                        dey
                        bne ror64_1
}

//------------------------------------------------------------------
// rol13(addr)
// 
// Macro to rotate a 64 bit word, 13 bits left.
// We do this by moving 16 bits left and then 3 bits right.
// TODO: Implement.
//------------------------------------------------------------------
.macro rol13(addr)
{
                        :rol16(addr)
                        :ror64bits(addr, 3)
}

//------------------------------------------------------------------
// rol16(addr)
// 
// Macro to rotate a 64 bit word, 16 bits left.
// We do this by moving the bytes two steps.
//------------------------------------------------------------------
.macro rol16(addr)
{
                        lda addr
                        sta tmp
                        lda addr + 1
                        sta tmp + 1

                        ldx #$00
rol16_1:                lda addr + 2, x
                        sta addr, x
                        inx
                        cpx #$07
                        bne rol16_1

                        lda tmp
                        sta addr + 6
                        lda tmp + 1
                        sta addr + 7
}

//------------------------------------------------------------------
// rol17(addr)
// 
// Macro to rotate a 64 bit word, 17 bits left.
// We do this by moving 2 bytes left and then rotating 1 bit left.
//------------------------------------------------------------------
.macro rol17(addr)
{
                        :rol16(addr)
                        :rol64bits(addr, 1)
}

//------------------------------------------------------------------
// rol21(addr)
// 
// Macro to rotate a 64 bit word, 21 bits left.
// We do this by moving 3 bytes left and rotating 3 bits right.
//------------------------------------------------------------------
.macro rol21(addr)
{
                        // Move three bytes left.
                        // Using tmp
                        ldx #$02
rol21_1:                lda addr, x
                        sta tmp, x
                        dex
                        bpl rol21_1

                        ldx #$00
rol21_2:                lda addr + 3, x
                        sta addr,x
                        inx
                        cpx #$07
                        bne rol21_2

                        ldx #$02
rol21_3:                lda tmp, x
                        sta addr + 5, x
                        dex
                        bpl rol21_3
                                                
                        :ror64bits(addr, 3)
}

//------------------------------------------------------------------
// rol32(addr)
// 
// Macro to rotate a 64 bit word, 32 bits left.
// We do this by moving 32 bits left via the temp bytes.
//------------------------------------------------------------------
.macro rol32(addr)
{
                        ldx #$03
rol32_1:                lda addr, x
                        sta tmp, x
                        lda addr+4, x
                        sta addr, x
                        lda tmp, x
                        sta addr + 4, x
                        dex
                        bpl rol32_1
}

//------------------------------------------------------------------
// xor64(addr0, addr1)
// 
// Macro to rotate 64 bit word bits number of steps.
//------------------------------------------------------------------
.macro xor64(addr0, addr1)
{
                        ldx #$07
xor64_1:                lda addr0, x
                        eor addr1, x
                        sta addr0, x
                        dex
                        bpl xor64_1
}

//------------------------------------------------------------------
// add64(addr0, addr1)
// 
// Macro to add two 64 bit words. Results in addr0.
//------------------------------------------------------------------
.macro add64(addr0, addr1)
{
                        ldx #$07
                        clc
add64_1:                lda addr0, x
                        adc addr1, x
                        sta addr0, x
                        dex
                        bpl add64_1
}

//------------------------------------------------------------------
// mov64(addr0, addr1)
// 
// Macro to move 64 bit word in addr1 into addr0
//------------------------------------------------------------------
.macro mov64(addr0, addr1)
{
                        ldx #$07
                        clc
mov64_1:                lda addr1, x
                        sta addr0, x
                        dex
                        bpl mov64_1
}

//------------------------------------------------------------------
// SipHash state registers and data fields.
//------------------------------------------------------------------
.pc = $7000 "Siphash State"
v0:          .byte $00, $00, $00, $00, $00, $00, $00, $00
v1:          .byte $00, $00, $00, $00, $00, $00, $00, $00
v2:          .byte $00, $00, $00, $00, $00, $00, $00, $00
v3:          .byte $00, $00, $00, $00, $00, $00, $00, $00

v0_initval:  .byte $73, $6f, $6d, $65, $70, $73, $65, $75
v1_initval:  .byte $64, $6f, $72, $61, $6e, $64, $6f, $6d
v2_initval:  .byte $6c, $79, $67, $65, $6e, $65, $72, $61
v3_initval:  .byte $74, $65, $64, $62, $79, $74, $65, $73

v2_xor:      .byte $00, $00, $00, $00, $00, $00, $00, $ff

tmp:         .byte $00, $00, $00, $00, $00, $00, $00, $00

k0:          .byte $00, $00, $00, $00, $00, $00, $00, $00
k1:          .byte $00, $00, $00, $00, $00, $00, $00, $00

m:           .byte $00, $00, $00, $00, $00, $00, $00, $00


.pc = $8000 "Siphash Test Data"
test_k0:     .byte $07, $06, $05, $04, $03, $02, $01, $00
test_k1:     .byte $0f, $0e, $0d, $0c, $0b, $0a, $09, $08

m0:          .byte $07, $06, $05, $04, $03, $02, $01, $00
m1:          .byte $0f, $0e, $0d, $0c, $0b, $0a, $09, $08

//======================================================================
// EOF siphash_6502.asm
//======================================================================
