module ai_engine (
    input clk,
    input [7:0] bpm_in,   // Raw Heart Rate from MAX30100
    input [7:0] spo2_in,  // Raw Blood Oxygen from MAX30100
    output reg [1:0] risk_class // 0=Normal, 1=Tachycardia, 2=Hypoxia, 3=Critical
);

    // ==========================================
    // SYNTHESIZED AI WEIGHTS (100.00% Accuracy)
    // ==========================================
    localparam signed [7:0] W1_0_0 = -2;
    localparam signed [7:0] W1_0_1 = 54;
    localparam signed [7:0] W1_0_2 = 45;
    localparam signed [7:0] W1_0_3 = 0;
    
    localparam signed [7:0] W1_1_0 = -2;
    localparam signed [7:0] W1_1_1 = -32;
    localparam signed [7:0] W1_1_2 = -46;
    localparam signed [7:0] W1_1_3 = 7;
    
    localparam signed [7:0] B1_0 = 10;
    localparam signed [7:0] B1_1 = -128;
    localparam signed [7:0] B1_2 = 127;
    localparam signed [7:0] B1_3 = -128;
    
    localparam signed [7:0] W2_0_0 = 0;
    localparam signed [7:0] W2_0_1 = 0;
    localparam signed [7:0] W2_0_2 = 0;
    localparam signed [7:0] W2_0_3 = 0;
    
    localparam signed [7:0] W2_1_0 = 1;
    localparam signed [7:0] W2_1_1 = -3;
    localparam signed [7:0] W2_1_2 = 1;
    localparam signed [7:0] W2_1_3 = -23;
    
    localparam signed [7:0] W2_2_0 = -128;
    localparam signed [7:0] W2_2_1 = -27;
    localparam signed [7:0] W2_2_2 = -82;
    localparam signed [7:0] W2_2_3 = 5;
    
    localparam signed [7:0] W2_3_0 = 127;
    localparam signed [7:0] W2_3_1 = 127;
    localparam signed [7:0] W2_3_2 = -128;
    localparam signed [7:0] W2_3_3 = -128;
    
    localparam signed [7:0] B2_0 = -128;
    localparam signed [7:0] B2_1 = -128;
    localparam signed [7:0] B2_2 = 127;
    localparam signed [7:0] B2_3 = 127;

    // Cast inputs to signed 16-bit integers for math
    wire signed [15:0] x1 = {8'b0, bpm_in};
    wire signed [15:0] x2 = {8'b0, spo2_in};

    // --- LAYER 1: Multiply-Accumulate (MAC) ---
    // Multiplies inputs by weights and adds the bias (scaled by 64 for Q6 fixed-point)
    wire signed [15:0] z1_0 = (x1 * W1_0_0) + (x2 * W1_1_0) + (B1_0 * 64);
    wire signed [15:0] z1_1 = (x1 * W1_0_1) + (x2 * W1_1_1) + (B1_1 * 64);
    wire signed [15:0] z1_2 = (x1 * W1_0_2) + (x2 * W1_1_2) + (B1_2 * 64);
    wire signed [15:0] z1_3 = (x1 * W1_0_3) + (x2 * W1_1_3) + (B1_3 * 64);

    // --- LAYER 1: ReLU Activation ---
    // If the neuron value is negative, it outputs 0. Otherwise, it passes the value.
    wire signed [15:0] a1_0 = (z1_0 > 0) ? z1_0 : 16'd0;
    wire signed [15:0] a1_1 = (z1_1 > 0) ? z1_1 : 16'd0;
    wire signed [15:0] a1_2 = (z1_2 > 0) ? z1_2 : 16'd0;
    wire signed [15:0] a1_3 = (z1_3 > 0) ? z1_3 : 16'd0;

    // --- LAYER 2: Output Neurons ---
    wire signed [15:0] out_0 = (a1_0 * W2_0_0) + (a1_1 * W2_1_0) + (a1_2 * W2_2_0) + (a1_3 * W2_3_0) + (B2_0 * 64);
    wire signed [15:0] out_1 = (a1_0 * W2_0_1) + (a1_1 * W2_1_1) + (a1_2 * W2_2_1) + (a1_3 * W2_3_1) + (B2_1 * 64);
    wire signed [15:0] out_2 = (a1_0 * W2_0_2) + (a1_1 * W2_1_2) + (a1_2 * W2_2_2) + (a1_3 * W2_3_2) + (B2_2 * 64);
    wire signed [15:0] out_3 = (a1_0 * W2_0_3) + (a1_1 * W2_1_3) + (a1_2 * W2_2_3) + (a1_3 * W2_3_3) + (B2_3 * 64);

    // --- ARGMAX: Find the highest probability class ---
    // The neuron with the highest value dictates the final risk classification
    always @(posedge clk) begin
        if (out_0 >= out_1 && out_0 >= out_2 && out_0 >= out_3) 
            risk_class <= 2'd0; // Normal
        else if (out_1 >= out_0 && out_1 >= out_2 && out_1 >= out_3) 
            risk_class <= 2'd1; // Tachycardia
        else if (out_2 >= out_0 && out_2 >= out_1 && out_2 >= out_3) 
            risk_class <= 2'd2; // Hypoxia
        else 
            risk_class <= 2'd3; // Critical
    end
endmodule