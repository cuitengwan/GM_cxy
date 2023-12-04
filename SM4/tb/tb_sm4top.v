`timescale 1ns/1ps
module tb_sm4top();
    reg clk;
    reg rstn;
    reg[127:0] datain;
    reg[127:0] mkin;
    reg start_input;
    reg end_input;
    reg isdec;
    wire[127:0] dataout;
    wire valid;

    sm4top sm4topinst(
        .clk(clk),
        .rstn(rstn),
        .datain(datain),
        .mkin(mkin),
        .start_input(start_input),
        .end_input(end_input),
        .isdec(isdec),
        .dataout(dataout),
        .valid(valid)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        datain <=0;
        mkin <= 0;
        start_input <= 0;
        end_input <= 0;
        isdec <= 0;
        #40;
        rstn <= 1;
        #30;
        start_input <= 1;
        #10;
        start_input <= 0;
        //datain <= 128'h681edf34d206965e86b3e94f536e4246;
        datain <= 128'h0123456789abcdeffedcba9876543210;
        mkin <= 128'h0123456789abcdeffedcba9876543210;
        isdec <= 0;
        #10;
        datain <= 0;
        mkin <= 0;
        #10;
        datain <= 128'h0123456789abcdeffedcba9876543210;
        mkin <= 128'h0123456789abcdeffedcba9876543210;
        #10;
        datain <= 0;
        mkin <= 0;
        #10;
        datain <= 128'h0123456789abcdeffedcba9876543210;
        mkin <= 128'h0123456789abcdeffedcba9876543210;
        #10;
        datain <= 0;
        mkin <= 0;
        #10;
        datain <= 128'h0123456789abcdeffedcba9876543210;
        mkin <= 128'h0123456789abcdeffedcba9876543210;
        end_input <= 1;
        #10;
        end_input <= 0;
        datain <= 0;
        mkin <= 0;
        isdec <= 0;
    end
endmodule
