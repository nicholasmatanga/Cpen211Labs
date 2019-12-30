module cpu(clk,reset,in,out,N,V,Z,mem_cmd,mem_addr,halt);
input clk, reset;
////??????
input [15:0] in;
output[15:0] out;
output[1:0] mem_cmd;
output[8:0] mem_addr;

output N, V, Z;



//Instruction Register
wire [15:0]reg_out;
//Instruction Decoder
wire [2:0] opcode;
wire [1:0] op;
wire [1:0]ALUop;
wire [15:0] sximm5;
wire [15:0] sximm8;

wire [2:0] readnum,writenum;
//inside instruction decoder
wire [4:0] imm5;
wire [7:0] imm8;
wire [2:0] Rm,Rd,Rn;
//State_machine
wire [2:0] nsel;
wire [5:0] present_state;
// datapath
wire [2:0]Z_out;
wire [3:0]vsel;
wire loada,loadb,asel,bsel,loadc,loads,loadir,loadpc,resetpc,addr_sel,load_addr,writefsm;
wire[8:0] addr_out;
wire [8:0] PC;
wire [2:0] cond;
output halt;
wire funcpc;
wire returnsig;
reg [1:0] shift;
//for instruction register
load_enable   #(16)  uo(in, reg_out, clk, loadir);

//for instruction Decoder
assign {opcode,op} = reg_out[15:11];////??????
assign ALUop =reg_out [12:11];

assign imm5 = reg_out[4:0];
assign imm8 = reg_out[7:0];
assign sximm5={ {11{imm5[4]}},imm5 };////????????
assign sximm8={ {8{imm8[7]}},imm8 };////????????
assign Rm=reg_out[2:0];

always@(*) begin
if((opcode==3'b011)|(opcode==3'b100))begin
shift=2'b00;
end else begin
shift=reg_out[4:3];
end

end



assign {Rn,Rd} = reg_out[10:5]; ///??????
assign cond=reg_out[10:8];


assign readnum=(Rm&{3{nsel[2]}}) | //3-input,3-bit multiplexer
              (Rd&{3{nsel[1]}}) |
              (Rn&{3{nsel[0]}}) ;  ///???????

assign writenum=(Rm&{3{nsel[2]}}) | //3-input,3-bit multiplexer
              (Rd&{3{nsel[1]}}) |
              (Rn&{3{nsel[0]}}) ;  ///???????

//for state machine

state_machine FSM(clk,reset,opcode,op,vsel,nsel,loada,loadb,loadc,loads,asel,bsel,writefsm,loadir,loadpc,resetpc,addr_sel,mem_cmd,load_addr,halt,funcpc,returnsig); 


//for datapath


 datapath DP(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, writefsm, out,
                 in,sximm8,PC,sximm5,Z_out);


assign N=Z_out[1];
assign V=Z_out[2];
assign Z=Z_out[0];

Counter1 ProgramCounter(opcode,op,cond,N,V,Z,sximm8[8:0],clk, resetpc, PC, loadpc,funcpc,out[8:0],returnsig);
MUX9b addr(PC, addr_out, addr_sel, mem_addr);

load_enable #(9) dataaddress(out[8:0],addr_out,clk,load_addr);

endmodule 

//state machine module

`define Reset     6'b000000
`define if1       6'b000001
`define if2       6'b000010
`define UpdatePC  6'b000011
`define Decode    6'b000100

`define GetA      6'b000101
`define GetB      6'b000110
`define Addzero   6'b000111
`define ALU       6'b001000
`define WriteReg  6'b001001
`define Writelmm  6'b001010

// the states below are the ones we introduced in Lab7 which do all the other operations as needed
// most states are self-descriptive, but the ones that are a bit ambiguous have a comment next to them
`define addimm5    6'b001011
`define WriteAddr  6'b001100
`define ReadMem    6'b001101
`define WriteIns   6'b001110
`define ReadReg    6'b001111
`define WriteMem   6'b010001
`define HALT       6'b010010

