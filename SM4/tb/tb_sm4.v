module tb_sm4();
    reg clk;
    reg rstn;
    reg[127:0] datain;
    reg[127:0] mkin;
    reg start_input;
    reg end_input;
    wire[127:0] dataout;
    wire valid;

    sm4top sm4topinst(
        .clk(clk),
        .rstn(rstn),
        .datain(datain),
        .mkin(mkin),
        .start_input(start_input),
        .end_input(end_input),
        .dataout(dataout),
        .valid(valid)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        datain <=0 ;
        mkin <= 0;
        start_input <= 0;
        end_input <= 0;
        #20;
        rstn <= 1;
        #30;
        start_input <= 1;
        #10;
        start_input <= 0;
        datain <= 128'h01010101010101010101010101010101;
        mkin <= 128'h10101010101010101010101010101010;
        #10;
        datain <= 128'h0123456789abcdeffedcba9876543210;
        mkin <= 128'h0123456789abcdeffedcba9876543210;
        end_input <= 1;
        #10;
        end_input <= 0;
        datain <= 0;
        mkin <= 0;
    end
endmodule
