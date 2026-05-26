cpu_special :: (ins: u32) {
    cpu_special_lut[ins & 0x3f](ins);
}

cpu_regimm :: (ins: u32) {
    cpu_regimm_lut[(ins >> 16) & 0x1f](ins);
}

cpu_lui :: (ins: u32) {
    _, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, imm << 16);
}

cpu_and :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rs) & cpu_reg_src(rt));
}

cpu_andi :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, cpu_reg_src(rs) & imm);
}

cpu_or :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rs) | cpu_reg_src(rt));
}

cpu_ori :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, cpu_reg_src(rs) | imm);
}

cpu_xor :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rs) ^ cpu_reg_src(rt));
}

cpu_xori :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, cpu_reg_src(rs) ^ imm);
}

cpu_sll :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, (cpu_reg_src(rt) << sa) & 0xffffffff);
}

cpu_sllv :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, (cpu_reg_src(rt) << (cpu_reg_src(rs) & 0x1f)) & 0xffffffff);
}

cpu_srl :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rt) >> sa);
}

cpu_srlv :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rt) >> (cpu_reg_src(rs) & 0x1f));
}

cpu_sra :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cast,no_check(u32,cast,no_check(s32,cpu_reg_src(rt)) >> sa));
}

cpu_addi :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    cpu_reg_dst(rt, (cpu_reg_src(rs) + imm) & 0xffffffff);
    // TODO: overflow exception
}

cpu_addiu :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    cpu_reg_dst(rt, (cpu_reg_src(rs) + imm) & 0xffffffff);
}

cpu_add :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, (cpu_reg_src(rs) + cpu_reg_src(rt)) & 0xffffffff);
    // TODO: overflow exception
}

cpu_addu :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, (cpu_reg_src(rs) + cpu_reg_src(rt)) & 0xffffffff);
}

cpu_subu :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, (cpu_reg_src(rs) - cpu_reg_src(rt)) & 0xffffffff);
}

cpu_multu :: (ins: u32) {
    rs, rt := decode_r(ins);
    result := cpu_reg_src(rs) * cpu_reg_src(rt);
    cpu.lo = result & 0xffffffff;
    cpu.hi = result >> 32;
}

cpu_div :: (ins: u32) {
    rs, rt := decode_r(ins);
    lo := (cpu_reg_src(rs) & 0xffffffff) / (cpu_reg_src(rt) & 0xffffffff);
    hi := (cpu_reg_src(rs) & 0xffffffff) % (cpu_reg_src(rt) & 0xffffffff);
    if lo & 0x80000000 != 0 then lo |= 0xffffffff00000000;
    if hi & 0x80000000 != 0 then hi |= 0xffffffff00000000;
    cpu.lo = lo;
    cpu.hi = hi;
}

cpu_dsll32 :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rt) << (32 + sa));
}

cpu_dsra32 :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cast,no_check(u64, cast,no_check(s64, cpu_reg_src(rt)) >> (32 + sa)));
}

cpu_dmultu :: (ins: u32) {
    rs, rt := decode_r(ins);
    hi, lo := multiply_64bits_with_overflow(cpu_reg_src(rs), cpu_reg_src(rt));
    cpu.lo = lo;
    cpu.hi = hi;
}

cpu_ddivu :: (ins: u32) {
    rs, rt := decode_r(ins);
    cpu.lo = cpu_reg_src(rs) / cpu_reg_src(rt);
    cpu.hi = cpu_reg_src(rs) % cpu_reg_src(rt);
}

cpu_mflo :: (ins: u32) {
    _, _, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu.lo);
}

cpu_mfhi :: (ins: u32) {
    _, _, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu.hi);
}

cpu_mtlo :: (ins: u32) {
    rs, _, _ := decode_r(ins);
    cpu.lo = cpu_reg_src(rs);
}

cpu_mthi :: (ins: u32) {
    rs, _, _ := decode_r(ins);
    cpu.hi = cpu_reg_src(rs);
}

cpu_slti :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    if cast,no_check(s32,cpu_reg_src(rs)) < cast,no_check(s32,imm) {
        cpu_reg_dst(rt, 1);
    } else {
        cpu_reg_dst(rt, 0);
    }
}

cpu_slt :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    if cast,no_check(s32,cpu_reg_src(rs)) < cast,no_check(s32,cpu_reg_src(rt)) {
        cpu_reg_dst(rd, 1);
    } else {
        cpu_reg_dst(rd, 0);
    }
}

cpu_sltiu :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if cpu_reg_src(rs) < imm {
        cpu_reg_dst(rt, 1);
    } else {
        cpu_reg_dst(rt, 0);
    }
}

cpu_sltu :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    if cpu_reg_src(rs) < cpu_reg_src(rt) {
        cpu_reg_dst(rd, 1);
    } else {
        cpu_reg_dst(rd, 0);
    }
}

cpu_lb :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    val : u64 = read_1_v(addr);
    if val & 0x80 != 0 then val |= 0xffffffffffffff00;
    cpu_reg_dst(rt, val);
}

cpu_lbu :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    cpu_reg_dst(rt, read_1_v(addr));
}

cpu_lhu :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    cpu_reg_dst(rt, read_2_v(addr));
}

cpu_lw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    cpu_reg_dst(rt, read_4_v(addr));
}

cpu_ld :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    addr &= 0xfffffff8;
    hi : u64 = read_4_v(addr);
    lo : u64 = read_4_v(addr + 4);
    cpu_reg_dst(rt, (hi << 32) | lo);
}

cpu_sb :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    write_1_v(addr, xx (cpu_reg_src(rt) & 0xff));
}

cpu_sh :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    write_2_v(addr, xx (cpu_reg_src(rt) & 0xffff));
}