`define PCtoREG    6'b010011
`define Updatefunc 6'b010100
`define FuncB      6'b010101





/*Wait w=1;
  Decode ;
  GetA               nsel=3'b001;             loada=1;
  GetB               nsel=3'b100;                    loadb=1;
  Add     asel=bsel=0;            shift=2'b00;              ALUop=2'b00;                   loadc=1; (loads=1;)
  Addzero asel=1;bsel=0;          shift=2'b00;              ALUop=2'b00;                   loadc=1; (loads=1;)
  Bit_not asel=bsel=0;            shift=2'b00;              ALUop=2'b11;                   loadc=1; (loads=1;)
  And     asel=bsel=0;            shift=2'b00;              ALUop=2'b10;                   loadc=1; (loads=1;)  
  WriteReg           nsel=3'b010;                                        vsel=0001; write=1;
  Writelmm           nsel=3'b001;                                        vsel=0100; write=1;
*/
module state_machine(clk,reset,opcode,op,vsel,nsel,loada,loadb,loadc,loads,asel,bsel,writefsm,loadir,loadpc,resetpc,addr_sel,mem_cmd,load_addr,halt,funcpc,returnsig); 
input clk,reset;
input [2:0]opcode;
input [1:0]op;
output reg loada,loadb,loadc,loads,asel,bsel,writefsm,loadir,loadpc,resetpc,addr_sel,load_addr; // we added loadir,loadpc,resetpc,load_addr,mem_cmd, and address select
output reg [2:0] nsel;
output reg[1:0]mem_cmd;
output reg [3:0] vsel;
reg [5:0]present_state;
output halt,funcpc,returnsig;
reg halt,funcpc,returnsig;


always@(posedge clk)begin
  if(reset==1'b1) begin
  present_state =  `Reset;   ////????
  {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b01_10_00_00_000_00_0000_0000;
 halt=1'b0;

  end else begin

  casex({opcode,op})


     5'b11010: case(present_state)
         
 			`Reset: present_state = `if1;			//this is where the controller starts
		    `if1: present_state = `if2;				//these instructions execute MOV instruction
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;
		 

                    `Decode: present_state=`Writelmm;
                     `Writelmm: present_state= `if1;
                     default:present_state=6'bxxxxxx;
              endcase
    5'b11000: case(present_state) 
   
		    `Reset: present_state = `if1;		//executes MOV Rd instruction
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state= `GetB;
                     `GetB: present_state=  `Addzero;
                     `Addzero: present_state=  `WriteReg;
                     `WriteReg: present_state= `if1;
                     default:present_state=6'bxxxxxx;
                endcase 

               
     5'b10101: case(present_state) 
/*
                  
*/
		    `Reset: present_state = `if1;		//executes CMP instructions
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state= `GetA;
                     `GetA: present_state=  `GetB;
                      `GetB: present_state=  `ALU;
                     `ALU: present_state=  `if1;
                     
                     default:present_state=6'bxxxxxx;
               endcase


	5'b10100: case(present_state) 
/*
                  
*/
		    `Reset: present_state = `if1;		//executes ADD instruction
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state= `GetA;
                     `GetA: present_state=  `GetB;
                      `GetB: present_state=  `ALU;
                     `ALU: present_state=  `WriteReg;
                     `WriteReg: present_state= `if1;
                     default:present_state=6'bxxxxxx;
               endcase


    5'b01100: case(present_state)
                    `Reset: present_state = `if1; 		//executes LDR instruction
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state = `GetA;
  	      	    `GetA: present_state = `addimm5;
 		    `addimm5: present_state = `WriteAddr;
		     `WriteAddr:present_state=`ReadMem;
		     `ReadMem:present_state= `WriteIns;
		     `WriteIns:present_state= `if1;
		   
		   default:present_state=6'bxxxxxx;
		endcase

    5'b10000: case(present_state)
                    `Reset: present_state = `if1;		//executes STR instruction
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state = `GetA;
		    `GetA: present_state = `addimm5;
 		    `addimm5: present_state = `WriteAddr;
		     `WriteAddr:present_state=`ReadReg;
		     `ReadReg:present_state=`Addzero;
		     `Addzero:present_state=`WriteMem;
		     `WriteMem:present_state=`if1;
         		default:present_state=6'bxxxxxx;
              endcase	

    5'b11100: case(present_state)
                    `Reset: present_state = `if1;	//executes HALT instruction
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state = `HALT;
		    `HALT: present_state = `HALT;     
		
              endcase	

	5'b00100:case(present_state)
			`Reset: present_state = `if1;
			 `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state = `if1;
			default:present_state=6'bxxxxxx;
			endcase

	5'b01011:case(present_state)
		`Reset: present_state = `if1;
			 `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `PCtoREG;
	             `PCtoREG:present_state=`Updatefunc;
			`Updatefunc:present_state=`if1;
			 default:present_state=6'bxxxxxx;
		endcase

	5'b01000:case(present_state)
			`Reset: present_state = `if1;
			 `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;
                    `Decode: present_state= `FuncB;
                     `FuncB: present_state=  `Addzero;
                     `Addzero: present_state=  `Updatefunc;
                       `Updatefunc : present_state= `if1;
		 default:present_state=6'bxxxxxx;
		endcase

	5'b10111:case(present_state)

		 `Reset: present_state = `if1; 		//executes MVN instructions
		    `if1: present_state = `if2;
		    `if2: present_state = `UpdatePC;
		    `UpdatePC: present_state = `Decode;

                    `Decode: present_state= `GetB;
                     `GetB: present_state=  `Addzero;
                     `Addzero: present_state=  `WriteReg;
                     `WriteReg: present_state= `if1;
                     default:present_state=6'bxxxxxx;
		endcase

	
 		
     default:present_state=6'bxxxxxx;
  endcase


// below if statement sets a signal to PC counter to execute PC=Rd

if({opcode,op}==5'b01000)begin
	if(present_state==`Updatefunc)begin
	returnsig=1'b1;
	end else begin
	returnsig=1'b0;
	end
