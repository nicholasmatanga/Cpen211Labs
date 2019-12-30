module regfile(data_in,writenum,write,readnum,clk,data_out);
input [15:0] data_in;
input [2:0] writenum, readnum;
input write, clk;
output [15:0] data_out;

wire [7:0] decodedwrite,decodedread,load;
wire [15:0] R0,R1,R2,R3,R4,R5,R6,R7;

decoder #(3,8) w(writenum,decodedwrite);
decoder #(3,8) r(readnum,decodedread);//decode the inputs

assign load = decodedwrite & {8{write}};//use AND gates to determine which R should store the input values
 
load_enable #(16) l0(data_in,R0,clk,load[0]);
load_enable #(16) l1(data_in,R1,clk,load[1]);
load_enable #(16) l2(data_in,R2,clk,load[2]);
load_enable #(16) l3(data_in,R3,clk,load[3]);
load_enable #(16) l4(data_in,R4,clk,load[4]);
load_enable #(16) l5(data_in,R5,clk,load[5]);
load_enable #(16) l6(data_in,R6,clk,load[6]);
load_enable #(16) l7(data_in,R7,clk,load[7]);//store the values

mux m(R7,R6,R5,R4,R3,R2,R1,R0,decodedread,data_out);//read the values

endmodule

module decoder(a,b);
parameter n=3;
parameter m=8;
input [n-1:0] a;
output [m-1:0] b;

wire [m-1:0] b = 1 << a;//decoder referring to slide set 6

endmodule

module load_enable(a,b,clk,load);
parameter n;
input [n-1:0] a;
input clk,load;
output reg [n-1:0] b;
wire [n-1:0] next;

assign next=load ? a : b;//first set value to wire

always@(posedge clk)
b = next;//when the clk rises append next to output b
endmodule



module mux(a7,a6,a5,a4,a3,a2,a1,a0,select,out);
input [15:0] a7,a6,a5,a4,a3,a2,a1,a0;
input [7:0] select;
output [15:0] out;

wire [15:0] out=({16{select[0]}} & a0 )|
		({16{select[1]}} & a1 )|
		({16{select[2]}} & a2 )|
		({16{select[3]}} & a3 )|
		({16{select[4]}} & a4 )|
		({16{select[5]}} & a5 )|
		({16{select[6]}} & a6 )|
		({16{select[7]}} & a7 );//multiplexer referring to slide set 6
endmodule

