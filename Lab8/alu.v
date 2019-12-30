
module ALU(Ain,Bin,ALUop,out,Z);
input [15:0] Ain, Bin;
input [1:0] ALUop;
output [15:0] out;
output[2:0] Z;

reg [15:0] out;
reg [2:0]Z;

always@(*)begin

case (ALUop)//operation decided by the input of ALU

2'b00:  out = Ain + Bin; //ALU = 00// Adds A and B
2'b01:  out = Ain - Bin; //ALU = 01// Subtracts B from A
2'b10:  out = Ain & Bin; //ALU = 10// ANDs A and B
2'b11:  out = ~Bin;     //ALU = 11// NOTs B

default: out = 16'bx;
endcase


if (ALUop == 2'b01) begin
	
	if(out == 16'b0000000000000000)begin
	Z[0]=1'b1;
	end else begin 
	Z[0] = 1'b0;
	end

	if(out[15]==1'b1)begin
	Z[1] = 1'b1;
	end else begin 
	Z[1] = 1'b0;
	end


	 if (Ain[15] == 1'b1 && Bin[15] == 1'b0) begin
		if ( out[15] == 1'b0) begin 
			Z[2] = 1'b1; 
		end else begin  
			Z[2] = 1'b0;
		end
	end else if (Ain[15] == 1'b0 && Bin[15] == 1'b1) begin
		if ( out[15] == 1'b1) begin 
			Z[2] = 1'b1; 
		end else begin  
			Z[2] = 1'b0;
		end
	end else begin  
			Z[2] = 1'b0;
	end

end else begin 
	Z = 3'b000;
	end

end

endmodule



module ALU_tb ; 
reg err;
reg [15:0] Ain, Bin;
reg [1:0] ALUop;
wire [2:0] Z;

wire [15:0] out;

ALU DUT(Ain,Bin,ALUop,out,Z);

initial begin
ALUop = 2'b01;
Ain = 16'd2;
Bin = 16'd5;

#10;

Ain = 16'd5;
Bin = 16'd2;

#10;

Ain = 16'd5;
Bin = 16'd5;

#10;

Ain = 16'b1000000000000000;
Bin = 16'b0000000000000001;
#10;

end

endmodule 

