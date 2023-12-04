`timescale  1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 01/11/2022 
// Design Name: 
// Module Name:   
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
//     SOS算法 调用1个64乘法器构建256乘法器
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module mul256 (
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
    output wire[511:0] c;
    output wire done;

    // 寄存器定义，输入划分为64位块，用R记录8组结果，carry记录进位
    reg  [63:0]     A_3,A_2,A_1,A_0;
    reg  [63:0]     B_3,B_2,B_1,B_0;
    wire            flg_AB_load;
    reg  [63:0]     R [7:0];
    wire            flg_R_load;
    reg  [64:0]     reg_carry;
    reg             done_reg;

    // 调用64位乘法器
    wire [63:0]     mul64_a;
    wire [63:0]     mul64_b;
    wire [127:0]    mul64_c;

    mul64 mul64inst(
        .a(mul64_a),
        .b(mul64_b),
        .c(mul64_c)
    );

    // counter
    reg  [3:0]      counter;
    wire [1:0]      counter_a;
    wire [1:0]      counter_b;
    wire [2:0]      counter_all;
    wire            counter_add;
    wire            counter_clr;

    reg             start_reg;
    wire            proc_reg_w;
    reg             proc_reg;

    assign          counter_add = ~(counter == 4'd0) || proc_reg;
    assign          counter_clr = counter_add && counter == 4'hf;
    assign          {counter_b,counter_a} = counter;
    assign          counter_all = counter_a + counter_b;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            start_reg <= 1'b0;
            proc_reg <= 1'b0;
        end 
        else begin
            start_reg <= start;
            proc_reg <= proc_reg_w;
        end
    end

    assign proc_reg_w = start && ~start_reg; // on processing

    // counter logic
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            counter <= 4'b0;
        end
        else if(counter_clr)begin
            counter <= 4'b0;
        end
        else if(counter_add)begin
            counter <= counter + 1'b1;
        end
    end
    

    // input logic
    // one cycle delay
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            {A_3,A_2,A_1,A_0}   <=  256'd0;
            {B_3,B_2,B_1,B_0}   <=  256'd0;
        end
        else if(flg_AB_load) begin
            {A_3,A_2,A_1,A_0}   <=  a;
            {B_3,B_2,B_1,B_0}   <=  b;
        end
        else begin
        end
    end
    assign flg_AB_load = proc_reg_w;
    assign flg_R_load = flg_AB_load;

    //multiply
    assign mul64_a = counter_b == 2'b00 ? B_0:
                       counter_b == 2'b01 ? B_1:
                       counter_b == 2'b10 ? B_2:
                       counter_b == 2'b11 ? B_3:
                       64'd0;
    assign mul64_b = counter_a == 2'b00 ? A_0:
                       counter_a == 2'b01 ? A_1:
                       counter_a == 2'b10 ? A_2:
                       counter_a == 2'b11 ? A_3:
                       64'd0;

    integer i;
    always @(posedge clk or negedge rstn) begin
        if(!rstn | flg_R_load) begin
            for ( i = 0; i < 8 ;i = i + 1 ) begin
                R[i] <= 64'b0;
            end
            reg_carry <= 65'd0;
        end
        else begin
            case (counter_b)
            3'd0:
            begin
                     if(counter_a == 2'd0){reg_carry,R[0]}        <=    mul64_c + R[0];
                else if(counter_a == 2'd1){reg_carry,R[1]}        <=    mul64_c + reg_carry + R[1];
                else if(counter_a == 2'd2){reg_carry,R[2]}        <=    mul64_c + reg_carry + R[2];
                else if(counter_a == 2'd3){R[4],     R[3]}        <=    mul64_c + reg_carry + R[3];
            end
            3'd1:
            begin
                     if(counter_a == 2'd0){reg_carry,R[1]}        <=    mul64_c + R[1];
                else if(counter_a == 2'd1){reg_carry,R[2]}        <=    mul64_c + reg_carry + R[2];
                else if(counter_a == 2'd2){reg_carry,R[3]}        <=    mul64_c + reg_carry + R[3];
                else if(counter_a == 2'd3){R[5],     R[4]}        <=    mul64_c + reg_carry + R[4];
            end
            3'd2:
            begin
                     if(counter_a == 2'd0){reg_carry,R[2]}        <=    mul64_c + R[2];
                else if(counter_a == 2'd1){reg_carry,R[3]}        <=    mul64_c + reg_carry + R[3];
                else if(counter_a == 2'd2){reg_carry,R[4]}        <=    mul64_c + reg_carry + R[4];
                else if(counter_a == 2'd3){R[6],     R[5]}        <=    mul64_c + reg_carry + R[5];
            end
            3'd3:
            begin
                     if(counter_a == 2'd0){reg_carry,R[3]}        <=    mul64_c + R[3];
                else if(counter_a == 2'd1){reg_carry,R[4]}        <=    mul64_c + reg_carry + R[4];
                else if(counter_a == 2'd2){reg_carry,R[5]}        <=    mul64_c + reg_carry + R[5];
                else if(counter_a == 2'd3){R[7],     R[6]}        <=    mul64_c + reg_carry + R[6];
            end
            endcase
        end
    end

    // finish signal
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            done_reg <= 1'b0;
        end
        else begin
            done_reg <= counter_add && counter == 4'hf;
        end
    end

    assign c = {R[7],R[6],R[5],R[4],R[3],R[2],R[1],R[0]};
    assign done = done_reg;

endmodule










/*
`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 최신융 Choi sin yuu
// 
// Create Date:    12:00:00 01/11/2022 
// Design Name: 
// Module Name:    mul256
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
//     256位乘法器，输出512位。
//     KO
//////////////////////////////////////////////////////////////////////////////////
module mul256(
    input           clk,
    input           rstn,
    input           start,
    input [255:0]   a,
    input [255:0]   b,
    output          done,
    output [511:0]  c
);

    wire mul_vld_i;
    wire [255:0] mul_a_i;
    wire [255:0] mul_b_i;
    wire mul_fin_o;
    wire [511:0] mul_r_o;

    assign mul_vld_i = start;
    assign mul_a_i = a;
    assign mul_b_i = b;
    assign done = mul_fin_o;
    assign c = mul_r_o;


