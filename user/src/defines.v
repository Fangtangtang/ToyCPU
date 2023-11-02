// defines for readability

// boolen
`define     TRUE                1'b1
`define     FALSE               1'b0

// sign bit
`define     ZERO                2'b00
`define     POS                 2'b01
`define     NEG                 2'b11

// branch flag
`define     NOTBRANCH           2'b00
`define     CONDBRANCH          2'b01
`define     UNCONDBRANCH        2'b10

// define for inst decode

// inst[6:0]
`define     LUI                 7'b0110111
`define     AUIPC               7'b0010111
`define     JAL                 7'b1101111
`define     JALR                7'b1100111

`define     BRANCH              7'b1100011
`define     LOAD                7'b0000011
`define     STORE               7'b0100011
`define     IMM                 7'b0010011
`define     BINARY              7'b0110011

// inst[30,14:12]

// BRANCH:
// only inst[14:12] matters, set first bit 0
`define     BEQ                 4'b0000
`define     BNE                 4'b0001
`define     BLT                 4'b0100
`define     BGE                 4'b0101
`define     BLTU                4'b0110
`define     BGEU                4'b0111

// LOAD
// only inst[14:12] matters, set first bit 0
`define     LB                  4'b0000
`define     LH                  4'b0001
`define     LW                  4'b0010
`define     LBU                 4'b0100
`define     LHU                 4'b0101

// STORE
// only inst[14:12] matters, set first bit 0
`define     SB                  4'b0000
`define     SH                  4'b0001
`define     SW                  4'b0010

// IMM
`define     ADDI                4'b0000
`define     SLTI                4'b0010
// todo:...


// BINARY
`define     ADD                 4'b0000
// todo:...

// STAGE STATE

// ex stage state
`define     NONEEXE             3'b000
`define     BRANCHCOND          3'b001
`define     MEMADDR             3'b010
`define     IMMEXPR             3'b011
`define     BINARYEXPR          3'b100
`define     PCBASED             3'b101
`define     IMMONLY             3'b110

`define     NONE                2'b00
// mem stage state
`define     READ                2'b01
`define     WRITE               2'b10
`define     BR                  2'b11

// wb stage state
`define     NPC                 2'b01
`define     MEM2REG             2'b10
`define     ARI                 2'b11

