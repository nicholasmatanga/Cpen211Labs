module shifter(in,shift,sout);
input [15:0] in;
input [1:0] shift;
output [15:0] sout;
reg [15:0] sout;

always@(*)begin

case(shift) //condition is the value of shift 

2'b00: sout = in; // shift = 00 // data is unchanged
2'b01: begin //shift = 01 // data is shifted 1 bit to the left
       
       sout[0] = 0;
       sout[1] = in[0];
       sout[2] = in[1];
       sout[3] = in[2];
       sout[4] = in[3];
       sout[5] = in[4];
       sout[6] = in[5];
       sout[7] = in[6];
       sout[8] = in[7];
       sout[9] = in[8];
       sout[10] = in[9];
       sout[11] = in[10];
       sout[12] = in[11];
       sout[13] = in[12];
       sout[14] = in[13];
       sout[15] = in[14];

      

       end
2'b10: begin // shift = 10 // data is shifted 1 bit to the right

  	sout[15] = 0;
	sout[14] = in[15];
	sout[13] = in[14];
	sout[12] = in[13];
	sout[11] = in[12];
	sout[10] = in[11];
	sout[9] = in[10];
	sout[8] = in[9];
	sout[7] = in[8];
	sout[6] = in[7];
	sout[5] = in[6];
	sout[4] = in[5];
	sout[3] = in[4];
	sout[2] = in[3];
	sout[1] = in[2];
	sout[0] = in[1];

end
2'b11: begin // shift = 11 // data is shifted to 1 bit to the right copying the previous MSB to the current MSB
  	sout[15] = in[15];
	sout[14] = in[15];
	sout[13] = in[14];
	sout[12] = in[13];
	sout[11] = in[12];
	sout[10] = in[11];
	sout[9] = in[10];
	sout[8] = in[9];
	sout[7] = in[8];
	sout[6] = in[7];
	sout[5] = in[6];
	sout[4] = in[5];
	sout[3] = in[4];
	sout[2] = in[3];
	sout[1] = in[2];
	sout[0] = in[1];

       end
default sout=in;
endcase

end

endmodule
