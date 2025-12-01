// tb_fa16_rev_control.sv
`timescale 1ns/1ps
`define USE_POWER_PINS   // keep consistent with your DUT

module tb_fa16_rev_ctrl;

    // Direction control
    reg         dir;

    // Forward interface (dir = 0)
    reg  [15:0] f_a;
    reg  [15:0] f_b;
    reg         f_c0_f;
    reg         f_z;

    wire [15:0] f_s;
    wire [15:0] f_a_b;
    wire        f_c0_b;
    wire        f_c15;

    // Backward interface (dir = 1)
    reg  [15:0] r_s;
    reg  [15:0] r_a_b;
    reg         r_c0_b;
    reg         r_c15;

    wire [15:0] r_a;
    wire [15:0] r_b;
    wire        r_c0_f;
    wire        r_z;

`ifdef USE_POWER_PINS
    wire VDD = 1'b1;
    wire VSS = 1'b0;
`endif

    // Instantiate DUT
    fa16_rev_ctrl dut (
    `ifdef USE_POWER_PINS
        .VDD   (VDD),
        .VSS   (VSS),
    `endif
        .dir   (dir),

        .f_a   (f_a),
        .f_b   (f_b),
        .f_c0_f(f_c0_f),
        .f_z   (f_z),

        .f_s   (f_s),
        .f_a_b (f_a_b),
        .f_c0_b(f_c0_b),
        .f_c15 (f_c15),

        .r_s   (r_s),
        .r_a_b (r_a_b),
        .r_c0_b(r_c0_b),
        .r_c15 (r_c15),

        .r_a   (r_a),
        .r_b   (r_b),
        .r_c0_f(r_c0_f),
        .r_z   (r_z)
    );

    // For logging / checking
    integer i;
    integer error_count = 0;

    reg [15:0] orig_a, orig_b;
    reg        orig_c0_f, orig_z;
    reg [15:0] saved_s, saved_a_b;
    reg        saved_c0_b, saved_c15;

    // VCD dump
    initial begin
        $dumpfile("fa16_rev_ctrl_tb.vcd");
        $dumpvars(0, tb_fa16_rev_ctrl);
    end

    initial begin
        // Initial values
        dir      = 1'b0;
        f_a      = 16'h0000;
        f_b      = 16'h0000;
        f_c0_f   = 1'b0;
        f_z      = 1'b0;

        r_s      = 16'h0000;
        r_a_b    = 16'h0000;
        r_c0_b   = 1'b0;
        r_c15    = 1'b0;

        #10; // let things settle

        // Run multiple random tests
        for (i = 0; i < 100; i = i + 1) begin
            // -------------------------------
            // Step 1: Forward (dir = 0)
            // -------------------------------
            orig_a    = $random;
            orig_b    = $random;
            orig_c0_f = $random & 1'b1;
            orig_z    = $random & 1'b1;

            f_a      = orig_a;
            f_b      = orig_b;
            f_c0_f   = orig_c0_f;
            f_z      = orig_z;

            dir      = 1'b0;

            #20; // allow combinational logic to settle

            saved_s    = f_s;
            saved_a_b  = f_a_b;
            saved_c0_b = f_c0_b;
            saved_c15  = f_c15;

            // -------------------------------
            // Step 2: Backward (dir = 1)
            // -------------------------------
            r_s    = saved_s;
            r_a_b  = saved_a_b;
            r_c0_b = saved_c0_b;
            r_c15  = saved_c15;

            #5;
            dir    = 1'b1;

            #20; // wait for backward propagation

            // -------------------------------
            // Step 3: Check round-trip
            // -------------------------------
            if (r_a    !== orig_a ||
                r_b    !== orig_b ||
                r_c0_f !== orig_c0_f ||
                r_z    !== orig_z) begin
                $display("[ERROR] iter %0d: round-trip mismatch", i);
                $display("        orig: A=%h B=%h C0=%b Z=%b",
                         orig_a, orig_b, orig_c0_f, orig_z);
                $display("        back: A=%h B=%h C0=%b Z=%b",
                         r_a, r_b, r_c0_f, r_z);
                error_count = error_count + 1;
            end
            else begin
                $display("[OK]    iter %0d: reversible round-trip passed.", i);
            end

            // Prepare for next iteration
            dir = 1'b0;
            #10;
        end

        $display("================================");
        $display("Simulation finished, error_count = %0d", error_count);
        if (error_count == 0)
            $display("All round-trip tests PASSED.");
        else
            $display("Some round-trip tests FAILED.");
        $display("================================");

        $finish;
    end

endmodule
