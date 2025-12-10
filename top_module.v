`timescale 1ns / 1ps
//==================================================
// SRAM Controller Module
// Handles the protocol and timing for accessing SRAM
//==================================================
module sram_controller (
    input wire clk,
    input wire reset,

    // CPU side interface
    input wire req,
    input wire rw,           // 1=read, 0=write
    input wire [7:0] addr,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output reg ready,

    // Burst mode controls
    input wire burst_en,
    input wire [2:0] burst_len,
    input wire [127:0] burst_data_in,

    // SRAM interface (connects to SRAM module)
    output reg [7:0] sram_addr,
    inout wire [15:0] sram_data,
    output reg sram_ce,      // Chip enable (active low)
    output reg sram_oe,      // Output enable (active low)
    output reg sram_we       // Write enable (active low)
);

    // Internal burst array (for easy indexing) [cite: 515]
    wire [15:0] burst_array [0:7];
    assign burst_array[0] = burst_data_in[15:0];
    assign burst_array[1] = burst_data_in[31:16];
    assign burst_array[2] = burst_data_in[47:32];
    assign burst_array[3] = burst_data_in[63:48];
    assign burst_array[4] = burst_data_in[79:64];
    assign burst_array[5] = burst_data_in[95:80];
    assign burst_array[6] = burst_data_in[111:96];
    assign burst_array[7] = burst_data_in[127:112];

    // State encoding [cite: 522]
    localparam IDLE    = 2'b00;
    localparam PERFORM = 2'b01;
    localparam DONE    = 2'b10;

    reg [1:0] state, next_state;
    reg [7:0] addr_reg;
    reg [2:0] count_reg;
    reg rw_reg;
    reg [2:0] burst_idx;
    reg burst_en_reg;

    // Next state logic [cite: 552]
    always @(*) begin
        case (state)
            IDLE:    next_state = req ? PERFORM : IDLE;
            PERFORM: next_state = (count_reg == 0) ? DONE : PERFORM;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Control signal generation [cite: 576]
    always @(*) begin
        // Default: all control signals inactive (high) [cite: 578]
        sram_ce   = 1'b1;
        sram_oe   = 1'b1;
        sram_we   = 1'b1;
        sram_addr = 8'h00;
        ready     = 1'b0;

        case (state)
            PERFORM: begin
                sram_addr = addr_reg; [cite: 595]
                if (rw_reg) begin
                    // Read operation [cite: 599]
                    sram_ce = 1'b0; // Enable chip [cite: 601, 602]
                    sram_oe = 1'b0; // Enable output [cite: 605, 607]
                    sram_we = 1'b1; // Write disabled [cite: 606, 608]
                end else begin
                    // Write operation [cite: 612]
                    sram_ce = 1'b0; // Enable chip [cite: 614, 615]
                    sram_oe = 1'b1; // Output disabled [cite: 617, 618]
                    sram_we = 1'b0; // Enable write [cite: 619, 620]
                end
            end
            DONE: ready = 1'b1; [cite: 626]
        endcase
    end

    // Tri-state data bus drive during write, high-Z during read [cite: 634]
    assign sram_data = (!sram_ce && !sram_we) ?
                       (burst_en_reg ? burst_array[burst_idx] : data_in) :
                       16'bz; [cite: 635, 636, 637, 639]

    // Sequential logic [cite: 642]
    always @(posedge clk or posedge reset) begin
        if (reset) begin [cite: 651]
            state        <= IDLE; [cite: 653]
            addr_reg     <= 8'h00; [cite: 654]
            count_reg    <= 3'h0; [cite: 655]
            rw_reg       <= 1'b0; [cite: 662]
            data_out     <= 16'h0000; [cite: 663]
            burst_idx    <= 3'b000; [cite: 664]
            burst_en_reg <= 1'b0; [cite: 669]
        end else begin
            state <= next_state; [cite: 670]
            case (state)
                IDLE: begin [cite: 675]
                    if (req) begin [cite: 676]
                        addr_reg     <= addr; [cite: 678, 679]
                        rw_reg       <= rw; [cite: 681, 682]
                        burst_en_reg <= burst_en; [cite: 684]
                        burst_idx    <= 3'b000; [cite: 686, 687]
                        if (burst_en) begin [cite: 690, 691]
                            // Burst transfer
                            count_reg <= burst_len; [cite: 695]
                        end else begin
                            // Single transfer
                            count_reg <= 3'b000; [cite: 716]
                        end
                    end
                end
                PERFORM: begin [cite: 719]
                    // Capture read data [cite: 720]
                    if (rw_reg) begin [cite: 721]
                        data_out <= sram_data; [cite: 723]
                    end
                    // Check for completion
                    if (count_reg == 0) begin [cite: 725]
                        // Last transfer complete, go to DONE next cycle
                    end else begin
                        // More transfers remaining
                        count_reg <= count_reg - 1; [cite: 731, 732]
                        // Increment address for next transfer
                        addr_reg <= addr_reg + 1; [cite: 734]
                        // Increment burst index if in burst mode
                        if (burst_en_reg && count_reg != 0) begin [cite: 735]
                            burst_idx <= burst_idx + 1; [cite: 736]
                        end
                    end
                end
                DONE: begin
                    // Transaction complete [cite: 756]
                end
            endcase
        end
    end
endmodule