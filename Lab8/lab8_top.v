//below are the values we decided to use for our READ and WRITE drivers

`define MREAD 2'b01
`define MWRITE 2'b10


module lab8_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;
output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
input CLOCK_50;
wire [1:0] mem_cmd;
wire [8:0] mem_addr;
wire [7:0] read_address,write_address;
wire [15:0] read_data, dout,write_data,out;
wire eqread,msel,clk,N,V,Z,eqwrite,write,halt;
reg activatebuffer; //tri_state buffer that connects to the switch inputs
reg loadLED; //register file which displays to the DE1 Soc


assign LEDR[8]=halt?1'b1:1'b0;

assign read_address=mem_addr[7:0];
assign write_address=mem_addr[7:0];

    assign HEX5[0] = ~Z;
  assign HEX5[6] = ~N;
  assign HEX5[3] = ~V;

  // fill in sseg to display 4-bits in hexidecimal 0,1,2...9,A,B,C,D,E,F
  sseg H0(write_data[3:0],   HEX0);
  sseg H1(write_data[7:4],   HEX1);
  sseg H2(write_data[11:8], HEX2);
  sseg H3(write_data[15:12], HEX3);
  assign HEX4 = 7'b1111111;
  assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled
  
  assign LEDR[9]=1'b0;




EqComp #(2) readcomp(`MREAD,mem_cmd,eqread); // comparator which drive read
EqComp #(1) zero(1'b0,mem_addr[8],msel); 
EqComp #(2) writecomp(`MWRITE,mem_cmd,eqwrite); //comparator which drives write

assign read_data=(eqread&msel) ? dout : 16'bz;
assign write_data=out;
assign write=(msel&eqwrite);

assign read_data[15:8]=activatebuffer?8'b0:8'bz;  //buffer which controls inputs to read_data//drives input of eight zeros
assign read_data[7:0]=activatebuffer?SW[7:0]:8'bz; // buffer which controls inputs to read_data from first 8 switches of DE1 soc


cpu CPU(CLOCK_50,~KEY[1],read_data,out,N,V,Z,mem_cmd,mem_addr,halt);
RAM  MEM(CLOCK_50,read_address,write_address,write,write_data,dout); //memory instantiation
load_enable #(8) outputLED(write_data[7:0],LEDR[7:0],CLOCK_50,loadLED); //LED register instantiation

//from line 56 to 70 theres combinational logic which is the select for my my tri-state buffers for read_data inputs and LED outputs


always @(*) begin

if({mem_addr,mem_cmd}=={9'b101000000,2'b01})begin
activatebuffer=1'b1;
end else begin
activatebuffer=1'b0;
end

if({mem_addr,mem_cmd}=={9'b100000000,2'b10})begin
loadLED=1'b1;
end else begin
loadLED=1'b0;
end

end


endmodule



//we used memory instantiation from slide set 7 to  right RAM module


module RAM(clk,read_address,write_address,write,din,dout);
  parameter data_width = 16; 
  parameter addr_width = 8;
  parameter filename = "data.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input write;
  input [data_width-1:0] din;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;

  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem);

  always @ (posedge clk) begin
    if (write)
      mem[write_address] <= din;
    dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                               // (this is due to Verilog non-blocking assignment "<=")
  end 
endmodule


//comparator module which checks for equality
module EqComp(a, b, eq) ;
  parameter k=8;
  input  [k-1:0] a,b;
  output eq;
  wire   eq;

  assign eq = (a==b) ;
endmodule



// sseg module provided to us in lab 6 and 5
module sseg(in,segs);
  input [3:0] in;
  output reg[6:0] segs;

 

  always @( * )begin
     case (in)
	4'b0000: segs = 7'b1000000;
	4'b0001: segs = 7'b1111001;
	4'b0010: segs = 7'b0100100;
	4'b0011: segs = 7'b0110000;
	4'b0100: segs = 7'b0011001;
	4'b0101: segs = 7'b0010010;
	4'b0110: segs = 7'b0000010;
	4'b0111: segs = 7'b1111000;
	4'b1000: segs = 7'b0000000;
	4'b1001: segs = 7'b0010000;
	4'b1010: segs = 7'b0001000;
	4'b1011: segs = 7'b0000011;
	4'b1100: segs = 7'b1000110;
	4'b1101: segs = 7'b0100001;
	4'b1110: segs = 7'b0000110;
	4'b1111: segs = 7'b0001110;

	default: segs = 7'b1000000;
     endcase
  end

endmodule



