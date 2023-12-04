`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 14/11/2022 
// Design Name: 
// Module Name:    sm4top
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
//     加密：先一个周期只start，再下一个周期开始数据，最后一个周期的同时last
//     解密：先一个周期只start，再下一个周期isdec和数据同时输入
//////////////////////////////////////////////////////////////////////////////////
module sm4top (
    clk,
    rstn,
    datain,
    mkin,
    start_input,
    end_input,
    isdec,
    dataout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[127:0] datain;
    input wire[127:0] mkin;
    input wire start_input;
    input wire end_input;
    input wire isdec;
    output wire[127:0] dataout;
    output wire valid;

    // isdec?
    reg SM4ISDEC;

    // memory for dec
    reg[127:0] dec_data;
    reg[127:0] dec_mk;
    reg[127:0] dec_out;
    reg dec_start;
    wire[127:0] dec_output;
    wire dec_valid;


    /* counter and states */
    reg [7:0]                   counter; // cycle counter, up to 32
    reg [15:0]             data_numbers; // how many groups of data
    reg [7:0]              currentstate;
    localparam       IDLE       = 8'b00000001;
    localparam       DATAIN     = 8'b00000010;
    localparam       CYCLE      = 8'b00000100;
    localparam       DATAOUT    = 8'b00001000;
    localparam       DECP       = 8'b00010000;
    localparam       DEC        = 8'b00100000;
    localparam       DECOUT     = 8'b01000000;
    

    // datain, datanumbers++
    // dataout, datanumbers--
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            counter <= 0;
            data_numbers <= 0;
        end
        else begin
            case(currentstate)
                IDLE:begin
                    counter <= 0;
                    data_numbers <= 0;
                end
                DATAIN:begin
                    //counter <= 0;
                    counter <= counter + 1;
                    data_numbers <= data_numbers + 1;
                end
                CYCLE:begin
                    counter <= counter + 1;
                    data_numbers <= data_numbers;
                end
                DATAOUT:begin
                    counter <= 0;
                    data_numbers <= data_numbers - 1;
                end
                default:begin
                end
            endcase
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            SM4ISDEC <= 0;
        end 
        else begin
            if(currentstate==DATAIN) begin
                SM4ISDEC <= isdec;
            end
            else begin
                SM4ISDEC <= SM4ISDEC;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            currentstate <= IDLE;
        end
        else begin
            case(currentstate)
                IDLE:begin
                    currentstate <= (start_input) ? DATAIN : IDLE;
                end
                DATAIN:begin
                    currentstate <= (end_input) ? ( isdec ? DECP : CYCLE ) : DATAIN;
                end
                CYCLE:begin
                    // caution: counter starts when data starts to input
                    // when counter>32, the state change to DATAOUT
                    // if groups of input data are more than 32, it continues inputing in DATAOUT state
                    if(counter>=33) begin
                        currentstate <= DATAOUT;
                    end
                    else begin
                    end
                end
                DATAOUT:begin // when all data finished, come to IDLE
                    currentstate <= ( data_numbers == 1 ) ? IDLE : DATAOUT;
                end
                DECP:begin // decrypt pre
                    currentstate <= DEC;
                end
                DEC:begin
                    currentstate <= dec_valid ? DECOUT : DEC;
                end
                DECOUT:begin
                    currentstate <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // dec memory
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            dec_data <= 0;
            dec_mk <= 0;
            dec_out <= 0;
            dec_start <= 0;
        end
        else begin
            case(currentstate)
                IDLE:begin
                    dec_data <= 0;
                    dec_mk <= 0;
                    dec_out <= 0;
                    dec_start <= 0;
                end
                DATAIN:begin
                    dec_data <= datain;
                    dec_mk <= mkin;
                    dec_start <= 1;
                end
                DEC:begin
                    dec_start <= 0;
                    dec_out <= dec_output;
                end
                DECOUT:begin
                end
                default:begin
                end
            endcase
        end
    end


    /* connection wires */
    wire[127:0]                  key_in;
    wire                      key_valid;
    wire[1023:0]                     rk;
    wire[127:0]                 data_in;
    wire[127:0]                data_out;

    assign key_in = mkin;
    assign data_in = datain;

    /* modules */
    // generate all the 32 rk at the same time
    key_top key_top_inst(
        .clk(clk),
        .rstn(rstn),
        .key(key_in),
        .valid(key_valid),
        .rk(rk)
    );

    // use the 32 rk and calculate 32 new X
    enc_top enc_top_inst(
        .clk(clk),
        .rstn(rstn),
        .data(data_in),
        .dataout(data_out),
        .rk(rk)
    );


    // independence decrypt module
    dec_top dec_top_inst(
        .clk(clk),
        .rstn(rstn),
        .data(dec_data),
        .mk(dec_mk),
        .startdec(dec_start),
        .dataout(dec_output),
        .valid(dec_valid)
    );

    assign dataout = SM4ISDEC ? dec_out : data_out;
    assign valid = ( (currentstate==DATAOUT) || (currentstate==DECOUT) ) ? 1 : 0;
    
endmodule
