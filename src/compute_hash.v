/*********************************************************************************************

    File name   : compute_hash.v
    Author      : Priyank Kashyap
    Affiliation : North Carolina State University, Raleigh, NC
    Date        : Oct 2018
    email       : pkashya2@ncsu.edu

    Description : Module reads in h_mmem, k_mem values and w_vec values and computes the hashed value

*********************************************************************************************/
module compute_hash #(parameter NUMBER_OF_Hs        = 8,
          parameter OUTPUT_LENGTH        = 8)
    (
      input  wire                                     clk               ,
      input  wire                                     reset             ,
      input  wire                                     trigger           ,
      input  wire  [31:0]                             hmem__dut__data   ,
      input  wire  [31:0]                             kmem__dut__data   , 
      input  wire  [31:0]                             w_in              , 
      input  wire                                     trigger_w         ,
      input  wire                                     trigger_dom_send  ,
      output reg  [31:0]                              dut__dom__data    ,  // write data
      output reg  [ $clog2(OUTPUT_LENGTH)-1:0]        dut__dom__address ,
      output reg                                      dut__dom__enable  ,
      output reg                                      dut__dom__write   ,
      output reg                                      hash_computed     , 
      output reg                                      completed_send                                      
      );

    //DOM-Mem
    reg dom__mem__enable, dom__mem__write; 
    reg  [3:0] counter;
    wire [2:0] values_to_write;
    //T
    reg [31:0] temp_a, temp_b, temp_c, temp_d, temp_e, temp_f,temp_g,temp_h;
    reg [31:0] ch, sig_1, add_1, maj, sig_0, add_2;
    //------------------------------------------------------
    //Register wire declarations
    //----------------------------------------------------
    reg [7:0]       beginning_point, data_sending_beginning;
    reg [31:0]      in_h_data, in_k_data_reg;
    reg [(NUMBER_OF_Hs*32)-1:0]   h_block, h_block_keep;
    reg [31:0] block_to_send;

    //---------------------------------------------
    //Reading in h_mem_data
    //--------------------------------------------
    reg calc_hash;

    parameter [3:0] // synopsys enum states
    waiting_for_trigger  = 4'b0000,
    hashing              = 4'b0001,
    calculating_final    = 4'b0011,
    done                 = 4'b0111;

    reg [3:0] /* synopsys enum states */ current_state, next_state;
    // synopsys state_vector current_state

    always@(posedge clk)
        if (reset) current_state <= waiting_for_trigger;
        else current_state <= next_state;
    
    //2 State FSM to control the 
    always@(*)
    begin 
        calc_hash=0; 
        hash_computed = 0;
        case (current_state) // synopsys full_case parallel_case

        waiting_for_trigger:
        begin
            calc_hash=0;
      hash_computed=0;
            if (trigger_w) 
            begin 
                next_state = hashing; 
            end
            else next_state = waiting_for_trigger;
        end
        
        hashing: 
        begin
            calc_hash=0;
            hash_computed=0;
            if(~trigger_w)
                next_state = done; 
            else 
            next_state=hashing;
        end

        done: 
        begin
          calc_hash=0;
          hash_computed=1;
          next_state=waiting_for_trigger;
        end

        default: next_state=waiting_for_trigger;
        endcase
    end



    always@(posedge clk)
    begin
      in_h_data   <= hmem__dut__data;
    end

    always@(posedge clk)
    begin
      if(reset) 
      begin
          beginning_point = 8'd255;
          h_block= {255'b0};
          h_block_keep= {255'b0};
      end
      else
      begin
          if(trigger)
          begin
            h_block      [beginning_point -: 32] = in_h_data;
            h_block_keep [beginning_point -: 32] = in_h_data;
            beginning_point = beginning_point-32;
          end
      end 
    end

    always@(h_block)
    begin
       temp_h=h_block[31 : 0];
       temp_g=h_block[63  :  32];
       temp_f=h_block[95  :  64];
       temp_e=h_block[127 :  96];
       temp_d=h_block[159 : 128];
       temp_c=h_block[191 : 160];
       temp_b=h_block[223 : 192];
       temp_a=h_block[255 : 224];
    end
  
  //------------------------------------------------------
  always@(posedge clk)
    begin
      in_k_data_reg  = kmem__dut__data;
    end

  
  always@(in_k_data_reg) 
    if(trigger_w)
    begin
      ch    = (temp_e & temp_f) ^ ( (~temp_e) & temp_g);
      sig_1 = {temp_e[5:0], temp_e[31:6]} ^ {temp_e[10:0], temp_e[31:11]} ^ {temp_e[24:0], temp_e[31:25]};
      add_1 =   in_k_data_reg+ w_in+ch + sig_1 + temp_h;

      maj   = (temp_a & temp_b) ^ (temp_a & temp_c) ^ (temp_b & temp_c);
      sig_0 = {temp_a[1:0], temp_a[31:2]} ^ {temp_a[12:0], temp_a[31:13]} ^ {temp_a[21:0], temp_a[31:22]};
      add_2 = maj+sig_0;

      h_block[31  :  0] = temp_g;
      h_block[63  : 32] = temp_f;
      h_block[95  : 64] = temp_e;
      h_block[127 : 96] = add_1+temp_d;
      h_block[159 :128] = temp_c;
      h_block[191 :160] = temp_b;
      h_block[223 :192] = temp_a;
      h_block[255 :224] = add_1+add_2;
  end
  //------------------------------------------------------------------------------
  always@(posedge clk)
  begin
    dut__dom__data    <= block_to_send;
    dut__dom__address <= counter;
    dut__dom__enable  <= dom__mem__enable;
    dut__dom__write   <= dom__mem__write;
  end
  
  assign values_to_write=3'd7;

  always@(posedge clk)
  begin
    if(reset) 
    begin
      data_sending_beginning = 8'd255;
      counter = 0;
      dut__dom__address = counter;
      dom__mem__enable  = 0;
      dom__mem__write   = 1;
      completed_send    = 1;
    end
    else
      begin
      if(trigger_dom_send)
        begin
        dom__mem__enable = 1;
        completed_send=0;
        if(counter > values_to_write)
          begin
      dom__mem__enable = 0;
          end
        else 
          begin
            block_to_send = h_block[data_sending_beginning  -:  8] + h_block_keep[data_sending_beginning -:  8]; 
            data_sending_beginning = data_sending_beginning-32;
            counter = counter+1;
            completed_send = 0;            
          end
      end
    end
  end


endmodule
