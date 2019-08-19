`default_nettype none

module risc16ba_top
  (
   input wire 	      clk_ext_in,
   input wire 	      clk_usb_in,
   input wire 	      n_rst_ext_in,
   
   // Push buttons
   input wire [7:0]   sw_in,
   
   // 7-segment LEDs
   output wire [5:0]  seg_sel,
   output wire [7:0]  seg_db,

   // LEDs
   output wire [7:0]  led, // active-low

   // USB IF
   input wire 	      usb_n_cmd, // active-low
   output wire 	      usb_n_ack64, // active-low
   input wire 	      usb_rg_dt, // high: register access / low: data access
   output wire 	      usb_n_ack, // active-low
   input wire 	      usb_n_bulk, // active-low
   inout wire [7:0]   usb_data,
   input wire 	      usb_n_frd, // active-low
   input wire 	      usb_n_fwr, // active-low

   // SRAM BANK A
   output wire [17:0] mem_a_addr,
   inout wire [15:0]  mem_a_data,
   output wire 	      mem_a_n_oe,
   output wire 	      mem_a_n_we,
   output wire 	      mem_a_n_ce,
   output wire 	      mem_a_n_lb,
   output wire 	      mem_a_n_ub,

   // SRAM BANK B
   output wire [17:0] mem_b_addr,
   inout wire [15:0]  mem_b_data,
   output wire 	      mem_b_n_oe,
   output wire 	      mem_b_n_we,
   output wire 	      mem_b_n_ce,
   output wire 	      mem_b_n_lb,
   output wire 	      mem_b_n_ub
   );

   localparam integer CLOCK_FREQ = 24000000;
   wire 	     clk_sys, n_rst_sys, clk_write, pll_locked, n_rst_usb;

   clk_generator
     clk_generator_inst
       (
	.inclk0(clk_ext_in),
	.c0(clk_sys),
	.c1(clk_write),
	.locked(pll_locked)
	);
   
   double_ff
     #(
       .WIDTH(1),
       .INIT_VAL(0)
       )
   double_ff_n_rst_sys
     (
      .clk(clk_sys),
      .din(n_rst_ext_in & pll_locked),
      .dout(n_rst_sys)
      );

   double_ff
     #(
       .WIDTH(1),
       .INIT_VAL(0)
       )
   double_ff_n_rst_usb
     (
      .clk(clk_usb_in),
      .din(n_rst_ext_in & pll_locked),
      .dout(n_rst_usb)
      );

   wire [15:0] 	     usb_mem_data_out, usb_mem_addr_out;
   wire 	     usb_mem_we;
 
   usb_if
     usb_if_inst
       (
	.clk(clk_usb_in),
	.n_rst(n_rst_usb),
	.n_cmd(usb_n_cmd),
	.n_ack64(usb_n_ack64),
	.rg_dt(usb_rg_dt),
	.n_ack(usb_n_ack),
	.n_bulk(usb_n_bulk),
	.usb_data(usb_data),
	.n_frd(usb_n_frd),
	.n_fwr(usb_n_fwr),
	.mem_data_out(usb_mem_data_out),
	.mem_data_in(mem_a_data),
	.mem_addr_out(usb_mem_addr_out),
	.mem_we(usb_mem_we)
	);

   wire [7:0] 	     sw_sync, sw_debounced, sw_event;
   
   double_ff
     #(
       .WIDTH(8),
       .INIT_VAL(8'hff)
       )
   double_ff_sw
     (
      .clk(clk_sys),
      .din(sw_in),
      .dout(sw_sync)
      );

   generate
      genvar 	     i;
      for (i = 0; i < 8; i = i + 1) begin: debouncer_gen
	 debouncer
	  #(
	    .CLOCK_FREQ(CLOCK_FREQ),
	    .MASK_DURATION_MS(100),
	    .INIT_VAL(1)
	    )
	 debouncer_inst
	   (
	    .clk(clk_sys),
	    .n_rst(n_rst_sys),
	    .din(sw_sync[i]),
	    .dout(sw_debounced[i])
	    );
      end
   endgenerate

   sync_diff
     #(
       .INIT_VAL(1)
       )
   sync_diff_inst_key0
     (
      .clk(clk_sys),
      .n_rst(n_rst_sys),
      .din(sw_debounced[0]),
      .dout(sw_event[0])
      );

   enum {STOP = 0, RUNNING = 1} cpu_state;
   
   always_ff @(posedge clk_sys) begin
      if (!n_rst_sys)
	cpu_state <= STOP;
      else if (sw_event[0]) begin
	 if (cpu_state == STOP)
	   cpu_state <= RUNNING;
	 else
	   cpu_state <= STOP;
      end
   end

   wire [15:0] cpu_dmem_data_out, cpu_dmem_addr_out, cpu_imem_addr_out;
   wire        cpu_dmem_oe, cpu_dmem_we0, cpu_dmem_we1, cpu_imem_oe;
   
   risc16ba
     risc16ba_inst
       (
	.clk(clk_sys),
	.rst((cpu_state == STOP)? 1'b1: 1'b0),
	.ddin(mem_a_data),
	.ddout(cpu_dmem_data_out),
	.daddr(cpu_dmem_addr_out),
	.doe(cpu_dmem_oe),
	.dwe0(cpu_dmem_we0),
	.dwe1(cpu_dmem_we1),
	.idin(mem_b_data),
	.iaddr(cpu_imem_addr_out),
	.ioe(cpu_imem_oe)
	);

   wire        cpu_dmem_we;
   assign cpu_dmem_we = cpu_dmem_we0 | cpu_dmem_we1;

   reg [23:0]  led_register;
   always_ff @(posedge clk_sys) begin
      if (!n_rst_sys)
	led_register <= 24'h0;
      else if (cpu_dmem_we == 1'b1) begin
	 if (cpu_dmem_addr_out == 16'h0200) begin
	    if (cpu_dmem_we1) led_register[7:0] <= cpu_dmem_data_out[7:0];
	    if (cpu_dmem_we0) led_register[15:8] <= cpu_dmem_data_out[15:8];
	 end
	 else if (cpu_dmem_addr_out == 16'h0202)
	   led_register[23:16] <= cpu_dmem_data_out[7:0];
      end
   end
   
   led_controller
     #(
       .CLOCK_FREQ(CLOCK_FREQ),
       .SWITCH_FREQ(800)
       )
   led_controoler_inst
     (
      .clk(clk_sys),
      .n_rst(n_rst_sys),
      .din(led_register),
      .seg_sel(seg_sel),
      .seg_db(seg_db)
      );

   assign led = {8{cpu_state[0]}};

   assign mem_a_n_ce = 1'b0;
   assign mem_a_n_lb = (cpu_state == STOP)? 1'b0: 
		       ~(cpu_dmem_oe | cpu_dmem_we1);
   assign mem_a_n_ub = (cpu_state == STOP)? 1'b0: 
		       ~(cpu_dmem_oe | cpu_dmem_we0);
   
   wire mem_a_n_we_int;
   assign mem_a_n_we_int = (cpu_state == STOP)? !usb_mem_we: !cpu_dmem_we;
   assign mem_a_n_we = mem_a_n_we_int | clk_write;
  
   assign mem_a_n_oe = (cpu_state == STOP)? usb_mem_we: cpu_dmem_we;
   
   assign mem_a_data = (mem_a_n_oe == 1'b0)? 16'hzzzz:
		       (cpu_state == STOP)? usb_mem_data_out: cpu_dmem_data_out;
   
   assign mem_a_addr = (cpu_state == STOP)? {2'b00, usb_mem_addr_out}: 
		       {3'b000, cpu_dmem_addr_out[15:1]};

   assign mem_b_n_ce = 1'b0;
   assign mem_b_n_lb = 1'b0;
   assign mem_b_n_ub = 1'b0;
   
   wire mem_b_n_we_int;
   assign mem_b_n_we_int = (cpu_state == STOP)? !usb_mem_we: 1'b1;
   assign mem_b_n_we = mem_b_n_we_int | clk_write;

   assign mem_b_n_oe = (cpu_state == STOP)? usb_mem_we: ~cpu_imem_oe;
   assign mem_b_data = (mem_b_n_oe == 1'b0)? 16'hzzzz:
		       (cpu_state == STOP)? usb_mem_data_out: 16'hzzzz;
   assign mem_b_addr = (cpu_state == STOP)? {2'b00, usb_mem_addr_out}: 
		       {3'b000, cpu_imem_addr_out[15:1]};   
endmodule 

      
module double_ff
    #(
      parameter integer WIDTH = 32,
      parameter [WIDTH-1:0] INIT_VAL = 0
      )
   (
    input wire              clk,
    input wire [WIDTH-1:0]  din,
    output wire [WIDTH-1:0] dout
    );

   reg [WIDTH-1:0]      tmp_reg = INIT_VAL;
   reg [WIDTH-1:0]      sync_reg = INIT_VAL;
   
   always @(posedge clk) begin
      tmp_reg <= din;
      sync_reg <= tmp_reg;
   end
   assign dout = sync_reg;
endmodule 


module debouncer
  #(
    parameter integer CLOCK_FREQ = 24000000,  // 24 MHz
    parameter integer MASK_DURATION_MS = 10,   // 10 ms
    parameter [0:0] INIT_VAL = 0
    )
  (
   input wire clk,
   input wire n_rst,
   input wire din,
   output reg dout
   );

   localparam integer MAX_COUNT = (CLOCK_FREQ / 1000) * MASK_DURATION_MS - 1;

   reg [1:0] 	      shift_reg;
   reg [$clog2(MAX_COUNT):0] count;
   always_ff @(posedge clk) begin
      if (!n_rst)
	count <= 'b0;
      else begin
	 if (shift_reg[0] ^ shift_reg[1])
	   count <= 'b1;
	 else if (count != 'b0) begin
	    if (count == MAX_COUNT)
	      count <= 'b0;
	    else
	      count <= count + 1'b1;
	 end
      end
   end
   
   always_ff @(posedge clk) begin
      if (!n_rst) 
	shift_reg <= {INIT_VAL, INIT_VAL};
      else 
	shift_reg <= {shift_reg[0], din};
   end

   always_ff @(posedge clk) begin
      if (!n_rst)
	dout <= INIT_VAL;
      else if (count == 'b0)
	dout <= shift_reg[0];
   end
endmodule


module sync_diff
  #(
    parameter [0:0] INIT_VAL = 0
    )
   (
    input wire clk,
    input wire n_rst,
    input wire din,
    output wire dout
    );

   reg [1:0] 	shift_reg;
   always_ff @(posedge clk) begin
      if (!n_rst)
	shift_reg <= {INIT_VAL, INIT_VAL};
      else
	shift_reg <= {shift_reg[0], din};
   end

   assign dout = ((shift_reg[1] == INIT_VAL) && 
		  (shift_reg[0] != INIT_VAL))? 1'b1: 1'b0;
endmodule


module led_controller
  #(
    parameter integer CLOCK_FREQ = 24000000, // 24MHz
    parameter integer SWITCH_FREQ = 600 // 600Hz
    )
  (
   input wire 	     clk,
   input wire 	     n_rst,
   input wire [23:0] din,
   output reg [5:0]  seg_sel,
   output reg [7:0]  seg_db
   );
   
   localparam integer MAX_COUNT = CLOCK_FREQ / SWITCH_FREQ - 1;
   
   reg [$clog2(MAX_COUNT):0] count;
   always_ff @(posedge clk) begin
      if (!n_rst)
	count <= 'b0;
      else begin
	 if (count == MAX_COUNT)
	   count <= 'b0;
	 else
	   count <= count + 1'b1;
      end
   end   

   always_ff @(posedge clk) begin
      if (!n_rst)
	seg_sel <= 6'b111110;
      else if (count == MAX_COUNT)
	seg_sel <= {seg_sel[4:0], seg_sel[5]};
   end

   always_ff @(posedge clk) begin
      if (!n_rst)
	seg_db <= 8'b00000000;
      else if (count == MAX_COUNT) begin
	case (seg_sel)
	  6'b111110: seg_db <= seg_db_decode(din[ 4 +: 4]);
	  6'b111101: seg_db <= seg_db_decode(din[ 8 +: 4]);
	  6'b111011: seg_db <= seg_db_decode(din[12 +: 4]);
	  6'b110111: seg_db <= seg_db_decode(din[16 +: 4]);
	  6'b101111: seg_db <= seg_db_decode(din[20 +: 4]);
	  6'b011111: seg_db <= seg_db_decode(din[ 0 +: 4]);
	  default:   seg_db <= 8'b00000000;
	endcase
      end
   end

   function [7:0] seg_db_decode(input [3:0] din);
      begin
	 case (din)
	   4'h0: seg_db_decode = 8'b00111111;
	   4'h1: seg_db_decode = 8'b00000110;
	   4'h2: seg_db_decode = 8'b01011011;
	   4'h3: seg_db_decode = 8'b01001111;
	   4'h4: seg_db_decode = 8'b01100110;
	   4'h5: seg_db_decode = 8'b01101101;
	   4'h6: seg_db_decode = 8'b01111101;
	   4'h7: seg_db_decode = 8'b00000111;
	   4'h8: seg_db_decode = 8'b01111111;
	   4'h9: seg_db_decode = 8'b01101111;
	   4'ha: seg_db_decode = 8'b01110111;
	   4'hb: seg_db_decode = 8'b01111100;
	   4'hc: seg_db_decode = 8'b00111001;
	   4'hd: seg_db_decode = 8'b01011110;
	   4'he: seg_db_decode = 8'b01111001;
	   4'hf: seg_db_decode = 8'b01110001;
	 endcase 
      end
   endfunction
endmodule // led_controller


module usb_if
  (
   // AN2135AC
   input wire 	      clk, // 24 MHz from AN2135SC
   input wire 	      n_rst, // active-low synchronous
   input wire 	      n_cmd, 
   output wire 	      n_ack64, 
   input wire 	      rg_dt, // high: register access / low: data access
   output wire 	      n_ack, 
   input wire 	      n_bulk,
   inout wire [7:0]   usb_data,
   input wire 	      n_frd, 
   input wire 	      n_fwr, 
   // Memory IF
   output wire [15:0] mem_data_out,
   input wire [15:0]  mem_data_in,
   output wire [15:0] mem_addr_out,
   output reg 	      mem_we
   );
   
   enum {IDLE, WAIT_1B, ACCESS_1B, WAIT_0B, ACCESS_0B} state, next_state;

   reg [15:0] wbuf;  // write bufffer
   reg [15:0] mar;   // memory address register
   reg [5:0] reg_addr;
   
   wire [7:0]  data_selected;
      
   // not in use
   assign n_ack = 1'b0;
   assign n_ack64 = 1'b0;

   // state controller
   always_ff @(posedge clk) begin
      if (!n_rst)
	state <= IDLE;
      else
	state <= next_state;
   end
   
   always_comb begin
      next_state <= state;
      case (state)
	IDLE:       
	  if ((!n_cmd) & (!n_fwr)) begin
	     if (usb_data[7:6] == 2'b01) // only support 16-bit access
	       next_state <= WAIT_1B;
	  end
	
	WAIT_1B:    
	  if ((!n_frd) | (!n_fwr)) 
	    next_state <= ACCESS_1B;
	
	ACCESS_1B:  
	  next_state <= WAIT_0B;
	
	WAIT_0B:    
	  if ((!n_frd) | (!n_fwr))
	    next_state <= ACCESS_0B;
	
	ACCESS_0B:  
	  next_state <= IDLE;
      endcase
   end 

   // addrress for register file
   always_ff @(posedge clk) begin
      if (!n_rst)
	reg_addr <= 6'h00;
      else if ((state == IDLE) && ((!n_cmd) & (!n_fwr)))
	reg_addr <= usb_data[5:0];
   end

   // write bufffer
   always_ff @(posedge clk) begin
      if (!n_rst)
	wbuf <= 16'h0000;
      else if ((reg_addr == 6'h01) && (state == WAIT_1B) && (!n_fwr))
	wbuf[7:0] <= usb_data;
      else if ((reg_addr == 6'h01) && (state == WAIT_0B) && (!n_fwr))
	wbuf[15:8] <= usb_data;
   end

   // write enable
   always_ff @(posedge clk) begin
      if (!n_rst)
	mem_we <= 1'b0;
      else begin
	 if ((reg_addr == 6'h01) && (state == WAIT_0B) && (!n_fwr))
	   mem_we <= 1'b1;
	 else 
	   mem_we <= 1'b0;
      end
   end

   // memory data register (for read)
   reg [15:0] mdr;
   always_ff @(posedge clk) begin
      if (!n_rst)
	mdr <= 16'h0000;
      else 
	mdr <= mem_data_in;
   end

   // memroy address register
   always_ff @(posedge clk) begin
      if (!n_rst)
	mar <= 16'h0000;
      else if ((reg_addr == 6'h00) && (state == WAIT_1B) && (!n_fwr))
	mar[7:0] <= usb_data;
      else if ((reg_addr == 6'h00) && (state == WAIT_0B) && (!n_fwr))
	mar[15:8] <= usb_data;
   end
      
   // data bus control
   assign data_selected = (state == WAIT_1B || state == ACCESS_1B)? 
			  mdr[7:0]: mdr[15:8];
   assign usb_data = (!n_frd)? data_selected: 8'hzz;
   assign mem_data_out = wbuf;
   assign mem_addr_out = mar;
endmodule
`default_nettype wire

