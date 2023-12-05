`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    axis s
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
//     slave module of SM3
//////////////////////////////////////////////////////////////////////////////////
	module sm3_axis_s #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		output wire[2047:0] wire_slave_to_sm3,
		output wire datain,
		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID
	);
	// function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.
	function integer clogb2 (input integer bit_depth);
	  begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      bit_depth = bit_depth >> 1;
	  end
	endfunction

	// Total number of input data.
	localparam NUMBER_OF_INPUT_WORDS  = 64;
	// bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);
	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state 

	                WRITE_FIFO  = 2'b01, // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 
					SI0 = 2'b11,
					SI1 = 2'b10;        // input data setting, SI0 input start and SI1 input datain
	wire  	axis_tready;
	// State variable
	reg[1:0] mst_exec_state;  
	// FIFO implementation signals
	genvar byte_index;     
	// FIFO write enable
	wire fifo_wren;
	// FIFO full flag
	reg fifo_full_flag;
	// FIFO write pointer
	reg [7:0] write_pointer;
	// sink has accepted all the streaming data and stored in FIFO
	  reg writes_done;
	// I/O Connections assignments

	assign S_AXIS_TREADY	= axis_tready;
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) 
	begin  
	  if (!S_AXIS_ARESETN) 
	  // Synchronous reset (active low)
	    begin
	      mst_exec_state <= IDLE;
	    end  
	  else
	    case (mst_exec_state)
	      IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID)
	            begin
	              mst_exec_state <= WRITE_FIFO;
	            end
	          else
	            begin
	              mst_exec_state <= IDLE;
	            end
	      WRITE_FIFO: 
	        // When the sink has accepted all the streaming input data,
	        // the interface swiches functionality to a streaming master
	        if (writes_done)
	          begin
	            mst_exec_state <= SI0;
	          end
	        else
	          begin
	            // The sink accepts and stores tdata 
	            // into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end
			SI0:begin
				mst_exec_state <= SI1;
			end
			SI1:begin
				mst_exec_state <= IDLE;
			end

	    endcase
	end
	// AXI Streaming Sink 
	// 
	// The example design sink is always ready to accept the S_AXIS_TDATA  until
	// the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	assign axis_tready = ((mst_exec_state == WRITE_FIFO) && (write_pointer <= NUMBER_OF_INPUT_WORDS-1));

	always@(posedge S_AXIS_ACLK)
	begin
	  if(!S_AXIS_ARESETN)
	    begin
	      write_pointer <= 0;
	      writes_done <= 1'b0;
	    end  
	  else
	    if (write_pointer <= NUMBER_OF_INPUT_WORDS-1)
	      begin
	        if (fifo_wren)
	          begin
	            // write pointer is incremented after every write to the FIFO
	            // when FIFO write signal is enabled.
	            write_pointer <= write_pointer + 1;
	            writes_done <= 1'b0;
	          end
	          if ((write_pointer == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
	            begin
	              // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	              // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	              writes_done <= 1'b1;
	            end
	      end
		  if(mst_exec_state==SI1) begin
			write_pointer <= 0;
		  end
		  if(mst_exec_state==IDLE) begin
			writes_done <= 0;
		  end
	end

	// FIFO write enable generation
	assign fifo_wren = S_AXIS_TVALID && axis_tready;
/*
	// FIFO Implementation
	generate 
	  for(byte_index=0; byte_index<= (C_S_AXIS_TDATA_WIDTH/8-1); byte_index=byte_index+1)
	  begin:FIFO_GEN

	    reg  [(C_S_AXIS_TDATA_WIDTH/4)-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];

	    // Streaming input data is stored in FIFO

	    always @( posedge S_AXIS_ACLK )
	    begin
	      if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
	        begin
	          stream_data_fifo[write_pointer] <= S_AXIS_TDATA[(byte_index*8+7) -: 8];
	        end  
	    end  
	  end		
	endgenerate
*/
	// Add user logic here

	reg[31:0] memory[0:67];
	reg[2047:0] outputdata;
	reg finished;
	//integer i;
	//reg[7:0] pointer;
	//reg[31:0] input_buffer;

	always @(posedge S_AXIS_ACLK) begin
		if(!S_AXIS_ARESETN) begin
			//pointer <= 0;
			finished <= 0;
			outputdata <= 0;
			//input_buffer <= 0;
			memory[0] <= 0 ; memory[1] <= 0 ; memory[2] <= 0 ; memory[3] <= 0 ;
			memory[4] <= 0 ; memory[5] <= 0 ; memory[6] <= 0 ; memory[7] <= 0 ;
			memory[8] <= 0 ; memory[9] <= 0 ; memory[10] <= 0 ; memory[11] <= 0 ;
			memory[12] <= 0 ; memory[13] <= 0 ; memory[14] <= 0 ; memory[15] <= 0 ;
			memory[16] <= 0 ; memory[17] <= 0 ; memory[18] <= 0 ; memory[19] <= 0 ;
			memory[20] <= 0 ; memory[21] <= 0 ; memory[22] <= 0 ; memory[23] <= 0 ;
			memory[24] <= 0 ; memory[25] <= 0 ; memory[26] <= 0 ; memory[27] <= 0 ;
			memory[28] <= 0 ; memory[29] <= 0 ; memory[30] <= 0 ; memory[31] <= 0 ;
			memory[32] <= 0 ; memory[33] <= 0 ; memory[34] <= 0 ; memory[35] <= 0 ;
			memory[36] <= 0 ; memory[37] <= 0 ; memory[38] <= 0 ; memory[39] <= 0 ;
			memory[40] <= 0 ; memory[41] <= 0 ; memory[42] <= 0 ; memory[43] <= 0 ;
			memory[44] <= 0 ; memory[45] <= 0 ; memory[46] <= 0 ; memory[47] <= 0 ;
			memory[48] <= 0 ; memory[49] <= 0 ; memory[50] <= 0 ; memory[51] <= 0 ;
			memory[52] <= 0 ; memory[53] <= 0 ; memory[54] <= 0 ; memory[55] <= 0 ;
			memory[56] <= 0 ; memory[57] <= 0 ; memory[58] <= 0 ; memory[59] <= 0 ;
			memory[60] <= 0 ; memory[61] <= 0 ; memory[62] <= 0 ; memory[63] <= 0 ;
			memory[64] <= 0 ; memory[65] <= 0 ; memory[66] <= 0 ; memory[67] <= 0 ;
		end
		else begin
			//input_buffer <= S_AXIS_TDATA;
			if(mst_exec_state==WRITE_FIFO) begin
				//input_buffer <= S_AXIS_TDATA;
				//memory[write_pointer] <= input_buffer;
				memory[write_pointer] <= S_AXIS_TDATA;
				//pointer <= pointer + 1;
			end
			else if(mst_exec_state==SI0) begin
				/*
				for( i = 0; i < 64; i = i + 1) begin
					//outputdata[(32*i) +: 32] <= memory[i];
					outputdata[(2047-(32*i)) -: 32] <= memory[i];
				end
				*/
				outputdata[2047:2016] <= memory[0];
				outputdata[2015:1984] <= memory[1];
				outputdata[1983:1952] <= memory[2];
				outputdata[1951:1920] <= memory[3];
				outputdata[1919:1888] <= memory[4];
				outputdata[1887:1856] <= memory[5];
				outputdata[1855:1824] <= memory[6];
				outputdata[1823:1792] <= memory[7];
				outputdata[1791:1760] <= memory[8];
				outputdata[1759:1728] <= memory[9];
				outputdata[1727:1696] <= memory[10];
				outputdata[1695:1664] <= memory[11];
				outputdata[1663:1632] <= memory[12];
				outputdata[1631:1600] <= memory[13];
				outputdata[1599:1568] <= memory[14];
				outputdata[1567:1536] <= memory[15];
				outputdata[1535:1504] <= memory[16];
				outputdata[1503:1472] <= memory[17];
				outputdata[1471:1440] <= memory[18];
				outputdata[1439:1408] <= memory[19];
				outputdata[1407:1376] <= memory[20];
				outputdata[1375:1344] <= memory[21];
				outputdata[1343:1312] <= memory[22];
				outputdata[1311:1280] <= memory[23];
				outputdata[1279:1248] <= memory[24];
				outputdata[1247:1216] <= memory[25];
				outputdata[1215:1184] <= memory[26];
				outputdata[1183:1152] <= memory[27];
				outputdata[1151:1120] <= memory[28];
				outputdata[1119:1088] <= memory[29];
				outputdata[1087:1056] <= memory[30];
				outputdata[1055:1024] <= memory[31];
				outputdata[1023:992] <= memory[32];
				outputdata[991:960] <= memory[33];
				outputdata[959:928] <= memory[34];
				outputdata[927:896] <= memory[35];
				outputdata[895:864] <= memory[36];
				outputdata[863:832] <= memory[37];
				outputdata[831:800] <= memory[38];
				outputdata[799:768] <= memory[39];
				outputdata[767:736] <= memory[40];
				outputdata[735:704] <= memory[41];
				outputdata[703:672] <= memory[42];
				outputdata[671:640] <= memory[43];
				outputdata[639:608] <= memory[44];
				outputdata[607:576] <= memory[45];
				outputdata[575:544] <= memory[46];
				outputdata[543:512] <= memory[47];
				outputdata[511:480] <= memory[48];
				outputdata[479:448] <= memory[49];
				outputdata[447:416] <= memory[50];
				outputdata[415:384] <= memory[51];
				outputdata[383:352] <= memory[52];
				outputdata[351:320] <= memory[53];
				outputdata[319:288] <= memory[54];
				outputdata[287:256] <= memory[55];
				outputdata[255:224] <= memory[56];
				outputdata[223:192] <= memory[57];
				outputdata[191:160] <= memory[58];
				outputdata[159:128] <= memory[59];
				outputdata[127:96] <= memory[60];
				outputdata[95:64] <= memory[61];
				outputdata[63:32] <= memory[62];
				outputdata[31:0] <= memory[63];
				finished <= 1;
			end
			else if(mst_exec_state==SI1) begin
				finished <= 0;
			end
		end
	end

	assign wire_slave_to_sm3 = outputdata;
	assign datain = finished;

	// User logic ends

	endmodule
