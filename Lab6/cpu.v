module cpu(clk,reset,s,load,in,out,N,V,Z,w);
input clk, reset, s, load;
////??????
input [15:0] in;
output[15:0] out;
output N, V, Z, w;

//Instruction Register
wire load;
wire [15:0]reg_out;
//Instruction Decoder
wire [2:0] opcode;
wire [1:0] op;
wire [1:0]ALUop;
wire [15:0] sximm5;
wire [15:0] sximm8;
wire [1:0] shift;
wire [2:0] readnum,writenum;
//inside instruction decoder
wire [4:0] imm5;
wire [7:0] imm8;
wire [2:0] Rm,Rd,Rn;
//State_machine
wire [2:0] nsel;
wire [2:0] present_state;
// datapath
wire [2:0]Z_out;
wire [3:0]vsel;
wire loada,loadb,asel,bsel,loadc,loads;
wire [15:0] mdata;
wire [7:0] PC;

//for instruction register
load_enable   #(16)  uo(in, reg_out, clk, load);

//for instruction Decoder
assign {opcode,op} = reg_out[15:11];////??????
assign ALUop =reg_out [12:11];

assign imm5 = reg_out[4:0];
assign imm8 = reg_out[7:0];
assign sximm5={ {11{imm5[4]}},imm5 };////????????
assign sximm8={ {8{imm8[7]}},imm8 };////????????
assign {shift,Rm} = reg_out[4:0]; ////?????
assign {Rn,Rd} = reg_out[10:5]; ///??????

assign readnum=(Rm&{3{nsel[2]}}) | //3-input,3-bit multiplexer
              (Rd&{3{nsel[1]}}) |
              (Rn&{3{nsel[0]}}) ;  ///???????

assign writenum=(Rm&{3{nsel[2]}}) | //3-input,3-bit multiplexer
              (Rd&{3{nsel[1]}}) |
              (Rn&{3{nsel[0]}}) ;  ///???????

//for state machine

state_machine MAC(clk,s,reset,opcode,op,vsel,nsel,loada,loadb,loadc,loads,asel,bsel,write,w); 


//for datapath
assign mdata= 16'b0 ;
assign PC =8'b0 ;

 datapath DP(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, write, out,
                 mdata,sximm8,PC,sximm5,Z_out);


assign N=Z_out[1];
assign V=Z_out[2];
assign Z=Z_out[0];

endmodule 

//state machine module


//`define Wait 3'b000
`define Reset 4'b1000
`define if1 4'b1001
`define if2 4'b1010
`define UpdatePC 4'b1011

`define Decode 4'b0001
`define GetA 4'b0010
`define GetB 4'b0011
`define Addzero 4'b0100
`define ALU 4'b0101
`define WriteReg 4'b0110
`define Writelmm 4'b0111
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
module state_machine(clk,s,reset,opcode,op,vsel,nsel,loada,loadb,loadc,loads,asel,bsel,write,w); 
input clk,s,reset;
input [2:0]opcode;
input [1:0]op;
output reg loada,loadb,loadc,loads,asel,bsel,write,w;
output reg [2:0] nsel;
output reg [3:0] vsel;
reg [2:0]present_state;

always@(posedge clk)begin
  if(reset) begin
  present_state =  `Wait;   ////????
  {asel,bsel,nsel, loada,loadb, vsel, write,loadc,loads,w}= 15'b00_000_10_0000_0001;
  end else begin
  casex({opcode,op})
     5'b11010: case(present_state)
                   `Wait: if(~s) begin
                          present_state=`Wait;
                             w=1; end
                          else
                          present_state=`Decode;
                    `Decode: present_state=`Writelmm;
                     `Writelmm: present_state= `Wait;
                     default:present_state=3'bxxx;
              endcase
    5'b11000: case(present_state) 
                   `Wait: if(~s) begin
                          present_state=`Wait;
                             w=1; end
                          else
                          present_state=`Decode;
                    `Decode: present_state= `GetB;
                     `GetB: present_state=  `Addzero;
                     `Addzero: present_state=  `WriteReg;
                     `WriteReg: present_state= `Wait;
                     default:present_state=3'bxxx;
                endcase 

               
     5'b101xx: case(present_state) 
                   `Wait: if(~s) begin
                          present_state=`Wait;
                             w=1; end
                          else
                          present_state=`Decode;
                    `Decode: present_state= `GetA;
                     `GetA: present_state=  `GetB;
                      `GetB: present_state=  `ALU;
                     `ALU: present_state=  `WriteReg;
                     `WriteReg: present_state= `Wait;
                     default:present_state=3'bxxx;
               endcase
     default:present_state=3'bxxx;
  endcase
 
/*Wait w=1;
  Decode ;
  GetA               nsel=3'b001;  loada=1;
  GetB               nsel=3'b100;          loadb=1;
  ALU     asel=bsel=0;                                                  loadc=1; (loads=1;)
  Addzero asel=1;bsel=0;                                                loadc=1; (loads=1;) 
  WriteReg           nsel=3'b010;                         vsel=0001; write=1;
  Writelmm           nsel=3'b001;                         vsel=0100; write=1;
*/

  case(present_state)

   `Wait :{asel,bsel,nsel, loada,loadb,  vsel, write,loadc,loads,w}=    15'b00_000_00_0000_0001;
   `Decode: {asel,bsel,nsel,loada,loadb,  vsel, write,loadc,loads,w}=   15'b00_000_00_0000_0000;
   `GetA :{asel,bsel,nsel, loada,loadb,  vsel, write,loadc,loads,w}=    15'b00_001_10_0000_0000;
   `GetB :{asel,bsel,nsel, loada,loadb, vsel, write,loadc,loads,w}=     15'b00_100_01_0000_0000;
   `ALU :{asel,bsel,nsel,loada,loadb,  vsel, write,loadc,loads,w}=      15'b00_000_00_0000_0110;
   `Addzero :{asel,bsel,nsel, loada,loadb,  vsel, write,loadc,loads,w}= 15'b10_000_00_0000_0110;
   `WriteReg :{asel,bsel,nsel, loada,loadb, vsel, write,loadc,loads,w}= 15'b00_010_00_0001_1000;
   `Writelmm :{asel,bsel,nsel, loada,loadb,  vsel, write,loadc,loads,w}=15'b00_001_00_0100_1000;
    default: {asel,bsel,nsel, loada,loadb,  vsel, write,loadc,loads,w}= 15'bxx_xxx_xx_xxxx_xxxx; 
   endcase 
  end
 end
endmodule












