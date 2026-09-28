module top (
    input  wire sys_clk,   // 27MHz system clock
    input  wire sys_rst_n, // Active-low reset button
    inout  wire i2c_sda,   // Shared I2C Data
    output wire i2c_scl,   // Shared I2C Clock
    output wire [3:0] led  // Onboard Tang Nano LEDs for AI Status
);

    // --- Wires for Signal Routing ---
    // 1. Raw Sensor Data
    wire [17:0] raw_red_wire;
    wire [17:0] raw_ir_wire;
    wire sample_valid_wire;
    wire init_done_wire;

    // 2. Filtered Optical Data
    wire [17:0] filtered_red_wire;
    wire [17:0] filtered_ir_wire;
    wire filtered_done_wire;

    // 3. Final Calculated Biometrics
    wire [7:0] final_bpm_wire;
    wire [7:0] final_spo2_wire;
    
    // 4. AI Output
    wire [1:0] ai_risk_class;

    // --- 1. Your Custom Combined I2C Master ---
    i2c_master_max30102 my_i2c_master (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda),
        .raw_red(raw_red_wire),
        .raw_ir(raw_ir_wire),
        .sample_valid(sample_valid_wire),
        .init_done(init_done_wire),
        .bpm_in(final_bpm_wire),    // Final BPM back to OLED
        .spo2_in(final_spo2_wire)   // Final SpO2 back to OLED
    );

    // --- 2. Moving Average Filter (Optical) ---
    moving_average_filter my_filter (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .sample_valid(sample_valid_wire),
        .raw_red(raw_red_wire),
        .raw_ir(raw_ir_wire),
        .filtered_red(filtered_red_wire),
        .filtered_ir(filtered_ir_wire),
        .filtered_done(filtered_done_wire)
    );

    // --- 3. Biometric Calculator ---
    biometric_calculator my_calc (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .filtered_red(filtered_red_wire),
        .filtered_ir(filtered_ir_wire),
        .bpm_out(final_bpm_wire),
        .spo2_out(final_spo2_wire)
    );

    // --- 4. Edge AI Neural Network Engine ---
    ai_engine my_ai_core (
        .clk(sys_clk),
        .bpm_in(final_bpm_wire),
        .spo2_in(final_spo2_wire),
        .risk_class(ai_risk_class)
    );

    // --- 5. Tang Nano LED Mapping for AI Visualizer ---
    // LED 0 ON = Normal | LED 1 ON = Tachycardia | LED 2 ON = Hypoxia | LED 3 ON = Critical
    assign led[0] = (ai_risk_class == 2'd0) ? 1'b0 : 1'b1; 
    assign led[1] = (ai_risk_class == 2'd1) ? 1'b0 : 1'b1; 
    assign led[2] = (ai_risk_class == 2'd2) ? 1'b0 : 1'b1; 
    assign led[3] = (ai_risk_class == 2'd3) ? 1'b0 : 1'b1; 

endmodule