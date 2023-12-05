`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 14/2/2023 
// Design Name: 
// Module Name:    axis m
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
//     master module of SM3
//////////////////////////////////////////////////////////////////////////////////
	module sm3_axis_m #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input wire[1023:0] wire_sm3_to_master,
		input wire calculate_valid,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);
	// Total number of output data                                                 
	localparam NUMBER_OF_OUTPUT_WORDS = 32;                                               
	                                                                                     
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 (input integer bit_depth);                                   
	  begin                                                                              
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
	      bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction                                                                          
	                                                                                     
	// WAIT_COUNT_BITS is the width of the wait counter.                                 
	localparam integer WAIT_COUNT_BITS = clogb2(C_M_START_COUNT-1);                      
	                                                                                     
	// bit_num gives the minimum number of bits needed to address 'depth' size of FIFO.  
	localparam bit_num  = clogb2(NUMBER_OF_OUTPUT_WORDS);                               
	                                                                                     
	// Define the states of state machine                                                
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO                                      
	parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state               
	                                                                                     
	                INIT_COUNTER  = 2'b01, // This state initializes the counter, once   
	                                // the counter reaches C_M_START_COUNT count,        
	                                // the state machine changes state to SEND_STREAM     
	                SEND_STREAM   = 2'b10; // In this state the                          
	                                     // stream data is output through M_AXIS_TDATA   
	// State variable                                                                    
	reg [1:0] mst_exec_state;                                                            
	// Example design FIFO read pointer                                                  
	reg [bit_num-1:0] read_pointer;                                                      

	// AXI Stream internal signals
	//wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
	reg [WAIT_COUNT_BITS-1 : 0] 	count;
	//streaming data valid
	wire  	axis_tvalid;
	//streaming data valid delayed by one clock cycle
	reg  	axis_tvalid_delay;
	//Last of the streaming data 
	wire  	axis_tlast;
	//Last of the streaming data delayed by one clock cycle
	reg  	axis_tlast_delay;
	//FIFO implementation signals
	reg [C_M_AXIS_TDATA_WIDTH-1 : 0] 	stream_data_out;
	wire  	tx_en;
	//The master has issued all the streaming data stored in FIFO
	reg  	tx_done;

	/* memory */
	reg[31:0] memory[0:31];


	// I/O Connections assignments

	assign M_AXIS_TVALID	= axis_tvalid_delay;
	assign M_AXIS_TDATA	= stream_data_out;
	assign M_AXIS_TLAST	= axis_tlast_delay;
	assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};


	// Control state machine implementation                             
	always @(posedge M_AXIS_ACLK)                                             
	begin                                                                     
	  if (!M_AXIS_ARESETN)                                                    
	  // Synchronous reset (active low)                                       
	    begin                                                                 
	      mst_exec_state <= IDLE;                                             
	      count    <= 0;                                                      
	    end                                                                   
	  else                                                                    
	    case (mst_exec_state)                                                 
	      IDLE:                                                               
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                               
	        if ( calculate_valid ) begin                                                           
	            mst_exec_state  <= INIT_COUNTER;                              
	        end                                                             
	        else begin                                                           
	            mst_exec_state  <= IDLE;                                      
	        end                                                             
	                                                                          
	      INIT_COUNTER:                                                       
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                               
	        if ( count == C_M_START_COUNT - 1 )                               
	          begin                                                           
	            mst_exec_state  <= SEND_STREAM;                               
	          end                                                             
	        else                                                              
	          begin                                                           
	            count <= count + 1;                                           
	            mst_exec_state  <= INIT_COUNTER;                              
	          end                                                             
	                                                                          
	      SEND_STREAM:                                                        
	        // The example design streaming master functionality starts       
	        // when the master drives output tdata from the FIFO and the slave
	        // has finished storing the S_AXIS_TDATA                          
	        if (tx_done)                                                      
	          begin                                                           
	            mst_exec_state <= IDLE;                                       
	          end                                                             
	        else                                                              
	          begin                                                           
	            mst_exec_state <= SEND_STREAM;                                
	          end                                                             
	    endcase                                                               
	end                                                                       


	//tvalid generation
	//axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	//number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	assign axis_tvalid = ((mst_exec_state == SEND_STREAM) && (read_pointer < NUMBER_OF_OUTPUT_WORDS));
	                                                                                               
	// AXI tlast generation                                                                        
	// axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
	// (0 to NUMBER_OF_OUTPUT_WORDS-1)                                                             
	assign axis_tlast = (read_pointer == NUMBER_OF_OUTPUT_WORDS-1);                                
	                                                                                               
	                                                                                               
	// Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	// to match the latency of M_AXIS_TDATA                                                        
	always @(posedge M_AXIS_ACLK)                                                                  
	begin                                                                                          
	  if (!M_AXIS_ARESETN)                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= 1'b0;                                                               
	      axis_tlast_delay <= 1'b0;                                                                
	    end                                                                                        
	  else                                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= axis_tvalid;                                                        
	      axis_tlast_delay <= axis_tlast;                                                          
	    end                                                                                        
	end                                                                                            


	//read_pointer pointer

	always@(posedge M_AXIS_ACLK)                                               
	begin                                                                            
	  if(!M_AXIS_ARESETN)                                                            
	    begin                                                                        
	      read_pointer <= 0;                                                         
	      tx_done <= 1'b0;                                                           
	    end                                                                          
	  else                                                                           
	    if (read_pointer <= NUMBER_OF_OUTPUT_WORDS-1)                                
	      begin                                                                      
	        if (tx_en)                                                               
	          // read pointer is incremented after every read from the FIFO          
	          // when FIFO read signal is enabled.                                   
	          begin                                                                  
	            read_pointer <= read_pointer + 1;                                    
	            tx_done <= 1'b0;                                                     
	          end                                                                    
	      end                                                                        
	    else if (read_pointer == NUMBER_OF_OUTPUT_WORDS)                             
	      begin                                                                      
	        // tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
	        // has been out.                                                         
	        tx_done <= 1'b1;                                                         
	      end                                                                        
	end                                                                              


	//FIFO read enable generation 

	assign tx_en = M_AXIS_TREADY && axis_tvalid;   
	                                                     
	    // Streaming output data is read from FIFO       
	    always @( posedge M_AXIS_ACLK )                  
	    begin                                            
	      if(!M_AXIS_ARESETN)                            
	        begin                                        
	          stream_data_out <= 1;                      
	        end                                          
	      else if (tx_en)// && M_AXIS_TSTRB[byte_index]  
	        begin                                        
	        //   stream_data_out <= read_pointer + 32'b1;   
				stream_data_out <= memory[read_pointer];
	        end                                          
	    end 

	// memory logic
	integer i;
	always @(posedge M_AXIS_ACLK) begin
		if(!M_AXIS_ARESETN) begin
			/*
			for( i = 0 ; i < 32 ; i = i + 1 ) begin
				memory[i] <= 0;
			end
			*/
			memory[0] <= 0 ; memory[1] <= 0 ; memory[2] <= 0 ; memory[3] <= 0 ;
			memory[4] <= 0 ; memory[5] <= 0 ; memory[6] <= 0 ; memory[7] <= 0 ;
			memory[8] <= 0 ; memory[9] <= 0 ; memory[10] <= 0 ; memory[11] <= 0 ;
			memory[12] <= 0 ; memory[13] <= 0 ; memory[14] <= 0 ; memory[15] <= 0 ;
			memory[16] <= 0 ; memory[17] <= 0 ; memory[18] <= 0 ; memory[19] <= 0 ;
			memory[20] <= 0 ; memory[21] <= 0 ; memory[22] <= 0 ; memory[23] <= 0 ;
			memory[24] <= 0 ; memory[25] <= 0 ; memory[26] <= 0 ; memory[27] <= 0 ;
			memory[28] <= 0 ; memory[29] <= 0 ; memory[30] <= 0 ; memory[31] <= 0 ;
		end
		else begin
			if(mst_exec_state==IDLE) begin
			//if(calculate_valid) begin
				/*
				for( i = 0 ; i < 32 ; i = i + 1) begin
					memory[i] <= wire_sm3_to_master[(32*i) +: 32];
				end
				*/
				memory[31] <= wire_sm3_to_master[31:0];
				memory[30] <= wire_sm3_to_master[63:32];
				memory[29] <= wire_sm3_to_master[95:64];
				memory[28] <= wire_sm3_to_master[127:96];
				memory[27] <= wire_sm3_to_master[159:128];
				memory[26] <= wire_sm3_to_master[191:160];
				memory[25] <= wire_sm3_to_master[223:192];
				memory[24] <= wire_sm3_to_master[255:224];
				memory[23] <= wire_sm3_to_master[287:256];
				memory[22] <= wire_sm3_to_master[319:288];
				memory[21] <= wire_sm3_to_master[351:320];
				memory[20] <= wire_sm3_to_master[383:352];
				memory[19] <= wire_sm3_to_master[415:384];
				memory[18] <= wire_sm3_to_master[447:416];
				memory[17] <= wire_sm3_to_master[479:448];
				memory[16] <= wire_sm3_to_master[511:480];
				memory[15] <= wire_sm3_to_master[543:512];
				memory[14] <= wire_sm3_to_master[575:544];
				memory[13] <= wire_sm3_to_master[607:576];
				memory[12] <= wire_sm3_to_master[639:608];
				memory[11] <= wire_sm3_to_master[671:640];
				memory[10] <= wire_sm3_to_master[703:672];
				memory[9] <= wire_sm3_to_master[735:704];
				memory[8] <= wire_sm3_to_master[767:736];
				memory[7] <= wire_sm3_to_master[799:768];
				memory[6] <= wire_sm3_to_master[831:800];
				memory[5] <= wire_sm3_to_master[863:832];
				memory[4] <= wire_sm3_to_master[895:864];
				memory[3] <= wire_sm3_to_master[927:896];
				memory[2] <= wire_sm3_to_master[959:928];
				memory[1] <= wire_sm3_to_master[991:960];
				memory[0] <= wire_sm3_to_master[1023:992];
			end
			else begin
			end
		end
	end                                             

	// Add user logic here

	// User logic ends

	endmodule
