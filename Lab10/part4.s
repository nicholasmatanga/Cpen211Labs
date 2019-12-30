.include    "address_map_arm.s" 
.include    "interrupt_ID.s" 

/* ********************************************************************************
 * This program demonstrates use of interrupts with assembly language code.
 * The program responds to interrupts from the pushbutton KEY port in the FPGA.
 *
 * The interrupt service routine for the pushbutton KEYs indicates which KEY has
 * been pressed on the LED display.
 ********************************************************************************/
//this is not the original file and it is just a copy.Original is interrupt_example

.section    .vectors, "ax" 

            B       _start                  // reset vector
            B       SERVICE_UND             // undefined instruction vector
            B       SERVICE_SVC             // software interrrupt vector
            B       SERVICE_ABT_INST        // aborted prefetch vector
            B       SERVICE_ABT_DATA        // aborted data vector
.word       0 // unused vector
            B       SERVICE_IRQ             // IRQ interrupt vector
            B       SERVICE_FIQ             // FIQ interrupt vector




.text        
.global     _start 
_start:                                     
/* Set up stack pointers for IRQ and SVC processor modes */
            MOV     R1, #0b11010010         // interrupts masked, MODE = IRQ
            MSR     CPSR_c, R1              // change to IRQ mode
            LDR     SP, =A9_ONCHIP_END - 3  // set IRQ stack to top of A9 onchip memory
