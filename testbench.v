`timescale 1ns / 1ps
module sram_system_tb;
// Clock and Reset
reg clk;
reg reset;
integer i;

// CPU side signals
reg req;
reg rw;
reg [7:0] addr;
reg [15:0] data_in;
wire [15:0] data_out;
wire ready;

// Burst mode controls
reg burst_en;
reg [2:0] burst_len;
reg [127:0] burst_data_in;

// Internal SRAM interface signals (connecting controller to memory)
wire [7:0] sram_addr;
wire [15:0] sram_data;
wire sram_ce;
wire sram_oe;
wire sram_we;

// Instantiate SRAM Controller
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

// Instantiate SRAM Memory
sram_memory #(
.ADDR_WIDTH (8),
.DATA_WIDTH (16),
.MEM_SIZE (256)
) memory (
.addr(sram_addr),
.data(sram_data),
.ce_n(sram_ce),
.oe_n(sram_oe),
.we_n(sram_we)
);

// Clock generation 10ns period (100MHz)
initial begin
clk = 0;
forever #25 clk=~clk;
end

// Test stimulus
initial begin
// Initialize signals
reset = 1;
req = 0;
rw = 0;
addr = 0;
data_in = 0;
burst_en = 0;
burst_len = 0;
burst_data_in = 0;

$display("========================================");
$display("Starting Modular SRAM System Test");
$display("========================================");

// Release reset
#20;
reset = 0;
#20;

//======================
// TEST 1: Single Write
//======================
$display("\n--- Test 1: Write 0x1234 to Address 0x0A ---");
@(posedge clk);
addr = 8'h0A;
data_in = 16'h1234;
rw = 0;
burst_en = 0;
req = 1;

@(posedge clk);
req = 0;
wait (ready == 1);
$display("Time=%0t: Write operation completed", $time);
@(posedge clk);
#20;

//======================
// TEST 2: Single Read
//======================
$display("\n--- Test 2: Read from Address 0x0A ---");
@(posedge clk);
addr = 8'h0A;
rw = 1;
burst_en = 0;
req = 1;
@(posedge clk);
req = 0;
wait (ready == 1);
$display("Time=%0t: Read operation completed", $time);
$display("Time=%0t: Data read = 0x%04h", $time, data_out);
@(posedge clk);
#20;

// Verify Test 1 & 2
$display("\n========================================");
if (data_out == 16'h1234) begin
    $display("TEST 1 & 2 PASSED!");
    $display("Expected: 0x1234, Got: 0x%04h", data_out);
end else begin
    $display("TEST 1 & 2 FAILED!");
    $display ("Expected: 0x1234, Got: 0x%04h", data_out);
end
$display("========================================");
#50;

//======================
// TEST 3: Second Single Write
//======================
$display("\n--- Test 3: Write 0x9999 to Address 0x0B ---");
@(posedge clk);
addr = 8'h0B;
data_in = 16'h9999;
rw = 0;
burst_en = 0;
req = 1;
@(posedge clk);
req = 0;
wait (ready == 1);
$display("Time=%0t: Write operation completed", $time);
@(posedge clk);
#20;

//======================
// TEST 4: Second Single Read
//======================
$display("\n--- Test 4: Read from Address 0x0B ---");
@(posedge clk);
addr = 8'h0B;
rw = 1;
burst_en = 0;
req = 1;
@(posedge clk);
req = 0;
wait (ready == 1);
$display("Time=%0t: Read operation completed", $time);
$display("Time=%0t: Data read = 0x%04h", $time, data_out);
@(posedge clk);
#20;

// Verify Test 3 & 4
$display("\n========================================");
if (data_out == 16'h9999) begin
    $display("TEST 3 & 4 PASSED!");
    $display("Expected: 0x9999, Got: 0x%04h", data_out);
end else begin
    $display("TEST 3 & 4 FAILED!");
    $display("Expected: 0x9999, Got: 0x%04h", data_out);
end
$display("========================================");
#50;

//======================================
// TEST 5: BURST WRITE
//======================================
$display("\n\n========================================");
$display("Starting BURST MODE Tests");
$display("========================================");
$display("\n--- Test 5: Burst Write to Address 0x20 (4 words) ---");

// Prepare burst data
burst_data_in[15:0] = 16'hAAAA; // Addr 0x20
burst_data_in[31:16] = 16'hBBBB; // Addr 0x21
burst_data_in[47:32] = 16'hCCCC; // Addr 0x22
burst_data_in[63:48] = 16'hDDDD; // Addr 0x23
burst_data_in[127:64] = 64'h0;

@(posedge clk);
addr = 8'h20;
rw = 0;
burst_en = 1;
burst_len = 3'b011; // 4 transfers
req = 1;

@(posedge clk);
req = 0;
wait (ready == 1);
$display("Time=%0t: Burst Write completed", $time);
@(posedge clk);
#20;

//======================
// TEST 6: VERIFY BURST WRITE
//======================
$display("\n--- Test 6: Verify Burst Write---");
// Read back all 4 addresses
for (i = 0; i < 4; i = i + 1) begin
    @(posedge clk);
    addr = 8'h20 + i;
    rw = 1;
    burst_en = 0;
    req = 1;
    @(posedge clk);
    req = 0;
    wait (ready == 1);

    case (i)
        0: $display("Time=%0t: Read Addr 0x20 = 0x%04h (Expected: 0xAAAA)", $time, data_out);
        1: $display("Time=%0t: Read Addr 0x21 = 0x%04h (Expected: 0xBBBB)", $time, data_out);
        2: $display("Time=%0t: Read Addr 0x22 = 0x%04h (Expected: 0xCCCC)", $time, data_out);
        3: $display("Time=%0t: Read Addr 0x23 = 0x%04h (Expected: 0xDDDD)", $time, data_out);
    endcase
    @(posedge clk);
    #20;
end

// Final verification message
$display("\n========================================");
$display("BURST MODE TEST COMPLETED");
$display ("Please verify the output above matches expected values");
$display("========================================");

$display("\n\n========================================");
$display("ALL TESTS COMPLETED");
$display("========================================");
#100;
$finish;
end

// Monitor for debugging Fixed hierarchy path
initial begin
$monitor("Time=%0t: State =%b, req =%b, ready =%b, addr =0x%02h, data_out=0x%04h | SRAM_CE =%b, SRAM_OE =%b, SRAM_WE =%b",
$time, controller.state, req, ready, addr, data_out,
sram_ce, sram_oe, sram_we);
end

// Timeout watchdog
initial begin
#100000;
$display("\nERROR: Simulation timeout!");
$finish;
end

// Waveform dump
initial begin
$dumpfile("sram_system_tb.vcd");
$dumpvars(0, sram_system_tb);
end

endmodule