//输入信号分割 {A,B}x{C,D} 与预处理
wire [127:0]        mul_A;
wire [127:0]        mul_B;
wire [127:0]        mul_C;
wire [127:0]        mul_D;
reg  [128:0]        mul_CpD;
reg  [128:0]        mul_ApB;
reg [129:0]         mul_ApBxCpD_adj; //129位使用128位乘法器的修正

//128位 无符号数乘法 IP
wire [127: 0]       mul_128a_a;
wire [127: 0]       mul_128a_b;
wire [255 : 0]      mul_128a_p;

wire [127: 0]       mul_128b_a;
wire [127: 0]       mul_128b_b;
wire [255 : 0]      mul_128b_p;

wire [127: 0]       mul_128c_a;
wire [127: 0]       mul_128c_b;
wire [255 : 0]      mul_128c_p;

//对有效信号取上升沿，并产生运算结束信号
reg                 mul_vld_r1;
wire                mul_vld_redge;
reg                 mul_fin;

//处理cycle标志
wire                mul_cyc_0;
reg                 mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5,mul_cyc_6;

//运算中间变量
reg  [383:0]        mul_r_mid;   
reg  [383:0]        mul_r_mid_1;   

//输入信号分割 {A,B}x{C,D}
assign              {mul_A,mul_B}   =   mul_a_i;
assign              {mul_C,mul_D}   =   mul_b_i;

//切断路径上的加法器
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        mul_CpD     <=   129'd0;
        mul_ApB     <=   129'd0;
    end else if(mul_cyc_0)begin
        mul_CpD     <=   mul_D + mul_C; 
        mul_ApB     <=   mul_B + mul_A;
    end
end

