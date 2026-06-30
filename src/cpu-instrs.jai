cpu_special :: (ins: u32) {
    cpu_special_lut[ins & 0x3f](ins);
}

cpu_regimm :: (ins: u32) {
    cpu_regimm_lut[(ins >> 16) & 0x1f](ins);
}

cpu_lui :: (ins: u32) {
    _, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, sign_extend_4(imm << 16));
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

cpu_nor :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rt, ~(cpu_reg_src(rs) | cpu_reg_src(rt)));
}

cpu_sll :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4((cpu_reg_src(rt) << sa) & 0xffffffff));
}

cpu_sllv :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4((cpu_reg_src(rt) << (cpu_reg_src(rs) & 0x1f)) & 0xffffffff));
}

cpu_srl :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4(cpu_reg_src(rt) >> sa));
}

cpu_srlv :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4(cpu_reg_src(rt) >> (cpu_reg_src(rs) & 0x1f)));
}

cpu_sra :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4(cast,no_check(u32,cast,no_check(s32,cpu_reg_src(rt)) >> sa)));
}

cpu_addi :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, sign_extend_4((cpu_reg_src(rs) + sign_extend_2(imm)) & 0xffffffff));
    // TODO: overflow exception
}

cpu_addiu :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, sign_extend_4((cpu_reg_src(rs) + sign_extend_2(imm)) & 0xffffffff));
}

cpu_add :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4((cpu_reg_src(rs) + cpu_reg_src(rt)) & 0xffffffff));
    // TODO: overflow exception
}

cpu_addu :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4((cpu_reg_src(rs) + cpu_reg_src(rt)) & 0xffffffff));
}

cpu_sub :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4((cpu_reg_src(rs) - cpu_reg_src(rt)) & 0xffffffff));
    // TODO: overflow exception
}

cpu_subu :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, sign_extend_4((cpu_reg_src(rs) - cpu_reg_src(rt)) & 0xffffffff));
}

cpu_multu :: (ins: u32) {
    rs, rt := decode_r(ins);
    result := cpu_reg_src(rs) * cpu_reg_src(rt);
    cpu.lo = sign_extend_4(result & 0xffffffff);
    cpu.hi = sign_extend_4(result >> 32);
}

cpu_div :: (ins: u32) {
    rs, rt := decode_r(ins);
    lo := (cpu_reg_src(rs) & 0xffffffff) / (cpu_reg_src(rt) & 0xffffffff);
    hi := (cpu_reg_src(rs) & 0xffffffff) % (cpu_reg_src(rt) & 0xffffffff);
    cpu.lo = sign_extend_4(lo);
    cpu.hi = sign_extend_4(hi);
}

cpu_divu :: (ins: u32) {
    rs, rt := decode_r(ins);
    lo := (cpu_reg_src(rs) & 0xffffffff) / (cpu_reg_src(rt) & 0xffffffff);
    hi := (cpu_reg_src(rs) & 0xffffffff) % (cpu_reg_src(rt) & 0xffffffff);
    cpu.lo = sign_extend_4(lo);
    cpu.hi = sign_extend_4(hi);
}

cpu_dsll32 :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rt) << (32 + sa));
}

cpu_dsra32 :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cast,no_check(u64, cast,no_check(s64, cpu_reg_src(rt)) >> (32 + sa)));
}

cpu_daddiu :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, (cpu_reg_src(rs) + sign_extend_2(imm)));
}

cpu_dmultu :: (ins: u32) {
    rs, rt := decode_r(ins);
    hi, lo := multiply_64bits_with_overflow(cpu_reg_src(rs), cpu_reg_src(rt));
    cpu.lo = lo;
    cpu.hi = hi;
}

