Cpu :: struct {
    gpr: [32]u64;
    cp0: [32]u32;
    pc: u32 = 0xbfc00000;
}

cpu_instr_lut := (_:u32).[
    null,
    null,
    null,
    null,
    null,
    cpu_bne,
    null,
    null,
    null,
    cpu_addiu,
    null,
    null,
    cpu_andi,
    cpu_ori,
    null,
    cpu_lui,
    cpu_cop0,
    null,
    null,
    null,
    cpu_beql,
    cpu_bnel,
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
    cpu_lw,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    cpu_sw,
    null,
    null,
    null,
    null,
];

read_4_v :: (addr: u32) -> u32 {
    if addr < 0x80000000 {
        assert(false, "TODO: Read KUSEG TLB map");
    }
    if addr < 0xc0000000 {
        return read_4(addr & 0x1fffffff);
    }
    if addr < 0xe0000000 {
        assert(false, "TODO: Read KSSEG TLB map");
    }
    assert(false, "TODO: Read KSEG3 TLB map");
    return 0;
}

write_4_v :: (addr: u32, val: u32) {
    if addr < 0x80000000 {
        assert(false, "TODO: Write KUSEG TLB map");
    }
    else if addr < 0xc0000000 {
        write_4(addr & 0x1fffffff, val);
    }
    else if addr < 0xe0000000 {
        assert(false, "TODO: Write KSSEG TLB map");
    }
    else assert(false, "TODO: Write KSEG3 TLB map");
}

cpu_next :: () -> u32 {
    ret := read_4_v(cpu.pc);
    cpu.pc += 4;
    return ret;
}

cpu_reg_src :: inline (idx: u32) -> u64 {
    return cpu.gpr[idx];
}

cpu_reg_dst :: inline (idx: u32, val: u64) {
    if idx > 0 cpu.gpr[idx] = val;
}

execute_next :: () {
    ins := cpu_next();
    #asm {
        bswap.32 ins;
    }
    cpu_instr_lut[ins >> 26](ins);
}
