`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    adder
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
//     adder
//////////////////////////////////////////////////////////////////////////////////
module adder(
    a,
    b,
    c
);
    input wire[31:0] a;
    input wire[31:0] b;
    output wire[31:0] c;
    assign c = a + b;
endmodule
