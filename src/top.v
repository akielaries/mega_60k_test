module top (
    input HCLK,
    input hwRstn,
    inout [15:0] GPIO,
    inout JTAG_7_SWDIO,
    inout JTAG_9_SWDCLK,
    input UART1RXD,
    output UART1TXD,
    output LOCKUP,
    output HALTED,
    inout BOOT_LED_A,
    output WS2812_LED
);

    // ------------------------------------------------------------
    // Cortex-M1 instantiation (unchanged)
    // ------------------------------------------------------------
    Gowin_EMPU_M1_Top Cortex_M1_instance(
        .LOCKUP(LOCKUP),
        .HALTED(HALTED),
        .GPIO(GPIO),
        .JTAG_7(JTAG_7_SWDIO),
        .JTAG_9(JTAG_9_SWDCLK),
        .UART1RXD(UART1RXD),
        .UART1TXD(UART1TXD),
        .HCLK(HCLK),
        .hwRstn(hwRstn)
    );

    // ------------------------------------------------------------
    // 0.5 second counter (unchanged) – drives BOOT_LED and triggers WS2812
    // ------------------------------------------------------------
    reg [24:0] counter;          // 25 bits for 0..24,999,999 (at 50 MHz)
    reg gpio1_out;                // toggles every 0.5 s
    reg trigger;                  // pulse to start a new WS2812 transmission

    always @(posedge HCLK or negedge hwRstn) begin
        if (!hwRstn) begin
            counter   <= 25'd0;
            gpio1_out <= 1'b0;
            trigger   <= 1'b0;
        end else begin
            if (counter == 25_000_000 - 1) begin
                counter   <= 25'd0;
                gpio1_out <= ~gpio1_out;      // toggle every 0.5 sec
                trigger   <= 1'b1;             // pulse high for one cycle
            end else begin
                counter <= counter + 1'b1;
                trigger <= 1'b0;                // pulse low after one cycle
            end
        end
    end

    assign BOOT_LED_A = gpio1_out;   // plain LED toggles
    reg [23:0] ws_color;


    ws2812_driver ws_drv (
        .clk(HCLK),
        .rstn(hwRstn),
        .ws_out(WS2812_LED)
    );

endmodule