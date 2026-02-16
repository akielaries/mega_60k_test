module system_info (
    input         HCLK,
    input         HRESET,

    input  [31:0] HADDR,
    input  [31:0] HWDATA,
    input         HWRITE,
    input  [1:0]  HTRANS,
    input         HSEL,

    output [31:0] HRDATA,
    output        HREADYOUT,
    output [1:0]  HRESP
);



    // --------------------------------------------------
    // Version constants
    // --------------------------------------------------
    localparam [15:0] VERSION_MAJOR = 16'd1;
    localparam [7:0]  VERSION_MINOR  = 8'd2;
    localparam [7:0]  VERSION_PATCH  = 8'd3;

    // --------------------------------------------------
    // Address decode: sysinfo occupies 0x8000_0000–0x8000_000F
    // --------------------------------------------------
    wire addr_hit = HSEL & HTRANS[1] & (HADDR[31:4] == 28'h8000_000);

    // --------------------------------------------------
    // Wires for bridge outputs (APB side)
    // --------------------------------------------------
    wire [31:0] paddr_bridge;
    wire        penable_bridge;
    wire        pwrite_bridge;
    wire [31:0] pwdata_bridge;

    wire [31:0] HRDATA_bridge;
    wire        HREADYOUT_bridge;
    wire [1:0]  HRESP_bridge;

    // --------------------------------------------------
    // AHB -> APB 32 Bridge instance
    // --------------------------------------------------
    AHB_to_APB_32_Bridge_Top sysinfo_bridge (
        // AHB side
        .hclk(HCLK),
        .hresetn(HRESET),
        .hsel(addr_hit),           // only active for sysinfo range
        .hready_in(1'b1),
        .htrans(HTRANS),
        .haddr(HADDR),
        .hsize(3'b010),            // word transfer
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
    // Cheby-generated sysinfo_regs instance
    // --------------------------------------------------
    wire [31:0] prdata_cheby;
    wire        pready_cheby;

    // drive psel directly from addr_hit
    wire psel_cheby = addr_hit;

    sysinfo_regs u_regs (
        .pclk(HCLK),
        .presetn(HRESET),
        .paddr(paddr_bridge[3:2]),  // word addressing
        .psel(psel_cheby),          // directly from addr_hit
        .pwrite(pwrite_bridge),
        .penable(penable_bridge),
        .pready(pready_cheby),
        .pwdata(pwdata_bridge),
        .pstrb(4'b1111),
        .prdata(prdata_cheby),
        .pslverr(),

        // Register values
        .magic_i(32'hDEADBEEF),
        .mfg_code_A_i(32'h476F7769), // "Gowi"
        .mfg_code_B_i(32'h6E36304B), // "n60K"
        .version_patch_i(VERSION_PATCH),
        .version_minor_i(VERSION_MINOR),
        .version_major_i(VERSION_MAJOR)
    );

    // --------------------------------------------------
    // Back to AHB
    // --------------------------------------------------
    assign HRDATA    = prdata_cheby;
    assign HREADYOUT = HREADYOUT_bridge; 
    assign HRESP     = HRESP_bridge;

endmodule
