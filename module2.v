//=============
// SRAM Memory Module
// Behavioral model of actual SRAM chip
//============================================
module sram_memory #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16,
    parameter MEM_SIZE   = 256
)(
    // SRAM interface
    input wire [ADDR_WIDTH-1:0] addr,
    inout wire [DATA_WIDTH-1:0] data,
    input wire ce_n,         // Chip enable (active low)
    input wire oe_n,         // Output enable (active low)
    input wire we_n          // Write enable (active low)
);

    // Internal memory array [cite: 810]
    reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1]; [cite: 812]

    // Internal data register for read operations [cite: 815]
    reg [DATA_WIDTH-1:0] data_out; [cite: 817]

    // Write operation (synchronous for simulation purposes) [cite: 823]
    always @(*) begin
        if (!ce_n && !we_n) begin [cite: 824]
            mem[addr] = data; [cite: 825]
        end
    end

    // Read operation [cite: 832]
    always @(*) begin [cite: 834]
        if (!ce_n && !oe_n && we_n) begin [cite: 839]
            data_out = mem[addr]; [cite: 840]
        end else begin
            data_out = {DATA_WIDTH{1'bz}}; [cite: 842]
        end
    end

    // Tri-state output [cite: 849]
    assign data = (!ce_n && !oe_n && we_n) ? data_out : {DATA_WIDTH{1'bz}}; [cite: 850]

    // Initialize memory to zero (for simulation) [cite: 851]
    integer i;
    initial begin
        for (i=0; i < MEM_SIZE; i=i+1) begin [cite: 865]
            mem[i] = {DATA_WIDTH{1'b0}}; [cite: 865]
        end
    end
endmodule