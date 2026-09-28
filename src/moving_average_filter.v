module moving_average_filter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_valid, 
    input  wire [17:0] raw_red,      
    input  wire [17:0] raw_ir,       
    output reg  [17:0] filtered_red, 
    output reg  [17:0] filtered_ir,  
    output reg         filtered_done 
);

    reg [17:0] red_buf [0:3];
    reg [17:0] ir_buf  [0:3];
    
    reg [19:0] red_sum;
    reg [19:0] ir_sum;

    always @(posedge clk) begin
        if (!rst_n) begin
            red_buf[0] <= 18'd0; red_buf[1] <= 18'd0; red_buf[2] <= 18'd0; red_buf[3] <= 18'd0;
            ir_buf[0]  <= 18'd0; ir_buf[1]  <= 18'd0; ir_buf[2]  <= 18'd0; ir_buf[3]  <= 18'd0;
            filtered_red <= 18'd0;
            filtered_ir  <= 18'd0;
            filtered_done <= 1'b0;
        end else if (sample_valid) begin
            red_buf[3] <= red_buf[2]; red_buf[2] <= red_buf[1]; red_buf[1] <= red_buf[0]; red_buf[0] <= raw_red;
            ir_buf[3]  <= ir_buf[2];  ir_buf[2]  <= ir_buf[1];  ir_buf[1]  <= ir_buf[0];  ir_buf[0]  <= raw_ir;

            red_sum <= raw_red + red_buf[0] + red_buf[1] + red_buf[2];
            ir_sum  <= raw_ir  + ir_buf[0]  + ir_buf[1]  + ir_buf[2];

            filtered_red <= red_sum[19:2]; 
            filtered_ir  <= ir_sum[19:2];
            filtered_done <= 1'b1;
        end else begin
            filtered_done <= 1'b0;
        end
    end

endmodule