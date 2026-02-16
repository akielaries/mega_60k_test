module apb_memmap (
    input        APBCLK,
    input        APBRESET,
    input [31:0] PADDR,
    input        PSEL,
    input        PENABLE,
    input        PWRITE,
    input [31:0] PWDATA,
    output [31:0] PRDATA,
    output       PREADY,
    output       PSLVERR
);

    // Sub-block wires
    wire [31:0] sysinfo_prdata;
    wire        sysinfo_pready;
    wire [31:0] gpio_prdata;
    wire        gpio_pready;

    // Decode hits
    wire sysinfo_sel = (PADDR[19:0] < 20'h10);
    wire gpio_sel    = (PADDR[19:0] >= 20'h10 &&
                        PADDR[19:0] < 20'h20);

    // Instantiate sub-blocks
    system_info sysinfo_inst (
        .APBCLK(APBCLK),
        .APBRESET(APBRESET),
        .PADDR(PADDR),
        .PSEL(PSEL & sysinfo_sel),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(sysinfo_prdata),
        .PREADY(sysinfo_pready),
        .PSLVERR()
    );

    wire [31:0] gpio_out;
    wire [31:0] gpio_stat = 32'h00C0FFEE;

    gpio gpio_inst (
        .APBCLK   (APBCLK),
        .APBRESET (APBRESET),

        .PADDR    (PADDR),
        .PSEL     (PSEL & gpio_sel),
        .PENABLE  (PENABLE),
        .PWRITE   (PWRITE),
        .PWDATA   (PWDATA),

        .PRDATA   (gpio_prdata),
        .PREADY   (gpio_pready),
        .PSLVERR  (),

        .gpio_out (gpio_out),
        .gpio_stat(gpio_stat)
    );

    // Route back to APB bus
    assign PRDATA =
        sysinfo_sel ? sysinfo_prdata :
        gpio_sel    ? gpio_prdata :
                      32'h00000000;

    assign PREADY =
        sysinfo_sel ? sysinfo_pready :
        gpio_sel    ? gpio_pready :
                      1'b1;

    assign PSLVERR =
        (PSEL && !(sysinfo_sel || gpio_sel));

endmodule
