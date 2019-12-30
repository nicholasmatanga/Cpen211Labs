module ALU(Ain,Bin,ALUop,out,Z_in);
input [15:0] Ain, Bin;
input [1:0] ALUop;
output reg [15:0] out;
output [2:0]Z_in;
wire overflow;
wire [15:0]addsubout;

AddSub #(16)U1(Ain,Bin,(~ALUop[1])&ALUop[0],addsubout,overflow);


always@* begin
casex(ALUop)
2'b0x: out=addsubout; //????
2'b10: out=Ain & Bin;
2'b11: out= ~Bin;
default: out=16'bxxxxxxxxxxxxxxxx;// referring to the ALU table
endcase
end


assign Z_in={ overflow,out[15],~out};// the status should be 1 if out=0; and 0 if out!=0

endmodule




//add a+b or subtract a-b, check for overflow
module AddSub(a,b,sub,s,ovf) ;
  parameter n  ;
  input [n-1:0] a, b ;
  input sub ;           // subtract if sub=1, otherwise add
  output [n-1:0] s ;
  output ovf ;          // 1 if overflow
  wire c1, c2 ;         // carry out of last two bits
  wire ovf = c1 ^ c2 ;  // overflow if signs don't match

  // add non sign bits
  Adder1 #(n-1) ai(a[n-2:0],b[n-2:0]^{n-1{sub}},sub,c1,s[n-2:0]) ;
  // add sign bits
  Adder1 #(1)   as(a[n-1],b[n-1]^sub,c1,c2,s[n-1]) ;
endmodule


// multi-bit adder - behavioral
module Adder1(a,b,cin,cout,s) ;
  parameter n = 8 ;
  input [n-1:0] a, b ;
  input cin ;
  output [n-1:0] s ;
  output cout ;
  wire [n-1:0] s;
  wire cout ;

  assign {cout, s} = a + b + cin ;
endmodule 

