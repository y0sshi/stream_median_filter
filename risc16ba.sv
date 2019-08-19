`default_nettype none
`timescale 1ns/1ns

// (* <directive>=<value> *) <word>;

// (* altera_attribute = {"-name SDC_STATEMENT \"create_clock -name {my_clk} -period 1 -waveform { 0.000 2.5 } [get_ports {clk_ext_in}]\";-name SDC_STATEMENT \"create_clock -name {my_usb_clk} -period 1 -waveform { 0.000 2.5 } [get_ports {clk_usb_in}]\";-name SDC_STATEMENT \"create_clock -name {vclk} -period 1\";-name SDC_STATEMENT \"create_generated_clock -source {clk_generator_inst|altpll_component|pll|inclk[0]} -duty_cycle 50.00 -name {processor clk} {clk_generator_inst|altpll_component|pll|clk[0]}\";-name SDC_STATEMENT \"set_false_path -from [get_clocks processor_clk] -to [get_clocks vclk]\";-name SDC_STATEMENT \"set_false_path -from [get_clocks vclk] -to [get_clocks processor_clk]\";-name CYCLONE_OPTIMIZATION_TECHNIQUE SPEED"} *)

typedef enum {
  S0,
  S1,
  S2,
  S3,
  S_INIT
} state_t;

