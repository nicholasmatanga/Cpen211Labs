/*sum:
.double 0.0

my_ArrayA:
.fill 35000,4,  0x00000000

 my_ArrayB:
 .fill 35000,4, 0x00000000

 my_ArrayC:
 .fill 35000,4
 */

 sum:
.double 0.0

my_ArrayA:
.double 1.1
.double 1.2
.double 1.3
.double 2.1
.double 2.2
.double 2.3
.double 3.1
.double 3.2
.double 3.3


my_ArrayB:
.double 1.1
.double 1.2
.double 1.3
.double 2.1
.double 2.2
.double 2.3
.double 3.1
.double 3.2
.double 3.3


my_ArrayC:
.fill 20,4


.text
.global _start
_start:

BL CONFIG_VIRTUAL_MEMORY
// Step 1-3: configure PMN0 to count cycles
MOV R0, #0                     // Write 0 into R0 then PMSELR
MCR p15, 0, R0, c9, c12, 5     // Write 0 into PMSELR selects PMN0
MOV R1, #0x11                  // Event 0x11 is CPU cycles
MCR p15, 0, R1, c9, c13, 1     // Write 0x11 into PMXEVTYPER (PMN0 measure CPU cycles)

MOV R0, #1
MCR p15, 0, R0, c9, c12, 5     //selects PMN1
MOV R1, #0x6                   //this is for counting the number of load instructions executed
MCR p15, 0, R1, c9, c13, 1 

MOV R0, #2
MCR p15, 0, R0, c9, c12, 5     //selects PMN2
MOV R1, #0x3                   //this is for L1 data cache misses
MCR p15, 0, R1, c9, c13, 1 


// Step 4: enable PMN0, and PMN1, and PMN2

mov R0, #7                  
MCR p15, 0, R0, c9, c12, 1    

// Step 5: clear all counters and start counters

mov r0, #3                     // bits 0 (start counters) and 1 (reset counters)
MCR p15, 0, r0, c9, c12, 0     // Setting PMCR to 3

// Step 6: code we wish to profile using hardware counters

LDR R5,=my_ArrayA
LDR R6,=my_ArrayB
LDR R9,=my_ArrayC
MOV R0, #3 //value of N

MOV R1, #0 // variable i

L_first:
MOV R2, #0 //varible j
L_second:
LDR R3,=sum //address of sum
.word 0xED930B00

MOV R4, #0 //variable k
L_third:

MUL R7,R1,R0
ADD R7,R7,R4
MOV R7,R7,LSL#3
ADD R7,R5,R7
.word 0xED971B00     // LDR of A[i][k]
MUL R8,R4,R0
ADD R8,R8,R2
MOV R8,R8,LSL#3
ADD R8,R6,R8
.word 0xED982B00     //LDR of B[k][j]
.word 0xEE213B02     //multiplication instruction
.word 0xEE300B03     //addition instruction
ADD R4,R4,#1        //k++
CMP R4,R0
BLT L_third
MUL R10,R1,R0
ADD R10,R10,R2
MOV R10,R10,LSL#3
ADD R10,R10,R9
.word 0xED8A0B00
ADD R2,R2,#1
CMP R2,R0
BLT L_second

ADD R1,R1,#1
CMP R1,R0
BLT L_first

 //Step 7: stop counters
mov r0, #0
MCR p15, 0, r0, c9, c12, 0    // Write 0 to PMCR to stop counters

//read and write to registers

mov r0, #0                     // PMN0
MCR p15, 0, R0, c9, c12, 5     // Write 0 to PMSELR
MRC p15, 0, R3, c9, c13, 2     // Read PMXEVCNTR into R3

mov r0, #1                     // PMN1
MCR p15, 0, R0, c9, c12, 5     // Write 1 to PMSELR
MRC p15, 0, R4, c9, c13, 2     // Read PMXEVCNTR into R4

mov r0, #2                     // PMN2
MCR p15, 0, R0, c9, c12, 5     // Write 2 to PMSELR
MRC p15, 0, R5, c9, c13, 2     // Read PMXEVCNTR into R5



end: b end // wait here





