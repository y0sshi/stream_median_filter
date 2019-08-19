`timescale 1ns/1ps
`default_nettype none

module sim_risc16ba();
  localparam integer SIMULATION_CYCLES  = 10000000;
  localparam real    CLOCK_FREQ_HZ      = 25 * 10**6; // 25MHz 
  localparam real    CLOCK_PERIOD_NS    = 10**9 / CLOCK_FREQ_HZ;
  logic              clk, rst;
  wire [15:0] 	      ddin, ddout, idin;
  wire [15:0] 	      daddr, iaddr;
  wire               doe, dwe0, dwe1, ioe;
  reg [7:0]          mem[0:65535];
  wire [23:0] 	      led;
  reg [7:0] 	      led_0, led_1, led_2;
  integer            i;

  risc16ba risc16ba_inst(.clk(clk), .rst(rst), .ddin(ddin), .ddout(ddout), 
  .daddr(daddr), .doe(doe), .dwe0(dwe0), .dwe1(dwe1),
  .idin(idin), .iaddr(iaddr), .ioe(ioe));

  initial begin
    $readmemb("sim_risc16ba.mem", mem);
    $readmemh("imfiles/set_image.mem", mem);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      led_0 <= 8'h0;
      led_2 <= 8'h0;
    end
    else if (dwe1) begin
      if (daddr == 16'h200) begin
        led_0 <= ddout[7:0];
      end
      else if (daddr == 16'h202) begin
        led_2 <= ddout[7:0];
      end
      else begin
        mem[daddr | 16'h1] <= ddout[7:0];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      led_1 <= 8'h0;
    end
    else if (dwe0) begin
      if (daddr == 16'h200)  begin
        led_1 <= ddout[15:8];
      end
      else begin
        mem[daddr & 16'hfffe] <= ddout[15:8];
      end
    end
  end

  assign led = {led_2, led_1, led_0};
  assign ddin = doe? {mem[daddr & 16'hfffe], mem[daddr | 16'h1]}: 16'hxxxx;
  assign idin = ioe? {mem[iaddr & 16'hfffe], mem[iaddr | 16'h1]}: 16'hxxxx;

  task dump_and_finish();
    integer fp, i;
    fp = $fopen("sim_risc16ba.dump");

    for (i = 16'hc000; i <= 16'hffff; i += 8) begin
      $fwrite(fp, "%X %X %X %X ", mem[i],   mem[i+1], mem[i+2], mem[i+3]);
      $fwrite(fp, "%X %X %X %X\n", mem[i+4], mem[i+5], mem[i+6], mem[i+7]);
    end
    $finish;
  endtask

  initial begin
    clk <= 1'b0;
    repeat (SIMULATION_CYCLES) begin
      #(CLOCK_PERIOD_NS / 2.0) 
      clk <= 1'b1;
      #(CLOCK_PERIOD_NS / 2.0)
      clk <= 1'b0;
      print();
      if (risc16ba_inst.finish) begin
        dump_and_finish();
      end
    end
    dump_and_finish();
  end

  initial begin
    rst <= 1'b1;
    #(CLOCK_PERIOD_NS)
    rst <= 1'b0;      
  end

  initial begin
    $shm_open("risc16ba.shm");
    $shm_probe(risc16ba_inst, "ACM");
  end

  task print(); 
    integer i;
    $write("==== clock: %1d ====\n", $rtoi($time / CLOCK_PERIOD_NS) - 1);  
    $write("ioe:%B iaddr:%X idin:%X finish:%B state:%1d\ndoe:%B dwe0:%B dwe1:%B daddr:%X ddin:%X ddout:%X\n\n",risc16ba_inst.ioe,
    risc16ba_inst.iaddr, risc16ba_inst.idin, risc16ba_inst.finish, risc16ba_inst.state0,
    risc16ba_inst.doe, risc16ba_inst.dwe0, risc16ba_inst.dwe1,
    risc16ba_inst.daddr, risc16ba_inst.ddin, risc16ba_inst.ddout);
    //$write(" if_pc:%X if_ir:%B\n", 
    // risc16ba_inst.if_pc, risc16ba_inst.if_ir);
    //$write(" rf_pc:%X rf_ir:%B rf_treg1:%X rf_treg2:%X rf_immediate:%X\n",
    // risc16ba_inst.rf_pc, risc16ba_inst.rf_ir,
    // risc16ba_inst.rf_treg1, risc16ba_inst.rf_treg2,
    // risc16ba_inst.rf_immediate);
    //$write(" ex_ir:%B ex_result:%X\n",
    // risc16ba_inst.ex_ir, risc16ba_inst.ex_result);
    //$write(" daddr:%X ddin:%X ddout:%X doe:%B dwe0:%B dwe1:%B\n",
    // risc16ba_inst.daddr, risc16ba_inst.ddin, risc16ba_inst.ddout, 
    // risc16ba_inst.doe, risc16ba_inst.dwe0, risc16ba_inst.dwe1);
    //$write(" iaddr:%X idin:%X ioe:%B\n",
    // risc16ba_inst.iaddr, risc16ba_inst.idin, risc16ba_inst.ioe);
    //$write(" alu_ain:%X alu_bin:%X alu_op:%B reg_file_we:%B if_pc_we:%B",
    // risc16ba_inst.alu_ain, risc16ba_inst.alu_bin,
    // risc16ba_inst.alu_op, risc16ba_inst.reg_file_we,
    // risc16ba_inst.if_pc_we);
    //$write(" led:%X\n", led);
    //$write(" regs: %X", risc16ba_inst.reg_file_inst.register0);
    //$write(" %X", risc16ba_inst.reg_file_inst.register1);
    //$write(" %X", risc16ba_inst.reg_file_inst.register2);
    //$write(" %X", risc16ba_inst.reg_file_inst.register3);
    //$write(" %X", risc16ba_inst.reg_file_inst.register4);
    //$write(" %X", risc16ba_inst.reg_file_inst.register5);
    //$write(" %X", risc16ba_inst.reg_file_inst.register6);
    //$write(" %X\n", risc16ba_inst.reg_file_inst.register7);
    //for (i = 0; i < 32; i += 8) begin
    //   $write(" mem[%02x-%02x]:", i, i+7);
    //   $write(" %X %X %X %X",   mem[i],   mem[i+1], mem[i+2], mem[i+3]);
    //   $write(" %X %X %X %X\n", mem[i+4], mem[i+5], mem[i+6], mem[i+7]);
    //end
    //$write("\n");
  endtask
endmodule

`default_nettype wire