end else begin
returnsig=1'b0;
end



//below if statement sets a signal to PC counter to execute PC=PC+sximm8
if({opcode,op}==5'b01011)begin
	if(present_state==`Updatefunc)begin
	funcpc=1'b1;
	end else begin
	funcpc=1'b0;
	end
end else begin
funcpc=1'b0;
end


//sets halt(a signal which turns on LEDR[8] to either 1 or 0 depending on whether I have reached HALT yet
if(present_state==`HALT)begin
halt=1'b1;
end else begin
halt=1'b0;
end

  case(present_state) //this is where changes in output takes place for each state
 
   `if1:       {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b00_01_01_00_000_00_0000_0000;
   `if2:       {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b10_01_01_00_000_00_0000_0000;

   `UpdatePC:  {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b01_00_00_00_000_00_0000_0000; 
   `Updatefunc:{loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b01_00_00_00_000_00_0000_0000; 



   `Decode:    {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b00_00_00_00_000_00_0000_0000;

   `GetA:      {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b00_00_00_00_001_10_0000_0000;
   `GetB:      {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b00_00_00_00_100_01_0000_0000;
   `ALU:       {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b00_00_01_00_000_00_0000_0110;
   `Addzero:   {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'b00_00_00_10_000_00_0000_011_0;

   `WriteReg:  {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_010_00_0001_100_0;
   `Writelmm:  {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_001_00_0100_1000;

   `addimm5:   {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_01_000_00_0000_011_0; 
   `WriteAddr: {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_000_00_0000_011_1;
   `ReadMem:   {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_01_00_000_00_0000_000_0;
   `WriteIns:  {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_01_00_010_00_1000_100_0;
   `ReadReg:   {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_010_01_0000_000_0;
   `WriteMem:  {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_10_00_000_00_0000_000_0;
   `HALT:      {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_000_00_0000_000_0;

   `PCtoREG:   {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_001_00_0010_100_0;
   `FuncB:     {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}=   21'b00_00_00_00_010_01_0000_0000;

    default:   {loadir,loadpc,resetpc,addr_sel,mem_cmd,asel,bsel,nsel, loada,loadb, vsel, writefsm,loadc,loads,load_addr}= 21'bxx_xx_xx_xx_xxx_xx_xxxx_xxxx; 
   endcase 
  end
 end
endmodule


module Counter1(opcode,op,cond,N,V,Z,imm,clk,rst,out, load,funcpc,in,returnsig) ;
  input rst, clk, load,N,V,Z,funcpc,returnsig ; // reset and clock
  output [8:0] out ;
  reg    [8:0] next_pc ;
input [8:0] imm,in;
input [2:0] opcode,cond;
input [1:0] op;



  load_enable #(9) count(next_pc, out, clk, load) ;

  always @(*) begin

if(rst)begin 
next_pc = 9'b000000000 ;
end else
    casex({opcode,op, cond})

      8'b001_00_000: next_pc = out+9'd1+imm;	//B instruction

      8'b001_00_001: begin 			
			if(Z == 1'b1) begin 	//BEQ instrucion
			next_pc = out+9'd1+imm;
			end else begin
			next_pc = out+9'd1;
			end 
		end

      8'b001_00_010:  begin 			//BNE instruction
			if(Z == 1'b0) begin 
			next_pc = out+9'd1+imm;
			end else begin
			next_pc = out+9'd1;
			end 
		end

      8'b001_00_011:  begin 			//BLT instruction
			if(N !== V) begin 
			next_pc = out+9'd1+imm;
			end else begin
			next_pc = out+9'd1;
			end 
		end

      8'b001_00_100: begin 			//BLE instruction
			if((N !== V)| (Z == 1'b1)) begin 
			next_pc = out+9'd1+imm;
			end else begin
			next_pc = out+9'd1;
			end 
		end
	8'b010_11_xxx:begin			//BL instruction
			if(funcpc==1'b1)begin
			next_pc = out+imm;
			end else begin
			next_pc = out+9'd1;
			end
		end
	8'b010_00_xxx:begin

	if(returnsig==1'b1)begin		//BX instruction
	next_pc=in;
	end else begin
	next_pc = out+9'd1;
	end
	end


//      1'b0: next_pc = out + 9'b000000001 ;
      default: next_pc =  out+9'd1;
    endcase
  end
endmodule


module MUX9b (a1, a0, s, b) ;
input [8:0] a0, a1;  // inputs
input s; // one-hot select (there might be a problem here )
output [8:0] b;
assign b = s ? a1 : a0;
endmodule






