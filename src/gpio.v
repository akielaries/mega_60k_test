module gpio (
    input         HCLK,
    input         HRESET,

    input  [31:0] HADDR,
    input  [31:0] HWDATA,
    input         HWRITE,
    input  [1:0]  HTRANS,
    input         HSEL,

    output [31:0] HRDATA,
    output        HREADYOUT,
    output [1:0]  HRESP,

    output [31:0] GPIO_OUT  // connect to your GPIO logic
);

    // --------------------------------------------------
    // Address decode: assign this module to a region
    // Let's start at 0x80000010–0x8000001F
    // --------------------------------------------------
    wire addr_hit = HSEL & HTRANS[1] & (HADDR[31:4] == 28'h8000001);

    // --------------------------------------------------
    // AHB -> APB 32 Bridge
    // --------------------------------------------------
    wire [31:0] paddr_bridge;
    wire        penable_bridge;
    wire        pwrite_bridge;
    wire [31:0] pwdata_bridge;

    wire [31:0] HRDATA_bridge;
    wire        HREADYOUT_bridge;
    wire [1:0]  HRESP_bridge;

    AHB_to_APB_32_Bridge_Top gpio_bridge (
        // AHB side
        .hclk(HCLK),
        .hresetn(HRESET),
        .hsel(addr_hit),        // enable only for this GPIO module
        .hready_in(1'b1),
        .htrans(HTRANS),
        .haddr(HADDR),
        .hsize(3'b010),         // word
        .hprot(4'b0000),
        .hwrite(HWRITE),
        .hwdata(HWDATA),
        .apb2ahb_clken(1'b1),
        .hrdata(HRDATA_bridge),
        .hready(HREADYOUT_bridge),
        .hresp(HRESP_bridge),

        // APB side
        .pclk(HCLK),
        .presetn(HRESET),
        .pprot(),
        .pstrb(),
        .paddr(paddr_bridge),
        .penable(penable_bridge),
        .pwrite(pwrite_bridge),
        .pwdata(pwdata_bridge)
    );

    // --------------------------------------------------
    // Cheby-generated GPIO instance
    // --------------------------------------------------
    wire [31:0] prdata_gpio;
    wire        pready_gpio;

    gpio_regs u_gpio_regs (
        .pclk(HCLK),
        .presetn(HRESET),
        .paddr(paddr_bridge[2:2]),   // Cheby uses [2:2] word addressing
        .psel(addr_hit),              // bridge always selects this slave
        .pwrite(pwrite_bridge),
        .penable(penable_bridge),
        .pready(pready_gpio),
        .pwdata(pwdata_bridge),
        .pstrb(4'b1111),
        .prdata(prdata_gpio),
        .pslverr(),

        .out_o(GPIO_OUT),
        .stat_i(32'h00C0FFEE)        // hardcoded status
    );

    // --------------------------------------------------
    // Back to AHB
    // --------------------------------------------------
    assign HRDATA    = prdata_gpio;
    assign HREADYOUT = HREADYOUT_bridge;
    assign HRESP     = HRESP_bridge;

endmodule
