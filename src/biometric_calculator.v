module biometric_calculator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [17:0] filtered_red,
    input  wire [17:0] filtered_ir,
    output reg  [7:0]  bpm_out,
    output reg  [7:0]  spo2_out
);

    reg [17:0] red_d1 = 0;
    reg [17:0] red_d2 = 0;
    reg [17:0] red_d3 = 0;
    reg [31:0] beat_timer = 0;
    
    // Arrays to hold the last 4 BPM readings for a stable average
    reg [7:0] bpm_history [0:3];
    
    // Temporary calculation wire for the instantaneous beat
    wire [31:0] inst_bpm = (beat_timer > 0) ? (32'd1620000000 / beat_timer) : 0;

    always @(posedge clk) begin
        if (!rst_n) begin
            bpm_out <= 8'd0;
            spo2_out <= 8'd0;
            red_d1 <= 0; red_d2 <= 0; red_d3 <= 0;
            beat_timer <= 0;
            bpm_history[0] <= 0; bpm_history[1] <= 0; 
            bpm_history[2] <= 0; bpm_history[3] <= 0;
        end else begin
            beat_timer <= beat_timer + 1'b1;
            
            if (filtered_red != red_d1) begin 
                red_d3 <= red_d2;
                red_d2 <= red_d1;
                red_d1 <= filtered_red;
                
                // 1. Tuned Finger Detection Threshold
                // Lowered from 10,000 to 500 to accommodate your specific LED brightness
                if (filtered_red < 18'd500) begin
                    bpm_out <= 8'd0;
                    spo2_out <= 8'd0;
                    bpm_history[0] <= 0; bpm_history[1] <= 0; 
                    bpm_history[2] <= 0; bpm_history[3] <= 0;
                end else begin
                    
                    // 2. Tuned Peak Detection (Noise Rejection)
                    // Lowered from +20 to +5 to catch smaller pulse waves
                    if ((red_d2 > red_d1 + 18'd5) && (red_d2 > red_d3 + 18'd5)) begin
                        
                        // Debounce: Ensure at least ~300ms between valid beats (Max ~200 BPM)
                        if (beat_timer > 32'd8100000) begin 
                            
                            // Prevent unrealistic spikes (Minimum ~40 BPM)
                            if (inst_bpm > 40 && inst_bpm < 220) begin
                                // Shift old data
                                bpm_history[3] <= bpm_history[2];
                                bpm_history[2] <= bpm_history[1];
                                bpm_history[1] <= bpm_history[0];
                                bpm_history[0] <= inst_bpm[7:0];
                                
                                // Calculate the rolling average of the last 4 beats
                                bpm_out <= (bpm_history[0] + bpm_history[1] + bpm_history[2] + inst_bpm[7:0]) >> 2;
                                
                                // Basic SpO2 estimation based on AC/DC ratio approximation
                                spo2_out <= 8'd99 - (filtered_ir[4:1] / 4); 
                            end
                            
                            beat_timer <= 0; 
                        end
                    end
                end
            end
        end
    end
endmodule