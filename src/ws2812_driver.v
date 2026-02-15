module ws2812_driver (
    input  wire clk,        // 50 MHz
    input  wire rstn,
    input  wire trigger,    // 1-cycle pulse starts transfer
    input wire [23:0] led_data,
    output reg  ws_out
);

    // ------------------------------------------------------------
    // Parameters (50 MHz timing)
    // ------------------------------------------------------------
    localparam T0H = 18;
    localparam T0L = 40;
    localparam T1H = 35;
    localparam T1L = 28;
    localparam RESET_TIME = 3000;

    reg [15:0] timer;
    reg [5:0]  bit_idx;
    reg [2:0]  state;
    reg        busy;

    localparam IDLE  = 0;
    localparam HIGH  = 1;
    localparam LOW   = 2;
    localparam RESET = 3;

    wire current_bit = led_data[23 - bit_idx];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ws_out  <= 1'b0;
            timer   <= 0;
            bit_idx <= 0;
            state   <= IDLE;
            busy    <= 0;
        end else begin
            case (state)

            IDLE: begin
                ws_out <= 1'b0;
                timer  <= 0;
                bit_idx<= 0;

                if (trigger && !busy) begin
                    busy  <= 1'b1;
                    state <= HIGH;
                end
            end

            HIGH: begin
                ws_out <= 1'b1;
                if (timer == (current_bit ? T1H : T0H)) begin
                    timer <= 0;
                    state <= LOW;
                end else
                    timer <= timer + 1;
            end

            LOW: begin
                ws_out <= 1'b0;
                if (timer == (current_bit ? T1L : T0L)) begin
                    timer <= 0;
                    if (bit_idx == 23)
                        state <= RESET;
                    else begin
                        bit_idx <= bit_idx + 1;
                        state <= HIGH;
                    end
                end else
                    timer <= timer + 1;
            end

            RESET: begin
                ws_out <= 1'b0;
                if (timer == RESET_TIME) begin
                    timer <= 0;
                    busy  <= 0;
                    state <= IDLE;
                end else
                    timer <= timer + 1;
            end

            endcase
        end
    end
endmodule