cpu_ddiv :: (ins: u32) {
    rs, rt := decode_r(ins);
    cpu.lo = cpu_reg_src(rs) / cpu_reg_src(rt);
    cpu.hi = cpu_reg_src(rs) % cpu_reg_src(rt);
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
    if cast,no_check(s32,cpu_reg_src(rs)) < cast,no_check(s32,sign_extend_2(imm)) {
        cpu_reg_dst(rt, 1);
    } else {
        cpu_reg_dst(rt, 0);
    }
}

cpu_slt :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    if cast,no_check(s64,cpu_reg_src(rs)) < cast,no_check(s64,cpu_reg_src(rt)) {
        cpu_reg_dst(rd, 1);
    } else {
        cpu_reg_dst(rd, 0);
    }
}

cpu_sltiu :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if cpu_reg_src(rs) < sign_extend_2(imm) {
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
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    cpu_reg_dst(rt, sign_extend_1(read_1_v(addr)));
}

cpu_lbu :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    cpu_reg_dst(rt, read_1_v(addr));
}

cpu_lh :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    cpu_reg_dst(rt, sign_extend_2(read_2_v(addr)));
}

cpu_lhu :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    cpu_reg_dst(rt, read_2_v(addr));
}

cpu_lw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    cpu_reg_dst(rt, sign_extend_4(read_4_v(addr)));
}

cpu_lwl :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    off := addr & 3;
    mem := read_4_v(addr);
    to_merge : u32 = xx (cpu_reg_src(rt) & 0xffffffff);

    to_merge &= ~cast(u32, 0xffffffff << (off * 8));
    to_merge |= mem << (off * 8);
    cpu_reg_dst(rt, sign_extend_4(to_merge));
}

cpu_lwr :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    off := addr & 3;
    mem := read_4_v(addr);
    to_merge : u32 = xx (cpu_reg_src(rt) & 0xffffffff);

    to_merge &= ~cast(u32, 0xffffffff >> ((3 - off) * 8));
    to_merge |= mem >> ((3 - off) * 8);
    cpu_reg_dst(rt, sign_extend_4(to_merge));
}

cpu_ld :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    addr &= 0xfffffff8;
    hi : u64 = read_4_v(addr);
    lo : u64 = read_4_v(addr + 4);
    cpu_reg_dst(rt, (hi << 32) | lo);
}

cpu_sb :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    write_1_v(addr, xx (cpu_reg_src(rt) & 0xff));
}

cpu_sh :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    write_2_v(addr, xx (cpu_reg_src(rt) & 0xffff));
}

cpu_sw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    write_4_v(addr, xx (cpu_reg_src(rt) & 0xffffffff));
}

cpu_swl :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    off := addr & 3;
    to_merge := read_4_v(addr);
    reg : u32 = xx (cpu_reg_src(rt) & 0xffffffff);

    to_merge &= ~cast(u32, 0xffffffff >> (off * 8));
    to_merge |= reg >> (off * 8);
    write_4_v(addr, to_merge);
}

cpu_swr :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    off := addr & 3;
    to_merge := read_4_v(addr);
    reg : u32 = xx (cpu_reg_src(rt) & 0xffffffff);

    to_merge &= ~cast(u32, 0xffffffff << ((3 - off) * 8));
    to_merge |= reg << ((3 - off) * 8);
    write_4_v(addr, to_merge);
}

cpu_sd :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    addr &= 0xfffffff8;
    val := cpu_reg_src(rt);
    write_4_v(addr, xx (val >> 32));
    write_4_v(addr + 4, xx (val & 0xffffffff));
}

cpu_lwc1 :: (ins: u32) {
    base, ft, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    cpu.fgr[ft].i32 = cast,no_check(s32,read_4_v(addr));
}

cpu_ldc1 :: (ins: u32) {
    base, ft, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    addr &= 0xfffffff8;
    hi : u64 = read_4_v(addr);
    lo : u64 = read_4_v(addr + 4);
    cpu.fgr[ft].i64 = cast,no_check(s64,(hi << 32) | lo);
}

