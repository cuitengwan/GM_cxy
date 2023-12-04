`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 24/1/2023 
// Design Name: 
// Module Name:    rkcalc
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
//     calculate a rk
//     rki = Ki+4 = Ki ^ T'( Ki+1 ^ Ki+2 ^ Ki+3 ^ CKi) 
//////////////////////////////////////////////////////////////////////////////////
module rk_calculate (
    k0,
    k1,
    k2,
    k3,
    k4,
    round
);
    input wire[31:0] k0;
    input wire[31:0] k1;
    input wire[31:0] k2;
    input wire[31:0] k3;
    output wire[31:0] k4;
    input wire[31:0] round;

    wire[31:0] ck;
    wire[7:0] currenttime;
    assign currenttime = round[7:0];
    assign ck = cki(currenttime);
    wire[31:0] bracket;
    assign bracket = k1 ^ k2 ^ k3 ^ ck;
    wire[31:0] after_sb;
    wire[7:0] temp1;
    wire[7:0] temp2;
    wire[7:0] temp3;
    wire[7:0] temp4;
    assign temp1 = lut_sb(bracket[31:24]);
    assign temp2 = lut_sb(bracket[23:16]);
    assign temp3 = lut_sb(bracket[15:8]);
    assign temp4 = lut_sb(bracket[7:0]);
    assign after_sb = { temp1, temp2, temp3, temp4 };
    wire[31:0] Tp;
    assign Tp = after_sb ^ ( (after_sb<<13)|(after_sb>>19) ) ^ ( (after_sb<<23)|(after_sb>>9) ) ;
    assign k4 = k0 ^ Tp;

    function[31: 0] cki;
        input[ 7: 0] sin;
        case (sin)
            8'd0:   cki = 32'h00070e15;
            8'd1:   cki = 32'h1c232a31;
            8'd2:   cki = 32'h383f464d;
            8'd3:   cki = 32'h545b6269;
            8'd4:   cki = 32'h70777e85;
            8'd5:   cki = 32'h8c939aa1;
            8'd6:   cki = 32'ha8afb6bd;
            8'd7:   cki = 32'hc4cbd2d9;
            8'd8:   cki = 32'he0e7eef5;
            8'd9:   cki = 32'hfc030a11;
            8'd10:  cki = 32'h181f262d;
            8'd11:  cki = 32'h343b4249;
            8'd12:  cki = 32'h50575e65;
            8'd13:  cki = 32'h6c737a81;
            8'd14:  cki = 32'h888f969d;
            8'd15:  cki = 32'ha4abb2b9;
            8'd16:  cki = 32'hc0c7ced5;
            8'd17:  cki = 32'hdce3eaf1;
            8'd18:  cki = 32'hf8ff060d;
            8'd19:  cki = 32'h141b2229;
            8'd20:  cki = 32'h30373e45;
            8'd21:  cki = 32'h4c535a61;
            8'd22:  cki = 32'h686f767d;
            8'd23:  cki = 32'h848b9299;
            8'd24:  cki = 32'ha0a7aeb5;
            8'd25:  cki = 32'hbcc3cad1;
            8'd26:  cki = 32'hd8dfe6ed;
            8'd27:  cki = 32'hf4fb0209;
            8'd28:  cki = 32'h10171e25;
            8'd29:  cki = 32'h2c333a41;
            8'd30:  cki = 32'h484f565d;
            8'd31:  cki = 32'h646b7279;
            default:cki = 32'h00000000;
        endcase
    endfunction


    function[ 7: 0] lut_sb;
        input[ 7: 0] sin;
        case (sin)
            8'h00: lut_sb = 8'hd6; 8'h01: lut_sb = 8'h90; 8'h02: lut_sb = 8'he9; 8'h03: lut_sb = 8'hfe; 8'h04: lut_sb = 8'hcc; 8'h05: lut_sb = 8'he1; 8'h06: lut_sb = 8'h3d; 8'h07: lut_sb = 8'hb7;
            8'h10: lut_sb = 8'h2b; 8'h11: lut_sb = 8'h67; 8'h12: lut_sb = 8'h9a; 8'h13: lut_sb = 8'h76; 8'h14: lut_sb = 8'h2a; 8'h15: lut_sb = 8'hbe; 8'h16: lut_sb = 8'h04; 8'h17: lut_sb = 8'hc3;
            8'h20: lut_sb = 8'h9c; 8'h21: lut_sb = 8'h42; 8'h22: lut_sb = 8'h50; 8'h23: lut_sb = 8'hf4; 8'h24: lut_sb = 8'h91; 8'h25: lut_sb = 8'hef; 8'h26: lut_sb = 8'h98; 8'h27: lut_sb = 8'h7a;
            8'h30: lut_sb = 8'he4; 8'h31: lut_sb = 8'hb3; 8'h32: lut_sb = 8'h1c; 8'h33: lut_sb = 8'ha9; 8'h34: lut_sb = 8'hc9; 8'h35: lut_sb = 8'h08; 8'h36: lut_sb = 8'he8; 8'h37: lut_sb = 8'h95;
            8'h40: lut_sb = 8'h47; 8'h41: lut_sb = 8'h07; 8'h42: lut_sb = 8'ha7; 8'h43: lut_sb = 8'hfc; 8'h44: lut_sb = 8'hf3; 8'h45: lut_sb = 8'h73; 8'h46: lut_sb = 8'h17; 8'h47: lut_sb = 8'hba;
            8'h50: lut_sb = 8'h68; 8'h51: lut_sb = 8'h6b; 8'h52: lut_sb = 8'h81; 8'h53: lut_sb = 8'hb2; 8'h54: lut_sb = 8'h71; 8'h55: lut_sb = 8'h64; 8'h56: lut_sb = 8'hda; 8'h57: lut_sb = 8'h8b;
            8'h60: lut_sb = 8'h1e; 8'h61: lut_sb = 8'h24; 8'h62: lut_sb = 8'h0e; 8'h63: lut_sb = 8'h5e; 8'h64: lut_sb = 8'h63; 8'h65: lut_sb = 8'h58; 8'h66: lut_sb = 8'hd1; 8'h67: lut_sb = 8'ha2;
            8'h70: lut_sb = 8'hd4; 8'h71: lut_sb = 8'h00; 8'h72: lut_sb = 8'h46; 8'h73: lut_sb = 8'h57; 8'h74: lut_sb = 8'h9f; 8'h75: lut_sb = 8'hd3; 8'h76: lut_sb = 8'h27; 8'h77: lut_sb = 8'h52;
            8'h80: lut_sb = 8'hea; 8'h81: lut_sb = 8'hbf; 8'h82: lut_sb = 8'h8a; 8'h83: lut_sb = 8'hd2; 8'h84: lut_sb = 8'h40; 8'h85: lut_sb = 8'hc7; 8'h86: lut_sb = 8'h38; 8'h87: lut_sb = 8'hb5;
            8'h90: lut_sb = 8'he0; 8'h91: lut_sb = 8'hae; 8'h92: lut_sb = 8'h5d; 8'h93: lut_sb = 8'ha4; 8'h94: lut_sb = 8'h9b; 8'h95: lut_sb = 8'h34; 8'h96: lut_sb = 8'h1a; 8'h97: lut_sb = 8'h55;
            8'hA0: lut_sb = 8'h1d; 8'hA1: lut_sb = 8'hf6; 8'hA2: lut_sb = 8'he2; 8'hA3: lut_sb = 8'h2e; 8'hA4: lut_sb = 8'h82; 8'hA5: lut_sb = 8'h66; 8'hA6: lut_sb = 8'hca; 8'hA7: lut_sb = 8'h60;
            8'hB0: lut_sb = 8'hd5; 8'hB1: lut_sb = 8'hdb; 8'hB2: lut_sb = 8'h37; 8'hB3: lut_sb = 8'h45; 8'hB4: lut_sb = 8'hde; 8'hB5: lut_sb = 8'hfd; 8'hB6: lut_sb = 8'h8e; 8'hB7: lut_sb = 8'h2f;
            8'hC0: lut_sb = 8'h8d; 8'hC1: lut_sb = 8'h1b; 8'hC2: lut_sb = 8'haf; 8'hC3: lut_sb = 8'h92; 8'hC4: lut_sb = 8'hbb; 8'hC5: lut_sb = 8'hdd; 8'hC6: lut_sb = 8'hbc; 8'hC7: lut_sb = 8'h7f;
            8'hD0: lut_sb = 8'h0a; 8'hD1: lut_sb = 8'hc1; 8'hD2: lut_sb = 8'h31; 8'hD3: lut_sb = 8'h88; 8'hD4: lut_sb = 8'ha5; 8'hD5: lut_sb = 8'hcd; 8'hD6: lut_sb = 8'h7b; 8'hD7: lut_sb = 8'hbd;
            8'hE0: lut_sb = 8'h89; 8'hE1: lut_sb = 8'h69; 8'hE2: lut_sb = 8'h97; 8'hE3: lut_sb = 8'h4a; 8'hE4: lut_sb = 8'h0c; 8'hE5: lut_sb = 8'h96; 8'hE6: lut_sb = 8'h77; 8'hE7: lut_sb = 8'h7e;
            8'hF0: lut_sb = 8'h18; 8'hF1: lut_sb = 8'hf0; 8'hF2: lut_sb = 8'h7d; 8'hF3: lut_sb = 8'hec; 8'hF4: lut_sb = 8'h3a; 8'hF5: lut_sb = 8'hdc; 8'hF6: lut_sb = 8'h4d; 8'hF7: lut_sb = 8'h20;

            8'h08: lut_sb = 8'h16; 8'h09: lut_sb = 8'hb6; 8'h0A: lut_sb = 8'h14; 8'h0B: lut_sb = 8'hc2; 8'h0C: lut_sb = 8'h28; 8'h0D: lut_sb = 8'hfb; 8'h0E: lut_sb = 8'h2c; 8'h0F: lut_sb = 8'h05;
            8'h18: lut_sb = 8'haa; 8'h19: lut_sb = 8'h44; 8'h1A: lut_sb = 8'h13; 8'h1B: lut_sb = 8'h26; 8'h1C: lut_sb = 8'h49; 8'h1D: lut_sb = 8'h86; 8'h1E: lut_sb = 8'h06; 8'h1F: lut_sb = 8'h99;
            8'h28: lut_sb = 8'h33; 8'h29: lut_sb = 8'h54; 8'h2A: lut_sb = 8'h0b; 8'h2B: lut_sb = 8'h43; 8'h2C: lut_sb = 8'hed; 8'h2D: lut_sb = 8'hcf; 8'h2E: lut_sb = 8'hac; 8'h2F: lut_sb = 8'h62;
            8'h38: lut_sb = 8'h80; 8'h39: lut_sb = 8'hdf; 8'h3A: lut_sb = 8'h94; 8'h3B: lut_sb = 8'hfa; 8'h3C: lut_sb = 8'h75; 8'h3D: lut_sb = 8'h8f; 8'h3E: lut_sb = 8'h3f; 8'h3F: lut_sb = 8'ha6;
            8'h48: lut_sb = 8'h83; 8'h49: lut_sb = 8'h59; 8'h4A: lut_sb = 8'h3c; 8'h4B: lut_sb = 8'h19; 8'h4C: lut_sb = 8'he6; 8'h4D: lut_sb = 8'h85; 8'h4E: lut_sb = 8'h4f; 8'h4F: lut_sb = 8'ha8;
            8'h58: lut_sb = 8'hf8; 8'h59: lut_sb = 8'heb; 8'h5A: lut_sb = 8'h0f; 8'h5B: lut_sb = 8'h4b; 8'h5C: lut_sb = 8'h70; 8'h5D: lut_sb = 8'h56; 8'h5E: lut_sb = 8'h9d; 8'h5F: lut_sb = 8'h35;
            8'h68: lut_sb = 8'h25; 8'h69: lut_sb = 8'h22; 8'h6A: lut_sb = 8'h7c; 8'h6B: lut_sb = 8'h3b; 8'h6C: lut_sb = 8'h01; 8'h6D: lut_sb = 8'h21; 8'h6E: lut_sb = 8'h78; 8'h6F: lut_sb = 8'h87;
            8'h78: lut_sb = 8'h4c; 8'h79: lut_sb = 8'h36; 8'h7A: lut_sb = 8'h02; 8'h7B: lut_sb = 8'he7; 8'h7C: lut_sb = 8'ha0; 8'h7D: lut_sb = 8'hc4; 8'h7E: lut_sb = 8'hc8; 8'h7F: lut_sb = 8'h9e;
            8'h88: lut_sb = 8'ha3; 8'h89: lut_sb = 8'hf7; 8'h8A: lut_sb = 8'hf2; 8'h8B: lut_sb = 8'hce; 8'h8C: lut_sb = 8'hf9; 8'h8D: lut_sb = 8'h61; 8'h8E: lut_sb = 8'h15; 8'h8F: lut_sb = 8'ha1;
            8'h98: lut_sb = 8'had; 8'h99: lut_sb = 8'h93; 8'h9A: lut_sb = 8'h32; 8'h9B: lut_sb = 8'h30; 8'h9C: lut_sb = 8'hf5; 8'h9D: lut_sb = 8'h8c; 8'h9E: lut_sb = 8'hb1; 8'h9F: lut_sb = 8'he3;
            8'hA8: lut_sb = 8'hc0; 8'hA9: lut_sb = 8'h29; 8'hAA: lut_sb = 8'h23; 8'hAB: lut_sb = 8'hab; 8'hAC: lut_sb = 8'h0d; 8'hAD: lut_sb = 8'h53; 8'hAE: lut_sb = 8'h4e; 8'hAF: lut_sb = 8'h6f;
            8'hB8: lut_sb = 8'h03; 8'hB9: lut_sb = 8'hff; 8'hBA: lut_sb = 8'h6a; 8'hBB: lut_sb = 8'h72; 8'hBC: lut_sb = 8'h6d; 8'hBD: lut_sb = 8'h6c; 8'hBE: lut_sb = 8'h5b; 8'hBF: lut_sb = 8'h51;
            8'hC8: lut_sb = 8'h11; 8'hC9: lut_sb = 8'hd9; 8'hCA: lut_sb = 8'h5c; 8'hCB: lut_sb = 8'h41; 8'hCC: lut_sb = 8'h1f; 8'hCD: lut_sb = 8'h10; 8'hCE: lut_sb = 8'h5a; 8'hCF: lut_sb = 8'hd8;
            8'hD8: lut_sb = 8'h2d; 8'hD9: lut_sb = 8'h74; 8'hDA: lut_sb = 8'hd0; 8'hDB: lut_sb = 8'h12; 8'hDC: lut_sb = 8'hb8; 8'hDD: lut_sb = 8'he5; 8'hDE: lut_sb = 8'hb4; 8'hDF: lut_sb = 8'hb0;
            8'hE8: lut_sb = 8'h65; 8'hE9: lut_sb = 8'hb9; 8'hEA: lut_sb = 8'hf1; 8'hEB: lut_sb = 8'h09; 8'hEC: lut_sb = 8'hc5; 8'hED: lut_sb = 8'h6e; 8'hEE: lut_sb = 8'hc6; 8'hEF: lut_sb = 8'h84;
            8'hF8: lut_sb = 8'h79; 8'hF9: lut_sb = 8'hee; 8'hFA: lut_sb = 8'h5f; 8'hFB: lut_sb = 8'h3e; 8'hFC: lut_sb = 8'hd7; 8'hFD: lut_sb = 8'hcb; 8'hFE: lut_sb = 8'h39; 8'hFF: lut_sb = 8'h48;
            default: lut_sb = 8'h00;
        endcase
    endfunction
endmodule
