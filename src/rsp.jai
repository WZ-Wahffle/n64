Rsp :: struct {
    gpr: [32]u32;
    cp0: [16]u32;
    pc: u32;

    bp: [32]u32;
    remaining_cycles := 0.0;
}

rsp_instr_lut := (_:u32).[
    rsp_special,
    rsp_regimm,
];

rsp_special_lut := (_:u32).[
];

rsp_regimm_lut := (_:u32).[
];

rsp_next :: () -> u32 {
    ret := mem.imem._32[rsp.pc];
    rsp.pc += 4;
    return ret;
}

rsp_reg_src :: inline (idx: u32) -> u32 {
    return rsp.gpr[idx];
}

rsp_reg_dst :: inline (idx: u32, val: u32) {
    if idx > 0 rsp.gpr[idx] = val;
}

rsp_execute_next :: () {
    if rsp.cp0[Sp.STATUS] & xx Sp_Status_R.HALT != 0 {
        rsp.remaining_cycles = 0;
    }

    if rsp.remaining_cycles > 0 {
        ins := rsp_next();
        rsp_execute(ins);
    }
}

rsp_execute :: (ins: u32) {
    rsp.remaining_cycles -= 1;
    rsp_instr_lut[ins >> 26](ins);
}

rsp_reset :: () {
    rsp.cp0[Sp.STATUS] = xx Sp_Status_R.HALT;
}
