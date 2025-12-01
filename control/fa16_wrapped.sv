// fa16_wrapped.sv

// This is the macro Defination
// Black Box: Pins are matched with those in the layout
// Synthesis / PnR should treate the module as a hard-coded macro, it's internal implementation comes from GDS

/*
Testbench Annotation:
// When SIM_REV_MODEL is defined: behavioural reversible "inverter-style" model for simulation
// Otherwise: black-box macro for synthesis / Place & Route
*/

`ifdef SIM_REV_MODEL

// Simulation behavioural model of fa16_rev_wrapped.
// Simple self-inverse reversible mapping using bitwise inversion.
module fa16_rev_wrapped (
`ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
`endif
    input  logic        dir,     // 0: a-side -> s-side, 1: s-side -> a-side

    inout  wire [15:0]  a,
    inout  wire [15:0]  a_not,
    inout  wire [15:0]  b,
    inout  wire [15:0]  b_not,
    inout  wire         c0_f,
    inout  wire         c0_f_not,
    inout  wire         z,
    inout  wire         z_not,

    inout  wire [15:0]  s,
    inout  wire [15:0]  s_not,
    inout  wire [15:0]  a_b,
    inout  wire [15:0]  a_not_b,
    inout  wire         c0_b,
    inout  wire         c0_b_not,
    inout  wire         c15,
    inout  wire         c15_not
);
    // Internal drivers for all pins
    logic [15:0] a_drv, a_not_drv;
    logic [15:0] b_drv, b_not_drv;
    logic        c0_f_drv, c0_f_not_drv;
    logic        z_drv,    z_not_drv;

    logic [15:0] s_drv, s_not_drv;
    logic [15:0] a_b_drv, a_not_b_drv;
    logic        c0_b_drv, c0_b_not_drv;
    logic        c15_drv,  c15_not_drv;

    // Connect drivers to the inout pins
    assign a        = a_drv;
    assign a_not    = a_not_drv;
    assign b        = b_drv;
    assign b_not    = b_not_drv;
    assign c0_f     = c0_f_drv;
    assign c0_f_not = c0_f_not_drv;
    assign z        = z_drv;
    assign z_not    = z_not_drv;

    assign s        = s_drv;
    assign s_not    = s_not_drv;
    assign a_b      = a_b_drv;
    assign a_not_b  = a_not_b_drv;
    assign c0_b     = c0_b_drv;
    assign c0_b_not = c0_b_not_drv;
    assign c15      = c15_drv;
    assign c15_not  = c15_not_drv;

    // Simple reversible behaviour:
    // dir = 0: (a,b,c0_f,z) -> (s,a_b,c0_b,c15) = bitwise inversion
    // dir = 1: (s,a_b,c0_b,c15) -> (a,b,c0_f,z) = bitwise inversion
    //
    // Apply it twice and we can get back the original input.
    always @* begin
        // Default all drivers to high-Z so we never fight with fa16_rev_ctrl
        a_drv        = {16{1'bz}};
        a_not_drv    = {16{1'bz}};
        b_drv        = {16{1'bz}};
        b_not_drv    = {16{1'bz}};
        c0_f_drv     = 1'bz;
        c0_f_not_drv = 1'bz;
        z_drv        = 1'bz;
        z_not_drv    = 1'bz;

        s_drv        = {16{1'bz}};
        s_not_drv    = {16{1'bz}};
        a_b_drv      = {16{1'bz}};
        a_not_b_drv  = {16{1'bz}};
        c0_b_drv     = 1'bz;
        c0_b_not_drv = 1'bz;
        c15_drv      = 1'bz;
        c15_not_drv  = 1'bz;

        if (dir == 1'b0) begin
            // Forward: drive S-side from A-side (invert)
            s_drv        = ~a;
            s_not_drv    =  a;       // double-rail: s_not = ~s = a
            a_b_drv      = ~b;
            a_not_b_drv  =  b;
            c0_b_drv     = ~c0_f;
            c0_b_not_drv =  c0_f;
            c15_drv      = ~z;
            c15_not_drv  =  z;
            // A-side pins are left Z here; fa16_rev_ctrl drives them.
        end
        else begin
            // Backward: drive A-side from S-side (invert)
            a_drv        = ~s;
            a_not_drv    =  s;
            b_drv        = ~a_b;
            b_not_drv    =  a_b;
            c0_f_drv     = ~c0_b;
            c0_f_not_drv =  c0_b;
            z_drv        = ~c15;
            z_not_drv    =  c15;
            // S-side pins are left Z here; fa16_rev_ctrl drives them.
        end
    end

endmodule

`else

// Synthesis / Place & Route version: real hard macro, no behaviour.
// This is the one we will use in LibreLane.

(* black_box, keep_hierarchy = "yes" *)
module fa16_rev_wrapped (
`ifdef USE_POWER_PINS
    inout wire VDD,
    inout wire VSS,
`endif

    inout  wire [15:0] a,
    inout  wire [15:0] a_not,
    inout  wire [15:0] b,
    inout  wire [15:0] b_not,
    inout  wire        c0_f,
    inout  wire        c0_f_not,
    inout  wire        z,
    inout  wire        z_not,

    inout  wire [15:0] s,
    inout  wire [15:0] s_not,
    inout  wire [15:0] a_b,
    inout  wire [15:0] a_not_b,
    inout  wire        c0_b,
    inout  wire        c0_b_not,
    inout  wire        c15,
    inout  wire        c15_not
);
// Real RTL content comes for custom layout
endmodule

`endif