module risc16ba
  (
    input wire          clk,
    input wire          rst,
    input wire   [15:0] ddin,
    output logic [15:0] ddout,
    output wire  [15:0] daddr,
    output logic        doe,
    output logic        dwe0, dwe1,
    input wire   [15:0] idin,
    output wire  [15:0] iaddr,
    output wire         ioe
  );

  assign doe = 1'b0;
  assign ioe = (iaddr<=16'hbffe);

  // parameter
  localparam integer DATA_WIDTH = 16;
  localparam integer ADDR_WIDTH = 14;
  localparam integer WIDTH = 128;
  localparam integer HEIGHT = 128;
  localparam integer W_WIDTH = 128;
  localparam integer W_HEIGHT = 128;
  localparam integer FIFO_RATENCY = 4;
  localparam integer INITIAL_ADDR_IN = 16'h8000;
  localparam integer INITIAL_ADDR_OUT = 16'hc000;

  // state
  //localparam S0 = 4'd0;
  //localparam S1 = 4'd1;
  //localparam S2 = 4'd2;
  //localparam S3 = 4'd3;
  //localparam S4 = 4'd4;
  //localparam S5 = 4'd5;
  //localparam S6 = 4'd6;
  //localparam S7 = 4'd7;
  //localparam S_INIT = 4'hf;

  state_t state, state0, state1;
  logic [15:0] in_addr, out_addr;
  logic [15:0] addr;

  // state machine
  always @(posedge clk) begin
    if (rst) begin
      state <= S_INIT;
    end
    else begin
      case(state)
        S0:begin
          state <= (in_addr==16'h8100) ? S1 : state;
        end
        S1:begin
          state <= (in_addr[(DATA_WIDTH/2)-2:0]==7'h7e) ? S2 : state;
        end
        S2:begin
          state <= (in_addr == 16'hc000) ? S3 : S1;
        end
        S3:begin
          state <= (in_addr[(DATA_WIDTH/2)-2:0]==7'h00) ? S_INIT : state;
        end
        S_INIT:begin
          state <= (in_addr == 16'h807e) ? S0 : state;
        end
        default: begin 
          state <= S_INIT;
        end
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
    end
    else begin
      state0 <= state;
      state1 <= state;
    end
  end

  //--- register and wire Declaration ---//
  // shift register
  reg [(DATA_WIDTH/2)-1:0] a;
  reg [(DATA_WIDTH/2)-1:0] b;
  reg [(DATA_WIDTH/2)-1:0] c;
  reg [(DATA_WIDTH/2)-1:0] d;

  reg [DATA_WIDTH-1:0] FIFO_1 [61:0];

  reg [(DATA_WIDTH/2)-1:0] e;
  reg [(DATA_WIDTH/2)-1:0] f;
  reg [(DATA_WIDTH/2)-1:0] g;
  reg [(DATA_WIDTH/2)-1:0] h;

  reg [DATA_WIDTH-1:0] FIFO_0 [61:0];

  reg [(DATA_WIDTH/2)-1:0] i;
  reg [(DATA_WIDTH/2)-1:0] j;
  reg [(DATA_WIDTH/2)-1:0] k;
  reg [(DATA_WIDTH/2)-1:0] l;

  // processing unit
  // stage 0
  reg [(DATA_WIDTH/2)-1:0] reg0_s0 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s0 [8:0];
  wire [(DATA_WIDTH*3/2)-1:0] sort3_s0_0, sort3_s0_1, sort3_s0_2;
  // stage 1
  reg [(DATA_WIDTH/2)-1:0] reg0_s1 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s1 [8:0];
  // stage 2
  reg [(DATA_WIDTH/2)-1:0] reg0_s2 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s2 [8:0];
  // stage 3
  reg [(DATA_WIDTH/2)-1:0] reg0_s3 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s3 [8:0];
  // stage 4
  reg [(DATA_WIDTH/2)-1:0] reg0_s4 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s4 [8:0];
  // stage 5
  reg [(DATA_WIDTH/2)-1:0] reg0_s5 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s5 [8:0];
  wire [(DATA_WIDTH*3/2)-1:0] sort3_s5;
  // stage 6
  reg [(DATA_WIDTH/2)-1:0] reg0_s6 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s6 [8:0];
  wire [(DATA_WIDTH*3/2)-1:0] sort3_s6;
  // stage 7
  reg [(DATA_WIDTH/2)-1:0] reg0_s7 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s7 [8:0];
  // stage 8
  reg [(DATA_WIDTH/2)-1:0] reg0_s8 [8:0];
  reg [(DATA_WIDTH/2)-1:0] reg1_s8 [8:0];
  // stage 9
  reg [(DATA_WIDTH/2)-1:0] reg0_s9, median0_s9;
  reg [(DATA_WIDTH/2)-1:0] reg1_s9, median1_s9;
  // stage a
  reg [(DATA_WIDTH/2)-1:0] median0_sa, median1_sa;
  // stage b
  reg [(DATA_WIDTH/2)-1:0] median1_sb;


  assign ddout = {median1_sb, median0_sa};


  reg        out_flag;
  reg [15:0] clk_count;

  reg finish;

  //--- register and wire Declaration ---//
  
  assign iaddr = in_addr;
  assign daddr = out_addr;

  integer index;

  reg dwe_flag_0, dwe_flag_1;
  //reg [20:0] pixel0_cnt_s0;
  //reg [20:0] pixel0_cnt_s1;
  //reg [20:0] pixel0_cnt_s2;
  //reg [20:0] pixel0_cnt_s3;
  //reg [20:0] pixel0_cnt_s4;
  //reg [20:0] pixel0_cnt_s5;
  //reg [20:0] pixel0_cnt_s6;
  //reg [20:0] pixel0_cnt_s7;
  //reg [20:0] pixel0_cnt_s8;
  //reg [20:0] pixel0_cnt_s9;

  //reg [20:0] pixel1_cnt_s0;
  //reg [20:0] pixel1_cnt_s1;
  //reg [20:0] pixel1_cnt_s2;
  //reg [20:0] pixel1_cnt_s3;
  //reg [20:0] pixel1_cnt_s4;
  //reg [20:0] pixel1_cnt_s5;
  //reg [20:0] pixel1_cnt_s6;
  //reg [20:0] pixel1_cnt_s7;
  //reg [20:0] pixel1_cnt_s8;
  //reg [20:0] pixel1_cnt_s9;
  //reg [20:0] pixel1_cnt_sa;

  // control enable and finish flag
  always @(posedge clk) begin
    if (rst) begin
      //rst
      clk_count <= 16'd0;
      out_flag <= 1'b0;
      in_addr <= INITIAL_ADDR_IN;
      out_addr <= INITIAL_ADDR_OUT;
      addr <= INITIAL_ADDR_IN;
      dwe0 <= 1'b0;
      dwe1 <= 1'b0;
      finish <= 1'b0;
      //pixel1_cnt_s0 <= 'd0;
    end
    else begin
      clk_count <= clk_count + 1'b1;
      in_addr <= in_addr + 2'd2;
      addr <= addr + 2;

      //pixel0_cnt_s0 <= pixel1_cnt_s0 + 1;
      //pixel0_cnt_s1 <= pixel0_cnt_s0;
      //pixel0_cnt_s2 <= pixel0_cnt_s1;
      //pixel0_cnt_s3 <= pixel0_cnt_s2;
      //pixel0_cnt_s4 <= pixel0_cnt_s3;
      //pixel0_cnt_s5 <= pixel0_cnt_s4;
      //pixel0_cnt_s6 <= pixel0_cnt_s5;
      //pixel0_cnt_s7 <= pixel0_cnt_s6;
      //pixel0_cnt_s8 <= pixel0_cnt_s7;
      //pixel0_cnt_s9 <= pixel0_cnt_s8;

      //pixel1_cnt_s0 <= (in_addr >= 16'h8084) ? pixel1_cnt_s0 + 2 : pixel1_cnt_s0;
      //pixel1_cnt_s1 <= pixel1_cnt_s0;
      //pixel1_cnt_s2 <= pixel1_cnt_s1;
      //pixel1_cnt_s3 <= pixel1_cnt_s2;
      //pixel1_cnt_s4 <= pixel1_cnt_s3;
      //pixel1_cnt_s5 <= pixel1_cnt_s4;
      //pixel1_cnt_s6 <= pixel1_cnt_s5;
      //pixel1_cnt_s7 <= pixel1_cnt_s6;
      //pixel1_cnt_s8 <= pixel1_cnt_s7;
      //pixel1_cnt_s9 <= pixel1_cnt_s8;
      //pixel1_cnt_sa <= pixel1_cnt_s9;

      out_flag <= (in_addr==16'h8098) ? ~out_flag : out_flag;

      out_addr <= out_addr + (out_flag << 1);

      finish <= (out_addr == 'hfffe);


      dwe0 <= (16'h8098 <= in_addr) & (in_addr < 16'hc098);
      dwe1 <= (16'h8098 <= in_addr) & (in_addr < 16'hc098);
    end
  end

  // shift register
  always @(posedge clk) begin
    if (rst) begin
    end
    else begin
      l <= idin[(DATA_WIDTH/2)-1:0];
      k <= idin[DATA_WIDTH-1:(DATA_WIDTH/2)];

      j <= l;
      i <= k;

      FIFO_0[0][(DATA_WIDTH/2)-1:0] <= j;
      FIFO_0[0][DATA_WIDTH-1:(DATA_WIDTH/2)] <= i;

      for (index = 1; index < 62; index = index + 1) begin
        FIFO_0[index] <= FIFO_0[index-1];
      end

      h <= FIFO_0[61][(DATA_WIDTH/2)-1:0];
      g <= FIFO_0[61][DATA_WIDTH-1:(DATA_WIDTH/2)];

      f <= h;
      e <= g;

      FIFO_1[0][(DATA_WIDTH/2)-1:0] <= f;
      FIFO_1[0][DATA_WIDTH-1:(DATA_WIDTH/2)] <= e;

      for (index = 1; index < 62; index = index + 1) begin
        FIFO_1[index] <= FIFO_1[index-1];
      end

      d <= FIFO_1[61][(DATA_WIDTH/2)-1:0];
      c <= FIFO_1[61][DATA_WIDTH-1:(DATA_WIDTH/2)];

      b <= d;
      a <= c;
    end
  end

  // processor 0
  always @(posedge clk) begin
    if (rst) begin
    end
    else begin
      // stage 0
      case (state0)
        S0: begin
          reg0_s0[0] <= 8'h0;
          reg0_s0[1] <= 8'h0;
          reg0_s0[2] <= 8'h0;
          reg0_s0[3] <= 8'h0;
          reg0_s0[4] <= f;
          reg0_s0[5] <= 8'hff;
          reg0_s0[6] <= 8'hff;
          reg0_s0[7] <= 8'hff;
          reg0_s0[8] <= 8'hff;
        end
        S1: begin
          reg0_s0[0] <= a;
          reg0_s0[1] <= b;
          reg0_s0[2] <= c;
          reg0_s0[3] <= e;
          reg0_s0[4] <= f;
          reg0_s0[5] <= g;
          reg0_s0[6] <= i;
          reg0_s0[7] <= j;
          reg0_s0[8] <= k;
        end
        S2: begin
          reg0_s0[0] <= 8'h0;
          reg0_s0[1] <= 8'h0;
          reg0_s0[2] <= 8'h0;
          reg0_s0[3] <= 8'h0;
          reg0_s0[4] <= f;
          reg0_s0[5] <= 8'hff;
          reg0_s0[6] <= 8'hff;
          reg0_s0[7] <= 8'hff;
          reg0_s0[8] <= 8'hff;
        end
        S3: begin
          reg0_s0[0] <= 8'h0;
          reg0_s0[1] <= 8'h0;
          reg0_s0[2] <= 8'h0;
          reg0_s0[3] <= 8'h0;
          reg0_s0[4] <= f;
          reg0_s0[5] <= 8'hff;
          reg0_s0[6] <= 8'hff;
          reg0_s0[7] <= 8'hff;
          reg0_s0[8] <= 8'hff;
        end
        default: begin
          reg0_s0[0] <= 8'hx;
          reg0_s0[1] <= 8'hx;
          reg0_s0[2] <= 8'hx;
          reg0_s0[3] <= 8'hx;
          reg0_s0[4] <= 8'hx;
          reg0_s0[5] <= 8'hx;
          reg0_s0[6] <= 8'hx;
          reg0_s0[7] <= 8'hx;
          reg0_s0[8] <= 8'hx;
        end
      endcase
      // stage 1
      reg0_s1[0] <= min2(reg0_s0[0], reg0_s0[1]);
      reg0_s1[1] <= max2(reg0_s0[0], reg0_s0[1]);
      reg0_s1[2] <= min2(reg0_s0[2], reg0_s0[3]);
      reg0_s1[3] <= max2(reg0_s0[2], reg0_s0[3]);
      reg0_s1[4] <= reg0_s0[4];
      reg0_s1[5] <= min2(reg0_s0[5], reg0_s0[6]);
      reg0_s1[6] <= max2(reg0_s0[5], reg0_s0[6]);
      reg0_s1[7] <= min2(reg0_s0[7], reg0_s0[8]);
      reg0_s1[8] <= max2(reg0_s0[7], reg0_s0[8]);
      // stage 2
      reg0_s2[0] <= min2(reg0_s1[0], reg0_s1[2]);
      reg0_s2[1] <= max2(reg0_s1[0], reg0_s1[2]);
      reg0_s2[2] <= min2(reg0_s1[1], reg0_s1[3]);
      reg0_s2[3] <= max2(reg0_s1[1], reg0_s1[3]);
      reg0_s2[4] <= reg0_s1[4];
      reg0_s2[5] <= min2(reg0_s1[5], reg0_s1[7]);
      reg0_s2[6] <= max2(reg0_s1[5], reg0_s1[7]);
      reg0_s2[7] <= min2(reg0_s1[6], reg0_s1[8]);
      reg0_s2[8] <= max2(reg0_s1[6], reg0_s1[8]);
      // stage 3
      reg0_s3[0] <= reg0_s2[0];
      reg0_s3[1] <= min2(reg0_s2[1], reg0_s2[2]);
      reg0_s3[2] <= max2(reg0_s2[1], reg0_s2[2]);
      reg0_s3[3] <= reg0_s2[3];
      reg0_s3[4] <= reg0_s2[4];
      reg0_s3[5] <= reg0_s2[5];
      reg0_s3[6] <= min2(reg0_s2[6], reg0_s2[7]);
      reg0_s3[7] <= max2(reg0_s2[6], reg0_s2[7]);
      reg0_s3[8] <= reg0_s2[8];
      // stage 4
      reg0_s4[0] <= min2(reg0_s3[0], reg0_s3[5]);
      reg0_s4[1] <= max2(reg0_s3[0], reg0_s3[5]);
      reg0_s4[2] <= min2(reg0_s3[1], reg0_s3[6]);
      reg0_s4[3] <= max2(reg0_s3[1], reg0_s3[6]);
      reg0_s4[4] <= reg0_s3[4];
      reg0_s4[5] <= min2(reg0_s3[2], reg0_s3[7]);
      reg0_s4[6] <= max2(reg0_s3[2], reg0_s3[7]);
      reg0_s4[7] <= min2(reg0_s3[3], reg0_s3[8]);
      reg0_s4[8] <= max2(reg0_s3[3], reg0_s3[8]);
      // stage 5
      reg0_s5[0] <= reg0_s4[0];
      reg0_s5[1] <= min2(reg0_s4[1], reg0_s4[2]);
      reg0_s5[2] <= max2(reg0_s4[1], reg0_s4[2]);
      reg0_s5[3] <= min2(reg0_s4[3], reg0_s4[5]);
      reg0_s5[4] <= reg0_s4[4];
      reg0_s5[5] <= max2(reg0_s4[3], reg0_s4[5]);
      reg0_s5[6] <= min2(reg0_s4[6], reg0_s4[7]);
      reg0_s5[7] <= max2(reg0_s4[6], reg0_s4[7]);
      reg0_s5[8] <= reg0_s4[8];
      // stage 6
      reg0_s6[0] <= reg0_s5[0];
      reg0_s6[1] <= reg0_s5[1];
      reg0_s6[2] <= min2(reg0_s5[2], reg0_s5[3]);
      reg0_s6[3] <= max2(reg0_s5[2], reg0_s5[3]);
      reg0_s6[4] <= reg0_s5[4];
      reg0_s6[5] <= min2(reg0_s5[5], reg0_s5[6]);
      reg0_s6[6] <= max2(reg0_s5[5], reg0_s5[6]);
      reg0_s6[7] <= reg0_s5[7];
      reg0_s6[8] <= reg0_s5[8];
      // stage 7
      reg0_s7[0] <= reg0_s6[0];
      reg0_s7[1] <= reg0_s6[1];
      reg0_s7[2] <= reg0_s6[2];
      reg0_s7[3] <= min2(reg0_s6[3], reg0_s6[5]);
      reg0_s7[4] <= reg0_s6[4];
      reg0_s7[5] <= max2(reg0_s6[3], reg0_s6[5]);
      reg0_s7[6] <= reg0_s6[6];
      reg0_s7[7] <= reg0_s6[7];
      reg0_s7[8] <= reg0_s6[8];
      // stage 8
      reg0_s8[0] <= reg0_s7[0];
      reg0_s8[1] <= reg0_s7[1];
      reg0_s8[2] <= min2(reg0_s7[2], reg0_s7[3]);
      reg0_s8[3] <= max2(reg0_s7[2], reg0_s7[3]);
      reg0_s8[4] <= reg0_s7[4];
      reg0_s8[5] <= min2(reg0_s7[5], reg0_s7[6]);
      reg0_s8[6] <= max2(reg0_s7[5], reg0_s7[6]);
      reg0_s8[7] <= reg0_s7[7];
      reg0_s8[8] <= reg0_s7[8];
      // stage 9
      reg0_s9 <= reg0_s8[5];
      median0_s9 <= max2(reg0_s8[3],reg0_s8[4]);
      // stage a
      median0_sa <= min2(median0_s9,reg0_s9);
    end
  end

  // processor 1
  always @(posedge clk) begin
    if (rst) begin
    end
    else begin
      // stage 0
      case (state1)
        S0: begin
          reg1_s0[0] <= 8'h0;
          reg1_s0[1] <= 8'h0;
          reg1_s0[2] <= 8'h0;
          reg1_s0[3] <= 8'h0;
          reg1_s0[4] <= g;
          reg1_s0[5] <= 8'hff;
          reg1_s0[6] <= 8'hff;
          reg1_s0[7] <= 8'hff;
          reg1_s0[8] <= 8'hff;
        end
        S1: begin
          reg1_s0[0] <= b;
          reg1_s0[1] <= c;
          reg1_s0[2] <= d;
          reg1_s0[3] <= f;
          reg1_s0[4] <= g;
          reg1_s0[5] <= h;
          reg1_s0[6] <= j;
          reg1_s0[7] <= k;
          reg1_s0[8] <= l;
        end
        S2: begin
          reg1_s0[0] <= 8'h0;
          reg1_s0[1] <= 8'h0;
          reg1_s0[2] <= 8'h0;
          reg1_s0[3] <= 8'h0;
          reg1_s0[4] <= g;
          reg1_s0[5] <= 8'hff;
          reg1_s0[6] <= 8'hff;
          reg1_s0[7] <= 8'hff;
          reg1_s0[8] <= 8'hff;
        end
        S3: begin
          reg1_s0[0] <= 8'h0;
          reg1_s0[1] <= 8'h0;
          reg1_s0[2] <= 8'h0;
          reg1_s0[3] <= 8'h0;
          reg1_s0[4] <= g;
          reg1_s0[5] <= 8'hff;
          reg1_s0[6] <= 8'hff;
          reg1_s0[7] <= 8'hff;
          reg1_s0[8] <= 8'hff;
        end
        default: begin
          reg1_s0[0] <= 8'hx;
          reg1_s0[1] <= 8'hx;
          reg1_s0[2] <= 8'hx;
          reg1_s0[3] <= 8'hx;
          reg1_s0[4] <= 8'hx;
          reg1_s0[5] <= 8'hx;
          reg1_s0[6] <= 8'hx;
          reg1_s0[7] <= 8'hx;
          reg1_s0[8] <= 8'hx;
        end
      endcase
      // stage 1
      reg1_s1[0] <= min2(reg1_s0[0], reg1_s0[1]);
      reg1_s1[1] <= max2(reg1_s0[0], reg1_s0[1]);
      reg1_s1[2] <= min2(reg1_s0[2], reg1_s0[3]);
      reg1_s1[3] <= max2(reg1_s0[2], reg1_s0[3]);
      reg1_s1[4] <= reg1_s0[4];
      reg1_s1[5] <= min2(reg1_s0[5], reg1_s0[6]);
      reg1_s1[6] <= max2(reg1_s0[5], reg1_s0[6]);
      reg1_s1[7] <= min2(reg1_s0[7], reg1_s0[8]);
      reg1_s1[8] <= max2(reg1_s0[7], reg1_s0[8]);
      // stage 2
      reg1_s2[0] <= min2(reg1_s1[0], reg1_s1[2]);
      reg1_s2[1] <= max2(reg1_s1[0], reg1_s1[2]);
      reg1_s2[2] <= min2(reg1_s1[1], reg1_s1[3]);
      reg1_s2[3] <= max2(reg1_s1[1], reg1_s1[3]);
      reg1_s2[4] <= reg1_s1[4];
      reg1_s2[5] <= min2(reg1_s1[5], reg1_s1[7]);
      reg1_s2[6] <= max2(reg1_s1[5], reg1_s1[7]);
      reg1_s2[7] <= min2(reg1_s1[6], reg1_s1[8]);
      reg1_s2[8] <= max2(reg1_s1[6], reg1_s1[8]);
      // stage 3
      reg1_s3[0] <= reg1_s2[0];
      reg1_s3[1] <= min2(reg1_s2[1], reg1_s2[2]);
      reg1_s3[2] <= max2(reg1_s2[1], reg1_s2[2]);
      reg1_s3[3] <= reg1_s2[3];
      reg1_s3[4] <= reg1_s2[4];
      reg1_s3[5] <= reg1_s2[5];
      reg1_s3[6] <= min2(reg1_s2[6], reg1_s2[7]);
      reg1_s3[7] <= max2(reg1_s2[6], reg1_s2[7]);
      reg1_s3[8] <= reg1_s2[8];
      // stage 4
      reg1_s4[0] <= min2(reg1_s3[0], reg1_s3[5]);
      reg1_s4[1] <= max2(reg1_s3[0], reg1_s3[5]);
      reg1_s4[2] <= min2(reg1_s3[1], reg1_s3[6]);
      reg1_s4[3] <= max2(reg1_s3[1], reg1_s3[6]);
      reg1_s4[4] <= reg1_s3[4];
      reg1_s4[5] <= min2(reg1_s3[2], reg1_s3[7]);
      reg1_s4[6] <= max2(reg1_s3[2], reg1_s3[7]);
      reg1_s4[7] <= min2(reg1_s3[3], reg1_s3[8]);
      reg1_s4[8] <= max2(reg1_s3[3], reg1_s3[8]);
      // stage 5
      reg1_s5[0] <= reg1_s4[0];
      reg1_s5[1] <= min2(reg1_s4[1], reg1_s4[2]);
      reg1_s5[2] <= max2(reg1_s4[1], reg1_s4[2]);
      reg1_s5[3] <= min2(reg1_s4[3], reg1_s4[5]);
      reg1_s5[4] <= reg1_s4[4];
      reg1_s5[5] <= max2(reg1_s4[3], reg1_s4[5]);
      reg1_s5[6] <= min2(reg1_s4[6], reg1_s4[7]);
      reg1_s5[7] <= max2(reg1_s4[6], reg1_s4[7]);
      reg1_s5[8] <= reg1_s4[8];
      // stage 6
      reg1_s6[0] <= reg1_s5[0];
      reg1_s6[1] <= reg1_s5[1];
      reg1_s6[2] <= min2(reg1_s5[2], reg1_s5[3]);
      reg1_s6[3] <= max2(reg1_s5[2], reg1_s5[3]);
      reg1_s6[4] <= reg1_s5[4];
      reg1_s6[5] <= min2(reg1_s5[5], reg1_s5[6]);
      reg1_s6[6] <= max2(reg1_s5[5], reg1_s5[6]);
      reg1_s6[7] <= reg1_s5[7];
      reg1_s6[8] <= reg1_s5[8];
      // stage 7
      reg1_s7[0] <= reg1_s6[0];
      reg1_s7[1] <= reg1_s6[1];
      reg1_s7[2] <= reg1_s6[2];
      reg1_s7[3] <= min2(reg1_s6[3], reg1_s6[5]);
      reg1_s7[4] <= reg1_s6[4];
      reg1_s7[5] <= max2(reg1_s6[3], reg1_s6[5]);
      reg1_s7[6] <= reg1_s6[6];
      reg1_s7[7] <= reg1_s6[7];
      reg1_s7[8] <= reg1_s6[8];
      // stage 8
      reg1_s8[0] <= reg1_s7[0];
      reg1_s8[1] <= reg1_s7[1];
      reg1_s8[2] <= min2(reg1_s7[2], reg1_s7[3]);
      reg1_s8[3] <= max2(reg1_s7[2], reg1_s7[3]);
      reg1_s8[4] <= reg1_s7[4];
      reg1_s8[5] <= min2(reg1_s7[5], reg1_s7[6]);
      reg1_s8[6] <= max2(reg1_s7[5], reg1_s7[6]);
      reg1_s8[7] <= reg1_s7[7];
      reg1_s8[8] <= reg1_s7[8];
      // stage 9
      reg1_s9 <= reg1_s8[5];
      median1_s9 <= max2(reg1_s8[3],reg1_s8[4]);
      // stage a
      median1_sa <= min2(median1_s9,reg1_s9);
      // stage b
      median1_sb <= median1_sa;
    end
  end

  function [(DATA_WIDTH/2)-1:0] min2;
    input  [(DATA_WIDTH/2)-1:0] a,b;
    begin
      min2 = (a < b) ? a : b;
    end
  endfunction

  function [(DATA_WIDTH/2)-1:0] max2;
    input [(DATA_WIDTH/2)-1:0] a,b;
    begin
      max2 = (a < b) ? b : a;
      //max2 = (a > b) ? a : b;
    end
  endfunction

  function [DATA_WIDTH-1:0] sort2;
    input a, b;
    begin
      sort2 = {min2(a,b), max2(a,b)};
    end
  endfunction

endmodule

//-----------------------------------------------------------------//

`default_nettype wire
