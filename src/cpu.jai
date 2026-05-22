Cpu_State :: enum {
    RUNNING;
    STOPPED;
    STARTED;
}

Cpu :: struct {
    gpr: [32]u64;
    cp0: [32]u32;
    pc: u32 = 0xbfc00000;
    hi: u64;
    lo: u64;

    bp: [32]u32;
    state := Cpu_State.STOPPED;
    remaining_cycles := 0;
}

cpu_instr_lut := (_:u32).[
    cpu_special,
    cpu_regimm,
    null,
    cpu_jal,
    cpu_beq,
    cpu_bne,
    null,
    null,
    cpu_addi,
    cpu_addiu,
    cpu_slti,
    cpu_sltiu,
    cpu_andi,
    cpu_ori,
    cpu_xori,
    cpu_lui,
    cpu_cop0,
    null,
    null,
    null,
    cpu_beql,
    cpu_bnel,
    cpu_blezl,
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
    cpu_cache,
];

cpu_special_lut := (_:u32).[
    cpu_sll,
    null,
    cpu_srl,
    null,
    cpu_sllv,
    null,
    cpu_srlv,
    null,
    cpu_jr,
    null,
    null,
    null,
    null,
    cpu_break,
    null,
    null,
    cpu_mfhi,
    null,
    cpu_mflo,
    null,
    null,
    null,
    null,
    null,
    null,
    cpu_multu,
    null,
    null,
    null,
    null,
    null,
    null,
    cpu_add,
    cpu_addu,
    null,
    cpu_subu,
    cpu_and,
    cpu_or,
    cpu_xor,
    null,
    null,
    null,
    cpu_slt,
    cpu_sltu,
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
    null,
    null,
];

cpu_regimm_lut := (_:u32).[
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
    cpu_bgezal,
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
];


read_4_v :: (addr: u32) -> u32 {
    return read_4(virt2phys(addr));
}

write_4_v :: (addr: u32, val: u32, override := false) {
    write_4(virt2phys(addr), val, true);
}

virt2phys :: (addr: u32) -> u32 {
    if addr < 0x80000000 {
        assert(false, "TODO: Resolve KUSEG TLB map at 0x%", formatInt(addr, 16, 8));
    }
    if addr < 0xc0000000 {
        return addr & 0x1fffffff;
    }
    if addr < 0xe0000000 {
        assert(false, "TODO: Resolve KSSEG TLB map at 0x%", formatInt(addr, 16, 8));
    }
    assert(false, "TODO: Resolve KSEG3 TLB map at 0x%", formatInt(addr, 16, 8));
    return 0;
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
    execute(ins);
}

execute :: (ins: u32) {
    cpu.remaining_cycles -= 1;
    cpu_instr_lut[ins >> 26](ins);
}

cpu_reset :: () {
    for * cpu.bp it.* = 0xffffffff;
}
