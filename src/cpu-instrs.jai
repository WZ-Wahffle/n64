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

cpu_mflo :: (ins: u32) {
    _, _, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu.lo);
}

cpu_mfhi :: (ins: u32) {
    _, _, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu.hi);
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

cpu_lw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    cpu_reg_dst(rt, read_4_v(addr));
}

cpu_sw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    if imm & 0x8000 != 0 then imm |= 0xffff0000;
    addr : u32 = xx cpu_reg_src(base) + imm;
    write_4_v(addr, xx cpu_reg_src(rt));
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

cpu_cop0 :: (ins: u32) {
    op, rt, imm := decode_i(ins);
    rd := imm >> 11;
    if op == {
        case 4; // move to gpr
            cpu.cp0[rd] = xx cpu_reg_src(rt);
        case;
            assert(false, "TODO");
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
