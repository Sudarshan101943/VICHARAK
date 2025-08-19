`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/06/2025 11:32:07 AM
// Module Name: cpu
//////////////////////////////////////////////////////////////////////////////////

module CPU(
  input clk,
  input reset,input [18:0] ins
);

 
  

  // Pipeline Registers 
  reg [18:0] Fetch_instr;
  reg [7:0]  Fetch_PC;

  reg [7:0]  Decode_PC;
  reg [2:0]  Decode_instruction;
  reg [2:0]  Decode_instr;
  reg [2:0]  Decode_opcode;
  reg [31:0] Decode_reg1, Decode_reg2;
  reg [3:0]  Decode_rd;
  reg [3:0]  Decode_offset;      
  reg [7:0]  Decode_imm8;

  reg [2:0]  Execute_instr;
  reg [2:0]  Execute_opcode;
  reg [31:0] Execute_reg1, Execute_reg2;
  reg [3:0]  Execute_rd;
  reg [3:0]  Execute_offset;      
  reg [7:0]  Execute_imm8;
  reg [7:0]  Execute_PC;
  reg [31:0] ALU_Result;
  reg        Execute_regwrite;

  reg [31:0] MEM_WB_result;
  reg [3:0]  MEM_WB_rd;
  reg        MEM_WB_regwrite;

  //  Branch control from Execute
  reg        Branch_instr;
  reg [7:0]  Branch_result;

  /// Memories  
  reg [18:0] instr_mem [0:255]; // used generally for acessing instructions but for easy passing of instructions i fed instructions from input 
  reg [7:0]  PC;

  reg [31:0] regfile [0:15];
  reg [18:0] data_mem[0:255];


  ////   Instruction groups 
  parameter key = 32'h46464646;//used for decription and encription
  localparam arithematic_instr   = 3'b000;  
  localparam logical_instr       = 3'b001;
  localparam control_flow_instr  = 3'b010;
  localparam memory_ac_instr     = 3'b011;
  localparam custom_instr        = 3'b100;

  // Arithmetic opcodes
  localparam ADD = 3'b000;
  localparam SUB = 3'b001;
  localparam MUL = 3'b010;
  localparam DIV = 3'b011;
  localparam INC = 3'b100;
  localparam DEC = 3'b101;

  // Logical opcodes
  localparam AND = 3'b000;
  localparam OR  = 3'b001;
  localparam XOR = 3'b010;
  localparam NOT = 3'b011;

  // Control flow opcodes
  localparam JMP  = 3'b000;
  localparam BEQ  = 3'b001;
  localparam BNE  = 3'b010;
  localparam CALL = 3'b011;
  localparam RET  = 3'b100;

  // Memory access opcodes
  localparam LOAD  = 3'b000;
  localparam STORE = 3'b001;

  // Custom opcodes
  localparam FFT = 3'b000;
  localparam ENC = 3'b001;
  localparam DECc = 3'b010;

  integer i;

  //  Instruction Fetch Stage 
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      PC          <= 8'd0;
      Fetch_instr <= 19'd0;
      Fetch_PC    <= 8'd0;

      
      for (i=0; i<32; i=i+1) begin
        regfile[i] <= 32'd0;
        data_mem[i] <= 32'd0;
      end

    end else begin
      Fetch_instr <= ins;
      Fetch_PC    <= PC;

      // Next PC decided by EX (one cycle old)
      if (Branch_instr)
        PC <= Branch_result;
      else
        PC <= PC + 8'd1;
    end
  end

  //  Instruction Decode Stage
  always @(posedge clk) begin
    Decode_PC          <= Fetch_PC;
    Decode_instruction <= Fetch_instr;
    Decode_instr       <= Fetch_instr[18:16];
    Decode_opcode      <= Fetch_instr[15:13];

    // Field usage depends on instr format; for branches we use imm8
    Decode_reg1        <= regfile[Fetch_instr[11:8]];
    Decode_reg2        <= regfile[Fetch_instr[7:4]];
    Decode_rd          <= Fetch_instr[3:0];
    Decode_offset      <= Fetch_instr[3:0];      // used for base+offset
    Decode_imm8        <= Fetch_instr[7:0];      // used for branches
  end

  // EXecute and ALU Stage) 
  always @(posedge clk) begin
   
    Execute_instr   <= Decode_instr;
    Execute_opcode  <= Decode_opcode;
    Execute_reg1    <= Decode_reg1;
    Execute_reg2    <= Decode_reg2;
    Execute_rd      <= Decode_rd;
    Execute_offset  <= Decode_offset;
    Execute_imm8    <= Decode_imm8;
    Execute_PC      <= Decode_PC;

    //Branch Control Variables 
    Branch_instr  <= 1'b0;
    Branch_result <= 8'd0;

    // Logic for WriteBack = Regwrite  (WB for ALU, LOGIC, LOAD, CUSTOM, and CALL )
    Execute_regwrite <= (Decode_instr == arithematic_instr) ||
                        (Decode_instr == logical_instr) ||
                        (Decode_instr == memory_ac_instr && Decode_opcode == LOAD) ||
                        (Decode_instr == custom_instr) ||
                        (Decode_instr == control_flow_instr && Decode_opcode == CALL);
  end

  // === ALU / EXecute Operations ===
  always @(posedge clk) begin
  
    ALU_Result <= 32'd0;

    case (Execute_instr)

      // Arithmetic Operations/////
      arithematic_instr: begin
        case (Execute_opcode)
          ADD: ALU_Result <= Execute_reg1 + Execute_reg2;
          SUB: ALU_Result <= Execute_reg1 - Execute_reg2;
          MUL: ALU_Result <= Execute_reg1 * Execute_reg2;
          DIV: ALU_Result <= (Execute_reg2 == 0) ? 32'd0 : (Execute_reg1 / Execute_reg2);
          INC: ALU_Result <= Execute_reg1 + 32'd1;
          DEC: ALU_Result <= Execute_reg1 - 32'd1;
        endcase
      end

      // Logical Operations////////
      logical_instr: begin
        case (Execute_opcode)
          AND: ALU_Result <= Execute_reg1 & Execute_reg2;
          OR : ALU_Result <= Execute_reg1 | Execute_reg2;
          XOR: ALU_Result <= Execute_reg1 ^ Execute_reg2;
          NOT: ALU_Result <= ~Execute_reg1;
        endcase
      end

      // Control Flow Operations//////////
      control_flow_instr: begin
        case (Execute_opcode)
          JMP: begin
            Branch_instr  <= 1'b1;                 ///to confirm you are in Branch Instruction
            Branch_result <= Execute_reg1[7:0];
          end
          BEQ: begin
            if (Execute_reg1 == Execute_reg2) begin
              Branch_instr  <= 1'b1;
              Branch_result <= $signed(Execute_PC) + $signed({{24{Execute_imm8[7]}}, Execute_imm8});
            end
          end
          BNE: begin
            if (Execute_reg1 != Execute_reg2) begin
              Branch_instr  <= 1'b1;
              Branch_result <= $signed(Execute_PC) + $signed({{24{Execute_imm8[7]}}, Execute_imm8});
            end
          end
          CALL: begin
            Branch_instr  <= 1'b1;
            Branch_result <= Execute_reg1[7:0];
            regfile[31]           <= Execute_PC + 8'd1;  
          end
          RET: begin
            Branch_instr  <= 1'b1;
            Branch_result <= regfile[31][7:0];
          end
        endcase
      end

      // Memory address calculation////////////////////
            memory_ac_instr: begin
        case (Execute_opcode)
          LOAD : ALU_Result <= Execute_reg1 + {{28{1'b0}}, Execute_offset}; // EA
          STORE: ALU_Result <= Execute_reg1 + {{28{1'b0}}, Execute_offset}; // EA
        endcase
      end

      // Custom   Operations
      custom_instr: begin
        case (Execute_opcode)
          FFT:  ALU_Result <= 32'd0;              // logic for fft operations is not included
          ENC:  ALU_Result <= (Execute_reg1 ^ key);
          DECc: ALU_Result <= (Execute_reg1 ^ key);
        endcase
      end

      default: begin
        ALU_Result <= 32'd0;
      end
    endcase
  end

  //  MEM Acess Stage 
  
  
  always @(posedge clk) begin
    //  WB control signals
    MEM_WB_rd        <= Execute_rd;
    MEM_WB_regwrite  <= Execute_regwrite;
    MEM_WB_result    <= ALU_Result;

    if (Execute_instr == memory_ac_instr) begin
      if (Execute_opcode == LOAD) begin
        
        MEM_WB_result <= data_mem[ALU_Result[4:0]];//data that need to writeback
       
      end else if (Execute_opcode == STORE) begin
        data_mem[ALU_Result[4:0]] <= Execute_reg2; // store rs2 to memory
       
      end
    end
  end

  //  Write Back Stage 
  always @(posedge clk) begin
    if (MEM_WB_regwrite) begin
      regfile[MEM_WB_rd] <= MEM_WB_result;
    end
  end

endmodule