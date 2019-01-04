/*********************************************************************************************

    File name   : controller.v
    Author      : Priyank Kashyap
    Affiliation : North Carolina State University, Raleigh, NC
    Date        : Oct 2018
    email       : pkashya2@ncsu.edu

    Description : Module connects to message memory to read in message & outputs a 512 bit value to be used 
    to construct the w_vec


*********************************************************************************************/
module controller #(parameter OUTPUT_LENGTH       = 8,
                    parameter NUMBER_OF_Hs        = 8 ,
                    parameter NUMBER_OF_Ks        = 64,
                    parameter MAX_MESSAGE_LENGTH  = 55)
            (
            input  wire                                     xxx__dut__go         ,  
            input  wire  [ $clog2(MAX_MESSAGE_LENGTH):0]    xxx__dut__msg_length ,
            output reg                                     dut__xxx__finish     ,
            //Message memory
            output reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   dut__msg__address    ,  // address of letter
            output reg                                      dut__msg__enable     ,
            output reg                                      dut__msg__write      ,
            output reg                                      trigger_msg_2        ,
            //W-Generation
            output  reg                                     initialize_w         , 
            output  reg                                     trigger_w            ,
            output reg  [ $clog2(NUMBER_OF_Ks)-1:0]         dut__kmem__address   ,
            output reg                                      dut__kmem__enable    ,
            output reg                                      dut__kmem__write     ,  
            output reg                                      trigger_dom_send     ,          
            //H-Memory
            output reg  [ $clog2(NUMBER_OF_Hs)-1:0]         dut__hmem__address   ,
            output reg                                      dut__hmem__enable    ,
            output reg                                      dut__hmem__write     ,
            output reg                                      trigger_h_2          ,
            //DOM Memory
            input reg                                       completed_send       ,
            //Reset and clock
            input  wire                                     hash_complete        ,
            input  wire                                     clk                  ,
            input  wire                                     reset  
            );

  //---------------------------------------------------------------------------
  //
  //Control signals
    reg [$clog2(MAX_MESSAGE_LENGTH)-1:0] in_msg_length;
    reg en, in_go, en_finish, send_dom_data;
    reg [6:0] counter;  
    //Message memory signals & registers
    reg msg_read_done, msg__mem__enable, msg__mem__write, trigger_msg_1; 
    wire [63:0] address_range;
    //H-memory signals & registers
    reg h_read_done, h__mem__enable, h__mem__write, trigger_h_1; 
    wire [2:0] h_mem_range;
    //W-Calc
    reg k__mem__enable, k__mem__write; 
    reg done_calc;
    wire [6:0] number_of_calc;
    //DOM-Mem
    reg done_write;

    parameter [2:0] // synopsys enum states
    waiting_for_go     = 4'b000,
    reading_in         = 4'b001,
    initalize_w_stage  = 4'b010,
    compute_hash       = 4'b100,
    wait_for_hash_done = 4'b101,
    sending_data_dom   = 4'b110,
    done_hashing       = 4'b111;

    reg [3:0] /* synopsys enum states */ current_state, next_state;
    // synopsys state_vector current_state

    always@(posedge clk)
        if (reset) current_state <= waiting_for_go;
        else current_state <= next_state;
    
    //2 State FSM to control the 
    always@(*)
    begin 
        en = 0; 
        en_finish = 0;
        trigger_w = 0; 
        initialize_w  = 0; 
        send_dom_data = 0;
        trigger_dom_send = 0;
        case (current_state) // synopsys full_case parallel_case

        waiting_for_go:
        begin
            //en_finish=1;
            if (in_go) 
            begin 
                next_state = reading_in; 
            end
            else next_state = waiting_for_go;
        end

        reading_in: 
        begin
            en = 1;
            if(msg_read_done && h_read_done)  
                next_state = initalize_w_stage; 
            else 
            next_state=reading_in;
        end
        
        initalize_w_stage: 
        begin
            initialize_w = 1;
            next_state=compute_hash;
        end

        compute_hash: 
        begin
            trigger_w= 1;
            if(done_calc)
                next_state=sending_data_dom;
            else
                next_state=compute_hash;
        end

        sending_data_dom: 
        begin
            send_dom_data = 1;
            if(~completed_send)
                next_state=done_hashing;
            else
                next_state=sending_data_dom;
        end

        done_hashing: 
        begin
            en_finish = 1;
            next_state=waiting_for_go;
        end

        default: next_state=waiting_for_go;
        endcase
    end
 
    //register the inputs
    always@(posedge clk)
    begin
        in_go              <= xxx__dut__go;
        in_msg_length      <= xxx__dut__msg_length;
        dut__msg__enable   <= msg__mem__enable;
        dut__msg__write    <= msg__mem__write;
        dut__hmem__enable  <= h__mem__enable;
        dut__hmem__write   <= h__mem__write;
        dut__kmem__enable  <= k__mem__enable;
        dut__kmem__write   <= k__mem__write;
        dut__xxx__finish   <= en_finish;
        dut__kmem__address <= counter;
        dut__msg__address  <= counter;
        dut__hmem__address <= counter;
    end

    
    assign address_range= in_msg_length-1;
    assign h_mem_range= 3'd7;
    assign number_of_calc=7'd63;

    always @(posedge clk) 
        if(~en && ~trigger_w && ~send_dom_data)
            counter = 0;
        else 
            counter= counter+1;
        
    
    //-------------------------------------------------------------------
    //Message memory control
    //-------------------------------------------------------------------
    always @(posedge clk) 
    begin
        if (~en) msg_read_done = 0;
        else if(counter > address_range) msg_read_done=1;
    end

    
    always@(posedge clk)
        if (reset) 
        begin
            msg__mem__enable = 0;
            msg__mem__write  = 1;
        end
        else 
        begin
            if (~msg_read_done && en) 
            begin
                msg__mem__enable  = 1;
                msg__mem__write   = 0;
            end
            else 
            begin
                msg__mem__enable  = 0;
                msg__mem__write   = 1;
            end
        end

    //register delays to 
    always@(posedge clk)
    begin
      trigger_msg_1 <= msg__mem__enable; 
      trigger_msg_2 <= trigger_msg_1; 
    end

    //-------------------------------------------------------------------
    //H-memory control
    //-------------------------------------------------------------------
    always @(posedge clk) 
    begin
        if (~en) h_read_done = 0;
        else if(counter > h_mem_range) h_read_done=1;
    end

    always@(posedge clk)
    if (reset) 
    begin
        h__mem__enable = 0;
        h__mem__write  = 1;
    end
    else 
    begin
        if (~h_read_done && en) 
        begin
            h__mem__enable  = 1;
            h__mem__write   = 0;
        end
        else 
        begin
            h__mem__enable  = 0;
            h__mem__write   = 1;
        end
    end

    always@(posedge clk)
    begin
      trigger_h_1 <= h__mem__enable; 
      trigger_h_2 <= trigger_h_1; 
    end

  //---------------------------------------------------------------------------
  //W-Generation control
  //---------------------------------------------------------------------------
    always @(posedge clk) 
    begin
        if (~trigger_w) done_calc = 0;
        else if(counter > number_of_calc) done_calc=1;
    end

    always@(posedge clk)
    if (reset) 
    begin
        k__mem__enable = 0;
        k__mem__write  = 1;
    end
    else 
    begin
        if (trigger_w) 
        begin
            k__mem__enable  = 1;
            k__mem__write   = 0;
        end
        else 
        begin
            k__mem__enable  = 0;
            k__mem__write   = 1;
        end
    end
    //////////////////////////////////////////////
    always@(send_dom_data)
    begin
      trigger_dom_send <= send_dom_data; 
    end

endmodule

