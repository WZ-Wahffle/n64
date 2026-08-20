Cpu :: struct {
    gpr: [32]u64;
    cp0: [32]u32;
    tlb: [32]struct {entry_lo0: u32; entry_lo1: u32; entry_hi: u32; page_mask: u32;};
    fgr: [64]union {
        i32: s32;
        i64: s64;
        f32: float32;
        f64: float64;
    };
    fcr: [32]u32;
    coc: bool;
    pc: u32 = 0xbfc00000;
    hi: u64;
    lo: u64;

    bp: [32]u32;
    state := Cpu_State.STOPPED;
    step_frame := false;
    remaining_cycles := 0.0;
}

Cpu_State :: enum {
    RUNNING;
    STOPPED;
    STARTED;
}

Cp0 :: enum {
    INDEX;
    RANDOM;
    ENTRYLO0;
    ENTRYLO1;
    CONTEXT;
    PAGEMASK;
    WIRED;
    _7;
    BADVADDR;
    COUNT;
    ENTRYHI;
    COMPARE;
    STATUS;
    CAUSE;
    EPC;
    PRID;
    CONFIG;
    LLADDR;
    WATCHLO;
    WATCHHI;
    XCONTEXT;
    _21;
    _22;
    _23;
    _24;
    _25;
    PARITYERROR;
    CACHEERROR;
    TAGLO;
    TAGHI;
    ERROREPC;
    _31;
}

Cpu_Cause :: enum {
    SW1 :: 0x100;
    SW2 :: 0x200;
    RCP :: 0x400;
    CART :: 0x800;
    COUNTER :: 0x8000;
}

cpu_instr_lut := (_:u32).[
    cpu_special,
    cpu_regimm,
    cpu_j,
    cpu_jal,
    cpu_beq,
    cpu_bne,
    cpu_blez,
    cpu_bgtz,
    cpu_addi,
    cpu_addiu,
    cpu_slti,
    cpu_sltiu,
    cpu_andi,
    cpu_ori,
    cpu_xori,
    cpu_lui,
    cpu_cop0,
    cpu_cop1,
    null,
    null,
    cpu_beql,
    cpu_bnel,
    cpu_blezl,
    null,
    null,
    cpu_daddiu,
    null,
    null,
    null,
    null,
    null,
    null,
    cpu_lb,
    cpu_lh,
    cpu_lwl,
    cpu_lw,
    cpu_lbu,
    cpu_lhu,
    cpu_lwr,
    null,
    cpu_sb,
    cpu_sh,
    cpu_swl,
    cpu_sw,
    null,
    null,
    cpu_swr,
    cpu_cache,
    null,
    cpu_lwc1,
    null,
    null,
    null,
    cpu_ldc1,
    null,
    cpu_ld,
    null,
    cpu_swc1,
    null,
    null,
    null,
    cpu_sdc1,
    null,
    cpu_sd,
];

cpu_special_lut := (_:u32).[
    cpu_sll,
    null,
    cpu_srl,
    cpu_sra,
    cpu_sllv,
    null,
    cpu_srlv,
    null,
    cpu_jr,
    cpu_jalr,
    null,
    null,
    null,
    cpu_break,
    null,
    null,
    cpu_mfhi,
    cpu_mthi,
    cpu_mflo,
    cpu_mtlo,
    null,
    null,
    null,
    null,
    null,
    cpu_multu,
    cpu_div,
    cpu_divu,
    null,
    cpu_dmultu,
    cpu_ddiv,
    cpu_ddivu,
    cpu_add,
    cpu_addu,
    cpu_sub,
    cpu_subu,
    cpu_and,
    cpu_or,
    cpu_xor,
    cpu_nor,
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
    cpu_dsll32,
    null,
    null,
    cpu_dsra32,
];

cpu_regimm_lut := (_:u32).[
    cpu_bltz,
    cpu_bgez,
    cpu_bltzl,
    cpu_bgezl,
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

read_1_v :: (addr: u32) -> u8 {
    return read_1(virt2phys(addr));
}

read_2_v :: (addr: u32) -> u16 {
    return read_2(virt2phys(addr));
}

read_4_v :: (addr: u32) -> u32 {
    return read_4(virt2phys(addr));
}

write_1_v :: (addr: u32, val: u8, override := false) {
    write_1(virt2phys(addr), val, override);
}

write_2_v :: (addr: u32, val: u16, override := false) {
    write_2(virt2phys(addr), val, override);
}

write_4_v :: (addr: u32, val: u32, override := false) {
    write_4(virt2phys(addr), val, override);
}

virt2phys :: (addr: u32) -> u32 {
    if addr < 0x80000000 {
        asid := cpu.cp0[Cp0.ENTRYHI] & 0xff;
        for cpu.tlb {
            entry_asid := it.entry_hi & 0xff;
            global := (it.entry_lo0 & 1) && (it.entry_lo1 & 1);

            if global || (asid == entry_asid) {
                page_size := ((it.page_mask >> 13) + 1) << 12;
                src_addr := it.entry_hi & 0xffffe000;

                if addr >= src_addr && addr < src_addr + page_size {
                    dst_addr1 := (it.entry_lo0 >> 6) << 12;
                    off := addr - src_addr;
                    return dst_addr1 + off;
                }
                if addr >= src_addr + page_size && addr < src_addr + page_size * 2 {
                    dst_addr2 := (it.entry_lo1 >> 6) << 12;
                    off := addr - (src_addr + page_size);
                    return dst_addr2 + off;
                }
            }
        }

        assert(false, "Failed TLB lookup of 0x%, TLB: %", formatInt(addr, 16, 8), cpu.tlb);
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

cpu_execute_next :: (cycle_bypass := false) {
    if cpu.remaining_cycles > 0 || cycle_bypass {
        ins := cpu_next();
        cpu_execute(ins);
    }
}

cpu_execute :: (ins: u32) {
    cpu.remaining_cycles -= 1;
    cpu.cp0[Cp0.COUNT] += 1;
    cpu_instr_lut[ins >> 26](ins);
    if cpu.cp0[Cp0.COUNT] == cpu.cp0[Cp0.COMPARE] {
        cpu.cp0[Cp0.CAUSE] |= xx Cpu_Cause.COUNTER;
    }
}

cpu_reset :: () {
    for * cpu.bp it.* = 0xffffffff;
    mem.boot_ram._32[9] = 0x003f0000;
}

check_rcp_interrupts :: () {
    if cpu.state != .RUNNING return;
    if mem.mi._32[Mi.INTR_MASK] & mem.mi._32[Mi.INTR] != 0 {
        cpu.cp0[Cp0.CAUSE] |= xx Cpu_Cause.RCP;
    } else {
        cpu.cp0[Cp0.CAUSE] &= xx ~Cpu_Cause.RCP;
    }

    check_interrupts();
}

check_interrupts :: () {
    if cpu.cp0[Cp0.STATUS] & 0x7 == 0x1 {
        if cpu.cp0[Cp0.STATUS] & cpu.cp0[Cp0.CAUSE] & 0xff00 != 0 {
            cpu.cp0[Cp0.STATUS] |= 0b10;
            cpu.cp0[Cp0.EPC] = cpu.pc;
            cpu.pc = 0x80000000;

            if cpu.step_frame && (mem.mi._32[Mi.INTR_MASK] & mem.mi._32[Mi.INTR] & xx Mi_Intr_R.DP) != 0 {
                cpu.step_frame = false;
                cpu.state = .STOPPED;
                cpu.remaining_cycles = 0;
                rsp.remaining_cycles = 0;
            }
        }
    }
}