// megafunction wizard: %ALTPLL%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altpll 

// ============================================================
// File Name: clk_generator.v
// Megafunction Name(s):
// 			altpll
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 13.0.1 Build 232 06/12/2013 SP 1 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2013 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, Altera MegaCore Function License 
//Agreement, or other applicable license agreement, including, 
//without limitation, that your use is for the sole purpose of 
//programming logic devices manufactured by Altera and sold by 
//Altera or its authorized distributors.  Please refer to the 
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module clk_generator (
	inclk0,
	c0,
	c1,
	locked);

	input	  inclk0;
	output	  c0;
	output	  c1;
	output	  locked;

	wire [5:0] sub_wire0;
	wire  sub_wire2;
	wire [0:0] sub_wire6 = 1'h0;
	wire [0:0] sub_wire3 = sub_wire0[0:0];
	wire [1:1] sub_wire1 = sub_wire0[1:1];
	wire  c1 = sub_wire1;
	wire  locked = sub_wire2;
	wire  c0 = sub_wire3;
	wire  sub_wire4 = inclk0;
	wire [1:0] sub_wire5 = {sub_wire6, sub_wire4};

	altpll	altpll_component (
				.inclk (sub_wire5),
				.clk (sub_wire0),
				.locked (sub_wire2),
				.activeclock (),
				.areset (1'b0),
				.clkbad (),
				.clkena ({6{1'b1}}),
				.clkloss (),
				.clkswitch (1'b0),
				.configupdate (1'b0),
				.enable0 (),
				.enable1 (),
				.extclk (),
				.extclkena ({4{1'b1}}),
				.fbin (1'b1),
				.fbmimicbidir (),
				.fbout (),
				.fref (),
				.icdrclk (),
				.pfdena (1'b1),
				.phasecounterselect ({4{1'b1}}),
				.phasedone (),
				.phasestep (1'b1),
				.phaseupdown (1'b1),
				.pllena (1'b1),
				.scanaclr (1'b0),
				.scanclk (1'b0),
				.scanclkena (1'b1),
				.scandata (1'b0),
				.scandataout (),
				.scandone (),
				.scanread (1'b0),
				.scanwrite (1'b0),
				.sclkout0 (),
				.sclkout1 (),
				.vcooverrange (),
				.vcounderrange ());
	defparam
		altpll_component.clk0_divide_by = 1,
		altpll_component.clk0_duty_cycle = 50,
		altpll_component.clk0_multiply_by = 1,
		altpll_component.clk0_phase_shift = "0",
		altpll_component.clk1_divide_by = 1,
		altpll_component.clk1_duty_cycle = 50,
		altpll_component.clk1_multiply_by = 1,
		altpll_component.clk1_phase_shift = "-10417",
		altpll_component.compensate_clock = "CLK0",
		altpll_component.inclk0_input_frequency = 41666,
		altpll_component.intended_device_family = "Cyclone",
		altpll_component.invalid_lock_multiplier = 5,
		altpll_component.lpm_type = "altpll",
		altpll_component.operation_mode = "NORMAL",
		altpll_component.pll_type = "AUTO",
		altpll_component.port_activeclock = "PORT_UNUSED",
		altpll_component.port_areset = "PORT_UNUSED",
		altpll_component.port_clkbad0 = "PORT_UNUSED",
		altpll_component.port_clkbad1 = "PORT_UNUSED",
		altpll_component.port_clkloss = "PORT_UNUSED",
		altpll_component.port_clkswitch = "PORT_UNUSED",
		altpll_component.port_configupdate = "PORT_UNUSED",
		altpll_component.port_fbin = "PORT_UNUSED",
		altpll_component.port_inclk0 = "PORT_USED",
		altpll_component.port_inclk1 = "PORT_UNUSED",
		altpll_component.port_locked = "PORT_USED",
		altpll_component.port_pfdena = "PORT_UNUSED",
		altpll_component.port_phasecounterselect = "PORT_UNUSED",
		altpll_component.port_phasedone = "PORT_UNUSED",
		altpll_component.port_phasestep = "PORT_UNUSED",
		altpll_component.port_phaseupdown = "PORT_UNUSED",
		altpll_component.port_pllena = "PORT_UNUSED",
		altpll_component.port_scanaclr = "PORT_UNUSED",
		altpll_component.port_scanclk = "PORT_UNUSED",
		altpll_component.port_scanclkena = "PORT_UNUSED",
		altpll_component.port_scandata = "PORT_UNUSED",
		altpll_component.port_scandataout = "PORT_UNUSED",
		altpll_component.port_scandone = "PORT_UNUSED",
		altpll_component.port_scanread = "PORT_UNUSED",
		altpll_component.port_scanwrite = "PORT_UNUSED",
		altpll_component.port_clk0 = "PORT_USED",
		altpll_component.port_clk1 = "PORT_USED",
		altpll_component.port_clk3 = "PORT_UNUSED",
		altpll_component.port_clk4 = "PORT_UNUSED",
		altpll_component.port_clk5 = "PORT_UNUSED",
		altpll_component.port_clkena0 = "PORT_UNUSED",
		altpll_component.port_clkena1 = "PORT_UNUSED",
		altpll_component.port_clkena3 = "PORT_UNUSED",
		altpll_component.port_clkena4 = "PORT_UNUSED",
		altpll_component.port_clkena5 = "PORT_UNUSED",
		altpll_component.port_extclk0 = "PORT_UNUSED",
		altpll_component.port_extclk1 = "PORT_UNUSED",
		altpll_component.port_extclk2 = "PORT_UNUSED",
		altpll_component.port_extclk3 = "PORT_UNUSED",
		altpll_component.valid_lock_multiplier = 1;


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ACTIVECLK_CHECK STRING "0"
// Retrieval info: PRIVATE: BANDWIDTH STRING "1.000"
// Retrieval info: PRIVATE: BANDWIDTH_FEATURE_ENABLED STRING "0"
// Retrieval info: PRIVATE: BANDWIDTH_FREQ_UNIT STRING "MHz"
// Retrieval info: PRIVATE: BANDWIDTH_PRESET STRING "Low"
// Retrieval info: PRIVATE: BANDWIDTH_USE_AUTO STRING "1"
// Retrieval info: PRIVATE: BANDWIDTH_USE_CUSTOM STRING "0"
// Retrieval info: PRIVATE: BANDWIDTH_USE_PRESET STRING "0"
// Retrieval info: PRIVATE: CLKBAD_SWITCHOVER_CHECK STRING "0"
// Retrieval info: PRIVATE: CLKLOSS_CHECK STRING "0"
// Retrieval info: PRIVATE: CLKSWITCH_CHECK STRING "0"
// Retrieval info: PRIVATE: CNX_NO_COMPENSATE_RADIO STRING "0"
// Retrieval info: PRIVATE: CREATE_CLKBAD_CHECK STRING "0"
// Retrieval info: PRIVATE: CREATE_INCLK1_CHECK STRING "0"
// Retrieval info: PRIVATE: CUR_DEDICATED_CLK STRING "c0"
// Retrieval info: PRIVATE: CUR_FBIN_CLK STRING "e0"
// Retrieval info: PRIVATE: DEVICE_FAMILY NUMERIC "11"
// Retrieval info: PRIVATE: DEVICE_SPEED_GRADE STRING "Any"
// Retrieval info: PRIVATE: DIV_FACTOR0 NUMERIC "1"
// Retrieval info: PRIVATE: DIV_FACTOR1 NUMERIC "1"
// Retrieval info: PRIVATE: DUTY_CYCLE0 STRING "50.00000000"
// Retrieval info: PRIVATE: DUTY_CYCLE1 STRING "50.00000000"
// Retrieval info: PRIVATE: EFF_OUTPUT_FREQ_VALUE0 STRING "24.000000"
// Retrieval info: PRIVATE: EFF_OUTPUT_FREQ_VALUE1 STRING "24.000000"
// Retrieval info: PRIVATE: EXPLICIT_SWITCHOVER_COUNTER STRING "0"
// Retrieval info: PRIVATE: EXT_FEEDBACK_RADIO STRING "0"
// Retrieval info: PRIVATE: GLOCKED_COUNTER_EDIT_CHANGED STRING "1"
// Retrieval info: PRIVATE: GLOCKED_FEATURE_ENABLED STRING "0"
// Retrieval info: PRIVATE: GLOCKED_MODE_CHECK STRING "0"
// Retrieval info: PRIVATE: GLOCK_COUNTER_EDIT NUMERIC "1048575"
// Retrieval info: PRIVATE: HAS_MANUAL_SWITCHOVER STRING "1"
// Retrieval info: PRIVATE: INCLK0_FREQ_EDIT STRING "24.000"
// Retrieval info: PRIVATE: INCLK0_FREQ_UNIT_COMBO STRING "MHz"
// Retrieval info: PRIVATE: INCLK1_FREQ_EDIT STRING "100.000"
// Retrieval info: PRIVATE: INCLK1_FREQ_EDIT_CHANGED STRING "1"
// Retrieval info: PRIVATE: INCLK1_FREQ_UNIT_CHANGED STRING "1"
// Retrieval info: PRIVATE: INCLK1_FREQ_UNIT_COMBO STRING "MHz"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone"
// Retrieval info: PRIVATE: INT_FEEDBACK__MODE_RADIO STRING "1"
// Retrieval info: PRIVATE: LOCKED_OUTPUT_CHECK STRING "1"
// Retrieval info: PRIVATE: LOCK_LOSS_SWITCHOVER_CHECK STRING "0"
// Retrieval info: PRIVATE: LONG_SCAN_RADIO STRING "1"
// Retrieval info: PRIVATE: LVDS_MODE_DATA_RATE STRING "Not Available"
// Retrieval info: PRIVATE: LVDS_MODE_DATA_RATE_DIRTY NUMERIC "0"
// Retrieval info: PRIVATE: LVDS_PHASE_SHIFT_UNIT0 STRING "deg"
// Retrieval info: PRIVATE: LVDS_PHASE_SHIFT_UNIT1 STRING "deg"
// Retrieval info: PRIVATE: MIG_DEVICE_SPEED_GRADE STRING "Any"
// Retrieval info: PRIVATE: MIRROR_CLK0 STRING "0"
// Retrieval info: PRIVATE: MIRROR_CLK1 STRING "0"
// Retrieval info: PRIVATE: MULT_FACTOR0 NUMERIC "1"
// Retrieval info: PRIVATE: MULT_FACTOR1 NUMERIC "1"
// Retrieval info: PRIVATE: NORMAL_MODE_RADIO STRING "1"
// Retrieval info: PRIVATE: OUTPUT_FREQ0 STRING "100.00000000"
// Retrieval info: PRIVATE: OUTPUT_FREQ1 STRING "100.00000000"
// Retrieval info: PRIVATE: OUTPUT_FREQ_MODE0 STRING "0"
// Retrieval info: PRIVATE: OUTPUT_FREQ_MODE1 STRING "0"
// Retrieval info: PRIVATE: OUTPUT_FREQ_UNIT0 STRING "MHz"
// Retrieval info: PRIVATE: OUTPUT_FREQ_UNIT1 STRING "MHz"
// Retrieval info: PRIVATE: PHASE_RECONFIG_FEATURE_ENABLED STRING "0"
// Retrieval info: PRIVATE: PHASE_RECONFIG_INPUTS_CHECK STRING "0"
// Retrieval info: PRIVATE: PHASE_SHIFT0 STRING "0.00000000"
// Retrieval info: PRIVATE: PHASE_SHIFT1 STRING "-90.00000000"
// Retrieval info: PRIVATE: PHASE_SHIFT_STEP_ENABLED_CHECK STRING "0"
// Retrieval info: PRIVATE: PHASE_SHIFT_UNIT0 STRING "deg"
// Retrieval info: PRIVATE: PHASE_SHIFT_UNIT1 STRING "deg"
// Retrieval info: PRIVATE: PLL_ADVANCED_PARAM_CHECK STRING "0"
// Retrieval info: PRIVATE: PLL_ARESET_CHECK STRING "0"
// Retrieval info: PRIVATE: PLL_AUTOPLL_CHECK NUMERIC "1"
// Retrieval info: PRIVATE: PLL_ENA_CHECK STRING "0"
// Retrieval info: PRIVATE: PLL_ENHPLL_CHECK NUMERIC "0"
// Retrieval info: PRIVATE: PLL_FASTPLL_CHECK NUMERIC "0"
// Retrieval info: PRIVATE: PLL_FBMIMIC_CHECK STRING "0"
// Retrieval info: PRIVATE: PLL_LVDS_PLL_CHECK NUMERIC "0"
// Retrieval info: PRIVATE: PLL_PFDENA_CHECK STRING "0"
// Retrieval info: PRIVATE: PLL_TARGET_HARCOPY_CHECK NUMERIC "0"
// Retrieval info: PRIVATE: PRIMARY_CLK_COMBO STRING "inclk0"
// Retrieval info: PRIVATE: SACN_INPUTS_CHECK STRING "0"
// Retrieval info: PRIVATE: SCAN_FEATURE_ENABLED STRING "0"
// Retrieval info: PRIVATE: SELF_RESET_LOCK_LOSS STRING "0"
// Retrieval info: PRIVATE: SHORT_SCAN_RADIO STRING "0"
// Retrieval info: PRIVATE: SPREAD_FEATURE_ENABLED STRING "0"
// Retrieval info: PRIVATE: SPREAD_FREQ STRING "50.000"
// Retrieval info: PRIVATE: SPREAD_FREQ_UNIT STRING "KHz"
// Retrieval info: PRIVATE: SPREAD_PERCENT STRING "0.500"
// Retrieval info: PRIVATE: SPREAD_USE STRING "0"
// Retrieval info: PRIVATE: SRC_SYNCH_COMP_RADIO STRING "0"
// Retrieval info: PRIVATE: STICKY_CLK0 STRING "1"
// Retrieval info: PRIVATE: STICKY_CLK1 STRING "1"
// Retrieval info: PRIVATE: SWITCHOVER_COUNT_EDIT NUMERIC "1"
// Retrieval info: PRIVATE: SWITCHOVER_FEATURE_ENABLED STRING "0"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: USE_CLK0 STRING "1"
// Retrieval info: PRIVATE: USE_CLK1 STRING "1"
// Retrieval info: PRIVATE: USE_CLKENA0 STRING "0"
// Retrieval info: PRIVATE: USE_CLKENA1 STRING "0"
// Retrieval info: PRIVATE: USE_MIL_SPEED_GRADE NUMERIC "0"
// Retrieval info: PRIVATE: ZERO_DELAY_RADIO STRING "0"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: CLK0_DIVIDE_BY NUMERIC "1"
// Retrieval info: CONSTANT: CLK0_DUTY_CYCLE NUMERIC "50"
// Retrieval info: CONSTANT: CLK0_MULTIPLY_BY NUMERIC "1"
// Retrieval info: CONSTANT: CLK0_PHASE_SHIFT STRING "0"
// Retrieval info: CONSTANT: CLK1_DIVIDE_BY NUMERIC "1"
// Retrieval info: CONSTANT: CLK1_DUTY_CYCLE NUMERIC "50"
// Retrieval info: CONSTANT: CLK1_MULTIPLY_BY NUMERIC "1"
// Retrieval info: CONSTANT: CLK1_PHASE_SHIFT STRING "-10417"
// Retrieval info: CONSTANT: COMPENSATE_CLOCK STRING "CLK0"
// Retrieval info: CONSTANT: INCLK0_INPUT_FREQUENCY NUMERIC "41666"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone"
// Retrieval info: CONSTANT: INVALID_LOCK_MULTIPLIER NUMERIC "5"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altpll"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "NORMAL"
// Retrieval info: CONSTANT: PLL_TYPE STRING "AUTO"
// Retrieval info: CONSTANT: PORT_ACTIVECLOCK STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_ARESET STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_CLKBAD0 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_CLKBAD1 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_CLKLOSS STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_CLKSWITCH STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_CONFIGUPDATE STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_FBIN STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_INCLK0 STRING "PORT_USED"
// Retrieval info: CONSTANT: PORT_INCLK1 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_LOCKED STRING "PORT_USED"
// Retrieval info: CONSTANT: PORT_PFDENA STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_PHASECOUNTERSELECT STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_PHASEDONE STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_PHASESTEP STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_PHASEUPDOWN STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_PLLENA STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANACLR STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANCLK STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANCLKENA STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANDATA STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANDATAOUT STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANDONE STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANREAD STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_SCANWRITE STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clk0 STRING "PORT_USED"
// Retrieval info: CONSTANT: PORT_clk1 STRING "PORT_USED"
// Retrieval info: CONSTANT: PORT_clk3 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clk4 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clk5 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clkena0 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clkena1 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clkena3 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clkena4 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_clkena5 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_extclk0 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_extclk1 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_extclk2 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: PORT_extclk3 STRING "PORT_UNUSED"
// Retrieval info: CONSTANT: VALID_LOCK_MULTIPLIER NUMERIC "1"
// Retrieval info: USED_PORT: @clk 0 0 6 0 OUTPUT_CLK_EXT VCC "@clk[5..0]"
// Retrieval info: USED_PORT: @extclk 0 0 4 0 OUTPUT_CLK_EXT VCC "@extclk[3..0]"
// Retrieval info: USED_PORT: c0 0 0 0 0 OUTPUT_CLK_EXT VCC "c0"
// Retrieval info: USED_PORT: c1 0 0 0 0 OUTPUT_CLK_EXT VCC "c1"
// Retrieval info: USED_PORT: inclk0 0 0 0 0 INPUT_CLK_EXT GND "inclk0"
// Retrieval info: USED_PORT: locked 0 0 0 0 OUTPUT GND "locked"
// Retrieval info: CONNECT: @inclk 0 0 1 1 GND 0 0 0 0
// Retrieval info: CONNECT: @inclk 0 0 1 0 inclk0 0 0 0 0
// Retrieval info: CONNECT: c0 0 0 0 0 @clk 0 0 1 0
// Retrieval info: CONNECT: c1 0 0 0 0 @clk 0 0 1 1
// Retrieval info: CONNECT: locked 0 0 0 0 @locked 0 0 0 0
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator.ppf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator_bb.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator_waveforms.html FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL clk_generator_wave*.jpg FALSE
// Retrieval info: LIB_FILE: altera_mf
