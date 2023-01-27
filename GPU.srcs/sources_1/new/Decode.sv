`timescale 1ns / 1ps

module Decode(
    input logic clk,
    input logic [3:0] STATE,
    input logic [31:0] instr,
    output logic [6:0] opcode,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [11:0] imm,
    output logic reset,
    output logic busy
);

    logic wasBusy=0;
    
    always_ff @(posedge clk)
    begin
        if(STATE == 1)
        begin
        case (instr[6:2])
            5'b01100: //R-TYPE
            begin
                opcode = instr[6:0];
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                funct7 = instr[31:25];
                imm = 0;

            end
            
            5'b00100, 5'b00000: //I-TYPE
            begin
                opcode = instr[6:0];
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = 0;
                funct7 = 0;
                imm = instr[31:20];
            end
            
            5'b01000:  //S-TYPE
            begin
                opcode = instr[6:0];
                rd = 0;
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                funct7 = 0;
                imm = {instr[31:25], instr[11:7]};
            end
                    
            5'b11000: //B-TYPE
            begin
                opcode = instr[6:0];
                rd = 0;
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                funct7 = 0;
                imm = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end 
            
            5'b11011: //J-TYPE
            begin
                opcode = instr[6:0];
                rd = instr[11:7];
                funct3 = 0;
                rs1 = 0;
                rs2 = 0;
                funct7 = 0;
                imm = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end 
            
            5'b11100: //EBREAK - end of warp
            begin       
                //error where busy gets set again. 
                // Bc its takes multiple clock cycles to dump after a ebreak
                if(!wasBusy) 
                begin
                    busy = 0;
                    wasBusy = 1;           
                end
                else
                begin
                    wasBusy = 0;
                end
            end
            
            default: opcode = 0;
            
        endcase
        end
    end
endmodule