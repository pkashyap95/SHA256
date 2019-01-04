/*********************************************************************************************

    File name   : read_in_message.v
    Author      : Priyank Kashyap
    Affiliation : North Carolina State University, Raleigh, NC
    Date        : Oct 2018
    email       : pkashya2@ncsu.edu

    Description : Module connects to read_in_message & outputs a 32 bit value to be used for hashing

*********************************************************************************************/
module w_generator #(parameter MAX_MESSAGE_LENGTH  = 55)
	    (	 
            input  wire          trigger         ,
            input  wire          clk             ,
            input  wire          init            , 
            input  wire          reset           ,
            input  wire  [511:0] block           ,
            output reg   [31:0]  w_out            
            );

  //---------------------------------------------------------------------------
  //Generate 
  //---------------------------------------------------------------------------
  reg [31:0] w_mem [0:15];
  wire [31:0] w_new, sigma_0, sigma_1, temp_mem_14, temp_mem_9, temp_mem_1, temp_mem_0;
  reg [31:0] w_temp;
  integer i;

  assign temp_mem_14 = w_mem[14];
  assign temp_mem_9  = w_mem[9];
  assign temp_mem_1  = w_mem[1];
  assign temp_mem_0  = w_mem[0];

  assign sigma_0     = {temp_mem_1[6:0], temp_mem_1[31:7]} ^ {temp_mem_1[17:0], temp_mem_1[31:18]} ^ {temp_mem_1>>3};
  assign sigma_1     = {temp_mem_14[16:0], temp_mem_14[31:17]} ^ {temp_mem_14[18:0], temp_mem_14[31:19]} ^ {temp_mem_14>>10};
  assign w_new       = sigma_1+ temp_mem_0+ temp_mem_9+ sigma_0;

  always @(posedge clk) 
  begin 
    if(reset) 
    begin
      for(i=0; i <16; i=i+1)
        w_mem[i]<=0;
    end 
    else 
    begin
      if(init)
      begin
        w_mem[15] <= block[31 : 0];
        w_mem[14] <= block[63  :  32];
        w_mem[13] <= block[95  :  64];
        w_mem[12] <= block[127 :  96];
        w_mem[11] <= block[159 : 128];
        w_mem[10] <= block[191 : 160];
        w_mem[9]  <= block[223 : 192];
        w_mem[8]  <= block[255 : 224];
        w_mem[7]  <= block[287 : 256];
        w_mem[6]  <= block[319 : 288];
        w_mem[5]  <= block[351 : 320];
        w_mem[4]  <= block[383 : 352];
        w_mem[3]  <= block[415 : 384];
        w_mem[2]  <= block[447 : 416];
        w_mem[1]  <= block[479 : 448];
        w_mem[0]  <= block[511 : 480];
      end
      else
      	if(trigger)
      	begin
        w_temp    <= w_mem[0];
        w_mem[15] <= w_new;
        w_mem[14] <= w_mem[15];
        w_mem[13] <= w_mem[14];
        w_mem[12] <= w_mem[13];
        w_mem[11] <= w_mem[12];
        w_mem[10] <= w_mem[11];
        w_mem[9]  <= w_mem[10];
        w_mem[8]  <= w_mem[9];
        w_mem[7]  <= w_mem[8];
        w_mem[6]  <= w_mem[7];
        w_mem[5]  <= w_mem[6];
        w_mem[4]  <= w_mem[5];
        w_mem[3]  <= w_mem[4];
        w_mem[2]  <= w_mem[3];
        w_mem[1]  <= w_mem[2];
        w_mem[0]  <= w_mem[1];
      	end
    end
  end

always@(posedge clk)
begin
  if(reset)
  	w_out = 32'b0;
  else
	w_out = w_temp;
end
endmodule
