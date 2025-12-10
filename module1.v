//======================================================
// Top Level Module
// Connects SRAM Controller to SRAM Memory
//======================================================
module sram_system (
    input wire clk,
    input wire reset,

    // CPU interface
    input wire req,
    input wire rw,
    input wire [7:0] addr,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    output wire ready,

    // Burst mode controls
    input wire burst_en,
    input wire [2:0] burst_len,
    input wire [127:0] burst_data_in
);

    // Internal SRAM interface signals [cite: 920]
    wire [7:0] sram_addr;
    wire [15:0] sram_data;
    wire sram_ce;
    wire sram_oe;
    wire sram_we;

    // Instantiate SRAM Controller [cite: 939]
    sram_controller controller (
        .clk(clk),
        .reset(reset),
        .req(req),
        .rw(rw),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out),
        .ready(ready),
        .burst_en(burst_en),
        .burst_len(burst_len),
        .burst_data_in(burst_data_in),
        .sram_addr(sram_addr),
        .sram_data(sram_data),
        .sram_ce(sram_ce),
        .sram_oe(sram_oe),
        .sram_we(sram_we)
    );

    // Instantiate SRAM Memory [cite: 981]
    sram_memory #(
        .ADDR_WIDTH (8),
        .DATA_WIDTH (16),
        .MEM_SIZE(256)
    ) memory (
        .addr(sram_addr),
        .data(sram_data),
        .ce_n(sram_ce),
        .oe_n(sram_oe),
        .we_n(sram_we)
    );
endmodule