Rsp :: struct {
    cp0: [16]u32;
}

rsp_reset_registers :: () {
    rsp.cp0[4] = 1;
}