cpu_swc1 :: (ins: u32) {
    base, ft, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    write_4_v(addr, cast,no_check(u32,cpu.fgr[ft].i32));
}

cpu_sdc1 :: (ins: u32) {
    base, ft, imm := decode_i(ins);
    addr : u32 = xx ((cpu_reg_src(base) + sign_extend_2(imm)) & 0xffffffff);
    addr &= 0xfffffff8;
    val := cpu.fgr[ft].i64;
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

cpu_bltz :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rs) & 0x80000000 != 0);
}

cpu_blez :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rs) & 0x80000000 != 0 || cpu_reg_src(rs) == 0);
}

cpu_bgtz :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rs) & 0x80000000 == 0 && cpu_reg_src(rs) != 0);
}

cpu_bgez :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch(addr, cpu_reg_src(rs) & 0x80000000 == 0);
}

cpu_beql :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rt) == cpu_reg_src(rs));
}

cpu_bnel :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rt) != cpu_reg_src(rs));
}

cpu_bltzl :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rs) & 0x80000000 != 0);
}

cpu_blezl :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rs) & 0x80000000 != 0 || cpu_reg_src(rs) == 0);
}

cpu_bgezl :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr := cpu.pc + (imm << 2);

    cpu_branch_likely(addr, cpu_reg_src(rs) & 0x80000000 == 0);
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
    cpu_execute_next(true);
    cpu.pc = (cpu.pc & 0xf0000000) | (addr << 2);
}

cpu_jr :: (ins: u32) {
    rs := decode_i(ins);
    addr : u32 = xx (cpu_reg_src(rs) & 0xffffffff);
    cpu_execute_next(true);
    cpu.pc = addr;
}

cpu_jal :: (ins: u32) {
    addr := decode_j(ins);
    cpu.gpr[31] = cpu.pc + 4; // TODO: verify
    cpu_execute_next(true);
    cpu.pc = (cpu.pc & 0xf0000000) | (addr << 2);
}

cpu_jalr :: (ins: u32) {
    rs := decode_i(ins);
    cpu.gpr[31] = cpu.pc + 4; // TODO: verify
    cpu_execute_next(true);
    cpu.pc = xx (cpu_reg_src(rs) & 0xffffffff);
}

cpu_cop0 :: (ins: u32) {
    op, rt, imm := decode_i(ins);
    rd := imm >> 11;
    if op == {
        case 0; // move from gpr
            cpu_reg_dst(rt, cpu.cp0[rd]);
        case 4; // move to gpr
            cpu.cp0[rd] = xx (cpu_reg_src(rt) & 0xffffffff);
        case 16;
            if (imm & 0x3f) == {
                case 1;
                    index := cpu.cp0[Cp0.INDEX];
                    global := (cpu.cp0[Cp0.ENTRYHI] >> 12) & 1;
                    cpu.cp0[Cp0.ENTRYLO0] = cpu.tlb[index].entry_lo0 | global;
                    cpu.cp0[Cp0.ENTRYLO1] = cpu.tlb[index].entry_lo1 | global;
                    cpu.cp0[Cp0.PAGEMASK] = cpu.tlb[index].page_mask;
                    cpu.cp0[Cp0.ENTRYHI] = cpu.tlb[index].entry_hi;
                case 2;
                    index := cpu.cp0[Cp0.INDEX];
                    entrylo0 := cpu.cp0[Cp0.ENTRYLO0];
                    entrylo1 := cpu.cp0[Cp0.ENTRYLO1];
                    pagemask := cpu.cp0[Cp0.PAGEMASK];
                    entryhi := cpu.cp0[Cp0.ENTRYHI];
                    cpu.tlb[index].entry_lo0 = entrylo0;
                    cpu.tlb[index].entry_lo1 = entrylo1;
                    cpu.tlb[index].page_mask = pagemask;
                    cpu.tlb[index].entry_hi = entryhi;
                case 8;
                    cpu.cp0[Cp0.INDEX] = 0x80000000;
                    entryhi := cpu.cp0[Cp0.ENTRYHI];
                    for cpu.tlb {
                        if it.entry_hi & 0xffffe000 == entryhi & 0xffffe000 &&
                        (it.entry_hi & 0x1000 != 0 || it.entry_hi & 0xff == entryhi & 0xff) {
                            cpu.cp0[Cp0.INDEX] = xx it_index;
                        }
                    }
                case 24;
                    if cpu.cp0[Cp0.STATUS] & 0b100 != 0 {
                        cpu.pc = cpu.cp0[Cp0.ERROREPC];
                        cpu.cp0[Cp0.STATUS] &= ~cast(u32,0b100);
                    } else {
                        cpu.pc = cpu.cp0[Cp0.EPC];
                        cpu.cp0[Cp0.STATUS] &= ~cast(u32,0b10);
                    }
                case;
                    assert(false, "TODO %", imm & 0x3f);
            }
        case;
            assert(false, "TODO %", op);
    }
}

