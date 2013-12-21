# SipHash Core #

(This repo has been moved from Gitorious.)

## Introduction ##

This is an implementation of the SipHash [1] keyed hash function in MOS
6502 assembler.

The purpose of the implementation is mainly to investigate how well the
SipHash function can be implemented on small 8-bit processors with few
registers and no support for 64-bit operations.


## Usage ##

Simply load the key into the key registers k0 and k1, load the message
block into m and then call compress for each block. Complete message
processing by calling finalization. The resulting message digest will be
in the v0 register.


## Implementation notes ## 

The complete code for SipHash requires 677 Bytes. Of these 407 comprises
the SipHash round operation. The SipHash function uses 103 Bytes for
data structurs. This inludes storage for key and message block.

The current implementation is neiter optimized for high speed nor
compact size. There are several possiblities to make the implementation
faster. Alternatively, by changing the macros into subroutines that are
reused, the implemenation could be much smaller. This version is just a
proof of concept.

The current implement performs SipHash compression in 4750 cycles or
about 520 cycles/Byte. Total number of cycles for a single block message
is about 15000 cycles.


## TODOs ##

* Create a compact version.

* Create a high speed version.

* Calculate block processing in number of cycles.

* Measure actual block processing time.


## References ##

[1] J-P. Aumasson, D. J. Bernstein. SipHash: a fast short-input PRF.

  - SipHash Project: https://131002.net/siphash/
  - Siphash Paper: https://131002.net/siphash/siphash.pdf        


