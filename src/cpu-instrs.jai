cpu_special :: (ins: u32) {
    cpu_special_lut[ins & 0x3f](ins);
}

cpu_lui :: (ins: u32) {
    _, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, imm << 16);
}

cpu_andi :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, cpu_reg_src(rs) & imm);
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

cpu_or :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rs) | cpu_reg_src(rt));
}

cpu_ori :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    cpu_reg_dst(rt, cpu_reg_src(rs) | imm);
}

cpu_srl :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    cpu_reg_dst(rd, cpu_reg_src(rt) >> sa);
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

cpu_jr :: (ins: u32) {
    rs := decode_i(ins);
    cpu.pc = xx cpu_reg_src(rs);
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
