// =============================================================================
// top.v — Gowin EMPU Cortex-M1 + GWCT debug module
//
// GWCT (Gowin Watch & Control Tool) is a UART-based debug master that can
// read and write APB-mapped registers independently of the Cortex-M1.
//
// APB bus arbitration (simple priority mux):
//   - GWCT has priority when it has an active transaction (gwct_apb_sel=1)
//   - Cortex-M1 APB bridge gets the bus otherwise
//
// This means: if GWCT is active, the Cortex-M1 cannot access APB until
// GWCT finishes its single transaction (~4-5 APB cycles). This is fine
// for debug purposes.
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
    // 0.5 second counter at 50mhz drives BOOT_LED
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
    // APB1 wires from Cortex-M1 APB bridge
    // =========================================================================
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
    // =========================================================================
    // DDR3 configuration
    // =========================================================================

    wire MCU_CLK;           //MCU input clock   50MHz
    wire DDR_CLK;           //DDR3 input clock  50MHz
    wire DDR_MEM_CLK;       //DDR3 memory clock 200MHz


    wire pll_lock;
    reg  pll_lock_r;
    reg  pll_lock_rr;
    wire mdrp_inc;
    wire [1:0] mdrp_op;
    wire [7:0] mdrp_wdata;
    wire [7:0] mdrp_rdata;

    assign mdrp_inc = 1'b0;
    assign mdrp_op = 2'b0;
    assign mdrp_wdata = 8'b0;


    always@(posedge HCLK)
    begin
        pll_lock_r <= pll_lock;
        pll_lock_rr <= pll_lock_r;
    end

    //Gowin_PLL instantiation
    Gowin_PLL u_Gowin_PLL
    (
        .lock(pll_lock),
        .clkout0(),
        .clkout2(DDR_MEM_CLK),
        .mdrdo(mdrp_rdata),
        .clkin(HCLK),
        .reset(1'b0),
        .mdclk(HCLK),
        .mdopc(mdrp_op),
        .mdainc(mdrp_inc),
        .mdwdi(mdrp_wdata),
        .pll_init_bypass(1'b0)
    );

    assign MCU_CLK = HCLK;
    assign DDR_CLK = HCLK;

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
//        .APB1PPROT(APB1PPROT),
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

        // Clock connections
        .DDR_MEM_CLK_I(DDR_MEM_CLK),
        .DDR_CLK_I(DDR_CLK),
        .DDR_LOCK_I(pll_lock),
        .DDR_RSTN_I(hwRstn),

        .HCLK(HCLK),
        .hwRstn(hwRstn)
    );

    // =========================================================================
    // GWCT debug bridge debug master with N-bus support
    // =========================================================================
    // Single bus configuration
    wire [31:0] gwct_PADDR;
    wire        gwct_PSEL;
    wire        gwct_PENABLE;
    wire        gwct_PWRITE;
    wire [31:0] gwct_PWDATA;
    wire [3:0]  gwct_PSTRB;
    wire [2:0]  gwct_PPROT;

    // Slave response wires
    wire [31:0] slave_PRDATA;
    wire        slave_PREADY;
    wire        slave_PSLVERR;

    gwct_debug_bridge_n #(
        .CLK_HZ(50_000_000),
        .BAUD(115_200),
        .NUM_APB_BUSES(1),          // Currently using 1 bus (APB1)
        .ADDR_BITS(28)              // Address decode uses addr[31:28]
    ) gwct_inst (
        .clk        (HCLK),
        .rstn       (hwRstn),
        
        // UART pins
        .uart_rx    (GWCT_RX),
        .uart_tx    (GWCT_TX),
        
        // APB master signals (single bus = simple wires)
        .PADDR      (gwct_PADDR),
        .PSEL       (gwct_PSEL),
        .PENABLE    (gwct_PENABLE),
        .PWRITE     (gwct_PWRITE),
        .PWDATA     (gwct_PWDATA),
        .PSTRB      (gwct_PSTRB),
        .PPROT      (gwct_PPROT),
        .PRDATA     (slave_PRDATA),
        .PREADY     (slave_PREADY),
        .PSLVERR    (slave_PSLVERR)
    );

    // =========================================================================
    // APB bus mux — GWCT takes priority over Cortex-M1
    //
    //   gwct_apb_sel = 1  →  GWCT drives the bus
    //   gwct_apb_sel = 0  →  Cortex-M1 drives the bus
    // =========================================================================
    wire gwct_apb_sel = gwct_PSEL;

    wire [31:0] mux_PADDR   = gwct_apb_sel ? gwct_PADDR   : APB1PADDR;
    wire        mux_PSEL    = gwct_apb_sel ? gwct_PSEL    : APB1PSEL;
    wire        mux_PENABLE = gwct_apb_sel ? gwct_PENABLE : APB1PENABLE;
    wire        mux_PWRITE  = gwct_apb_sel ? gwct_PWRITE  : APB1PWRITE;
    wire [31:0] mux_PWDATA  = gwct_apb_sel ? gwct_PWDATA  : APB1PWDATA;

    // Feed response back to Cortex-M1 (stall if GWCT owns bus)
    assign APB1PRDATA  = slave_PRDATA;
    assign APB1PREADY  = gwct_apb_sel ? 1'b0 : slave_PREADY;
    assign APB1PSLVERR = slave_PSLVERR;

    // =========================================================================
    // apb_memmap slave — sees muxed bus
    // =========================================================================
    apb_memmap apb_memmap_inst (
        .APBCLK   (APB1PCLK),
        .APBRESET (APB1PRESET),
        .PADDR    (mux_PADDR),
        .PSEL     (mux_PSEL),
        .PENABLE  (mux_PENABLE),
        .PWRITE   (mux_PWRITE),
        .PWDATA   (mux_PWDATA),
        .PRDATA   (slave_PRDATA),
        .PREADY   (slave_PREADY),
        .PSLVERR  (slave_PSLVERR)
    );

    reg [23:0] ws_color;

    ws2812_driver ws_drv (
        .clk(HCLK),
        .rstn(hwRstn),
        .ws_out(WS2812_LED)
    );
/*
    uart_hello hello_inst (
        .clk  (HCLK),
        .rstn (hwRstn),
        .tx   (GWCT_TX)
    );
*/
endmodule