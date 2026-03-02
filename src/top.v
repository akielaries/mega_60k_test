// =============================================================================
// top.v — Gowin EMPU Cortex-M1 + GWCT debug module (EXTENSIBLE VERSION)
//
// Clean architecture that supports:
//   - APB peripherals @ 0x6000_0000 (via apb_memmap)
//   - AHB peripherals @ 0x8000_0000 (via apb2ahb bridge)
//   - Easy to add more buses in the future
//
// GWCT has 2 buses:
//   Bus 0 (0x6xxx_xxxx): APB peripherals - shared with Cortex-M1
//   Bus 1 (0x8xxx_xxxx): AHB SRAM - shared with Cortex-M1 via bridge
//
// =============================================================================

module top (
    input HCLK,
    input hwRstn,
    inout [15:0] GPIO,
    inout JTAG_7_SWDIO,
    inout JTAG_9_SWDCLK,
    input UART1RXD,
    output UART1TXD,
    output GWCT_TX,
    input  GWCT_RX,  
    output LOCKUP,
    output HALTED,
    inout BOOT_LED_A,
    output WS2812_LED,
    // DDR3
    output DDR_INIT_COMPLETE_O,
    output [13:0] DDR_ADDR_O,
    output [2:0] DDR_BA_O,
    output DDR_CS_N_O,
    output DDR_RAS_N_O,
    output DDR_CAS_N_O,
    output DDR_WE_N_O,
    output DDR_CLK_O,
    output DDR_CLK_N_O,
    output DDR_CKE_O,
    output DDR_ODT_O,
    output DDR_RESET_N_O,
    output [1:0] DDR_DQM_O,
    inout [15:0] DDR_DQ_IO,
    inout [1:0] DDR_DQS_IO,
    inout [1:0] DDR_DQS_N_IO
);

    // =========================================================================
    // Boot LED blinker
    // =========================================================================
    reg [24:0] counter;
    reg gpio1_out;

    always @(posedge HCLK or negedge hwRstn) begin
        if (!hwRstn) begin
            counter   <= 25'd0;
            gpio1_out <= 1'b0;
        end else begin
            if (counter == 25_000_000 - 1) begin
                counter   <= 25'd0;
                gpio1_out <= ~gpio1_out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

    assign BOOT_LED_A = gpio1_out;

    // =========================================================================
    // Cortex-M1 APB1 interface
    // =========================================================================
    wire [31:0] APB1PADDR;
    wire        APB1PENABLE;
    wire        APB1PWRITE;
    wire [3:0]  APB1PSTRB;
    wire [31:0] APB1PWDATA;
    wire [31:0] APB1PRDATA;
    wire        APB1PREADY;
    wire        APB1PSLVERR;
    wire        APB1PCLK;
    wire        APB1PRESET;
    wire        APB1PSEL;

    // =========================================================================
    // Cortex-M1 AHB1 interface
    // =========================================================================
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

    // =========================================================================
    // DDR3 PLL
    // =========================================================================
    wire MCU_CLK;
    wire DDR_CLK;
    wire DDR_MEM_CLK;
    wire pll_lock;
    reg  pll_lock_r;
    reg  pll_lock_rr;

    always @(posedge HCLK) begin
        pll_lock_r  <= pll_lock;
        pll_lock_rr <= pll_lock_r;
    end

    Gowin_PLL u_Gowin_PLL (
        .lock(pll_lock),
        .clkout0(),
        .clkout2(DDR_MEM_CLK),
        .mdrdo(),
        .clkin(HCLK),
        .reset(1'b0),
        .mdclk(HCLK),
        .mdopc(2'b0),
        .mdainc(1'b0),
        .mdwdi(8'b0),
        .pll_init_bypass(1'b0)
    );

    assign MCU_CLK = HCLK;
    assign DDR_CLK = HCLK;

    // =========================================================================
    // Cortex-M1 instantiation
    // =========================================================================
    Gowin_EMPU_M1_Top Cortex_M1_instance (
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

        // APB1 interface
        .APB1PADDR(APB1PADDR),
        .APB1PENABLE(APB1PENABLE),
        .APB1PWRITE(APB1PWRITE),
        .APB1PSTRB(APB1PSTRB),
        .APB1PWDATA(APB1PWDATA),
        .APB1PRDATA(APB1PRDATA),
        .APB1PREADY(APB1PREADY),
        .APB1PSLVERR(APB1PSLVERR),
        .APB1PCLK(APB1PCLK),
        .APB1PRESET(APB1PRESET),
        .APB1PSEL(APB1PSEL),

        // DDR3 connections
        .DDR_INIT_COMPLETE_O(DDR_INIT_COMPLETE_O),
        .DDR_ADDR_O(DDR_ADDR_O),
        .DDR_BA_O(DDR_BA_O),
        .DDR_CS_N_O(DDR_CS_N_O),
        .DDR_RAS_N_O(DDR_RAS_N_O),
        .DDR_CAS_N_O(DDR_CAS_N_O),
        .DDR_WE_N_O(DDR_WE_N_O),
        .DDR_CLK_O(DDR_CLK_O),
        .DDR_CLK_N_O(DDR_CLK_N_O),
        .DDR_CKE_O(DDR_CKE_O),
        .DDR_ODT_O(DDR_ODT_O),
        .DDR_RESET_N_O(DDR_RESET_N_O),
        .DDR_DQM_O(DDR_DQM_O),
        .DDR_DQ_IO(DDR_DQ_IO),
        .DDR_DQS_IO(DDR_DQS_IO),
        .DDR_DQS_N_IO(DDR_DQS_N_IO),
        .DDR_MEM_CLK_I(DDR_MEM_CLK),
        .DDR_CLK_I(DDR_CLK),
        .DDR_LOCK_I(pll_lock),
        .DDR_RSTN_I(hwRstn),

        .HCLK(HCLK),
        .hwRstn(hwRstn)
    );

    // =========================================================================
    // GWCT debug bridge - 2 buses
    // =========================================================================
    // Bus 0: APB peripherals (0x6xxx_xxxx)
    // Bus 1: AHB SRAM        (0x8xxx_xxxx)
    
    wire [32*2-1:0] gwct_PADDR;
    wire [2-1:0]    gwct_PSEL;
    wire [2-1:0]    gwct_PENABLE;
    wire [2-1:0]    gwct_PWRITE;
    wire [32*2-1:0] gwct_PWDATA;
    wire [4*2-1:0]  gwct_PSTRB;
    wire [3*2-1:0]  gwct_PPROT;
    wire [32*2-1:0] gwct_PRDATA;
    wire [2-1:0]    gwct_PREADY;
    wire [2-1:0]    gwct_PSLVERR;

    gwct_debug_bridge_n #(
        .CLK_HZ(50_000_000),
        .BAUD(115_200),
        .NUM_APB_BUSES(2),
        .ADDR_BITS(28)
    ) gwct_inst (
        .clk     (HCLK),
        .rstn    (hwRstn),
        .uart_rx (GWCT_RX),
        .uart_tx (GWCT_TX),
        .PADDR   (gwct_PADDR),
        .PSEL    (gwct_PSEL),
        .PENABLE (gwct_PENABLE),
        .PWRITE  (gwct_PWRITE),
        .PWDATA  (gwct_PWDATA),
        .PSTRB   (gwct_PSTRB),
        .PPROT   (gwct_PPROT),
        .PRDATA  (gwct_PRDATA),
        .PREADY  (gwct_PREADY),
        .PSLVERR (gwct_PSLVERR)
    );

    // Extract bus 0 signals (APB peripherals)
    wire [31:0] gwct_apb_PADDR   = gwct_PADDR[31:0];
    wire        gwct_apb_PSEL    = gwct_PSEL[0];
    wire        gwct_apb_PENABLE = gwct_PENABLE[0];
    wire        gwct_apb_PWRITE  = gwct_PWRITE[0];
    wire [31:0] gwct_apb_PWDATA  = gwct_PWDATA[31:0];

    // Extract bus 1 signals (AHB via bridge)
    wire [31:0] gwct_ahb_PADDR   = gwct_PADDR[63:32];
    wire        gwct_ahb_PSEL    = gwct_PSEL[1];
    wire        gwct_ahb_PENABLE = gwct_PENABLE[1];
    wire        gwct_ahb_PWRITE  = gwct_PWRITE[1];
    wire [31:0] gwct_ahb_PWDATA  = gwct_PWDATA[63:32];
    wire [3:0]  gwct_ahb_PSTRB   = gwct_PSTRB[7:4];

    // =========================================================================
    // Bus 0: APB peripherals (CPU + GWCT shared)
    // =========================================================================
    wire gwct_apb_active = gwct_apb_PSEL;

    wire [31:0] apb_mux_PADDR   = gwct_apb_active ? gwct_apb_PADDR   : APB1PADDR;
    wire        apb_mux_PSEL    = gwct_apb_active ? gwct_apb_PSEL    : APB1PSEL;
    wire        apb_mux_PENABLE = gwct_apb_active ? gwct_apb_PENABLE : APB1PENABLE;
    wire        apb_mux_PWRITE  = gwct_apb_active ? gwct_apb_PWRITE  : APB1PWRITE;
    wire [31:0] apb_mux_PWDATA  = gwct_apb_active ? gwct_apb_PWDATA  : APB1PWDATA;

    wire [31:0] apb_slave_PRDATA;
    wire        apb_slave_PREADY;
    wire        apb_slave_PSLVERR;

    assign APB1PRDATA  = apb_slave_PRDATA;
    assign APB1PREADY  = gwct_apb_active ? 1'b0 : apb_slave_PREADY;
    assign APB1PSLVERR = apb_slave_PSLVERR;

    assign gwct_PRDATA[31:0] = apb_slave_PRDATA;
    assign gwct_PREADY[0]    = apb_slave_PREADY;
    assign gwct_PSLVERR[0]   = apb_slave_PSLVERR;

    apb_memmap apb_memmap_inst (
        .APBCLK   (APB1PCLK),
        .APBRESET (APB1PRESET),
        .PADDR    (apb_mux_PADDR),
        .PSEL     (apb_mux_PSEL),
        .PENABLE  (apb_mux_PENABLE),
        .PWRITE   (apb_mux_PWRITE),
        .PWDATA   (apb_mux_PWDATA),
        .PRDATA   (apb_slave_PRDATA),
        .PREADY   (apb_slave_PREADY),
        .PSLVERR  (apb_slave_PSLVERR)
    );

    // =========================================================================
    // Bus 1: APB2AHB bridge (GWCT only, no CPU arbiter needed)
    // =========================================================================
    wire [31:0] bridge_HADDR;
    wire        bridge_HWRITE;
    wire [2:0]  bridge_HSIZE;
    wire [1:0]  bridge_HTRANS;
    wire [31:0] bridge_HWDATA;
    wire        bridge_HSEL;
    wire [31:0] bridge_HRDATA;
    wire        bridge_HREADYOUT;
    wire [1:0]  bridge_HRESP;

    wire [31:0] ahb_bridge_PRDATA;
    wire        ahb_bridge_PREADY;
    wire        ahb_bridge_PSLVERR;

    apb2ahb_bridge apb2ahb_inst (
        .clk       (HCLK),
        .rstn      (hwRstn),
        
        // APB side (from GWCT bus 1)
        .PADDR     (gwct_ahb_PADDR),
        .PSEL      (gwct_ahb_PSEL),
        .PENABLE   (gwct_ahb_PENABLE),
        .PWRITE    (gwct_ahb_PWRITE),
        .PWDATA    (gwct_ahb_PWDATA),
        .PSTRB     (gwct_ahb_PSTRB),
        .PRDATA    (ahb_bridge_PRDATA),
        .PREADY    (ahb_bridge_PREADY),
        .PSLVERR   (ahb_bridge_PSLVERR),
        
        // AHB side (to arbiter)
        .HADDR     (bridge_HADDR),
        .HWRITE    (bridge_HWRITE),
        .HSIZE     (bridge_HSIZE),
        .HTRANS    (bridge_HTRANS),
        .HWDATA    (bridge_HWDATA),
        .HSEL      (bridge_HSEL),
        .HRDATA    (bridge_HRDATA),
        .HREADYOUT (bridge_HREADYOUT),
        .HRESP     (bridge_HRESP)
    );

    assign gwct_PRDATA[63:32] = ahb_bridge_PRDATA;
    assign gwct_PREADY[1]     = ahb_bridge_PREADY;
    assign gwct_PSLVERR[1]    = ahb_bridge_PSLVERR;

    // =========================================================================
    // AHB arbiter - CPU vs GWCT bridge (SRAM range only!)
    // =========================================================================
    // CRITICAL: Only arbitrate the SRAM range (0x80000000-0x80003FFF)
    // The DDR3 controller at 0x88000000 must NOT be arbitrated
    
    wire cpu_sram_access    = (AHB1HADDR >= 32'h80000000) && (AHB1HADDR < 32'h80004000);
    wire bridge_sram_access = (bridge_HADDR >= 32'h80000000) && (bridge_HADDR < 32'h80004000);
    
    wire gwct_ahb_active = bridge_HSEL && bridge_sram_access;

    wire [31:0] ahb_mux_HADDR  = gwct_ahb_active ? bridge_HADDR  : AHB1HADDR;
    wire        ahb_mux_HWRITE = gwct_ahb_active ? bridge_HWRITE : AHB1HWRITE;
    wire [2:0]  ahb_mux_HSIZE  = gwct_ahb_active ? bridge_HSIZE  : AHB1HSIZE;
    wire [1:0]  ahb_mux_HTRANS = gwct_ahb_active ? bridge_HTRANS : AHB1HTRANS;
    wire [31:0] ahb_mux_HWDATA = gwct_ahb_active ? bridge_HWDATA : AHB1HWDATA;
    wire        ahb_mux_HSEL   = gwct_ahb_active ? bridge_HSEL   : (AHB1HSEL && cpu_sram_access);

    // =========================================================================
    // AHB SRAM (accessible by both CPU and GWCT)
    // =========================================================================
    // IMPORTANT: The Cortex-M1 AHB1 interface connects to MULTIPLE peripherals:
    //   - 0x80000000-0x80003FFF: External SRAM (this module, arbitrated)
    //   - 0x88000000-0x88xxxxxx: DDR3 controller (inside Cortex-M1 IP, NOT arbitrated)
    //
    // The arbiter above only intercepts SRAM accesses. DDR3 controller
    // accesses go directly through without arbitration.
    
    wire [31:0] ahb_ram_hrdata;
    wire        ahb_ram_hreadyout;
    wire [1:0]  ahb_ram_hresp;

    ahb_sram #(
        .SIZE      (16384),
        .BASE_ADDR (32'h8000_0000)
    ) ahb_ram_inst (
        .HCLK       (HCLK),
        .HRESETn    (hwRstn),
        .HADDR      (ahb_mux_HADDR),
        .HWRITE     (ahb_mux_HWRITE),
        .HSIZE      (ahb_mux_HSIZE),
        .HTRANS     (ahb_mux_HTRANS),
        .HWDATA     (ahb_mux_HWDATA),
        .HSEL       (ahb_mux_HSEL),
        .HRDATA     (ahb_ram_hrdata),
        .HREADYOUT  (ahb_ram_hreadyout),
        .HRESP      (ahb_ram_hresp)
    );

    // Route SRAM responses back to both masters
    // Only stall CPU if GWCT is accessing SRAM, not for DDR3 accesses!
    assign AHB1HRDATA    = ahb_ram_hrdata;
    assign AHB1HREADYOUT = gwct_ahb_active ? 1'b0 : ahb_ram_hreadyout;
    assign AHB1HRESP     = cpu_sram_access ? ahb_ram_hresp : 2'b00;

    assign bridge_HRDATA    = ahb_ram_hrdata;
    assign bridge_HREADYOUT = ahb_ram_hreadyout;
    assign bridge_HRESP     = ahb_ram_hresp;

    // =========================================================================
    // Other peripherals
    // =========================================================================
    ws2812_driver ws_drv (
        .clk   (HCLK),
        .rstn  (hwRstn),
        .ws_out(WS2812_LED)
    );

endmodule