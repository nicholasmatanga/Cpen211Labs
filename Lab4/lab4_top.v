`define Sa 7'b0100100
`define Sb 7'b0110000
`define Sc 7'b0000010
`define Sd 7'b0010010
`define Se 7'b1111000
`define SS 7'bxxxxxxx

module lab4_top(SW,KEY,HEX0);
  input [9:0] SW;
  input [3:0] KEY;
  output reg [6:0] HEX0;
  wire clk;
  wire reset;
  wire direction;
  reg[6:0] present_state;
 
assign clk=~(KEY[0]);		//this part of my code assigns my clock to the opposite of my KEY[0],i.e ~KEY[0]
assign reset=~(KEY[1]);		//this part of my code assigns my reset key the same way my clock is assigned.
assign direction=SW[0];		//assigns my direction to the first switch on the DE1.


always @(posedge clk)begin	//statements below are evalated everytime on the rising edge of the clock
    if(reset) begin		//checks for a reset, and if true, resets and displays my first value in my number
     present_state=`Sa;
	HEX0=present_state;
  end else begin
    case(present_state)
 `SS:present_state= `Sa;
	
      `Sa: if(SW[0]==1'b0)        // checks if my direction is set to 0, and if so, numbers are displayed in reverse
              present_state= `Se;
            else
		present_state=`Sb; //if my direction switch is any other value, my numbers are displayed in forward order
	`Sb: if(SW[0]==1'b0)		// the rest of the code from here implements the same logic as the above statements below the case statement
		present_state=`Sa;
	     else 
		present_state=`Sc;
	`Sc: if(SW[0]==1'b0)
		present_state=`Sb;
	     else
		present_state=`Sd;
	`Sd: if(SW[0]==1'b0)
		present_state= `Sc;
	     else
		present_state=`Se;
	`Se: if(SW[0]==1'b0)
		present_state=`Sd;
	     else
		present_state=`Sa;
	default: present_state= 7'bxxxxxxx; // this is the default, which is displayed at the start up of the machine when there are no inputs defined.
endcase
end
HEX0=present_state;  // after my always block is evaluated, my present state which is my number,is displayed on the HEX display
end

endmodule
