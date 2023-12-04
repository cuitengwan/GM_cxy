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
	module sm4_axis_s #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		output wire isdec,
		output wire start_input,
		output wire end_input,
		output wire[127:0] datain,
		output wire[127:0] mkin,
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
	localparam NUMBER_OF_INPUT_WORDS  = 65;
	// bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);
	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	parameter [7:0] IDLE = 8'b00000001,        // This is the initial/idle state 

					WRITE_FIFO = 8'b00000010, // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 
					SI0 = 8'b10000000,		
					SI1 = 8'b10000001,
					SI2 = 8'b10000011,		
					SI3 = 8'b10000010,
					SI4 = 8'b10000110,
					SI5 = 8'b10000100,
					SI6 = 8'b10001100,
					SI7 = 8'b10001000,
					SI8 = 8'b10011000,
					SI9 = 8'b10010000;
	wire  	axis_tready;
	// State variable
	reg[7:0] mst_exec_state;  
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
				mst_exec_state <= SI2;
			end
			SI2:begin
				mst_exec_state <= SI3;
			end
			SI3:begin
				mst_exec_state <= SI4;
			end
			SI4:begin
				mst_exec_state <= SI5;
			end
			SI5:begin
				mst_exec_state <= SI6;
			end
			SI6:begin
				mst_exec_state <= SI7;
			end
			SI7:begin
				mst_exec_state <= SI8;
			end
			SI8:begin
				mst_exec_state <= SI9;
			end
			SI9:begin
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
	reg[127:0] outputdata;
	reg[127:0] outputmk;
	//reg[31:0] input_buffer;
	reg r_isdec;
	reg r_start_input;
	reg r_end_input;

	/*
	always @(posedge S_AXIS_ACLK) begin
		if(!S_AXIS_ARESETN) begin
			input_buffer <= 0;
		end
		else begin
			input_buffer <= S_AXIS_TDATA;
		end
	end
	*/

	always @(posedge S_AXIS_ACLK) begin
		if(!S_AXIS_ARESETN) begin
			//pointer <= 0;
			outputdata <= 0;
			outputmk <= 0;
			r_isdec <= 0;
			r_end_input <= 0;
			r_start_input <= 0;
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
			case(mst_exec_state)
				IDLE:begin
					outputdata <= 0;
					outputmk <= 0;
					r_isdec <= 0;
					r_end_input <= 0;
					r_start_input <= 0;
				end
				WRITE_FIFO:begin
					//memory[write_pointer] <= input_buffer;
					memory[write_pointer] <= S_AXIS_TDATA;
				end
				SI0:begin
					r_isdec <= ( memory[0] == 32'hFFFFFFFF ) ? 1 : 0;
					r_start_input <= 1;
				end
				SI1:begin
					r_start_input <= 0;
					outputdata <= { memory[1], memory[2], memory[3], memory[4] };
					outputmk <= { memory[5], memory[6], memory[7], memory[8] };
				end
				SI2:begin
					outputdata <= { memory[9], memory[10], memory[11], memory[12] };
					outputmk <= { memory[13], memory[14], memory[15], memory[16] };
				end
				SI3:begin
					outputdata <= { memory[17], memory[18], memory[19], memory[20] };
					outputmk <= { memory[21], memory[22], memory[23], memory[24] };
				end
				SI4:begin
					outputdata <= { memory[25], memory[26], memory[27], memory[28] };
					outputmk <= { memory[29], memory[30], memory[31], memory[32] };
				end
				SI5:begin
					outputdata <= { memory[33], memory[34], memory[35], memory[36] };
					outputmk <= { memory[37], memory[38], memory[39], memory[40] };
				end
				SI6:begin
					outputdata <= { memory[41], memory[42], memory[43], memory[44] };
					outputmk <= { memory[45], memory[46], memory[47], memory[48] };
				end
				SI7:begin
					outputdata <= { memory[49], memory[50], memory[51], memory[52] };
					outputmk <= { memory[53], memory[54], memory[55], memory[56] };
				end
				SI8:begin
					r_end_input <= 1;
					outputdata <= { memory[57], memory[58], memory[59], memory[60] };
					outputmk <= { memory[61], memory[62], memory[63], memory[64] };
				end
				SI9:begin
					r_end_input <= 0;
					outputdata <= 0;
					outputmk <= 0;
				end
				default:begin
				end
			endcase
		end
	end

	assign datain = outputdata;
	assign mkin = outputmk;
	assign isdec = r_isdec;
	assign start_input = r_start_input;
	assign end_input = r_end_input;

	// User logic ends

	endmodule
