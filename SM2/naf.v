`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 15/11/2022 
// Design Name: 
// Module Name:    naf
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
//     NAF编码计算模块
//     输入数字k，输出序列h,h每一位取自-1,0,1
//     设计h每一位用2个比特，11，00，01代表-1，0，1
//////////////////////////////////////////////////////////////////////////////////
module naf (
    clk,
    rstn,
    k,
    start,
    h,
    hlength,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] k;
    input wire start;
    output wire[511:0] h;
    output wire[31:0] hlength;
    output wire done;

    // state machine
    reg[3:0] state;
    localparam IDLE = 4'b0001;
    localparam PROC = 4'b0010;
    localparam FIN  = 4'b0100;

    // state wire
    wire proc_finished;
    reg r_proc_finished;
    assign proc_finished = r_proc_finished;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE: state <= start ? PROC : IDLE;
                PROC: state <= proc_finished ? FIN : PROC;
                FIN : state <= IDLE;
            endcase
        end
    end

    // data processing
    // i is for h. each time i+2
    // h is small endian, h[i+1]h[i]=01 is h[j]=1 in algorithm
    reg[255:0] k_current;
    reg[31:0] i;
    reg[511:0] h_reg;
    // the lowest 2 bits of k
    wire[1:0] k_lowest;
    assign k_lowest = k_current[1:0];
    wire[31:0] length_counter;
    assign length_counter = ( i - 4 ) >> 1;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            k_current <= 0;
            i <= 0;
            h_reg <= 0;
            r_proc_finished <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    k_current <= k;
                    i <= 0;
                    h_reg <= 0;
                    r_proc_finished <= 0;
                end
                PROC:begin
                    case(k_lowest)
                        2'b00:begin
                            h_reg[i] <= 0;
                            h_reg[i+1] <= 0;
                            k_current <= k_current >> 1;
                            i <= i + 2;
                        end
                        2'b01:begin
                            h_reg[i] <= 1;
                            h_reg[i+1] <= 0;
                            k_current <= ( k_current - 1 ) >> 1;
                            i <= i + 2;
                        end
                        2'b10:begin
                            h_reg[i] <= 0;
                            h_reg[i+1] <= 0;
                            k_current <= k_current >> 1;
                            i <= i + 2;
                        end
                        2'b11:begin
                            h_reg[i] <= 1;
                            h_reg[i+1] <= 1;
                            k_current <= ( k_current + 1 ) >> 1;
                            i <= i + 2;
                        end
                        default:begin
                            h_reg <= h_reg;
                            i <= i;
                            k_current <= k_current;
                        end
                    endcase
                    //k_current <= k_current >> 1;
                    //i <= i + 2;
                    if(k_current==0) begin
                        r_proc_finished <= 1;
                    end
                end
                FIN:begin
                    h_reg <= h_reg;
                end
                default:begin
                    h_reg <= h_reg;
                end
            endcase
        end
    end
    
    assign h = h_reg;
    assign hlength = ( state == FIN ) ? length_counter : 0;
    assign done = ( state == FIN ) ? 1 : 0;

    /*
    function [9:0] clog2_div2;
        input[511:0] value;
        reg[511:0] temp;
        begin
            temp = value - 1;
            for( clog2_div2 = 0; temp > 0; clog2_div2 = clog2_div2 + 1) begin
                temp = temp >> 1;
            end
            clog2_div2 = clog2_div2 >> 1;
        end
    endfunction
    */

endmodule
