/*********************************************************************************************

    File name   : read_in_message.v
    Author      : Priyank Kashyap
    Affiliation : North Carolina State University, Raleigh, NC
    Date        : Oct 2018
    email       : pkashya2@ncsu.edu

    Description : Module connects to message memory to read in message & outputs a 512 bit value to be used 
    to construct the w_vec


*********************************************************************************************/
module read_in_message #(parameter OUTPUT_LENGTH       = 8,
                  parameter MAX_MESSAGE_LENGTH  = 55,
                  parameter NUMBER_OF_Ks        = 64,
                  parameter NUMBER_OF_Hs        = 8 ,
                  parameter SYMBOL_WIDTH        = 8  )
            (
            input  wire                                  trigger              ,
            input  wire                                  clk                  ,
            input  wire                                  reset                ,
            input  wire  [7:0]                           msg__dut__data       ,
            input  wire  [ $clog2(MAX_MESSAGE_LENGTH):0] xxx__dut__msg_length ,
            output reg   [511:0] block
            );

  //---------------------------------------------------------------------------
  //
    reg [8:0] beginning_point;
    reg [7:0] in_msg_data;
    reg [ $clog2(MAX_MESSAGE_LENGTH):0] in_msg_length;
    wire[63:0] bit_length;
    
    assign bit_length= in_msg_length << 3; 
    always@(posedge clk) 
    begin
        in_msg_data   <= msg__dut__data;
        in_msg_length <= xxx__dut__msg_length;
    end

    always@(posedge clk)
    begin
       if(reset) 
       begin
           beginning_point = 9'd511;
           block= {512'b0, bit_length};
       end
       else
       begin
          if(trigger)
          begin
            block[beginning_point -: 8] = in_msg_data;
            beginning_point = beginning_point-8;
	    block[beginning_point] = 1'b1;
          end
       end 
    end


  // 
  //---------------------------------------------------------------------------

endmodule

