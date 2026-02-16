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
    // -----------------------------
    // AHB1 slave/master interface
    // -----------------------------
/*
    // --- Read interface (from slave to master) ---
    wire [31:0] AHB1HRDATA;     // Read data bus: data returned from the slave to the master
    wire        AHB1HREADYOUT;  // Ready signal: indicates slave can accept next transfer or has valid data
    wire [1:0]  AHB1HRESP;      // Response code from slave: 00=OKAY, 01=ERROR, etc.

    // --- Control signals (from master to slave) ---
    wire [1:0]  AHB1HTRANS;     // Transfer type: indicates if the current transfer is IDLE, BUSY, NONSEQ, SEQ
    wire [2:0]  AHB1HBURST;     // Burst type: single, incrementing, or wrapping burst transfers
    wire [3:0]  AHB1HPROT;      // Protection control: privilege, bufferable, cacheable, etc.
    wire [2:0]  AHB1HSIZE;      // Transfer size: width of the transfer (byte=0, halfword=1, word=2, etc.)
    wire        AHB1HWRITE;     // Direction of transfer: 1=write, 0=read
    wire        AHB1HREADYMUX;  // Ready mux output: used internally in the core for pipeline alignment
    wire [3:0]  AHB1HMASTER;    // Master ID: identifies which master is driving the current transfer (if multiple masters)
    wire        AHB1HMASTLOCK;  // Locked transfer: indicates exclusive/locked transfer sequence

    // --- Address/data buses ---
    wire [31:0] AHB1HADDR;      // Address bus: 32-bit address of the current transfer
    wire [31:0] AHB1HWDATA;     // Write data bus: 32-bit data being written from master to slave

    // --- Slave select / clock / reset ---
    wire        AHB1HSEL;       // Slave select: active when this slave is addressed
    wire        AHB1HCLK;       // AHB clock: synchronizes all transfers
    wire        AHB1HRESET;     // AHB reset: resets bus and slaves
*/

    wire [31:0] APB1PADDR;
    wire        APB1PENABLE;
    wire        APB1PWRITE;
    wire [3:0]  APB1PSTRB;
    wire [2:0]  APB1PPROT;
    wire [31:0] APB1PWDATA;
    wire [31:0] APB1PRDATA;
    wire        APB1PREADY;
    wire        APB1PSLVERR;
    wire        APB1PCLK;
    wire        APB1PRESET;
    wire        APB1PSEL;

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

        // APB1 interface
        .APB1PADDR(APB1PADDR),
        .APB1PENABLE(APB1PENABLE),
        .APB1PWRITE(APB1PWRITE),
        .APB1PSTRB(APB1PSTRB),
        .APB1PPROT(APB1PPROT),
        .APB1PWDATA(APB1PWDATA),
        .APB1PRDATA(APB1PRDATA),
        .APB1PREADY(APB1PREADY),
        .APB1PSLVERR(APB1PSLVERR),
        .APB1PCLK(APB1PCLK),
        .APB1PRESET(APB1PRESET),
        .APB1PSEL(APB1PSEL),        

        .HCLK(HCLK),
        .hwRstn(hwRstn)
    );

    // ------------------------------------------------------------
    // Advanced High-Performance Bus (AHB) instantiation (s)
    // ------------------------------------------------------------
 
    apb_memmap apb_memmap_inst (
        .APBCLK   (APB1PCLK),
        .APBRESET (APB1PRESET),

        .PADDR    (APB1PADDR),
        .PSEL     (APB1PSEL),
        .PENABLE  (APB1PENABLE),
        .PWRITE   (APB1PWRITE),
        .PWDATA   (APB1PWDATA),

        .PRDATA   (APB1PRDATA),
        .PREADY   (APB1PREADY),
        .PSLVERR  (APB1PSLVERR)
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