`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 15/11/2022 
// Design Name: 
// Module Name:    point_mul
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
//     点乘模块，加重射影坐标
//     调用点加模块，输入的是NAF序列和点坐标
//////////////////////////////////////////////////////////////////////////////////
module pointmul_naf(
    clk,
    rstn,
    x1,
    y1,
    z1,
    h,
    hlength,
    start,
    x2,
    y2,
    z2,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] x1;
    input wire[255:0] y1;
    input wire[255:0] z1;
    input wire[1023:0] h;
    input wire[31:0] hlength;
    input wire start;
    output wire[255:0] x2;
    output wire[255:0] y2;
    output wire[255:0] z2;
    output wire done;

    parameter p = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;

    // registers
    reg[255:0] x1_reg;
    reg[255:0] y1_reg;
    reg[255:0] y1_neg_reg;
    reg[255:0] z1_reg;
    reg[1023:0] r_h;
    reg[31:0]   r_hlength;
    // q
    reg[255:0] q_x;
    reg[255:0] q_y;
    reg[255:0] q_z;
    // counter
    reg[31:0] counter;
    // reg for first add
    reg first_add;

    // state machine
    reg[15:0] state;
    localparam IDLE = 16'b0000000000000001;
    localparam DIN  = 16'b0000000000000010;
    localparam LOOP = 16'b0000000000000100;
    localparam ADD  = 16'b0000000000001000;
    localparam SUB  = 16'b0000000000010000;
    localparam POA  = 16'b0000000000100000;
    localparam UPD1 = 16'b0000000001000000;
    localparam DBP  = 16'b0000000010000000;
    localparam DOUB = 16'b0000000100000000;
    localparam UPD2 = 16'b0000001000000000;
    localparam FIN  = 16'b0000010000000000;
    // for q=O special
    localparam SPA  = 16'b0000100000000000;
    localparam SPS  = 16'b0001000000000000;

    // state change signals
    reg loop_finished;
    reg add_finished;
    reg double_finished;
    // loop state
    wire[1:0] loop_state;
    wire[31:0] counter_twice;
    assign counter_twice = counter << 1;
    assign loop_state = { r_h[counter_twice+1], r_h[counter_twice] };

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? DIN : IDLE;
                end
                DIN:begin
                    // In din, process the O+P or O-P
                    // if first h is 00, then continue DIN and counter++
                    // else, set Q=P or Q=-p and counter++
                    /*
                    if(loop_state==2'b00 || loop_state==2'b10) begin
                        state <= DIN;
                    end
                    else begin
                        state <= LOOP;
                    end
                    */
                    state <= LOOP;
                end
                LOOP:begin
                    if(loop_finished) begin
                        state <= FIN;
                    end
                    else if(loop_state==2'b01) begin
                        state <= ADD;
                    end
                    else if(loop_state==2'b11) begin
                        state <= SUB;
                    end
                    else begin
                        state <= DBP;
                    end                    
                end
                ADD:begin
                    state <= first_add ? SPA : POA;
                end
                SUB:begin
                    state <= first_add ? SPS : POA;
                end
                POA:begin
                    state <= add_finished ? UPD1 : POA;
                end
                UPD1:begin
                    state <= DBP;
                end
                DBP:begin
                    state <= DOUB;
                end
                DOUB:begin
                    state <= double_finished ? UPD2 : DOUB;
                end
                UPD2:begin
                    state <= LOOP;
                end
                SPA:begin
                    state <= UPD1;
                end
                SPS:begin
                    state <= UPD1;
                end
                FIN:begin
                    state <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // module regs
    reg[255:0]  pa_x1;
    reg[255:0]  pa_y1;
    reg[255:0]  pa_z1;
    reg[255:0]  pa_x2;
    reg[255:0]  pa_y2;
    reg[255:0]  pa_z2;
    reg         pa_start;
    wire[255:0] pa_x3;
    wire[255:0] pa_y3;
    wire[255:0] pa_z3;
    wire        pa_done;
    // temp for module output
    reg[255:0]  tmpx;
    reg[255:0]  tmpy;
    reg[255:0]  tmpz;

    // data control
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            x1_reg <= 0;
            y1_reg <= 0;
            y1_neg_reg <= 0;
            z1_reg <= 0;
            r_h <= 0;
            r_hlength <= 0;
            counter <= 0;
            q_x <= 0;
            q_y <= 0;
            q_z <= 0;
            pa_x1 <= 0;
            pa_y1 <= 0;
            pa_z1 <= 0;
            pa_x2 <= 0;
            pa_y2 <= 0;
            pa_z2 <= 0;
            pa_start <= 0;
            tmpx <= 0;
            tmpy <= 0;
            tmpz <= 0;
            loop_finished <= 0;
            add_finished <= 0;
            double_finished <= 0;
            first_add <= 1;
        end
        else begin
            case(state)
                IDLE:begin
                    //x1_reg <= 0;
                    //y1_reg <= 0;
                    //y1_neg_reg <= 0;
                    //z1_reg <= 0;
                    //r_h <= 0;
                    //r_hlength <= 0;
                    x1_reg <= x1;
                    y1_reg <= y1;
                    y1_neg_reg <= p - y1;
                    z1_reg <= z1;
                    r_h <= h;
                    r_hlength <= hlength;
                    counter <= 0;
                    q_x <= 0;
                    q_y <= 0;
                    q_z <= 0;
                    pa_x1 <= 0;
                    pa_y1 <= 0;
                    pa_z1 <= 0;
                    pa_x2 <= 0;
                    pa_y2 <= 0;
                    pa_z2 <= 0;
                    pa_start <= 0;
                    tmpx <= 0;
                    tmpy <= 0;
                    tmpz <= 0;
                    loop_finished <= 0;
                    add_finished <= 0;
                    double_finished <= 0;
                    first_add <= 1;
                end
                DIN:begin
                    //x1_reg <= x1;
                    //y1_reg <= y1;
                    //y1_neg_reg <= p - y1;
                    //z1_reg <= z1;
                    //r_h <= h;
                    //r_hlength <= hlength;
                    /*
                    if(loop_state==2'b01) begin
                        q_x <= x1_reg;
                        q_y <= y1_reg;
                        q_z <= z1_reg;
                    end
                    else if(loop_state==2'b11) begin
                        q_x <= x1_reg;
                        q_y <= y1_neg_reg;
                        q_z <= z1_reg;
                    end
                    else begin
                    end
                    counter <= counter + 1;     
                    */       
                    pa_x1 <= 0;
                    pa_y1 <= 0;
                    pa_z1 <= 0;
                    pa_x2 <= 0;
                    pa_y2 <= 0;
                    pa_z2 <= 0;
                    pa_start <= 0;
                    tmpx <= 0;
                    tmpy <= 0;
                    tmpz <= 0;
                end
                LOOP:begin
                    //y1_neg_reg <= p - y1_reg;
                    tmpx <= 0;
                    tmpy <= 0;
                    tmpz <= 0;
                    counter <= counter + 1;
                end
                ADD:begin
                    pa_x1 <= q_x;
                    pa_y1 <= q_y;
                    pa_z1 <= q_z;
                    pa_x2 <= x1_reg;
                    pa_y2 <= y1_reg;
                    pa_z2 <= z1_reg;
                    //pa_start <= 1;
                    pa_start <= first_add ? 0 : 1;
                    tmpx <= 0;
                    tmpy <= 0;
                    tmpz <= 0;
                end
                SUB:begin
                    pa_x1 <= q_x;
                    pa_y1 <= q_y;
                    pa_z1 <= q_z;
                    pa_x2 <= x1_reg;
                    pa_y2 <= y1_neg_reg;
                    pa_z2 <= z1_reg;
                    //pa_start <= 1;
                    pa_start <= first_add ? 0 : 1;
                    tmpx <= 0;
                    tmpy <= 0;
                    tmpz <= 0;
                end
                POA:begin
                    pa_start <= 0;
                    add_finished <= pa_done ? 1 : 0;
                    tmpx <= pa_done ? pa_x3 : tmpx;
                    tmpy <= pa_done ? pa_y3 : tmpy;
                    tmpz <= pa_done ? pa_z3 : tmpz;
                end
                UPD1:begin
                    q_x <= tmpx;
                    q_y <= tmpy;
                    q_z <= tmpz;
                end
                DBP:begin
                    pa_x1 <= x1_reg;
                    pa_y1 <= y1_reg;
                    pa_z1 <= z1_reg;
                    pa_x2 <= x1_reg;
                    pa_y2 <= y1_reg;
                    pa_z2 <= z1_reg;
                    pa_start <= 1;
                    tmpx <= 0;
                    tmpy <= 0;
                    tmpz <= 0;
                    loop_finished <= ( counter >= r_hlength ) ? 1 : 0;
                end
                DOUB:begin
                    pa_start <= 0;
                    double_finished <= pa_done ? 1 : 0;
                    tmpx <= pa_done ? pa_x3 : tmpx;
                    tmpy <= pa_done ? pa_y3 : tmpy;
                    tmpz <= pa_done ? pa_z3 : tmpz;
                end
                UPD2:begin
                    x1_reg <= tmpx;
                    y1_reg <= tmpy;
                    y1_neg_reg <= p - tmpy;
                    z1_reg <= tmpz;
                    //loop_finished <= ( counter >= r_hlength ) ? 1 : 0;
                end
                SPA:begin
                    q_x <= x1_reg;
                    q_y <= y1_reg;
                    q_z <= z1_reg;
                    tmpx <= x1_reg;
                    tmpy <= y1_reg;
                    tmpz <= z1_reg;
                    first_add <= 0;
                end
                SPS:begin
                    q_x <= x1_reg;
                    q_y <= y1_neg_reg;
                    q_z <= z1_reg;
                    tmpx <= x1_reg;
                    tmpy <= y1_neg_reg;
                    tmpz <= z1_reg;
                    first_add <= 0;
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end

    // module initialize
    point_add pointadd_in_pointmulnaf(
        .clk(clk),
        .rstn(rstn),
        .x1(pa_x1),
        .y1(pa_y1),
        .z1(pa_z1),
        .x2(pa_x2),
        .y2(pa_y2),
        .z2(pa_z2),
        .start(pa_start),
        //.start_double(pa_start_double),
        .x3(pa_x3),
        .y3(pa_y3),
        .z3(pa_z3),
        .done(pa_done)
    );


    assign x2 = q_x;
    assign y2 = q_y;
    assign z2 = q_z;
    assign done = ( state == FIN ) ? 1 : 0;

endmodule
