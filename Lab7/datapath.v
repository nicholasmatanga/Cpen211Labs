module datapath (clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, write, datapath_out,
                 mdata,sximm8,PC,sximm5,Z_out);//new added for lab6




//for datapath

output [15:0] datapath_out;

wire   [15:0] data_in;

// for regfile
input[15:0] mdata,sximm8;
input [8:0]PC;
input  [3:0] vsel;
input  loadc, loads;
input [2:0] writenum, readnum;
input write, clk;
wire  [15:0] data_out;

// between regfile and ALU
input loada, loadb;
wire  [15:0] A, B;

//for shifter
input  [1:0]  shift;
wire   [15:0] sout;
//for mux-es
input [15:0]sximm5;
input asel, bsel;

//for ALU
input [1:0]  ALUop;
output [2:0] Z_out;
wire  [15:0] Ain, Bin, C, out_ALU;
wire [2:0] Z_in;

// assign mdata and PC to 0 ??????

//module call
Mux4          #(16)      m0(C, {7'b0,PC}, sximm8, mdata, vsel, data_in);
regfile                  REGFILE(data_in, writenum, write, readnum, clk, data_out);
load_enable   #(16)      a0(data_out, A, clk, loada);
load_enable   #(16)      b0(data_out, B, clk, loadb);
shifter                  s0(B, shift, sout);
Mux2                     m1(16'b0, A, asel, Ain);
Mux2                     m2( sximm5, sout, bsel, Bin);
ALU                      a1(Ain, Bin, ALUop, out_ALU, Z_in);
load_enable   #(16)      r3(out_ALU, C, clk, loadc);
load_enable   #(3)       r4(Z_in, Z_out, clk, loads);
assign datapath_out=C;


endmodule
                                                    
            

// 16-bit 2-input mux with one-hot select
// used slide set 6 p17 as reference
module Mux2(a1, a0, s, b) ;
input [15:0] a0, a1;  // inputs
input s; // one-hot select (there might be a problem here )
output [15:0] b;
assign b = s ? a1 : a0;
endmodule

// k-bit 4-input mux with on hot select
module Mux4(a0,a1,a2,a3,sel,b);
parameter k;
input [k-1:0] a0,a1,a2,a3;
input [3:0]sel;
output [k-1:0] b;
wire [k-1:0] b;
assign b=(a0&{k{sel[0]}}) |
         (a1&{k{sel[1]}}) |
         (a2&{k{sel[2]}}) |
         (a3&{k{sel[3]}}) ;

endmodule













