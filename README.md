# VICHARAK
<pre> 
**binary:** 000000000100100011 (19 bits) 
<br>

Custom CPU Instruction Format : <br>

[18:16] instr_group (3 bits)     // category:thsese bits will give the identify wether it is arithmetic, logical, control, mem, custom instruction and 
[15:13] opcode (3 bits)          // opcode will identify within group which operation is need be performed. [12] reserved (1 bit) 
[11:8] field_A (4 bits)          // depends on instr_group often it is source adress 1 or base address (often rs1 or base) 
[7:4] field_B (4 bits)           // meaning depends on instr_group often it is source adress 2 or offset (rs2 or imm[7:4]) 
[3:0] field_C (4 bits)           // is mostly used of destination adress 

for example <br>
[18:16] = 3'b000       // arithmetic_instr
[15:13] = opcode       // e.g., ADD = 3'b000
[12]    = 1'b0         // reserved <br>
[11:8]  = rs1          // source register 1 <br>
[7:4]   = rs2          // source register 2 (unused for INC/DEC)  
[3:0]   = rd           //Destination adress 
 <br>
bits: 000   000     0     0001  0010  0011 
       ^     ^      ^     ^^^^  ^^^^  ^^^^ 
    [18:16][ 15:13] [12] [11:8] [7:4] [3:0] 

   <br>  
INSTRUCTION GROUP AND OPCODE MAP 
 <br> 
Arithmetic (3'b000)  : ADD=000,  SUB=001,    MUL=010, DIV=011, INC=100, DEC=101 
  
Logical (3'b001)     : AND=000,  OR=001,     XOR=010, NOT=011 

Control (3'b010)     : JMP=000,  BEQ=001,    BNE=010, CALL=011, RET=100

Memory (3'b011)      : LOAD=000, STORE=001 

Custom (3'b100)      : FFT=000,  ENC=001,   DECc=010    


 <br>
INSTRUCTION FETCH STAGE :
 <br>
The CPU uses the Program Counter (PC) to fetch the next instruction from instruction memory generally but for easy tb acesss i gave it from tb as ins . The fetched instruction (19 bits) is loaded into the IF/ID (Fetch_instr)  pipeline register. 
Normally the PC then increments by 1 (pointing to the next instruction) unless a branch is taken.
  
 <br>
INSTRUCTION DECODE STAGE :
 <br>
The Decode stage interprets the fetched instruction. The control unit (CU) decodes the instr_group and opcode fields to generate the necessary control signals for later stages
bits: 000     000     0         0001   0010    0011
       ^      ^       ^         ^^^^   ^^^^    ^^^^ 
    [18:16] [ 15:13] [12]     [11:8]  [7:4]   [3:0] 
instr_group opcode  reserved source1 source1  destination

. Meanwhile, source register addresses (from field_A and field_B) are used to read operands from the register file. The register file read values (regfile[rs1] and regfile[rs2]) and any immediate/offset (from bits 7:0 or 3:0) are placed into    the (Decode decode_offset or decode_imm8) ID/EX (pipeline registers. In effect, the Decode stage prepares all operands and control flags needed to the EX stage.
 <br>
EXECUTE STAGE :
 <br>
In the Execute stage, the ALU performs the requested operation. 
For arithmetic/logic instructions, this means the ALU adds, subtracts, ANDs, etc., using the operand values from the register file.
For memory instructions, the ALU computes a memory address (e.g. base + offset). 
For control-flow instructions, the ALU evaluates branch conditions or computes jump targets.  For example, on a BEQ or BNE, the ALU checks equality of two registers; on JMP/CALL, it computes the new PC; on CALL it also saves return address. 
The result from the ALU (or the branch target address) is stored into the (ALU_Result)EX/MEM pipeline register. Notably, if a branch or jump is taken, the branch target will be used to update the PC in the next cycle (instead of simply incrementing).

Note :- I just passed the FFT operation result as 0 as i feel it a bit complex and need a bit extra time to execute.
 <br>
MEMORY ACCESS STAGE :
 <br>
This stage handles data memory operations.
If the instruction is a LOAD, the computed address from execute stage is used to read from data memory. 
if it’s a STORE, the data from the second source register is written to memory at that address. The data read (for LOAD) or the ALU result (for other instructions) is then placed into the MEM/WB (Write_back_result)pipeline register. If the instruction does not involve memory, this stage simply forwards the ALU result. In other words, memory instructions access data_mem[ALU_Result], and the loaded data is forwarded for write-back
 <br>
WRITE BACK STAGE :
 <br>
In the Write-Back stage, results are written back into the register file. If the instruction produces a register result (e.g. arithmetic result, logical result, or data loaded from memory), that value is written to the destination register (rd) using the control signal RegWrite. A pipeline control flag (called MEM_WB_regwrite in the implementation) indicates whether the write-back should occur. Only certain instructions assert RegWrite (arithmetic/logic ops, LOADs, CALL, etc.)

When RegWrite is true, the value from MEM_WB_result is written into regfile[MEM_WB_rd]. Otherwise, if RegWrite is false (for a STORE or branch), no register is updated. 

In summary, stage 5 takes the value from the Execute or memory and updates the register file if needed, completing the instruction’s effect.


Reference to understand the flow 
https://eseo-tech.github.io/emulsiV/


BLOCK DIAGRAM


<img width="1536" height="1024" alt="vicharak" src="https://github.com/user-attachments/assets/9d44b8d6-e237-4f5e-b457-ceeb030e731c" />



<pre>







