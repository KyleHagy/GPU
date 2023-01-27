`timescale 1ns / 1ps

module Thread(
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
    output logic [31:0] V_REG_FILE[32],
    output logic [7:0] MEM [1000]
);
    
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] imm_fixed;
    
    // Get the thread # located at v0 or V_REG_FILE[0]. 
    // Then see if the bit at s0 is turned on or off.
    // The bit will set to 0/turned off if a warp divergence.
    
    always_ff @(posedge clk)
    begin
        if(S_REG_FILE[1][ V_REG_FILE[1] ] && opcode[0] == 1 && STATE == 2)
        begin
            //vector only
            if(opcode[1] == 1)
            begin
                rs1_val = V_REG_FILE[rs1];
                rs2_val = V_REG_FILE[rs2];
            end
            //scalar and vector
            else if(opcode[1] == 0)
            begin
                rs1_val = V_REG_FILE[rs1];
                rs2_val = S_REG_FILE[rs2];
            end
            
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
                            0:  V_REG_FILE[rd] = rs1_val + rs2_val;  // ADD
                            32: V_REG_FILE[rd] = rs1_val - rs2_val;  // SUB
                        endcase
                    3: V_REG_FILE[rd] = rs1_val * rs2_val;  //MULU
                    4: V_REG_FILE[rd] = rs1_val ^ rs2_val;  // XOR
                    6: V_REG_FILE[rd] = rs1_val | rs2_val;  // OR
                    7: V_REG_FILE[rd] = rs1_val & rs2_val;  // AND
                    endcase
                end
    
    
                5'b00100:
                begin
                    case(funct3)      
                        0: V_REG_FILE[rd] = rs1_val + imm_fixed;                     // ADDI
                        4: V_REG_FILE[rd] = rs1_val ^ imm_fixed;                     // XORI
                        6: V_REG_FILE[rd] = rs1_val | imm_fixed;                     // ORI
                        7: V_REG_FILE[rd] = rs1_val & imm_fixed;                     // ANDI
                    endcase
                end
                
    
                5'b00000:
                  begin
                    case(funct3)      
                        4: V_REG_FILE[rd] = MEM[ rs1_val +imm_fixed];   // LBU
                    endcase
                  end
        
                5'b01000: //S
                case(funct3)
                    0: MEM[ rs1_val +imm_fixed] = rs2_val[7:0];                            
                endcase
                                
                
                5'b11000: //B
                //these are opposite
                case(funct3)      
                    0: if(rs1_val != rs2_val)                    S_REG_FILE[1][ V_REG_FILE[1] ] = 0;
                    1: if(rs1_val == rs2_val)                    S_REG_FILE[1][ V_REG_FILE[1] ] = 0;
                    4: if($signed(rs1_val) >=  $signed(rs2_val)) S_REG_FILE[1][ V_REG_FILE[1] ] = 0;
                    5: if($signed(rs1_val) < $signed(rs2_val))   S_REG_FILE[1][ V_REG_FILE[1] ] = 0;
                    6: if(rs1_val >=  rs2_val)                   S_REG_FILE[1][ V_REG_FILE[1] ] = 0;
                    7: if(rs1_val < rs2_val)                     S_REG_FILE[1][ V_REG_FILE[1] ] = 0;
                endcase
                
                default: S_REG_FILE[0] = 0;
            endcase
        end
    end
endmodule