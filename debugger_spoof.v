// This module intercepts debugger reads and spoofs the PID/CID registers.
module debugger_spoof (
    input wire [31:0] HADDR,
    input wire HSEL,
    input wire HREADY,
    input wire [1:0] HTRANS,
    output wire [31:0] HRDATA
);

    // Default to passing through the real HRDATA
    // (This will require connecting the real HRDATA to this module's input)
    reg [31:0] spoofed_hrdata;

    // The real HRDATA from the bus matrix will be connected here
    wire [31:0] real_hrdata;

    // TODO: Connect this to the real bus matrix
    assign real_hrdata = 32'h0;

    always @(*) begin
        if (HSEL && HREADY && (HTRANS == 2'b10)) begin // Only when a transfer is active
            case (HADDR[11:0])
                // PIDR0-3
                12'hFE0: spoofed_hrdata = 32'h00000091;
                12'hFE4: spoofed_hrdata = 32'h000000b4;
                12'hFE8: spoofed_hrdata = 32'h0000000b;
                12'hFEC: spoofed_hrdata = 32'h00000000;
                // CIDR0-3 (Preamble)
                12'hFF0: spoofed_hrdata = 32'h0d;
                12'hFF4: spoofed_hrdata = 32'h00;
                12'hFF8: spoofed_hrdata = 32'h05;
                12'hFFC: spoofed_hrdata = 32'hb1;
                default: spoofed_hrdata = real_hrdata;
            endcase
        end else begin
            spoofed_hrdata = real_hrdata;
        end
    end

    assign HRDATA = spoofed_hrdata;

endmodule
