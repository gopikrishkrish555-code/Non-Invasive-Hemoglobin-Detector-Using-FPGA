module i2c_master_max30102 (
    input  wire        clk,          
    input  wire        rst_n,        
    output reg         i2c_scl,      
    inout  wire        i2c_sda,      
    output reg  [17:0] raw_red,      
    output reg  [17:0] raw_ir,       
    output reg         sample_valid, 
    output reg         init_done,
    input  wire [7:0]  bpm_in,       
    input  wire [7:0]  spo2_in       
);

    reg [15:0] clk_div = 16'd0;
    wire tick = (clk_div == 16'd674);
    
    always @(posedge clk) begin
        if (tick) clk_div <= 16'd0;
        else clk_div <= clk_div + 1'b1;
    end

    reg [1:0]  phase = 2'd0;  
    reg [7:0]  bit_cnt = 8'd0; 
    reg [7:0]  state = 8'd0;
    reg [2:0]  col_cnt = 3'd0; 
    reg [3:0]  clear_page = 4'd0; 
    reg [6:0]  clear_col = 7'd0;  
    
    reg sda_out = 1'b1;
    reg sda_dir = 1'b1; 
    assign i2c_sda = sda_dir ? sda_out : 1'bz;
    wire sda_in = i2c_sda;

    reg [23:0] payload;
    reg [31:0] read_buffer; 
    
    wire [3:0] bpm_tens  = (bpm_in / 10) % 10;
    wire [3:0] bpm_units = bpm_in % 10;
    wire [3:0] spo2_tens = (spo2_in / 10) % 10;
    wire [3:0] spo2_units= spo2_in % 10;

    wire [3:0] b_idx = (bit_cnt <= 9) ? (9 - bit_cnt) : (bit_cnt <= 18) ? (18 - bit_cnt) : (29 - bit_cnt);
    wire [7:0] tx_byte = (bit_cnt <= 9) ? 8'hAE : (bit_cnt <= 18) ? 8'h05 : 8'hAF;

    function [7:0] get_font_byte;
        input [7:0] char;
        input [2:0] col;
        reg [39:0] f;
        begin
            case(char)
                8'd0: f = 40'h3E_51_49_45_3E; 
                8'd1: f = 40'h00_42_7F_40_00;
                8'd2: f = 40'h42_61_51_49_46;
                8'd3: f = 40'h21_41_45_4B_31;
                8'd4: f = 40'h18_14_12_7F_10;
                8'd5: f = 40'h27_45_45_45_39;
                8'd6: f = 40'h3C_4A_49_49_30;
                8'd7: f = 40'h01_71_09_05_03;
                8'd8: f = 40'h36_49_49_49_36;
                8'd9: f = 40'h06_49_49_29_1E;
                8'h42: f = 40'h7F_49_49_49_36; // B
                8'h50: f = 40'h7F_09_09_09_06; // P
                8'h4D: f = 40'h7F_02_0C_02_7F; // M
                8'h53: f = 40'h26_49_49_49_32; // S
                8'h4F: f = 40'h3E_41_41_41_3E; // O
                8'h25: f = 40'h23_13_08_64_62; // %
                default: f = 40'h00_00_00_00_00; // Space
            endcase
            case(col)
                3'd0: get_font_byte = f[39:32];
                3'd1: get_font_byte = f[31:24];
                3'd2: get_font_byte = f[23:16];
                3'd3: get_font_byte = f[15:8];
                3'd4: get_font_byte = f[7:0];
                default: get_font_byte = 8'h00; 
            endcase
        end
    endfunction

    always @(*) begin
        case(state)
            8'd0: payload = 24'h78_00_AE; 
            8'd1: payload = 24'h78_00_8D; 
            8'd2: payload = 24'h78_00_14; 
            8'd3: payload = 24'h78_00_20; 
            8'd4: payload = 24'h78_00_02; 
            8'd5: payload = 24'h78_00_AF; 
            
            8'd6: payload = 24'hAE_06_00; 
            8'd7: payload = 24'hAE_06_03; 
            8'd8: payload = 24'hAE_09_33; 
            8'd9: payload = 24'hAE_07_07; 
            
            8'd10: payload = {16'h7800, 8'hB0 + {4'd0, clear_page}}; 
            8'd11: payload = 24'h78_00_00; 
            8'd12: payload = 24'h78_00_10; 
            8'd13: payload = 24'h78_40_00; 
            
            8'd15: payload = 24'h78_00_B2; 
            8'd16: payload = 24'h78_00_00; 
            8'd17: payload = 24'h78_00_10; 
            
            8'd18: payload = {16'h7840, get_font_byte(8'h42, col_cnt)};
            8'd19: payload = {16'h7840, get_font_byte(8'h50, col_cnt)};
            8'd20: payload = {16'h7840, get_font_byte(8'h4D, col_cnt)};
            8'd21: payload = {16'h7840, get_font_byte(8'h00, col_cnt)};
            8'd22: payload = {16'h7840, get_font_byte({4'd0, bpm_tens}, col_cnt)};
            8'd23: payload = {16'h7840, get_font_byte({4'd0, bpm_units}, col_cnt)};
            
            8'd24: payload = 24'h78_00_B4; 
            8'd25: payload = 24'h78_00_00; 
            8'd26: payload = 24'h78_00_10; 
            
            8'd27: payload = {16'h7840, get_font_byte(8'h53, col_cnt)};
            8'd28: payload = {16'h7840, get_font_byte(8'h50, col_cnt)};
            8'd29: payload = {16'h7840, get_font_byte(8'h4F, col_cnt)};
            8'd30: payload = {16'h7840, get_font_byte(8'h00, col_cnt)};
            8'd31: payload = {16'h7840, get_font_byte({4'd0, spo2_tens}, col_cnt)};
            8'd32: payload = {16'h7840, get_font_byte({4'd0, spo2_units}, col_cnt)};
            8'd33: payload = {16'h7840, get_font_byte(8'h25, col_cnt)};
            default: payload = 24'h78_00_AF;
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            i2c_scl      <= 1'b1;
            sda_out      <= 1'b1;
            sda_dir      <= 1'b1;
            init_done    <= 1'b0;
            phase        <= 2'd0;
            bit_cnt      <= 8'd0;
            state        <= 8'd0;
            col_cnt      <= 3'd0;
            clear_page   <= 4'd0;
            clear_col    <= 7'd0;
            raw_red      <= 18'd0; 
            raw_ir       <= 18'd0; 
            sample_valid <= 1'b0;
        end else begin
            // Clear the valid pulse dynamically to avoid multiple drivers
            if (sample_valid) sample_valid <= 1'b0;

            if (tick) begin
                phase <= phase + 1'b1;
                
                if (state != 8'd14) begin
                    if (bit_cnt == 0) begin 
                        case(phase)
                            2'd0: begin sda_out <= 1'b1; sda_dir <= 1'b1; i2c_scl <= 1'b1; end
                            2'd1: begin sda_out <= 1'b0; i2c_scl <= 1'b1; end 
                            2'd2: begin sda_out <= 1'b0; i2c_scl <= 1'b1; end
                            2'd3: begin sda_out <= 1'b0; i2c_scl <= 1'b0; bit_cnt <= bit_cnt + 1'b1; end 
                        endcase
                    end
                    else if (bit_cnt >= 1 && bit_cnt <= 27) begin 
                        case(phase)
                            2'd0: begin 
                                i2c_scl <= 1'b0; 
                                if (bit_cnt == 9 || bit_cnt == 18 || bit_cnt == 27) sda_dir <= 1'b0; 
                                else begin 
                                    sda_dir <= 1'b1; 
                                    if (bit_cnt <= 8) sda_out <= payload[24 - bit_cnt];
                                    else if (bit_cnt <= 17) sda_out <= payload[25 - bit_cnt];
                                    else sda_out <= payload[26 - bit_cnt];
                                end
                            end
                            2'd1: begin i2c_scl <= 1'b1; end 
                            2'd2: begin i2c_scl <= 1'b1; end 
                            2'd3: begin i2c_scl <= 1'b0; bit_cnt <= bit_cnt + 1'b1; end
                        endcase
                    end
                    else if (bit_cnt == 28) begin 
                        case(phase)
                            2'd0: begin i2c_scl <= 1'b0; sda_out <= 1'b0; sda_dir <= 1'b1; end 
                            2'd1: begin i2c_scl <= 1'b1; sda_out <= 1'b0; end 
                            2'd2: begin i2c_scl <= 1'b1; sda_out <= 1'b1; end 
                            2'd3: begin 
                                i2c_scl <= 1'b1; sda_out <= 1'b1; bit_cnt <= 0; 
                                
                                if (state == 8'd13) begin 
                                    if (clear_col < 7'd127) clear_col <= clear_col + 1'b1;
                                    else begin
                                        clear_col <= 7'd0;
                                        if (clear_page < 4'd7) begin clear_page <= clear_page + 1'b1; state <= 8'd10; end 
                                        else state <= 8'd14; 
                                    end
                                end
                                else if ((state >= 8'd18 && state <= 8'd23) || (state >= 8'd27 && state <= 8'd33)) begin
                                    if (col_cnt < 3'd5) col_cnt <= col_cnt + 1'b1;
                                    else begin col_cnt <= 3'd0; state <= state + 1'b1; end
                                end
                                else begin
                                    if (state < 8'd33) state <= state + 1'b1;
                                    else begin init_done <= 1'b1; state <= 8'd14; end
                                end
                            end
                        endcase
                    end
                end else begin
                    // --- SENSOR READ PROTOCOL (STATE 14) ---
                    if (bit_cnt == 0 || bit_cnt == 20) begin 
                        case(phase)
                            2'd0: begin sda_out <= 1'b1; sda_dir <= 1'b1; i2c_scl <= 1'b1; end
                            2'd1: begin sda_out <= 1'b0; i2c_scl <= 1'b1; end 
                            2'd2: begin sda_out <= 1'b0; i2c_scl <= 1'b1; end
                            2'd3: begin sda_out <= 1'b0; i2c_scl <= 1'b0; bit_cnt <= bit_cnt + 1'b1; end 
                        endcase
                    end
                    else if ((bit_cnt >= 1 && bit_cnt <= 18) || (bit_cnt >= 21 && bit_cnt <= 29)) begin 
                        case(phase)
                            2'd0: begin 
                                i2c_scl <= 1'b0;
                                if (b_idx == 0) sda_dir <= 1'b0; 
                                else begin sda_dir <= 1'b1; sda_out <= tx_byte[b_idx - 1]; end
                            end
                            2'd1: begin i2c_scl <= 1'b1; end 
                            2'd2: begin i2c_scl <= 1'b1; end 
                            2'd3: begin i2c_scl <= 1'b0; bit_cnt <= bit_cnt + 1'b1; end
                        endcase
                    end
                    else if (bit_cnt == 19) begin 
                        case(phase)
                            2'd0: begin i2c_scl <= 1'b0; sda_out <= 1'b0; sda_dir <= 1'b1; end 
                            2'd1: begin i2c_scl <= 1'b1; sda_out <= 1'b0; end 
                            2'd2: begin i2c_scl <= 1'b1; sda_out <= 1'b1; end 
                            2'd3: begin i2c_scl <= 1'b1; bit_cnt <= bit_cnt + 1'b1; end 
                        endcase
                    end
                    else if (bit_cnt >= 30 && bit_cnt <= 65) begin 
                        case(phase)
                            2'd0: begin 
                                i2c_scl <= 1'b0; 
                                if (bit_cnt == 38 || bit_cnt == 47 || bit_cnt == 56) begin sda_dir <= 1'b1; sda_out <= 1'b0; end 
                                else if (bit_cnt == 65) begin sda_dir <= 1'b1; sda_out <= 1'b1; end 
                                else sda_dir <= 1'b0; 
                            end
                            2'd1: begin i2c_scl <= 1'b1; end 
                            2'd2: begin 
                                i2c_scl <= 1'b1; 
                                if (sda_dir == 1'b0) read_buffer <= {read_buffer[30:0], sda_in};
                            end 
                            2'd3: begin i2c_scl <= 1'b0; bit_cnt <= bit_cnt + 1'b1; end
                        endcase
                    end
                    else if (bit_cnt == 66) begin 
                        case(phase)
                            2'd0: begin i2c_scl <= 1'b0; sda_out <= 1'b0; sda_dir <= 1'b1; end 
                            2'd1: begin i2c_scl <= 1'b1; sda_out <= 1'b0; end 
                            2'd2: begin i2c_scl <= 1'b1; sda_out <= 1'b1; end 
                            2'd3: begin 
                                i2c_scl <= 1'b1; 
                                bit_cnt <= 0; 
                                raw_ir  <= {read_buffer[31:24], read_buffer[23:16], 2'b00};
                                raw_red <= {read_buffer[15:8], read_buffer[7:0], 2'b00};
                                sample_valid <= 1'b1; // Pulses HIGH here, resets automatically on next clk
                                state <= state + 1'b1; 
                            end
                        endcase
                    end
                end
            end
        end
    end

endmodule