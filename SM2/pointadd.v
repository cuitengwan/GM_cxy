`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 09/11/2022 
// Design Name: 
// Module Name:    mod_inv_p
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
//     点加模块，加重射影坐标
//     输入：x1,y1,z1,x2,y2,z2,start,
//     输出：x3,y3,z3
//     每一个时钟周期运算一条指令
//////////////////////////////////////////////////////////////////////////////////
module point_add(
    clk,
    rstn,
    x1,
    y1,
    z1,
    x2,
    y2,
    z2,
    start,
    //start_double,
    x3,
    y3,
    z3,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] x1;
    input wire[255:0] y1;
    input wire[255:0] z1;
    input wire[255:0] x2;
    input wire[255:0] y2;
    input wire[255:0] z2;
    input wire start;
    //input wire start_double;
    output wire[255:0] x3;
    output wire[255:0] y3;
    output wire[255:0] z3;
    output wire done;

    // double or add
    wire start_double;
    assign start_double = (x1==x2) && (y1==y2) && (z1==z2); 

    // parameters
    parameter p = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;
    parameter p257 = 257'h0FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;

    // 2
    wire[255:0] number2;
    assign number2 = 256'h0000000000000000000000000000000000000000000000000000000000000002;

    // memory initialize
    // address is based on the documentation
    reg[255:0] memory_pointadd[0:32];

    // regs initialize
    reg[255:0] x1_reg;
    reg[255:0] x2_reg;
    reg[255:0] y1_reg;
    reg[255:0] y2_reg;
    reg[255:0] z1_reg;
    reg[255:0] z2_reg;
    // results
    reg[255:0] x3_reg;
    reg[255:0] y3_reg;
    reg[255:0] z3_reg;

    // state machine
    // IDLE -> DOUBLE -> WAITDOUBLE -> FIN
    //     \-> ADD    -> WAITADD    ->/
    reg[7:0] state;
    localparam IDLE = 8'b00000001;
    localparam DOUBLE = 8'b00000010;
    localparam WAIT_DOUBLE = 8'b00000100;
    localparam ADD = 8'b00001000;
    localparam WAIT_ADD = 8'b00010000;
    localparam FIN = 8'b00100000;

    // wait signals
    wire double_finished;
    wire add_finished;
    reg r_double_finished;
    reg r_add_finished;

    assign double_finished = r_double_finished;
    assign add_finished = r_add_finished;


    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? ( start_double ? DOUBLE : ADD ) : IDLE;
                end
                DOUBLE:begin
                    state <= WAIT_DOUBLE;
                end
                WAIT_DOUBLE:begin
                    state <= ( double_finished ) ? FIN : WAIT_DOUBLE;
                end
                ADD:begin
                    state <= WAIT_ADD;
                end
                WAIT_ADD:begin
                    state <= ( add_finished ) ? FIN : WAIT_ADD;
                end
                FIN:begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // processing counter
    reg[7:0] counter;

    // wire and regs use in module
    reg[255:0] mul_a;
    reg[255:0] mul_b;
    reg mul_start;
    wire[255:0] mul_c;
    wire mul_done;
    reg[255:0] add_a;
    reg[255:0] add_b;
    reg add_start;
    reg add_minus;
    wire[255:0] add_c;
    wire add_done;
    reg r_mul_done;
    reg r_add_done;
    // a reg to save 2y3, its 257bit for add
    reg[256:0] temp_y3y3;

    // data
    // use counter to control the input/output of multiplier and adder
    // each step use two counts, odd: data input, even: wait and save memory
    // the address of memory is in the document. from 1 to 32.
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            x1_reg <= 0;
            y1_reg <= 0;
            z1_reg <= 0;
            x2_reg <= 0;
            y2_reg <= 0;
            z2_reg <= 0;
            x3_reg <= 0;
            y3_reg <= 0;
            z3_reg <= 0;
            mul_a <= 0;
            mul_b <= 0;
            mul_start <= 0;
            add_a <= 0;
            add_b <= 0;
            add_start <= 0;
            add_minus <= 0;
            r_mul_done <= 0;
            r_add_done <= 0;
            r_double_finished <= 0;
            r_add_finished <= 0;
            counter <= 0;
            temp_y3y3 <= 0;
            memory_pointadd[0] <= 0;memory_pointadd[1] <= 0;memory_pointadd[2] <= 0;memory_pointadd[3] <= 0;
            memory_pointadd[4] <= 0;memory_pointadd[5] <= 0;memory_pointadd[6] <= 0;memory_pointadd[7] <= 0;
            memory_pointadd[8] <= 0;memory_pointadd[9] <= 0;memory_pointadd[10] <= 0;memory_pointadd[11] <= 0;
            memory_pointadd[12] <= 0;memory_pointadd[13] <= 0;memory_pointadd[14] <= 0;memory_pointadd[15] <= 0;
            memory_pointadd[16] <= 0;memory_pointadd[17] <= 0;memory_pointadd[18] <= 0;memory_pointadd[19] <= 0;
            memory_pointadd[20] <= 0;memory_pointadd[21] <= 0;memory_pointadd[22] <= 0;memory_pointadd[23] <= 0;
            memory_pointadd[24] <= 0;memory_pointadd[25] <= 0;memory_pointadd[26] <= 0;memory_pointadd[27] <= 0;
            memory_pointadd[28] <= 0;memory_pointadd[29] <= 0;memory_pointadd[30] <= 0;memory_pointadd[31] <= 0;
            memory_pointadd[32] <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    x1_reg <= x1;
                    y1_reg <= y1;
                    z1_reg <= z1;
                    x2_reg <= x2;
                    y2_reg <= y2;
                    z2_reg <= z2;
                    r_double_finished <= 0;
                    r_add_finished <= 0;
                    counter <= 0;
                end
                DOUBLE: begin
                    counter <= 1;
                end
                WAIT_DOUBLE: begin
                    case(counter)
                        8'd1:begin // z1*z1
                            mul_a <= z1_reg;
                            mul_b <= z1_reg;
                            mul_start <= 1;
                            counter <= 8'd2;
                            r_mul_done <= 0;
                        end
                        8'd2:begin
                            memory_pointadd[1] <= mul_done ? mul_c : memory_pointadd[1];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd3 : 8'd2;
                        end
                        8'd3:begin // y1*y1  x1+z1*z1
                            mul_a <= y1_reg;
                            mul_b <= y1_reg;
                            mul_start <= 1;
                            add_a <= x1_reg;
                            add_b <= memory_pointadd[1];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd4;
                        end
                        8'd4:begin
                            memory_pointadd[3] <= mul_done ? mul_c : memory_pointadd[3];
                            memory_pointadd[4] <= add_done ? add_c : memory_pointadd[4];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd5 : 8'd4;
                        end
                        8'd5:begin // x1*y1*y1  x1-z1*z1
                            mul_a <= x1_reg;
                            mul_b <= memory_pointadd[3];
                            mul_start <= 1;
                            add_a <= x1_reg;
                            add_b <= memory_pointadd[1];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd6;
                        end
                        8'd6:begin
                            memory_pointadd[5] <= mul_done ? mul_c : memory_pointadd[5];
                            memory_pointadd[6] <= add_done ? add_c : memory_pointadd[6];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd7 : 8'd6;
                        end
                        8'd7:begin // (y1)^4  2*x1*y1*y1
                            mul_a <= memory_pointadd[3];
                            mul_b <= memory_pointadd[3];
                            mul_start <= 1;
                            add_a <= memory_pointadd[5];
                            add_b <= memory_pointadd[5];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd8;
                        end
                        8'd8:begin
                            memory_pointadd[7] <= mul_done ? mul_c : memory_pointadd[7];
                            memory_pointadd[8] <= add_done ? add_c : memory_pointadd[8];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd9 : 8'd8;
                        end
                        8'd9:begin // (x1+z1*z1)(x1-z1*z1)  4*x1*y1*y1=R2
                            mul_a <= memory_pointadd[4];
                            mul_b <= memory_pointadd[6];
                            mul_start <= 1;
                            add_a <= memory_pointadd[8];
                            add_b <= memory_pointadd[8];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd10;
                        end
                        8'd10:begin
                            memory_pointadd[9] <= mul_done ? mul_c : memory_pointadd[9];
                            memory_pointadd[10] <= add_done ? add_c : memory_pointadd[10];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd11 : 8'd10;
                        end
                        8'd11:begin // y1*z1=z3  2*(x1+z1*z1)(x1-z1*z1)
                            mul_a <= y1_reg;
                            mul_b <= z1_reg;
                            mul_start <= 1;
                            add_a <= memory_pointadd[9];
                            add_b <= memory_pointadd[9];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd12;
                        end
                        8'd12:begin
                            memory_pointadd[11] <= mul_done ? mul_c : memory_pointadd[11];
                            memory_pointadd[12] <= add_done ? add_c : memory_pointadd[12];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd13 : 8'd12;
                        end
                        8'd13:begin // 2y1z1=z3  3*(x1+z1*z1)(x1-z1*z1)=R1
                            add_a <= memory_pointadd[9];
                            add_b <= memory_pointadd[12];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd14;
                        end
                        8'd14:begin
                            memory_pointadd[14] <= add_done ? add_c : memory_pointadd[14];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd15 : 8'd14;
                        end
                        8'd15:begin // R1*R1  2*R2
                            mul_a <= memory_pointadd[14];
                            mul_b <= memory_pointadd[14];
                            mul_start <= 1;
                            add_a <= memory_pointadd[10];
                            add_b <= memory_pointadd[10];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd16;
                        end
                        8'd16:begin
                            memory_pointadd[15] <= mul_done ? mul_c : memory_pointadd[15];
                            memory_pointadd[16] <= add_done ? add_c : memory_pointadd[16];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd17 : 8'd16;
                        end
                        8'd17:begin // -  R1*R1-2*R2=x3
                            add_a <= memory_pointadd[15];
                            add_b <= memory_pointadd[16];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd18;
                        end
                        8'd18:begin
                            memory_pointadd[18] <= add_done ? add_c : memory_pointadd[18];
                            add_start <= 0;
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd19 : 8'd18;
                        end
                        8'd19:begin // -  R2-x3
                            add_a <= memory_pointadd[10];
                            add_b <= memory_pointadd[18];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd20;
                        end
                        8'd20:begin
                            memory_pointadd[20] <= add_done ? add_c : memory_pointadd[20];
                            add_start <= 0;
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd21 : 8'd20;
                        end
                        8'd21:begin // R1*(R2-x3)  2*(y1)^4
                            mul_a <= memory_pointadd[14];
                            mul_b <= memory_pointadd[20];
                            mul_start <= 1;
                            add_a <= memory_pointadd[7];
                            add_b <= memory_pointadd[7];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd22;
                        end
                        8'd22:begin
                            memory_pointadd[21] <= mul_done ? mul_c : memory_pointadd[21];
                            memory_pointadd[22] <= add_done ? add_c : memory_pointadd[22];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd23 : 8'd22;
                        end
                        8'd23:begin // -  4*(y1)^4
                            add_a <= memory_pointadd[22];
                            add_b <= memory_pointadd[22];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd24;
                        end
                        8'd24:begin
                            memory_pointadd[24] <= add_done ? add_c : memory_pointadd[24];
                            add_start <= 0;
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd25 : 8'd24;
                        end
                        8'd25:begin // -  8*(y1)^4=R3
                            add_a <= memory_pointadd[24];
                            add_b <= memory_pointadd[24];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd26;
                        end
                        8'd26:begin
                            memory_pointadd[26] <= add_done ? add_c : memory_pointadd[26];
                            add_start <= 0;
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd27 : 8'd26;
                        end
                        8'd27:begin // -  R1(R2-x3)-R3=y3
                            add_a <= memory_pointadd[21];
                            add_b <= memory_pointadd[26];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd28;
                        end
                        8'd28:begin
                            memory_pointadd[28] <= add_done ? add_c : memory_pointadd[28];
                            add_start <= 0;
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd29 : 8'd28;
                        end
                        8'd29:begin // -  2y1z1=z3
                            add_a <= memory_pointadd[11];
                            add_b <= memory_pointadd[11];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd30;
                        end
                        8'd30:begin
                            memory_pointadd[27] <= add_done ? add_c : memory_pointadd[27];
                            add_start <= 0;
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= r_add_done ? 8'd31 : 8'd30;
                        end
                        8'd31:begin
                            x3_reg <= memory_pointadd[18];
                            y3_reg <= memory_pointadd[28];
                            z3_reg <= memory_pointadd[27];
                            r_double_finished <= 1;
                            counter <= 8'd0;
                        end
                        default:begin
                        end
                    endcase
                end
                ADD:begin
                    counter <= 1;
                end
                WAIT_ADD:begin
                    case(counter)
                        8'd1:begin //z2*z2  -
                            mul_a <= z2_reg;
                            mul_b <= z2_reg;
                            mul_start <= 1;
                            add_start <= 0;
                            counter <= 8'd2;
                            r_mul_done <= 0;
                        end
                        8'd2:begin
                            memory_pointadd[1] <= mul_done ? mul_c : memory_pointadd[1];
                            mul_start <= 0;
                            r_add_done <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd3 : 8'd2;
                        end
                        8'd3:begin //z1*z1  -
                            mul_a <= z1_reg;
                            mul_b <= z1_reg;
                            mul_start <= 1;
                            counter <= 8'd4;
                            r_mul_done <= 0;
                        end
                        8'd4:begin
                            memory_pointadd[2] <= mul_done ? mul_c : memory_pointadd[2];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd5 : 8'd4;
                        end
                        8'd5:begin //x1*z2*z2=R1  -
                            mul_a <= x1_reg;
                            mul_b <= memory_pointadd[1];
                            mul_start <= 1;
                            counter <= 8'd6;
                            r_mul_done <= 0;
                        end
                        8'd6:begin
                            memory_pointadd[3] <= mul_done ? mul_c : memory_pointadd[3];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd7 : 8'd6;
                        end
                        8'd7:begin //x2*z1*z1=R2  -
                            mul_a <= x2_reg;
                            mul_b <= memory_pointadd[2];
                            mul_start <= 1;
                            counter <= 8'd8;
                            r_mul_done <= 0;
                        end
                        8'd8:begin
                            memory_pointadd[4] <= mul_done ? mul_c : memory_pointadd[4];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd9 : 8'd8;
                        end
                        8'd9:begin // z1*z1*z1  R1-R2=R3
                            mul_a <= memory_pointadd[2];
                            mul_b <= z1_reg;
                            mul_start <= 1;
                            add_a <= memory_pointadd[3];
                            add_b <= memory_pointadd[4];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd10;
                        end
                        8'd10:begin
                            memory_pointadd[5] <= mul_done ? mul_c : memory_pointadd[5];
                            memory_pointadd[6] <= add_done ? add_c : memory_pointadd[6];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd11 : 8'd10;
                        end
                        8'd11:begin // z2*z2*z2  R1+R2=R7
                            mul_a <= memory_pointadd[1];
                            mul_b <= z2_reg;
                            mul_start <= 1;
                            add_a <= memory_pointadd[3];
                            add_b <= memory_pointadd[4];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd12;
                        end
                        8'd12:begin
                            memory_pointadd[7] <= mul_done ? mul_c : memory_pointadd[7];
                            memory_pointadd[8] <= add_done ? add_c : memory_pointadd[8];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd13 : 8'd12;
                        end
                        8'd13:begin //y1*z2*z2*z2=R4  -
                            mul_a <= y1_reg;
                            mul_b <= memory_pointadd[7];
                            mul_start <= 1;
                            counter <= 8'd14;
                            r_mul_done <= 0;
                        end
                        8'd14:begin
                            memory_pointadd[9] <= mul_done ? mul_c : memory_pointadd[9];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd15 : 8'd14;
                        end
                        8'd15:begin //y2*z1*z1*z1=R5  -
                            mul_a <= y2_reg;
                            mul_b <= memory_pointadd[5];
                            mul_start <= 1;
                            counter <= 8'd16;
                            r_mul_done <= 0;
                        end
                        8'd16:begin
                            memory_pointadd[10] <= mul_done ? mul_c : memory_pointadd[10];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd17 : 8'd16;
                        end
                        8'd17:begin // R3*R3  R4-R5=R6
                            mul_a <= memory_pointadd[6];
                            mul_b <= memory_pointadd[6];
                            mul_start <= 1;
                            add_a <= memory_pointadd[9];
                            add_b <= memory_pointadd[10];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd18;
                        end
                        8'd18:begin
                            memory_pointadd[11] <= mul_done ? mul_c : memory_pointadd[11];
                            memory_pointadd[12] <= add_done ? add_c : memory_pointadd[12];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd19 : 8'd18;
                        end
                        8'd19:begin // R7*R3*R3  R4+R5=R8
                            mul_a <= memory_pointadd[8];
                            mul_b <= memory_pointadd[11];
                            mul_start <= 1;
                            add_a <= memory_pointadd[9];
                            add_b <= memory_pointadd[10];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd20;
                        end
                        8'd20:begin
                            memory_pointadd[13] <= mul_done ? mul_c : memory_pointadd[13];
                            memory_pointadd[14] <= add_done ? add_c : memory_pointadd[14];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd21 : 8'd20;
                        end
                        8'd21:begin //R6*R6  -
                            mul_a <= memory_pointadd[12];
                            mul_b <= memory_pointadd[12];
                            mul_start <= 1;
                            counter <= 8'd22;
                            r_mul_done <= 0;
                        end
                        8'd22:begin
                            memory_pointadd[15] <= mul_done ? mul_c : memory_pointadd[15];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd23 : 8'd22;
                        end
                        8'd23:begin // R3*R3*R3  R6*R6-R7*R3*R3=x3
                            mul_a <= memory_pointadd[6];
                            mul_b <= memory_pointadd[11];
                            mul_start <= 1;
                            add_a <= memory_pointadd[15];
                            add_b <= memory_pointadd[13];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd24;
                        end
                        8'd24:begin
                            memory_pointadd[17] <= mul_done ? mul_c : memory_pointadd[17];
                            memory_pointadd[18] <= add_done ? add_c : memory_pointadd[18];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd25 : 8'd24;
                        end
                        8'd25:begin // R8*R3*R3*R3  2*x3
                            mul_a <= memory_pointadd[14];
                            mul_b <= memory_pointadd[17];
                            mul_start <= 1;
                            add_a <= memory_pointadd[18];
                            add_b <= memory_pointadd[18];
                            add_minus <= 0;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd26;
                        end
                        8'd26:begin
                            memory_pointadd[19] <= mul_done ? mul_c : memory_pointadd[19];
                            memory_pointadd[20] <= add_done ? add_c : memory_pointadd[20];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd27 : 8'd26;
                        end
                        8'd27:begin // z1*z2  R7*R3*R3-2*x3=R9
                            mul_a <= z1_reg;
                            mul_b <= z2_reg;
                            mul_start <= 1;
                            add_a <= memory_pointadd[13];
                            add_b <= memory_pointadd[20];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd28;
                        end
                        8'd28:begin
                            memory_pointadd[21] <= mul_done ? mul_c : memory_pointadd[21];
                            memory_pointadd[22] <= add_done ? add_c : memory_pointadd[22];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd29 : 8'd28;
                        end
                        8'd29:begin //R6*R9  -
                            mul_a <= memory_pointadd[12];
                            mul_b <= memory_pointadd[22];
                            mul_start <= 1;
                            counter <= 8'd30;
                            r_mul_done <= 0;
                        end
                        8'd30:begin
                            memory_pointadd[23] <= mul_done ? mul_c : memory_pointadd[23];
                            mul_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            counter <= r_mul_done ? 8'd31 : 8'd30;
                        end
                        8'd31:begin // z1*z2*R3=z3  R6*R9-R8*R3*R3*R3=2y3
                            mul_a <= memory_pointadd[21];
                            mul_b <= memory_pointadd[6];
                            mul_start <= 1;
                            add_a <= memory_pointadd[23];
                            add_b <= memory_pointadd[19];
                            add_minus <= 1;
                            add_start <= 1;
                            r_mul_done <= 0;
                            r_add_done <= 0;
                            counter <= 8'd32;
                        end
                        8'd32:begin
                            memory_pointadd[25] <= mul_done ? mul_c : memory_pointadd[25];
                            memory_pointadd[26] <= add_done ? add_c : memory_pointadd[26];
                            mul_start <= 0;
                            add_start <= 0;
                            r_mul_done <= r_mul_done ? 1 : ( mul_done ? 1 : 0 );
                            r_add_done <= r_add_done ? 1 : ( add_done ? 1 : 0 );
                            counter <= ( r_mul_done && r_add_done ) ? 8'd33 : 8'd32;
                        end
                        8'd33:begin
                            temp_y3y3 <= { 1'b0, memory_pointadd[26] };
                            counter <= 8'd34;
                        end
                        8'd34:begin
                            temp_y3y3 <= temp_y3y3[0] ? ( temp_y3y3 + p257 ) : temp_y3y3;
                            counter <= 8'd35;
                        end
                        8'd35:begin
                            temp_y3y3 <= temp_y3y3 >> 1;
                            counter <= 8'd36;
                        end
                        8'd36:begin
                            x3_reg <= memory_pointadd[18];
                            y3_reg <= temp_y3y3;
                            z3_reg <= memory_pointadd[25];
                            r_add_finished <= 1;
                            counter <= 8'd0;
                        end
                        default:begin
                        end
                    endcase
                end
                default:begin
                end
            endcase
        end
    end


    // modules initialize
    // use one mul_mod module and one adder module

    mod_mul256_p modmul_in_pointadd(
        .clk(clk),
        .rstn(rstn),
        .a(mul_a),
        .b(mul_b),
        .start(mul_start),
        .c(mul_c),
        .done(mul_done)
    );

    mod_add_p modadd_in_pointadd(
        .clk(clk),
        .rstn(rstn),
        .a(add_a),
        .b(add_b),
        .start(add_start),
        .minus(add_minus),
        .c(add_c),
        .done(add_done)
    );


    // outputs
    assign x3 = x3_reg;
    assign y3 = y3_reg;
    assign z3 = z3_reg;
    assign done = ( state == FIN ) ? 1 : 0;

endmodule