//对乘法进行修正
//假设 mul_CpD[0] && ~mul_ApB[0] 则代表少加了 mul_ApB，反之相同
//假设 mul_CpD[0] &&  mul_ApB[0] 则代表少加了 mul_ApB mul_CpD，多加了 1，修正之
// assign              mul_ApBxCpD_adj =   mul_cyc_4 ? (
//                                         ( mul_CpD[0] && ~mul_ApB[0])? mul_ApB :
//                                         (~mul_CpD[0] &&  mul_ApB[0])? mul_CpD :
//                                         ( mul_CpD[0] &&  mul_ApB[0])? mul_ApB + mul_CpD - 1'b1:
//                                         65'd0):
//                                         65'd0
//                                     ;

//使用寄存器进行 mul_ApBxCpD_adj 的累加，减少关键路径
always @(posedge clk or negedge rstn) begin
    if(~rstn | mul_cyc_0) begin
        mul_ApBxCpD_adj              <= 129'b0;
    end else if(mul_cyc_1 && mul_CpD[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj + mul_ApB;
    end else if(mul_cyc_2 && mul_ApB[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj + mul_CpD;
    end else if(mul_cyc_3 && mul_ApB[0] && mul_CpD[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj - 1'b1;
    end
end


//分配乘法器的输入 乘法器A分配 AxC B分配 BxD C分配（A+B）x（C+D）
assign              mul_128a_a  =   mul_A;
assign              mul_128a_b  =   mul_C;
assign              mul_128b_a  =   mul_B;
assign              mul_128b_b  =   mul_D;
assign              mul_128c_a  =   mul_CpD[128-:128];//129位使用128位乘法器
assign              mul_128c_b  =   mul_ApB[128-:128];//129位使用128位乘法器

//对有效信号取上升沿，并产生运算结束信号
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        mul_vld_r1              <= 1'b0;
    end else begin
        mul_vld_r1              <= mul_vld_i;
    end
end

assign              mul_vld_redge   =   mul_vld_i && ~mul_vld_r1;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        mul_fin              <= 1'b0;
    end else begin
        mul_fin              <= mul_cyc_4;
    end
end

//处理cycle标志
assign              mul_cyc_0       =   mul_vld_redge;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        {mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5,mul_cyc_6}<= 6'b0;
    end else begin
        {mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5,mul_cyc_6}<= 
        {mul_cyc_0,mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5};
    end
end

//运算中间变量 mul_cyc_3 运算 此处保留左移128bit，以减少运算位
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        mul_r_mid              <= 384'b0;
    end else if(mul_cyc_3)begin//{AC,BD}
        mul_r_mid              <= {mul_128a_p,mul_128b_p[255-:128]} - {128'd0,mul_128a_p} - {128'd0,mul_128b_p}; 
    end
end

//运算结果 mul_cyc_4 运算 此处保留左移128bit，以减少运算位
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        mul_r_mid_1              <= 384'b0;
    end else if(mul_cyc_4)begin //mul_64r_ApBxCpD
        mul_r_mid_1              <= {mul_128c_p,2'b00} + mul_r_mid + {mul_ApBxCpD_adj};//mul_64r_ApBxCpD 需要修正
    end
end

//128位分治算法乘法器，运算周期 4，寄存器输出
mul128 U_mul_128_a (
    .clk(clk), 
    .rst_n(rstn), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_128a_a), 
    .mul_b_i(mul_128a_b), 
    .mul_r_o(mul_128a_p),
    .mul_fin_o()
    );

mul128 U_mul_128_b (
    .clk(clk), 
    .rst_n(rstn), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_128b_a), 
    .mul_b_i(mul_128b_b), 
    .mul_r_o(mul_128b_p),
    .mul_fin_o()
    );

mul128 U_mul_128_c (
    .clk(clk), 
    .rst_n(rstn), 
    .mul_vld_i(mul_vld_r1), //等待加法结束后的一周期开始
    .mul_a_i(mul_128c_a), 
    .mul_b_i(mul_128c_b), 
    .mul_r_o(mul_128c_p),
    .mul_fin_o()
    );

//输出控制
assign              mul_fin_o       =       mul_fin;
//此处恢复低128bit
assign              mul_r_o         =       {mul_r_mid_1,mul_128b_p[127:0]};

endmodule


*/