cpu_cop1 :: (ins: u32) {
    fmt, ft, fs, fd := decode_r(ins);
    funct := ins & 0x3f;
    if fmt < 16 {
        if fmt == {
            case 0;
                cpu_reg_dst(ft, cast,no_check(u32,cpu.fgr[fs].i32));
            case 2;
                cpu_reg_dst(ft, cpu.fcr[fs]);
            case 4;
                cpu.fgr[fs].i64 = cast,no_check(s64,cpu_reg_src(ft) & 0xffffffff);
            case 6;
                cpu.fcr[fs] = xx cpu_reg_src(ft);
            case 8;
                imm := ins & 0xffff;
                if imm & 0x8000 != 0 then imm |= 0xffff0000;
                addr := cpu.pc + (imm << 2);
                if ft == 0 {
                    cpu_branch(addr, !cpu.coc);
                } else {
                    cpu_branch(addr, cpu.coc);
                }
            case;
                assert(false, "TODO %", fmt);
        }
    } else {
        if funct > 47 {
            cond := funct & 0xf;
            less : bool;
            equal : bool;
            unordered : bool;
            if fmt == {
                case 16;
                    if isnan(cpu.fgr[fs].f32) || isnan(cpu.fgr[fs].f32) {
                        less = false;
                        equal = false;
                        unordered = true;
                    } else {
                        less = cpu.fgr[fs].f32 < cpu.fgr[ft].f32;
                        equal = cpu.fgr[fs].f32 == cpu.fgr[ft].f32;
                        unordered = false;
                    }
                case 17;
                    if isnan(cpu.fgr[fs].f64) || isnan(cpu.fgr[fs].f64) {
                        less = false;
                        equal = false;
                        unordered = true;
                    } else {
                        less = cpu.fgr[fs].f64 < cpu.fgr[ft].f64;
                        equal = cpu.fgr[fs].f64 == cpu.fgr[ft].f64;
                        unordered = false;
                    }
                case;
                    assert(false, "Invalid format %", fmt);
            }
            cpu.coc = (cond & 0b100 != 0 && less) || (cond & 0b10 != 0 && equal) || (cond & 0b1 != 0 && unordered);
        } else if funct == {
            case 0;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f32 = cpu.fgr[fs].f32 + cpu.fgr[ft].f32;
                    case 17;
                        cpu.fgr[fd].f64 = cpu.fgr[fs].f64 + cpu.fgr[ft].f64;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 1;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f32 = cpu.fgr[fs].f32 - cpu.fgr[ft].f32;
                    case 17;
                        cpu.fgr[fd].f64 = cpu.fgr[fs].f64 - cpu.fgr[ft].f64;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 2;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f32 = cpu.fgr[fs].f32 * cpu.fgr[ft].f32;
                    case 17;
                        cpu.fgr[fd].f64 = cpu.fgr[fs].f64 * cpu.fgr[ft].f64;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 3;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f32 = cpu.fgr[fs].f32 / cpu.fgr[ft].f32;
                    case 17;
                        cpu.fgr[fd].f64 = cpu.fgr[fs].f64 / cpu.fgr[ft].f64;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 4;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f32 = sqrt(cpu.fgr[fs].f32);
                    case 17;
                        cpu.fgr[fd].f64 = sqrt(cpu.fgr[fs].f64);
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 7;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f32 = -cpu.fgr[fs].f32;
                    case 17;
                        cpu.fgr[fd].f64 = -cpu.fgr[fs].f64;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 13;
                mode := get_rounding_mode();
                set_rounding_mode(Rounding_Mode.ZERO);
                if fmt == {
                    case 16;
                        cpu.fgr[fd].i32 = round_f32_to_i32(cpu.fgr[fs].f32);
                        cpu.fgr[fd].i64 &= 0xffffffff;
                    case 17;
                        cpu.fgr[fd].i32 = round_f64_to_i32(cpu.fgr[fs].f64);
                        cpu.fgr[fd].i64 &= 0xffffffff;
                }
                set_rounding_mode(mode);
            case 32;
                if fmt == {
                    case 17;
                        cpu.fgr[fd].f32 = xx cpu.fgr[fs].f64;
                        cpu.fgr[fd].i64 &= 0xffffffff;
                    case 20;
                        cpu.fgr[fd].f32 = xx cpu.fgr[fs].i32;
                        cpu.fgr[fd].i64 &= 0xffffffff;
                    case 21;
                        cpu.fgr[fd].f32 = xx cpu.fgr[fs].i64;
                        cpu.fgr[fd].i64 &= 0xffffffff;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 33;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].f64 = xx cpu.fgr[fs].f32;
                    case 20;
                        cpu.fgr[fd].f64 = xx cpu.fgr[fs].i32;
                    case 21;
                        cpu.fgr[fd].f64 = xx cpu.fgr[fs].i64;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case 36;
                if fmt == {
                    case 16;
                        cpu.fgr[fd].i32 = xx cpu.fgr[fs].f32;
                        cpu.fgr[fd].i64 &= 0xffffffff;
                    case 17;
                        cpu.fgr[fd].i32 = xx cpu.fgr[fs].f64;
                        cpu.fgr[fd].i64 &= 0xffffffff;
                    case;
                        assert(false, "Invalid format %", fmt);
                }
            case;
                assert(false, "TODO %", funct);
        }
    }
}

