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
    // Advanced High-Performance Bus (AHB) instantiation (s)
    // ------------------------------------------------------------
    system_info sysinfo_inst (
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