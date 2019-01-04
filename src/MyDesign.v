//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------
`define MSG_LENGTH 5


module MyDesign #(parameter OUTPUT_LENGTH       = 8,
                  parameter MAX_MESSAGE_LENGTH  = 55,
                  parameter NUMBER_OF_Ks        = 64,
                  parameter NUMBER_OF_Hs        = 8 ,
                  parameter SYMBOL_WIDTH        = 8  )
            (
            //---------------------------------------------------------------------------
            // Control
            //
            output wire                                  dut__xxx__finish     ,
            input  wire                                  xxx__dut__go         ,  
            input  wire  [ $clog2(MAX_MESSAGE_LENGTH):0] xxx__dut__msg_length ,
            //---------------------------------------------------------------------------
            // Message memory interface
            //
            output wire  [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   dut__msg__address  ,  // address of letter
            output wire                                      dut__msg__enable   ,
            output wire                                      dut__msg__write    ,
            input  wire [7:0]                               msg__dut__data     ,  // read each letter
            //---------------------------------------------------------------------------
            // K memory interface
            //
            output wire  [ $clog2(NUMBER_OF_Ks)-1:0]     dut__kmem__address  ,
            output wire                                  dut__kmem__enable   ,
            output wire                                  dut__kmem__write    ,
            input  wire [31:0]                           kmem__dut__data     ,  // read data
            //---------------------------------------------------------------------------
            // H memory interface
            //
            output wire  [ $clog2(NUMBER_OF_Hs)-1:0]     dut__hmem__address  ,
            output wire                                  dut__hmem__enable   ,
            output wire                                  dut__hmem__write    ,
            input  wire [31:0]                           hmem__dut__data     ,  // read data
            //---------------------------------------------------------------------------
            // Output data memory 
            //
            output wire  [ $clog2(OUTPUT_LENGTH)-1:0]    dut__dom__address  ,
            output wire  [31:0]                          dut__dom__data     ,  // write data
            output wire                                  dut__dom__enable   ,
            output wire                                  dut__dom__write    ,
            //-------------------------------
            // General
            //
            input  wire                 clk             ,
            input  wire                 reset  

            );

  //---------------------------------------------------------------------------
  //Modified Code   
  //---------------------------------------------------------------------------
    wire trigger_msg, trigger_h, trigger_w, init, hash_complete, trigger_dom_send, completed_send;
    wire [31:0]  w_mem_out;
    wire [511:0] block;
    
    controller #(.OUTPUT_LENGTH      (OUTPUT_LENGTH     ),
         .NUMBER_OF_Ks       (NUMBER_OF_Ks      ),
         .NUMBER_OF_Hs       (NUMBER_OF_Hs      ),
                 .MAX_MESSAGE_LENGTH (MAX_MESSAGE_LENGTH))
            mem_controller (
                .clk                    (clk)                   , 
                .reset                  (reset)                 ,

        .dut__xxx__finish   (dut__xxx__finish)  ,
                .xxx__dut__go           (xxx__dut__go)          ,
                .xxx__dut__msg_length   (xxx__dut__msg_length)  ,

                .dut__msg__address      (dut__msg__address)     , 
                .dut__msg__enable       (dut__msg__enable)      ,
                .dut__msg__write        (dut__msg__write)       ,
                .trigger_msg_2          (trigger_msg)           ,

                .dut__hmem__address     (dut__hmem__address)    , 
                .dut__hmem__enable      (dut__hmem__enable)     ,
                .dut__hmem__write       (dut__hmem__write)      ,
                .trigger_h_2            (trigger_h)             ,

                .dut__kmem__address     (dut__kmem__address)     , 
                .dut__kmem__enable      (dut__kmem__enable)      ,
                .dut__kmem__write       (dut__kmem__write)       ,
                .initialize_w           (init)                   ,
        .trigger_w              (trigger_w)              ,
        .trigger_dom_send       (trigger_dom_send)       ,
                .hash_complete          (hash_complete)          ,
                .completed_send              (completed_send)
            );   

    read_in_message read_in (
                .clk                    (clk)                   , 
                .reset                  (reset)                 ,
                .xxx__dut__msg_length   (xxx__dut__msg_length)  , 
                .msg__dut__data         (msg__dut__data)        , 
                .trigger                (trigger_msg)           ,
                .block                  (block)                         
            );    

    w_generator #(.MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH))
    w_mem_gen
    (
            .trigger                    (trigger_w)             ,
            .clk                        (clk)                   ,
            .init                       (init)                  , 
            .reset                      (reset)                 ,
            .block                      (block)                 ,
            .w_out                      (w_mem_out)             
            );

    compute_hash #(.NUMBER_OF_Hs (NUMBER_OF_Hs),
           .OUTPUT_LENGTH      (OUTPUT_LENGTH     ))
        compute_hash_test
        (
                .clk                    (clk)                    ,
                .reset                  (reset)                  ,
                .trigger                (trigger_h)              ,
                .hmem__dut__data        (hmem__dut__data)        ,
                .kmem__dut__data        (kmem__dut__data)        ,
            .trigger_w      (trigger_w)              ,
            .w_in               (w_mem_out)              ,
            .hash_computed          (hash_complete)          ,
            .trigger_dom_send       (trigger_dom_send)       ,
            .dut__dom__data         (dut__dom__data)         ,
                .dut__dom__address      (dut__dom__address)      ,
                .dut__dom__enable       (dut__dom__enable)       ,
                .dut__dom__write        (dut__dom__write)        ,
                .completed_send         (completed_send)
        );
  //---------------------------------------------------------------------------

endmodule





