`timescale 1ns / 1ps

module GPU (
    input logic clk
    );
     
    // Memory declaration - 1024KB 
    logic [7:0] MEM [1000]; 
    logic changing = 0;
    
    //mem address of start of warp (first instruction)
    logic [31:0] warps [6];
    logic CU_busy[4];   
    int curr_warp = 0;
    
    //assign the current warp to this so that the next warp can be assigned.
    //only assigning module with warps[curr_warp] can cause the same warp to be issued on multiple CUs.
    logic [31:0] warpForCU [4];
    
    // reset the PC when a new warp is issued
    logic reset[4];
    
    initial 
    begin
        warps[0] = 0;
        warps[1] = 88;
        warps[2] = 96;
        warps[3] = 104;
        warps[4] = 112;
        warps[5] = 120;
        
        for (int i = 0; i < 4; i++)
        begin
            warpForCU[i] = 0;
        end
    
        CU_busy[0] = 0;
        CU_busy[1] = 0;
        CU_busy[2] = 0;
        CU_busy[3] = 0;
        
        reset[0] = 1;
        reset[1] = 1;
        reset[2] = 1;
        reset[3] = 1;
        
        // ininitalize v0
        for (int i = 0; i < 1000; i++)
        begin
            MEM[i] = 0;
        end
        
    // 0x90e0f0ff sORI s1, s1, 0xFFFFFFFF
    // set all cores high(on) how to set this per SM)
    MEM[0] = 8'h90;
    MEM[1] = 8'he0;
    MEM[2] = 8'hf0;
    MEM[3] = 8'hff;

    // sADDI s2, s2, 0 
    MEM[4] = 8'h10;
    MEM[5] = 8'h01;
    MEM[6] = 8'h01;
    MEM[7] = 8'h00;

    // 0x90e0f0ff sORI s1, s1, 0xFFFFFFFF
    // iteration for if a warp has jumped here
    MEM[8] = 8'h90;
    MEM[9] = 8'he0;
    MEM[10] = 8'hf0;
    MEM[11] = 8'hff;

    // 0x30 sMUL s4, s3, s2 
    // blockDim.x * blockIdx.x => s3 * s2
    MEM[12] = 8'h30;
    MEM[13] = 8'hb2;
    MEM[14] = 8'h21;
    MEM[15] = 8'h00;

    // 0x31814000 vsADD v2, v1, s4
    // int i = threadIdx.x + blockDim.x * blockIdx.x; Ex: core #4 block #2 = 32*2 + 4 = 68th core
    MEM[16]  = 8'h31;
    MEM[17]  = 8'h81;
    MEM[18] = 8'h40;
    MEM[19] = 8'h00;

    // sADDI s4, s0, 171 
    // Load in 171 into s4 for comparison. Used for vsBLTU s0, v2, s4
    MEM[20] = 8'h10;
    MEM[21] = 8'h02;
    MEM[22] = 8'hb0;
    MEM[23] = 8'h0a;

    // 0x61604100 vsBLTU v2, s4, 0
    // // If (i < n) If not true set thread#'s bit in s1 reg to 0 (core off).
    MEM[24] = 8'h61;
    MEM[25] = 8'h60;
    MEM[26] = 8'h41;
    MEM[27] = 8'h00;

    // vADDI v3, v2, 829
    // starting at 829, the v2 + 829
    MEM[28] = 8'h93;
    MEM[29] = 8'h01;
    MEM[30] = 8'hd1;
    MEM[31] = 8'h33;

    // vADDI v4, v2, 658
    // starting at 658, the v2 + 658
    MEM[32] = 8'h13;
    MEM[33] = 8'h02;
    MEM[34] = 8'h21;
    MEM[35] = 8'h29;

    // 0x83c20100 vLD v5, 0(v3)  // CHANGE ZERO TO THE SPOT IN MEM Load MEM[v2] into vec reg v3 (load into a)
    MEM[36] = 8'h83;
    MEM[37] = 8'hc2;
    MEM[38] = 8'h01;
    MEM[39] = 8'h00;

    // 0x03430200 vLD v6, 0(v4)  // Load MEM[v2] into vec reg v3 (load into b)
    MEM[40] = 8'h03;
    MEM[41] = 8'h43;
    MEM[42] = 8'h02;
    MEM[43] = 8'h00;

    // 0x63e06200 vBLTU v5, v6, v0
    // if (a[i] < b[i]),  If true set  (core off) 
    MEM[44] = 8'h63;
    MEM[45] = 8'he0;
    MEM[46] = 8'h62;
    MEM[47] = 8'h00;

    // 0xb3035340 vSUB v7, v6, v5 // c[i] = b[i] - a[i];
    MEM[48] = 8'hb3;
    MEM[49] = 8'h03;
    MEM[50] = 8'h53;
    MEM[51] = 8'h40;

    /*
    //CANT USE: Doesnt work 0x55 => 0xFFFFFFee
    // 0x90c0f0ff sXORI s1, s1, 0xFFFFFFFF // s0 threads that are off now turn on and vice versa
    MEM[52] = 8'h90;
    MEM[53] = 8'hc0;
    MEM[54] = 8'hf0;
    MEM[55] = 8'hff;
    */

    //=========================
    // 0x90e0f0ff sORI s1, s1, 0xFFFFFFFF
    // set all cores high(on) how to set this per SM)
    MEM[52] = 8'h90;
    MEM[53] = 8'he0;
    MEM[54] = 8'hf0;
    MEM[55] = 8'hff;

    // 0x61604100 vsBLTU v2, s4, 0
    // // If (i < n) If not true set thread#'s bit in s1 reg to 0 (core off).
    MEM[56] = 8'h61;
    MEM[57] = 8'h60;
    MEM[58] = 8'h41;
    MEM[59] = 8'h00;

    // 0x63f06200 vBGEU v5, v6, v0
    // if (a[i] >= b[i]),  If true set (core off) 
    MEM[60] = 8'h63;
    MEM[61] = 8'hf0;
    MEM[62] = 8'h62;
    MEM[63] = 8'h00;
    //==============================================

    // 0xb3035300 vADD v7, v6, v5 // c[i] = b[i] + a[i];
    MEM[64] = 8'hb3;
    MEM[65] = 8'h03;
    MEM[66] = 8'h53;
    MEM[67] = 8'h00;

    // if statement ends
    // 0x90e0f0ff sORI s1, s1, 0xFFFFFFFF
    // set all cores high(on) how to set this per SM)
    MEM[68] = 8'h90;
    MEM[69] = 8'he0;
    MEM[70] = 8'hf0;
    MEM[71] = 8'hff;

    // 0x61604100 vsBLTU v2, s4, 0
    // // If (i < n) If not true set thread#'s bit in s1 reg to 0 (core off).
    MEM[72] = 8'h61;
    MEM[73] = 8'h60;
    MEM[74] = 8'h41;
    MEM[75] = 8'h00;

    // 0x23807100 vST v7, 0(v3) 
    // store all values from v7 into mem
    MEM[76] = 8'h23;
    MEM[77] = 8'h80;
    MEM[78] = 8'h71;
    MEM[79] = 8'h00;

    // 0x90e0f0ff sORI s1, s1, 0xFFFFFFFF
    // set all cores high(on) how to set this per SM)
    MEM[80] = 8'h90;
    MEM[81] = 8'he0;
    MEM[82] = 8'hf0;
    MEM[83] = 8'hff;
    
    // 0x73000000 EBREAK //sets the CU to ready
    MEM[84] = 8'h73;
    MEM[85] = 8'h00;
    MEM[86] = 8'h00;
    MEM[87] = 8'h00;

    //===================== WARP 2 =====================
    // set this as next warp (put on CU1) start at 32 threadId
    // sADDI s2, s2, 1 
    MEM[88] = 8'h10;
    MEM[89] = 8'h01;
    MEM[90] = 8'h11;
    MEM[91] = 8'h00;

    // Go through previous loop
    // sJAL x31, 8 - where code starts 
    MEM[92] = 8'hec;
    MEM[93] = 8'h0f;
    MEM[94] = 8'h80;
    MEM[95] = 8'h00;

    //===================== WARP 3 =====================

    // set this as next warp (put on CU1) start at 32 threadId
    // sADDI s2, s2, 2
    MEM[96] = 8'h10;
    MEM[97] = 8'h01;
    MEM[98] = 8'h21;
    MEM[99] = 8'h00;

    // Go through previous loop
    // sJAL x31, 8 - where code starts 
    MEM[100] = 8'hec;
    MEM[101] = 8'h0f;
    MEM[102] = 8'h80;
    MEM[103] = 8'h00;

    //===================== WARP 4 =====================
    // set this as next warp (put on CU1) start at 32 threadId
    // sADDI s2, s2, 3
    MEM[104] = 8'h10;
    MEM[105] = 8'h01;
    MEM[106] = 8'h31;
    MEM[107] = 8'h00;

    // Go through previous loop
    // sJAL x31, 8 - where code starts 
    MEM[108] = 8'hec;
    MEM[109] = 8'h0f;
    MEM[110] = 8'h80;
    MEM[111] = 8'h00;

    //===================== WARP 5 =====================
    // set this as next warp (put on CU1) start at 32 threadId
    // sADDI s2, s2, 4
    MEM[112] = 8'h10;
    MEM[113] = 8'h01;
    MEM[114] = 8'h41;
    MEM[115] = 8'h00;

    // Go through previous loop
    // sJAL x31, 8 - where code starts 
    MEM[116] = 8'hec;
    MEM[117] = 8'h0f;
    MEM[118] = 8'h80;
    MEM[119] = 8'h00;

    //===================== WARP 6 =====================
    // set this as next warp (put on CU1) start at 32 threadId
    // sADDI s2, s2, 5
    MEM[120] = 8'h10;
    MEM[121] = 8'h01;
    MEM[122] = 8'h51;
    MEM[123] = 8'h00;

    // Go through previous loop
    // sJAL x31, 8 - where code starts 
    MEM[124] = 8'hec;
    MEM[125] = 8'h0f;
    MEM[126] = 8'h80;
    MEM[127] = 8'h00;
    
        changing = 0;
        for(int i = 999; i > 999-171; i--)
        begin
            if(changing)
            begin
                MEM[i] = 10;
                changing = 0;
            end
            else
            begin
                MEM[i] = 30;
                changing = 1;
            end
        end
    
        changing = 0;
        for(int i = 999-171; i > 999-(2*171); i--)
        begin
            if(changing)
            begin
                MEM[i] = 30;
                changing = 0;
            end
            else
            begin
                MEM[i] = 10;
                changing = 1;
            end
        end

    end
    

    always_ff @(posedge clk) 
    begin
        //set to the number of warps that you have
        if (curr_warp < 6)
        begin
            // single warp scheduler
            if(!CU_busy[0])
            begin
                CU_busy[0] = 1;
                reset[0] = 1;
                warpForCU[0] = warps[curr_warp];
                curr_warp++;
            end
    
            else if(!CU_busy[1])
            begin 
                CU_busy[1] = 1;
                reset[1] = 1;
                warpForCU[1] = warps[curr_warp];
                curr_warp++;
            end
    
            else if(!CU_busy[2])
            begin
                CU_busy[2] = 1;
                reset[2] = 1;
                warpForCU[2] = warps[curr_warp];
                curr_warp++;
            end
    
            else if(!CU_busy[3])
            begin
                CU_busy[3] = 1;
                reset[3] = 1;
                warpForCU[3] = warps[curr_warp];
                curr_warp++;
            end
        end
    end
    
     CU CU0(.clk(clk), .warp(warpForCU[0]), .threadsPerCU(32), .busy(CU_busy[0]), .reset(reset[0]), .MEM(MEM));
     CU CU1(.clk(clk), .warp(warpForCU[1]), .threadsPerCU(32), .busy(CU_busy[1]), .reset(reset[1]), .MEM(MEM));
     CU CU2(.clk(clk), .warp(warpForCU[2]), .threadsPerCU(32), .busy(CU_busy[2]), .reset(reset[2]), .MEM(MEM));            
     CU CU3(.clk(clk), .warp(warpForCU[3]), .threadsPerCU(32), .busy(CU_busy[3]), .reset(reset[3]), .MEM(MEM));


endmodule