module ssd1306_oled (
    input clk,
    input rst_n,
    inout sda,
    output scl,
    input [7:0] bpm_val,
    input [7:0] spo2_val,
    input [39:0] ai_text // 5 ASCII characters from the AI
);

    // Simplified I2C state machine for OLED (Placeholder for your specific I2C driver logic)
    // To keep the file manageable, this is the structural wrapper.
    // You will route your initialization sequence (0xAE, 0x20, 0x10, 0xAF, etc.) here.

    reg [7:0] i2c_data;
    reg i2c_start;
    wire i2c_done;
    
    // Example state machine to update display
    reg [3:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            i2c_start <= 0;
        end else begin
            case (state)
                0: begin
                    // Send BPM Data to OLED RAM
                    i2c_data <= bpm_val;
                    i2c_start <= 1;
                    if (i2c_done) state <= 1;
                end
                1: begin
                    // Send SpO2 Data to OLED RAM
                    i2c_data <= spo2_val;
                    i2c_start <= 1;
                    if (i2c_done) state <= 2;
                end
                2: begin
                    // Send AI Text to OLED RAM
                    // Breaks down the 40-bit string into 8-bit ASCII characters
                    // e.g., ai_text[39:32], ai_text[31:24]...
                    i2c_data <= ai_text[39:32]; 
                    i2c_start <= 1;
                    if (i2c_done) state <= 0; 
                end
            endcase
        end
    end

    // Note: You must link this state machine to a standard I2C byte-transmitter block.
endmodule