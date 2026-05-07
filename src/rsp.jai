Rsp :: struct {
    cp0: [16]u32;
}

rsp_reset :: () {
    rsp.cp0[4] = 1;
}
