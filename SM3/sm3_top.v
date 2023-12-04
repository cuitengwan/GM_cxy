`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 22/11/2022 
// Design Name: 
// Module Name:    SM3 top
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//     Top module of SM3 algorithm
//     input: any length data, 512 bit each group, and it's bit length L
//     output: 256 bit hash result 
//     tip: to save space, the max length of L is in parameter
//     start: start and 5 groups of data input in a same cycle
//////////////////////////////////////////////////////////////////////////////////
module sm3_top(
    clk,
    rstn,
    datain1,
    datain2,
    datain3,
    datain4,
    datain5,
    l,
    start,
    hashout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[511:0] datain1;
    input wire[511:0] datain2;
    input wire[511:0] datain3;
    input wire[511:0] datain4;
    input wire[511:0] datain5;
    input wire[31:0] l;
    input wire start;
    output wire[255:0] hashout;
    output wire valid;

    // max length ( 512*(x-1) )
    parameter SM3_MAXLEN = 6; // but max input length is 512*5

    // memory
    reg[511:0] din_memory[0:SM3_MAXLEN-1];
    reg[31:0] vector_A;
    reg[31:0] vector_B;
    reg[31:0] vector_C;
    reg[31:0] vector_D;
    reg[31:0] vector_E;
    reg[31:0] vector_F;
    reg[31:0] vector_G;
    reg[31:0] vector_H;
    reg[31:0] l_memory;
    reg[8:0] length_last_memory;
    reg[22:0] length_group_memory;
    reg[255:0] hashresult;

    wire[31:0] w_length_group_memory;
    wire[63:0] w_length_memory;
    assign w_length_group_memory = { 9'b0, length_group_memory };
    assign w_length_memory = { 32'b0, l_memory };
    wire[31:0] w_length_group_memory_minus1;
    assign w_length_group_memory_minus1 = w_length_group_memory - 1;
    //wire[31:0] l_memory_minus1; // especially for data which is exactly 512,1024,1536,2048 bits
    //assign l_memory_minus1 = l_memory - 1;

    wire[31:0]              IV_A;
    wire[31:0]              IV_B;
    wire[31:0]              IV_C;
    wire[31:0]              IV_D;
    wire[31:0]              IV_E;
    wire[31:0]              IV_F;
    wire[31:0]              IV_G;
    wire[31:0]              IV_H;
    assign IV_A = 32'h7380166F;
    assign IV_B = 32'h4914b2b9;
    assign IV_C = 32'h172442d7;
    assign IV_D = 32'hda8a0600;
    assign IV_E = 32'ha96f30bc;
    assign IV_F = 32'h163138aa;
    assign IV_G = 32'he38dee4d;
    assign IV_H = 32'hb0fb0e4e;


    // state machine
    reg[9:0] state;
    localparam IDLE     = 10'b0000000001;
    localparam DIN      = 10'b0000000010;
    localparam WAITPAD  = 10'b0000000100;
    localparam PAD      = 10'b0000001000;
    localparam AFTERPAD = 10'b0000010000;
    localparam WAITCYC  = 10'b0000100000;
    localparam CYCLE    = 10'b0001000000;
    localparam UPDATE   = 10'b0010000000;
    localparam FINP     = 10'b0100000000;
    localparam FIN      = 10'b1000000000;

    // state signal
    wire pad_finished;
    wire cycle_finished;
    wire proc_finished;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? DIN : IDLE;
                end
                DIN:begin
                    state <= WAITPAD;
                end
                WAITPAD:begin
                    state <= PAD;
                end
                PAD:begin
                    state <= pad_finished ? AFTERPAD : PAD;
                end
                AFTERPAD:begin
                    state <= WAITCYC;
                end
                WAITCYC:begin
                    state <= CYCLE;
                end
                CYCLE:begin
                    state <= cycle_finished ? UPDATE : CYCLE;
                end
                UPDATE:begin
                    state <= proc_finished ? FINP : WAITCYC;
                end
                FINP:begin
                    state <= FIN;
                end
                FIN:begin
                    state <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // regs and wires in module
    reg [511:0]           padding_din;
    reg [63:0]         padding_length;
    reg                 padding_start;
    wire[1023:0]         padding_dout;
    wire                padding_valid;
    wire               padding_double;
    reg [511:0]        process_datain;
    reg                 process_start;
    wire[255:0]       process_hashout;
    wire                process_valid;

    reg [1023:0]       r_padding_dout;
    reg              r_padding_double;
    reg [255:0]     r_process_hashout;
    

    // data
    integer i;
    reg[3:0] proc_counter;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            din_memory[0] <= 0;
            din_memory[1] <= 0;
            din_memory[2] <= 0;
            din_memory[3] <= 0;
            din_memory[4] <= 0;
            din_memory[5] <= 0;
            vector_A <= IV_A;
            vector_B <= IV_B;
            vector_C <= IV_C;
            vector_D <= IV_D;
            vector_E <= IV_E;
            vector_F <= IV_F;
            vector_G <= IV_G;
            vector_H <= IV_H;
            l_memory <= 0;
            length_group_memory <= 0;
            length_last_memory <= 0;
            hashresult <= 0;
            padding_din <= 0;
            padding_length <= 0;
            padding_start <= 0;
            process_datain <= 0;
            process_start <= 0;
            r_padding_dout <= 0;
            r_padding_double <= 0;
            proc_counter <= 0;
            r_process_hashout <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    din_memory[0] <= datain1;
                    din_memory[1] <= datain2;
                    din_memory[2] <= datain3;
                    din_memory[3] <= datain4;
                    din_memory[4] <= datain5;
                    din_memory[5] <= 0;
                    vector_A <= IV_A;
                    vector_B <= IV_B;
                    vector_C <= IV_C;
                    vector_D <= IV_D;
                    vector_E <= IV_E;
                    vector_F <= IV_F;
                    vector_G <= IV_G;
                    vector_H <= IV_H;
                    l_memory <= l;
                    length_group_memory <= l[31:9];
                    //length_group_memory <= l_memory_minus1[31:9];
                    length_last_memory <= l[8:0];
                    hashresult <= 0;
                    padding_din <= 0;
                    padding_length <= 0;
                    padding_start <= 0;
                    process_datain <= 0;
                    process_start <= 0;
                    r_padding_dout <= 0;
                    r_padding_double <= 0;
                    proc_counter <= 0;
                    r_process_hashout <= 0;
                end
                DIN:begin
                end
                WAITPAD:begin // last group 
                    // padding_din <= din_memory[w_length_group_memory];
                    // change for just 512x bits
                    if(length_last_memory) begin
                        padding_din <= din_memory[w_length_group_memory];
                    end
                    else begin
                        padding_din <= din_memory[w_length_group_memory-1];
                    end
                    padding_length <= w_length_memory;
                    padding_start <= 1;
                end
                PAD:begin
                    padding_start <= 0;
                    r_padding_dout <= padding_dout;
                    r_padding_double <= padding_double;
                end
                AFTERPAD:begin
                    /*
                    din_memory[w_length_group_memory] <= r_padding_dout[1023:512];
                    if(r_padding_double) begin
                        din_memory[w_length_group_memory+1] <= r_padding_dout[511:0];
                        //length_group_memory <= length_group_memory + 1;
                        if(length_last_memory!=0) begin // if is exactly 512 bit, dont need to add
                            length_group_memory <= length_group_memory + 1;
                        end
                    end
                    else begin
                    end
                    */
                    if(length_last_memory) begin
                        din_memory[w_length_group_memory] <= r_padding_dout[1023:512];
                        if(r_padding_double) begin
                            din_memory[w_length_group_memory+1] <= r_padding_dout[511:0];
                            //length_group_memory <= length_group_memory + 1;
                        end
                        else begin
                        end
                    end
                    else begin
                        din_memory[w_length_group_memory] <= r_padding_dout[511:0];
                    end
                end
                WAITCYC:begin
                    process_datain <= din_memory[proc_counter];
                    process_start <= 1;
                end
                CYCLE:begin
                    process_start <= 0;
                    r_process_hashout <= process_hashout;
                end
                UPDATE:begin
                    proc_counter = proc_counter + 1;
                    vector_A <= r_process_hashout[255:224];
                    vector_B <= r_process_hashout[223:192];
                    vector_C <= r_process_hashout[191:160];
                    vector_D <= r_process_hashout[159:128];
                    vector_E <= r_process_hashout[127:96];
                    vector_F <= r_process_hashout[95:64];
                    vector_G <= r_process_hashout[63:32];
                    vector_H <= r_process_hashout[31:0];
                end
                FINP:begin
                    hashresult <= { vector_A, vector_B, vector_C, vector_D,
                                    vector_E, vector_F, vector_G, vector_H };
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end

    // modules
    sm3_padding padding_in_universalsm3(
        .clk(clk),
        .rstn(rstn),
        .din(padding_din),
        .length(padding_length),
        .start(padding_start),
        .dout(padding_dout),
        .valid(padding_valid),
        .double(padding_double)
    );

    sm3_processing processing_in_universalsm3(
        .clk(clk),
        .rstn(rstn),
        .datain(process_datain),
        .hashin_a(vector_A),
        .hashin_b(vector_B),
        .hashin_c(vector_C),
        .hashin_d(vector_D),
        .hashin_e(vector_E),
        .hashin_f(vector_F),
        .hashin_g(vector_G),
        .hashin_h(vector_H),
        .start(process_start),
        .hashout(process_hashout),
        .valid(process_valid)
    );


    assign pad_finished = padding_valid;
    assign cycle_finished = process_valid;
    assign proc_finished = ( proc_counter >= w_length_group_memory ) ? 1 : 0;
    //assign proc_finished = ( proc_counter >= w_length_group_memory_minus1 ) ? 1 : 0;


    assign hashout = hashresult;
    assign valid = ( state == FIN ) ? 1 : 0;

endmodule