cpu_cache :: (ins: u32) {
    base, op, off := decode_i(ins);
    if off & 0x8000 != 0 then off |= 0xffff0000;
    addr := cpu_reg_src(base) + (off << 2);
    // print("CACHE operation % on 0x%\n", op, formatInt(addr, 16, 8));
}

cpu_break :: (ins: u32) {
    if cpu.state == .RUNNING {
        cpu.state = .STOPPED;
        cpu.pc -= 4;
        cpu.remaining_cycles = 0;
        rsp.remaining_cycles = 0;
    } else {
        idx := ((ins >> 6) & 0xfffff) - 1;
        cpu_execute(cpu.bp[idx]);
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
    cpu_execute_next(true);
    if cond {
        cpu.pc = addr;
    }
}

cpu_branch_likely :: inline (addr: u32, cond: bool) {
    if cond {
        cpu_execute_next(true);
        cpu.pc = addr;
    } else {
        cpu.pc += 4;
    }
}

sign_extend_1 :: inline (val: u64) -> u64 {
    if val & 0x80 != 0 then val |= 0xffffffffffffff00;
    return val;
}

sign_extend_2 :: inline (val: u64) -> u64 {
    if val & 0x8000 != 0 then val |= 0xffffffffffff0000;
    return val;
}

sign_extend_4 :: inline (val: u64) -> u64 {
    if val & 0x80000000 != 0 then val |= 0xffffffff00000000;
    return val;
}
