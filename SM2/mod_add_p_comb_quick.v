`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 01/11/2022 
// Design Name: 
// Module Name:    modadd quick
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
//     模加专用组合逻辑模块，要求ab都小于p(在外面处理好再输进来)
//////////////////////////////////////////////////////////////////////////////////
module mod_add_p_comb_quick (
    a,
    b,
    c
);
    input wire[255:0] a;
    input wire[255:0] b;
    output wire[255:0] c;
    parameter p257 = 257'h0FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;
    wire[256:0] add,add2;
    assign add = a + b;
    assign add2 = ( add > p257 ) ? ( add - p257 ) : add;
    assign c = add2[255:0];
endmodule
