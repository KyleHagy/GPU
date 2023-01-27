`timescale 1ns / 1ps

typedef struct packed{
    logic [6:0] opcode;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [11:0] imm;
} instr_t;

module CU (
    input logic clk,
    input logic [31:0] warp,
    input logic [31:0] threadsPerCU,
    output logic busy,
    output logic reset,
    output logic [7:0] MEM [1000]
    );

    logic [31:0] S_REG_FILE[32]; 
    logic [31:0] V_REG_FILE[32][32]; // 32 regs per core 
    logic [31:0] PC = warp;
    logic [31:0] instr;
    logic [3:0] STATE = 0;
    instr_t instr_decoded;


    Decode decode(
    .clk(clk), 
    .STATE(STATE),
    .instr(instr), 
    .opcode(instr_decoded.opcode), 
    .rs1(instr_decoded.rs1), 
    .rs2(instr_decoded.rs2),
    .rd(instr_decoded.rd), 
    .funct3(instr_decoded.funct3),
    .funct7(instr_decoded.funct7),
    .imm(instr_decoded.imm),
    .reset(reset),
    .busy(busy)
    );
    
    Scalar scalar(
    .clk(clk),
    .STATE(STATE),
    .opcode(instr_decoded.opcode),
    .rs1(instr_decoded.rs1),
    .rs2(instr_decoded.rs2),
    .rd(instr_decoded.rd),
    .funct3(instr_decoded.funct3),
    .funct7(instr_decoded.funct7),
    .imm(instr_decoded.imm),
    .S_REG_FILE(S_REG_FILE),
    .MEM(MEM),
    .PC(PC)
    );
    
    genvar i;
    generate
    for(i = 0; i < 32; i=i+1) begin
    Thread thread(
    .clk(clk),
    .STATE(STATE),
    .opcode(instr_decoded.opcode),
    .rs1(instr_decoded.rs1),
    .rs2(instr_decoded.rs2),
    .rd(instr_decoded.rd),
    .funct3(instr_decoded.funct3),
    .funct7(instr_decoded.funct7),
    .imm(instr_decoded.imm),
    .S_REG_FILE(S_REG_FILE),
    .V_REG_FILE(V_REG_FILE[i]),
    .MEM(MEM)
    );
    end 
    endgenerate
                    
    always_ff @(posedge clk)
    begin

        if(busy)
        begin
             case (STATE)
                0: //fetch
                begin
                    STATE = 1;
                    if (reset == 1) 
                    begin
                        PC = warp;
                        reset = 0;
                    end
                    instr = {MEM[PC+3], MEM[PC+2], MEM[PC+1], MEM[PC]};
                    PC = PC+4;
                    
                end
    
                1: //decode
                begin
                    STATE = 2;
                    if (reset == 1) begin
                        PC = warp;
                        reset = 0;
                        STATE = 0;
                    end
                end
    
                2: //execute
                begin  
                    STATE = 0;   
                   if (reset == 1) begin
                        PC = warp;
                        reset = 0;
                        STATE = 0;
                    end           
                end
            endcase
        end
       
    end
    
    always_ff @(negedge busy)
    begin   
       S_REG_FILE[0] <= 0;
        
       //set that all cores are on
       S_REG_FILE[1] <= 32'hFFFFFFFF;
       
       // set the CU #: reserved for a instruction
       S_REG_FILE[2] <= 0;
        
       //set the threads total in the CU (32)
       S_REG_FILE[3] <= threadsPerCU;
       
        for (int i = 4; i < 32; i++)
        begin
            S_REG_FILE[i] <= 0;
        end
            
        for (int i = 0; i < 32; i++)
        begin
            for (int j = 2; j < 32; j++)
            begin
                V_REG_FILE[i][j] <= 0;
            end
        end
        
         // ininitalize v0
        for (int i = 0; i < 32; i++)
        begin
            V_REG_FILE[i][0] <= 0;
            V_REG_FILE[i][1] <= i;
        end
    end

endmodule
