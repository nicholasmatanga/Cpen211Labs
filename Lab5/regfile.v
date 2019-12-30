

module vDFFE(clk, en, in, out) ;
  parameter n = 16;  // width
  input clk, en ;
  input  [n-1:0] in ;
  output [n-1:0] out ;
  reg    [n-1:0] out ;
  wire   [n-1:0] next_out ;

  assign next_out = en ? in : out;

  always @(posedge clk)
    out = next_out;  
endmodule


module MUX1b(a2,a1,s,b); //the multiplexer decoder, and flip_flop modules are intellectual property of Tor Aamodt from slide set 6
input[15:0] a2, a1;
input s;
output[15:0] b;
reg [15:0]b;

always@(*)begin
case(s)
1'b1:b=a2;
1'b0:b=a1;
default: b= {16{1'b0}};
endcase
end
endmodule

module MUX2b(a0,a1,a2,a3,a4,a5,a6,a7,s,b); //the multiplexer decoder, and flip_flop modules are intellectual property of Tor Aamodt from slide set 6
input[15:0] a0,a1,a2,a3,a4,a5,a6,a7;
input [7:0] s;
output [15:0] b;
reg [15:0] b;

always@(*)begin // my always block is always initiating
case(s)
8'b00000001: b = a0;
8'b00000010: b = a1;
8'b00000100: b = a2;
8'b00001000: b = a3;
8'b00010000: b = a4;
8'b00100000: b = a5;
8'b01000000: b = a6;
8'b10000000: b = a7;

default: b= {16{1'b0}};
endcase
end
endmodule





module bdecoder(a,b); // decoder which converts a 3 bit number to an 8bit one-hot code
parameter n=3;
parameter m=8;

input [n-1:0] a;
output[m-1:0] b;

wire[m-1:0]b=1<<a; //shifts the 1 by a, where a is the number of bits
endmodule



module regfile(data_in,writenum,write,readnum,clk,data_out); //my inputs and outputs
input [15:0] data_in;
input [2:0] writenum, readnum;
input write, clk;
output [15:0] data_out;
wire [7:0] wnumoh, rnumoh;// my rnumoh also means "readnum-one-hot"
wire [7:0] address;
wire [7:0] address1;
wire [15:0] R0,R1,R2,R3,R4,R5,R6,R7;


assign address=({8{write}} & wnumoh); // this is ANDing my write to my wnumoh, where wnumoh is "writenum-one-hot"

bdecoder A1(writenum,wnumoh);


 
     vDFFE M0(clk, address[0],data_in,R0) ; // from this instantiation of M0 to M7, my data_in is being driven into one of my register files depending on the inputs
     vDFFE M1(clk, address[1],data_in,R1) ;
     vDFFE M2(clk, address[2],data_in,R2) ;
     vDFFE M3(clk, address[3],data_in,R3) ;
     vDFFE M4(clk, address[4],data_in,R4) ;
     vDFFE M5(clk, address[5],data_in,R5) ;
     vDFFE M6(clk, address[6],data_in,R6) ;
     vDFFE M7(clk, address[7],data_in,R7) ;

bdecoder A2(readnum, rnumoh);

MUX2b  Rout(R0,R1,R2,R3,R4,R5,R6,R7,rnumoh,data_out); // this multiplexer is choosing which value is going to be driven onto data_out




endmodule
