`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    p0tt2
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
//     calculate p0(tt2)
//////////////////////////////////////////////////////////////////////////////////
module p0tt2 (
    din,
    dout
);
    input wire[31:0] din;
    output wire[31:0] dout;
    wire[31:0] temp1;
    wire[31:0] temp2;

    shifter shifterp01(
        .din(din),
        .num(8'd9),
        .dout(temp1)
    );
    shifter shifterp02(
        .din(din),
        .num(8'd17),
        .dout(temp2)
    );

    assign dout = din ^ temp1 ^ temp2;
endmodule
