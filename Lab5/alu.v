
module ALU(Ain,Bin,ALUop,out,Z);
input [15:0] Ain, Bin;
input [1:0] ALUop;
output [15:0] out;
output Z;

reg [15:0] out;
reg Z;

always@(*)begin

case (ALUop)//operation decided by the input of ALU

2'b00:  out = Ain + Bin; //ALU = 00// Adds A and B
2'b01:  out = Ain - Bin; //ALU = 01// Subtracts B from A
2'b10:  out = Ain & Bin; //ALU = 10// ANDs A and B
2'b11:  out = ~Bin;     //ALU = 11// NOTs B

default: out = 16'bx;
endcase

if(out == 16'b0)begin
 Z = 1;
end else begin
 Z = 0;
end
end

endmodule