/* Change to SVC (supervisor) mode with interrupts disabled */
            MOV     R1, #0b11010011         // interrupts masked, MODE = SVC
            MSR     CPSR, R1                // change to supervisor mode
            LDR     SP, =DDR_END - 3        // set SVC stack to top of DDR3 memory

            BL      CONFIG_GIC              // configure the ARM generic interrupt controller

                                            // write to the pushbutton KEY interrupt mask register
            LDR     R0, =KEY_BASE           // pushbutton KEY base address
            MOV     R1, #0xF               // set interrupt mask bits
            STR     R1, [R0, #0x8]          // interrupt mask register is (base + 8)

                                            // enable IRQ interrupts in the processor
            MOV     R0, #0b01010011         // IRQ unmasked, MODE = SVC
            MSR     CPSR_c, R0              


			LDR R0, =MPCORE_PRIV_TIMER
			LDR R1, =bignum
			LDR R2, [R1]
			STR R2,[R0]
			MOV R3 ,#7
			STR R3,[R0,#8]

	LDR R0, =JTAG_UART_BASE
	MOV R1, #1
	STR R1,[R0,#4]


IDLE:          

	LDR R1, =CHAR_FLAG
	LDR R2,[R1]

	CMP R2,#1
	BNE IDLE

	LDR R1,=CHAR_BUFFER
	LDR R0,[R1]
	BL PUT_JTAG
	LDR R1,=CHAR_FLAG
	MOV R2,#0
	STR R2,[R1]
	B IDLE

PROC1:
MOV R0,#0 //count
ADD R0,R0,#1
LDR R1,=LEDR_BASE
STR R0,[R1]

MOV R2,#0 //i=0
B INSIDE

INSIDE:
ADD R2,R2,#1
LDR R3,=LARGE_NUMBER
LDR R4,[R3]
CMP R2,R4
BLT INSIDE
BGE PROC1

	
PUT_JTAG: LDR R1, =0xFF201000 // JTAG UART base address
LDR R2, [R1, #4] // read the JTAG UART control register
LDR R3, =0xFFFF
ANDS R2, R2, R3 // check for write space
BEQ END_PUT // if no space, ignore the character
STR R0, [R1] // send the character
	
END_PUT: BX LR
	

	
                         
                             // main program simply idles

/* Define the exception service routines */

/*--- Undefined instructions --------------------------------------------------*/
SERVICE_UND:                                
            B       SERVICE_UND             

/*--- Software interrupts -----------------------------------------------------*/
SERVICE_SVC:                                
            B       SERVICE_SVC             

/*--- Aborted data reads ------------------------------------------------------*/
SERVICE_ABT_DATA:                           
            B       SERVICE_ABT_DATA        

/*--- Aborted instruction fetch -----------------------------------------------*/
SERVICE_ABT_INST:                           
            B       SERVICE_ABT_INST        

/*--- IRQ ---------------------------------------------------------------------*/
SERVICE_IRQ:                                
            PUSH    {R0-R7, LR}             

/* Read the ICCIAR from the CPU interface */
            LDR     R4, =MPCORE_GIC_CPUIF   
            LDR     R5, [R4, #ICCIAR]       // read from ICCIAR
			CMP R5, #29
			BEQ L1
			CMP R5,#80
			BEQ L2

			STOP:B STOP

		     L1:
			LDR R0, =MPCORE_PRIV_TIMER
			MOV R2,#1
			STR R2,[R0,#0xC]
			LDR R0,=CURRENT_PID
			LDR R1,[R0]
			CMP R1,#0
			BEQ L3
			
			MOV R1,#0
			STR R1,[R0]
			
			LDR R0,=PD_ARRAY
			STR R8, [R0, #100]
			STR R9, [R0, #104]
			STR R10, [R0, #108]
			STR R11, [R0, #112]
			STR R12, [R0, #116]
			
			MRS R1, SPSR
			STR R1,[R0,#132]
			
			POP {R0-R7, LR}   
			LDR R8,=PD_ARRAY
			STR R0, [R8, #68]
			STR R1, [R8, #72]
			STR R2, [R8, #76]
			STR R3, [R8, #80]
			STR R4, [R8, #84]
			STR R5, [R8, #88]
			STR R6, [R8, #92]
			STR R7, [R8, #96]
			STR LR, [R8, #128]
			
		    MOV     R1, #0b11010011         // interrupts masked, MODE = SVC
            MSR     CPSR, R1                // change to supervisor mode
          
			STR sp,[R8,#120]
			STR lr,[R8,#124]
			
			LDR sp, [R8, #52]
			LDR lr, [R8, #56]
			
			MOV     R0, #0b01010011         // IRQ unmasked, MODE = SVC
            MSR     CPSR_c, R0    


			LDR R0,[R8,#0]
			LDR R1,[R8,#4]
			LDR R2,[R8,#8]
			LDR R3,[R8,#12]
			LDR R4,[R8,#16]
			LDR R5,[R8,#20]
			LDR R6,[R8,#24]
			LDR R7,[R8,#28]
			LDR R9,[R8,#36]
			LDR R10,[R8,#40]
			LDR R11,[R8,#44]
			LDR R12,[R8,#48]
			STR     R5, [R4, #ICCEOIR] 
			  SUBS    PC, LR, #4    
			
			
			L3:
			MOV R1,#1
			STR R1,[R0]
			
			LDR R0,=PD_ARRAY
			STR R8, [R0, #32]
			STR R9, [R0, #36]
			STR R10, [R0, #40]
			STR R11, [R0, #44]
			STR R12, [R0, #48]
			
			MRS R1, SPSR
			STR R1,[R0,#64]
			
			POP {R0-R7, LR}   
			LDR R8,=PD_ARRAY
			STR R0, [R8, #0]
			STR R1, [R8, #4]
			STR R2, [R8, #8]
			STR R3, [R8, #12]
			STR R4, [R8, #16]
			STR R5, [R8, #20]
			STR R6, [R8, #24]
			STR R7, [R8, #28]
			STR LR, [R8, #60]
			
		    MOV     R1, #0b11010011         // interrupts masked, MODE = SVC
            MSR     CPSR, R1                // change to supervisor mode
          
			STR sp, [R8, #52]
			STR lr, [R8, #56]
			
			LDR sp,[R8,#120]
			LDR lr,[R8,#124]
			
			MOV     R0, #0b01010011         // IRQ unmasked, MODE = SVC
            MSR     CPSR_c, R0    


			LDR R0,[R8,#68]
			LDR R1,[R8,#72]
			LDR R2,[R8,#76]
			LDR R3,[R8,#80]
			LDR R4,[R8,#84]
			LDR R5,[R8,#88]
			LDR R6,[R8,#92]
			LDR R7,[R8,#96]
			LDR R9,[R8,#104]
			LDR R10,[R8,#108]
			LDR R11,[R8,#112]
			LDR R12,[R8,#116]
			 STR     R5, [R4, #ICCEOIR] 
			  SUBS    PC, LR, #4    

			L2:
			LDR R0,=JTAG_UART_BASE
			LDRB R1,[R0]
			LDR R0, =CHAR_BUFFER
			STR R1,[R0]
			MOV R2,#1;
			LDR R0,=CHAR_FLAG
			STR R2,[R0]
			B EXIT_IRQ
			
			
			
			

FPGA_IRQ1_HANDLER:                          
            CMP     R5, #KEYS_IRQ           
UNEXPECTED: BNE     UNEXPECTED              // if not recognized, stop here

            BL      KEY_ISR                 
EXIT_IRQ:                                   
/* Write to the End of Interrupt Register (ICCEOIR) */
            STR     R5, [R4, #ICCEOIR]      // write to ICCEOIR

            POP     {R0-R7, LR}             
            SUBS    PC, LR, #4    
/*--- FIQ ---------------------------------------------------------------------*/
SERVICE_FIQ:                                
            B       SERVICE_FIQ  

CURRENT_PID:
.word 0

LARGE_NUMBER:
.word 1000000000

CHAR_BUFFER:
.word 0

CHAR_FLAG:
.word 0
			
bignum:
.word 100000000

somenum:
.word 0

PD_ARRAY:
.fill 17,4,0xDEADBEEF
.fill 13,4,0xDEADBEE1
.word 0x3F000000 // SP
.word 0 // LR
.word PROC1+4 // PC
.word 0x53 // CPSR (0x53 means IRQ enabled, mode = SVC)


.end         
