Rsp :: struct {
    gpr: [32]u32;
    v: [32] union {
        _64: [2]u64;
        _32: [4]u32;
        _16: [8]u16;
        _16s: [8]s16;
        _8: [16]u8;
        _8s: [16]s8;
    };
    acc: [8] union {
        _8: [6]u8;
        _16: [3]u16;
    };
    divin: u32;
    divout: u32;

    greatereq: [8]bool;
    lesseq: [8]bool;
    carry: [8]bool;
    nonzero: [8]bool;
    compareex: [8]bool;

    cp0: [16]u32;
    pc: u32;

    bp: [32]u32;
    remaining_cycles := 0.0;
}

rsp_instr_lut := (_:u32).[
    rsp_special,
    rsp_regimm,
    rsp_j,
    rsp_jal,
    rsp_beq,
    rsp_bne,
    rsp_blez,
    rsp_bgtz,
    rsp_addi,
    rsp_addiu,
    null,
    null,
    rsp_andi,
    rsp_ori,
    rsp_xori,
    rsp_lui,
    rsp_cop0,
    null,
    rsp_cop2,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    rsp_lb,
    rsp_lh,
    null,
    rsp_lw,
    rsp_lbu,
    rsp_lhu,
    null,
    null,
    rsp_sb,
    rsp_sh,
    null,
    rsp_sw,
    null,
    null,
    null,
    null,
    null,
    null,
    rsp_lwc2,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    rsp_swc2,
    null,
    null,
    null,
    null,
    null,
];

rsp_special_lut := (_:u32).[
    rsp_sll,
    null,
    rsp_srl,
    rsp_sra,
    rsp_sllv,
    null,
    null,
    null,
    rsp_jr,
    null,
    null,
    null,
    null,
    rsp_break,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    rsp_add,
    rsp_addu,
    rsp_sub,
    null,
    rsp_and,
    rsp_or,
    rsp_xor,
    null,
    null,
    null,
    rsp_slt
];

rsp_regimm_lut := (_:u32).[
    rsp_bltz,
    rsp_bgez
];

rsp_next :: () -> u32 {
    ret := wswap(mem.imem._32[rsp.pc >> 2]);
    rsp.pc += 4;
    return ret;
}

rsp_reg_src :: inline (idx: u32) -> u32 {
    return rsp.gpr[idx];
}

rsp_reg_dst :: inline (idx: u32, val: u32) {
    if idx > 0 rsp.gpr[idx] = val;
}

rsp_execute_next :: (cycle_bypass := false) {
    if rsp.cp0[Sp.STATUS] & xx Sp_Status_R.HALT != 0 {
        rsp.remaining_cycles = 0;
    }

    if rsp.remaining_cycles > 0 || cycle_bypass {
        ins := rsp_next();
        rsp_execute(ins);
        // if rsp.pc == 0x200 print("%\n", formatInt(rsp.gpr[2], 16, 8));
        // print("%\n", formatInt(rsp.pc, 16, 8));
        if rsp.pc % 4 != 0 exit(1);
    }
}

rsp_execute :: (ins: u32) {
    rsp.remaining_cycles -= 1;
    rsp_instr_lut[ins >> 26](ins);
}

rsp_reset :: () {
    rsp.cp0[Sp.STATUS] = xx Sp_Status_R.HALT;
    for * rsp.bp it.* = 0xffffffff;
}
