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
    // AHB1 wires
    // ------------------------------------------------------------
    wire [31:0] AHB1HRDATA;
    wire        AHB1HREADYOUT;
    wire [1:0]  AHB1HRESP;

    wire [1:0]  AHB1HTRANS;
    wire [2:0]  AHB1HBURST;
    wire [3:0]  AHB1HPROT;
    wire [2:0]  AHB1HSIZE;
    wire        AHB1HWRITE;
    wire        AHB1HREADYMUX;
    wire [3:0]  AHB1HMASTER;
    wire        AHB1HMASTLOCK;
    wire [31:0] AHB1HADDR;
    wire [31:0] AHB1HWDATA;
    wire        AHB1HSEL;
    wire        AHB1HCLK;
    wire        AHB1HRESET;

    // ------------------------------------------------------------
    // Cortex-M1 instantiation
    // ------------------------------------------------------------
    Gowin_EMPU_M1_Top Cortex_M1_instance(
        .LOCKUP(LOCKUP),
        .HALTED(HALTED),
        .GPIO(GPIO),
        .JTAG_7(JTAG_7_SWDIO),
        .JTAG_9(JTAG_9_SWDCLK),
        .UART1RXD(UART1RXD),
        .UART1TXD(UART1TXD),

        // AHB1 interface
        .AHB1HRDATA(AHB1HRDATA),
        .AHB1HREADYOUT(AHB1HREADYOUT),
        .AHB1HRESP(AHB1HRESP),
        .AHB1HTRANS(AHB1HTRANS),
        .AHB1HBURST(AHB1HBURST),
        .AHB1HPROT(AHB1HPROT),
        .AHB1HSIZE(AHB1HSIZE),
        .AHB1HWRITE(AHB1HWRITE),
        .AHB1HREADYMUX(AHB1HREADYMUX),
        .AHB1HMASTER(AHB1HMASTER),
        .AHB1HMASTLOCK(AHB1HMASTLOCK),
        .AHB1HADDR(AHB1HADDR),
        .AHB1HWDATA(AHB1HWDATA),
        .AHB1HSEL(AHB1HSEL),
        .AHB1HCLK(AHB1HCLK),
        .AHB1HRESET(AHB1HRESET),
        

        .HCLK(HCLK),
        .hwRstn(hwRstn)
    );

    // ------------------------------------------------------------
    // Advanced High-Performance Bus (AHB) instantiation
    // ------------------------------------------------------------
    ahb_dummy ahb_test (
        .HCLK(AHB1HCLK),
        .HRESET(AHB1HRESET),

        .HADDR(AHB1HADDR),
        .HWDATA(AHB1HWDATA),
        .HWRITE(AHB1HWRITE),
        .HTRANS(AHB1HTRANS),
        .HSEL(AHB1HSEL),

        .HRDATA(AHB1HRDATA),
        .HREADYOUT(AHB1HREADYOUT),
        .HRESP(AHB1HRESP)
    );

    // ------------------------------------------------------------
    // 0.5 second counter (unchanged) – drives BOOT_LED
    // ------------------------------------------------------------
    reg [24:0] counter;          // 25 bits for 0..24,999,999 (at 50 MHz)
    reg gpio1_out;                // toggles every 0.5 s

    always @(posedge HCLK or negedge hwRstn) begin
        if (!hwRstn) begin
            counter   <= 25'd0;
            gpio1_out <= 1'b0;
        end else begin
            if (counter == 25_000_000 - 1) begin
                counter   <= 25'd0;
                gpio1_out <= ~gpio1_out;      // toggle every 0.5 sec
            end else begin
                counter <= counter + 1'b1;
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