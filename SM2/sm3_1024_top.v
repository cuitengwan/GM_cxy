`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 17/11/2022 
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
//     input: 512bit x||y , 32bit appending counter
//     output: 256 bit hash result 
//     start: start and data input in a same cycle
//////////////////////////////////////////////////////////////////////////////////
module sm3_1024_top(
    clk,
    rstn,
    datain,
    appendin,
    start,
    hashout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[511:0] datain;
    input wire[31:0] appendin;
    input wire start;
    output wire[255:0] hashout;
    output wire valid;

    // registers
    reg[511:0] hashdata1;
    reg[511:0] hashdata2;
    reg[255:0] hashresult;
    // 1024 bit wire
    wire[1023:0] hashdata;
    assign hashdata = { hashdata1, hashdata2 };

    // state machine
    reg[5:0] state;
    localparam IDLE = 6'b000001;
    localparam WAIT = 6'b000010;
    localparam PROC = 6'b000100;
    localparam FIN  = 6'b001000;

    // state signal
    wire proc_finished;
    reg start_processing;
    wire[255:0] processing_out;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? WAIT : IDLE;
                end
                WAIT:begin
                    state <= PROC;
                end
                PROC:begin
                    state <= proc_finished ? FIN : PROC;
                end
                FIN:begin
                    state <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // data
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            hashdata1 <= 0;
            hashdata2 <= 0;
            hashresult <= 0;
            start_processing <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    hashdata1 <= datain;
                    hashdata2 <= { appendin, 1'b1, 415'b0, 64'h0000000000000220};
                    hashresult <= 0;
                    start_processing <= 0;
                end
                WAIT:begin
                    hashdata1 <= hashdata1;
                    hashdata2 <= hashdata2;
                    start_processing <= 1;
                end
                PROC:begin
                    start_processing <= 0;
                    hashresult <= processing_out;
                end
                FIN:begin
                    hashresult <= hashresult;
                end
                default:begin
                end
            endcase
        end
    end

    sm3_1024_processing sm31024processing_inst(
        .clk(clk),
        .rstn(rstn),
        .datain(hashdata),
        .start(start_processing),
        .hashout(processing_out),
        .valid(proc_finished)
    );

    assign hashout = hashresult;
    assign valid = ( state == FIN ) ? 1 : 0;

endmodule
