`timescale 1ns / 1ps

module Scalar(
    input logic clk,
    input logic [3:0] STATE,
    input logic [6:0] opcode,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [11:0] imm,
    output logic [31:0] S_REG_FILE[32],
    output logic [7:0] MEM [1000],
    output logic [31:0] PC
);

    logic [31:0] imm_fixed;

    always_ff @(posedge clk)
    begin        
    
        if(opcode[0] == 0 && STATE == 2) 
        begin
        
            if(imm[11] == 1)
            begin
                imm_fixed = 32'hFFFFF000 + imm;
            end
            else
            begin
                imm_fixed = imm;
            end

         case (opcode[6:2])
          5'b01100: //R-TYPE 
          begin
            case (funct3)
              0:
                  case (funct7)
                    0:  S_REG_FILE[rd] = S_REG_FILE[rs1] + S_REG_FILE[rs2];  // ADD
                    32: S_REG_FILE[rd] = S_REG_FILE[rs1] - S_REG_FILE[rs2];  // SUB
                  endcase
              3: S_REG_FILE[rd] = S_REG_FILE[rs1] * S_REG_FILE[rs2];  //MULU
              4: S_REG_FILE[rd] = S_REG_FILE[rs1] ^ S_REG_FILE[rs2]; // XOR
              6: S_REG_FILE[rd] = S_REG_FILE[rs1] | S_REG_FILE[rs2]; // OR
              7: S_REG_FILE[rd] = S_REG_FILE[rs1] & S_REG_FILE[rs2]; // AND
            endcase
          end


          5'b00100:
          begin         
            case(funct3)      
                0: S_REG_FILE[rd] = S_REG_FILE[rs1] + imm_fixed;   // ADDI
                4: S_REG_FILE[rd] = S_REG_FILE[rs1] ^ imm_fixed;   // XORI
                6: S_REG_FILE[rd] = S_REG_FILE[rs1] | imm_fixed;   // ORI
                7: S_REG_FILE[rd] = S_REG_FILE[rs1] & imm_fixed;   // ANDI
            endcase
          end

        5'b00000:
          begin
            case(funct3)      
                4: S_REG_FILE[rd] = MEM[ S_REG_FILE[rs1] +imm_fixed];   // LBU
            endcase
          end

          5'b01000: //S
          case(funct3)
                0: MEM[ S_REG_FILE[rs1] +imm_fixed] = S_REG_FILE[rs2][7:0];                            
          endcase
          
          5'b11000: //B
            //these are opposite
            case(funct3)      
                0: if(S_REG_FILE[rs1] != S_REG_FILE[rs2])                    S_REG_FILE[1] = 0;
                1: if(S_REG_FILE[rs1] == S_REG_FILE[rs2])                    S_REG_FILE[1] = 0;
                4: if($signed(S_REG_FILE[rs1]) >=  $signed(S_REG_FILE[rs2])) S_REG_FILE[1] = 0;
                5: if($signed(S_REG_FILE[rs1]) < $signed(S_REG_FILE[rs2]))   S_REG_FILE[1] = 0;
                6: if(S_REG_FILE[rs1] >=  S_REG_FILE[rs2])                   S_REG_FILE[1] = 0;
                7: if(S_REG_FILE[rs1] < S_REG_FILE[rs2])                     S_REG_FILE[1] = 0;
            endcase
            
          // JAL - modified such that PC + imm is not PC = imm
          5'b11011:
          begin   
            S_REG_FILE[rd] = PC+4;
            PC = imm;
          end
            
        endcase
        end
    end
endmodule