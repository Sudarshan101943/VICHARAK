`timescale 1ns/1ps

module cpu_tb;

  reg clk;
  reg reset;
  reg [18:0] ins;

  // Instantiate DUT
  CPU dut (
    .clk(clk),
    .reset(reset),
    .ins(ins)
  );

  // Clock
  always #5 clk = ~clk;

  integer i;

  // === Encode Functions ===
  function [18:0] encode_arith(input [2:0] opcode, input [3:0] rs1, input [3:0] rs2, input [3:0] rd);
    begin
      encode_arith = {3'b000, opcode, rs1, rs2, rd};
    end
  endfunction

  function [18:0] encode_mem(input [2:0] opcode, input [3:0] base, input [3:0] rd, input [3:0] offset);
    begin
      encode_mem = {3'b011, opcode, base, rd, offset};
    end
  endfunction

  // === Testbench Flow ===
  initial begin
    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, cpu_tb);

    clk = 0;
    reset = 1;
    ins = 19'd0;

    #12 reset = 0;

    // Preload register file + data memory
    dut.regfile[1] = 32'd5;    // R1 = 5
    dut.regfile[2] = 32'd7;    // R2 = 7
    dut.regfile[3] = 32'd0;    // R3 = 0
    dut.data_mem[0] = 32'd99;  // MEM[0] = 99

    // =============================
    // Test 1: ADD R3 = R1 + R2
    // =============================
    @(posedge clk);
    ins = encode_arith(3'b000, 4'd1, 4'd2, 4'd3); // ADD

    // wait for pipeline to propagate
    repeat(5) @(posedge clk);

    if (dut.regfile[3] == (5+7))
      $display("PASS: ADD result = %0d", dut.regfile[3]);
    else
      $display("FAIL: ADD got %0d expected %0d", dut.regfile[3], 5+7);

    // =============================
    // Test 2: LOAD R4 <- MEM[R1+0]
    // =============================
    @(posedge clk);
    ins = encode_mem(3'b000, 4'd1, 4'd4, 4'd0); // LOAD R4 = MEM[R1+0] (EA=5+0=5 → MEM[5])

    dut.data_mem[5] = 32'd123; // preload MEM[5]

    repeat(5) @(posedge clk);

    if (dut.regfile[4] == 32'd123)
      $display("PASS: LOAD result = %0d", dut.regfile[4]);
    else
      $display("FAIL: LOAD got %0d expected %0d", dut.regfile[4], 123);

    // =============================
    // Test 3: STORE MEM[R1+0] <- R2
    // =============================
    @(posedge clk);
    ins = encode_mem(3'b001, 4'd1, 4'd2, 4'd0); // STORE MEM[R1+0] = R2

    repeat(5) @(posedge clk);

    if (dut.data_mem[5] == 32'd7)
      $display("PASS: STORE result = %0d", dut.data_mem[5]);
    else
      $display("FAIL: STORE got %0d expected %0d", dut.data_mem[5], 7);

    // =============================
    // Finish
    // =============================
    $display("\nFinal Register File:");
    for (i=0; i<8; i=i+1)
      $display("R[%0d] = %0d", i, dut.regfile[i]);

    $display("\nFinal Data Memory:");
    for (i=0; i<8; i=i+1)
      $display("MEM[%0d] = %0d", i, dut.data_mem[i]);

    $finish;
  end

endmodule
