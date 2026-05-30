Rsp :: struct {
    pc: u32;
    cp0: [16]u32;
}

rsp_reset :: () {
    rsp.cp0[Sp.STATUS] = xx Sp_Status_R.HALT;
}
