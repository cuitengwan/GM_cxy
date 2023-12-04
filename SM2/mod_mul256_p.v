`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 07/11/2022 
// Design Name: 
// Module Name:    mod_mul256_p
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
//     Mod multiplition module. 
//     Input 256 bit A and B, output 256 bit (A*B)%p.
//     P is fixed in SM2 algorithm.
//     Used mul 256 module and speed mod module.
//////////////////////////////////////////////////////////////////////////////////
module mod_mul256_p(
    clk,
    rstn,
    a,
    b,
    start,
    c,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] a;
    input wire[255:0] b;
    input wire start;
    output wire[255:0] c;
    output wire done;

    wire mul_finished;
    wire mod_start;
    wire mod_finished;
    wire[511:0] middle;
    wire[255:0] w_final_data;
    reg[511:0] mid_data;
    reg[255:0] final_data;


    // state machine
    // idle, mul, dataload, mod, finish
    reg[5:0] state;
    localparam IDLE = 6'b000001;
    localparam MUL = 6'b000010;
    localparam LOAD = 6'b000100;
    localparam MOD = 6'b001000;
    localparam PREFIN = 6'b010000;
    localparam FIN = 6'b100000;

    // middle signals
    assign mod_start = ( state == MOD ) ? 1 : 0;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? MUL : IDLE;
                end
                MUL:begin
                    state <= mul_finished ? LOAD : MUL;
                end
                LOAD:begin
                    state <= MOD;
                end
                MOD:begin
                    state <= mod_finished ? PREFIN : MOD;
                end
                PREFIN:begin
                    state <= FIN;
                end
                FIN:begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            final_data <= 0;
        end
        else begin
            if(state==PREFIN) begin
                final_data <= w_final_data;
            end
            else begin
                final_data <= final_data;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            mid_data <= 0;
        end
        else begin
            if(mul_finished) begin
                mid_data <= middle;
            end
            else begin
                mid_data <= mid_data;
            end
        end
    end

    mul256 mul256_in_modmul(
        .clk(clk),
        .rstn(rstn),
        .a(a),
        .b(b),
        .start(start),
        .c(middle),
        .done(mul_finished)
    );

    mod256_p mod256p_in_modmul(
        .clk(clk),
        .rstn(rstn),
        .a(mid_data),
        .start(mod_start),
        .c(w_final_data),
        .done(mod_finished)
    );

    assign done = ( state == FIN ) ? 1 : 0;
    assign c = final_data;

endmodule
