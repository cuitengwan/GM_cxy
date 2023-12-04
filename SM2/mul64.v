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
//     实际使用时应该改换成multiplier IP
//////////////////////////////////////////////////////////////////////////////////
module mul64 (
    a,
    b,
    c
);
    input wire[63:0] a;
    input wire[63:0] b;
    output wire[127:0] c;
    assign c = a * b;
endmodule
