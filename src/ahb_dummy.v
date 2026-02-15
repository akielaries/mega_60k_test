module ahb_dummy (
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

    // ------------------------------------------------------------
    // Constant read value
    // ------------------------------------------------------------
    localparam [31:0] MAGIC_VALUE = 32'hDEADBEEF;

    // Always return constant
    assign HRDATA = MAGIC_VALUE;

    // Always ready / always OK
    assign HREADYOUT = 1'b1;
    assign HRESP     = 2'b00;

endmodule