cpu_sw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    write_4_v(addr, xx (cpu_reg_src(rt) & 0xffffffff));
}

cpu_sd :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    addr &= 0xfffffff8;
    val := cpu_reg_src(rt);
    write_4_v(addr, xx (val >> 32));
    write_4_v(addr + 4, xx (val & 0xffffffff));
}

cpu_beq :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rt) == cpu_reg_src(rs));
}

cpu_bne :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rt) != cpu_reg_src(rs));
}

cpu_blez :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rs) & 0x80000000 == 1 || cpu_reg_src(rs) == 0);
}

cpu_beql :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rt) == cpu_reg_src(rs));
}

cpu_bnel :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rt) != cpu_reg_src(rs));
}

cpu_blezl :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rs) & 0x80000000 == 1 || cpu_reg_src(rs) == 0);
}

cpu_bgezal :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);
    cpu.gpr[31] = cpu.pc + 4; // TODO: verify
    cpu_branch(addr, cpu_reg_src(rs) & 0x80000000 == 0);
}

cpu_j :: (ins: u32) {
    addr := decode_j(ins);
    execute_next();
    cpu.pc &= 0xf0000000;
    cpu.pc |= addr << 2;
}

cpu_jr :: (ins: u32) {
    rs := decode_i(ins);
    execute_next();
    cpu.pc = xx cpu_reg_src(rs);
}

cpu_jal :: (ins: u32) {
    addr := decode_j(ins);
    cpu.gpr[31] = cpu.pc + 4; // TODO: verify
    execute_next();
    cpu.pc &= 0xf0000000;
    cpu.pc |= addr << 2;
}

cpu_jalr :: (ins: u32) {
    rs := decode_i(ins);
    cpu.gpr[31] = cpu.pc + 4; // TODO: verify
    execute_next();
    cpu.pc = xx cpu_reg_src(rs);
}

cpu_cop0 :: (ins: u32) {
    op, rt, imm := decode_i(ins);
    rd := imm >> 11;
    if op == {
        case 0; // move from gpr
            cpu_reg_dst(rt, cpu.cp0[rd]);
        case 4; // move to gpr
            cpu.cp0[rd] = xx cpu_reg_src(rt);
        case 16;
            if (imm & 0x3f) == {
                case 1;
                    index := cpu.cp0[0];
                    global := (cpu.cp0[10] >> 12) & 1;
                    cpu.cp0[2] = cpu.tlb[index].entry_lo0 | global;
                    cpu.cp0[3] = cpu.tlb[index].entry_lo1 | global;
                    cpu.cp0[5] = cpu.tlb[index].page_mask;
                    cpu.cp0[10] = cpu.tlb[index].entry_hi;
                case 2;
                    index := cpu.cp0[0];
                    entrylo0 := cpu.cp0[2];
                    entrylo1 := cpu.cp0[3];
                    pagemask := cpu.cp0[5];
                    entryhi := cpu.cp0[10];
                    cpu.tlb[index].entry_lo0 = entrylo0;
                    cpu.tlb[index].entry_lo1 = entrylo1;
                    cpu.tlb[index].page_mask = pagemask;
                    cpu.tlb[index].entry_hi = entryhi;
                case 8;
                    cpu.cp0[0] = 0x80000000;
                    entryhi := cpu.cp0[10];
                    for cpu.tlb {
                        if it.entry_hi & 0xffffe000 == entryhi & 0xffffe000 &&
                        (it.entry_hi & 0x1000 != 0 || it.entry_hi & 0xff == entryhi & 0xff) {
                            cpu.cp0[0] = xx it_index;
                        }
                    }
                case 24;
                    if cpu.cp0[12] & 0b100 != 0 {
                        cpu.pc = cpu.cp0[30];
                    } else {
                        cpu.pc = cpu.cp0[14];
                    }
                case;
                    assert(false, "TODO %", imm & 0x3f);
            }
        case;
            assert(false, "TODO %", op);
    }
}

cpu_cop1 :: (ins: u32) {
    op, rt, imm := decode_i(ins);
    rd := imm >> 11;
    if op == {
        case 2;
            cpu_reg_dst(rt, cpu.fcr[rd]);
        case 6;
            cpu.fcr[rd] = xx cpu_reg_src(rt);
        case;
            assert(false, "TODO %", op);
    }
}

cpu_cache :: (ins: u32) {
    base, op, off := decode_i(ins);
    if off & 0x8000 != 0 then off |= 0xffff0000;
    addr := cpu_reg_src(base) + (off << 2);
    print("CACHE operation % on 0x%\n", op, formatInt(addr, 16, 8));
}

cpu_break :: (ins: u32) {
    if cpu.state == .RUNNING {
        cpu.state = .STOPPED;
        cpu.pc -= 4;
    } else {
        idx := ((ins >> 6) & 0xfffff) - 1;
        execute(cpu.bp[idx]);
    }
}

decode_i :: inline (ins: u32) -> (rs: u32, rt: u32, imm: u32) {
    return (ins >> 21) & 0x1f, (ins >> 16) & 0x1f, ins & 0xffff;
}

decode_j :: inline (ins: u32) -> addr: u32 {
    return ins & 0x3ffffff;
}

decode_r :: inline (ins: u32) -> (rs: u32, rt: u32, rd: u32, sa: u32) {
    return (ins >> 21) & 0x1f, (ins >> 16) & 0x1f, (ins >> 11) & 0x1f, (ins >> 6) & 0x1f;
}

#scope_file

cpu_branch :: inline (addr: u32, cond: bool) {
    execute_next();
    if cond {
        cpu.pc = addr;
    }
}

cpu_branch_likely :: inline (addr: u32, cond: bool) {
    if cond {
        execute_next();
        cpu.pc = addr;
    } else {
        cpu.pc += 4;
    }
}
