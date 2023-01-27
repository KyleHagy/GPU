`timescale 1ns / 1ps

module sim(
    );
    
    logic CLK = 0;

    GPU gpu(.clk(CLK));    
   
    always #5 CLK = ~CLK; 
    
    initial begin   
        #1400   
        $finish;
    end 
    
endmodule
