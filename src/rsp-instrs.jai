rsp_special :: (ins: u32) {
    rsp_special_lut[ins & 0x3f](ins);
}

rsp_regimm :: (ins: u32) {
    rsp_regimm_lut[(ins >> 16) & 0x1f](ins);
}

rsp_lui :: (ins: u32) {
    _, rt, imm := decode_i(ins);
    rsp_reg_dst(rt, imm << 16);
}

rsp_and :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, rsp_reg_src(rs) & rsp_reg_src(rt));
}

rsp_andi :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    rsp_reg_dst(rt, rsp_reg_src(rs) & imm);
}

rsp_or :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, rsp_reg_src(rs) | rsp_reg_src(rt));
}

rsp_ori :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    rsp_reg_dst(rt, rsp_reg_src(rs) | imm);
}

rsp_xor :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, rsp_reg_src(rs) ^ rsp_reg_src(rt));
}

rsp_xori :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    rsp_reg_dst(rt, rsp_reg_src(rs) ^ imm);
}

rsp_sll :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    rsp_reg_dst(rd, rsp_reg_src(rt) << sa);
}

rsp_sllv :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, (rsp_reg_src(rt) << (rsp_reg_src(rs) & 0x1f)));
}

rsp_srl :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    rsp_reg_dst(rd, rsp_reg_src(rt) >> sa);
}

rsp_sra :: (ins: u32) {
    _, rt, rd, sa := decode_r(ins);
    rsp_reg_dst(rd, cast,no_check(u32,cast,no_check(s32,rsp_reg_src(rt)) >> sa));
}

rsp_addi :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    rsp_reg_dst(rt, (rsp_reg_src(rs) + sign_extend_2(imm)));
}

rsp_addiu :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    rsp_reg_dst(rt, (rsp_reg_src(rs) + sign_extend_2(imm)));
}

rsp_add :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, (rsp_reg_src(rs) + rsp_reg_src(rt)));
}

rsp_addu :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, (rsp_reg_src(rs) + rsp_reg_src(rt)));
}

rsp_sub :: (ins: u32) {
    rs, rt, rd := decode_r(ins);
    rsp_reg_dst(rd, (rsp_reg_src(rs) - rsp_reg_src(rt)));
}

rsp_lb :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    rsp_reg_dst(rt, sign_extend_1(mem.dmem._8[addr]));
}

rsp_lbu :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    rsp_reg_dst(rt, mem.dmem._8[addr]);
}

rsp_lh :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    rsp_reg_dst(rt, sign_extend_2(rsp_read_16(addr)));
}

rsp_lhu :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    rsp_reg_dst(rt, rsp_read_16(addr));
}

rsp_lw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    rsp_reg_dst(rt, rsp_read_32(addr));
}

rsp_sb :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    mem.dmem._8[addr] = xx (rsp_reg_src(rt) & 0xff);
}

rsp_sh :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    mem.dmem._16[addr >> 1] = hswap(xx (rsp_reg_src(rt) & 0xffff));
}

rsp_sw :: (ins: u32) {
    base, rt, imm := decode_i(ins);
    addr := (rsp_reg_src(base) + sign_extend_2(imm)) & 0xfff;
    mem.dmem._32[addr >> 2] = wswap(rsp_reg_src(rt));
}

rsp_beq :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    addr := rsp.pc + (sign_extend_2(imm) << 2);

    rsp_branch(addr, rsp_reg_src(rt) == rsp_reg_src(rs));
}

rsp_bne :: (ins: u32) {
    rs, rt, imm := decode_i(ins);
    addr := rsp.pc + (sign_extend_2(imm) << 2);

    rsp_branch(addr, rsp_reg_src(rt) != rsp_reg_src(rs));
}

rsp_bltz :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    addr := rsp.pc + (sign_extend_2(imm) << 2);

    rsp_branch(addr, rsp_reg_src(rs) & 0x80000000 != 0);
}

rsp_blez :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    addr := rsp.pc + (sign_extend_2(imm) << 2);

    rsp_branch(addr, rsp_reg_src(rs) & 0x80000000 != 0 || rsp_reg_src(rs) == 0);
}

rsp_bgtz :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    addr := rsp.pc + (sign_extend_2(imm) << 2);

    rsp_branch(addr, rsp_reg_src(rs) & 0x80000000 == 0 && rsp_reg_src(rs) != 0);
}

rsp_bgez :: (ins: u32) {
    rs, _, imm := decode_i(ins);
    addr := rsp.pc + (sign_extend_2(imm) << 2);

    rsp_branch(addr, rsp_reg_src(rs) & 0x80000000 == 0);
}

rsp_j :: (ins: u32) {
    addr := decode_j(ins);
    rsp_execute_next(true);
    rsp.pc = (addr << 2) & 0xfff;
}

rsp_jr :: (ins: u32) {
    rs := decode_i(ins);
    addr := rsp_reg_src(rs) & 0xfff;
    rsp_execute_next(true);
    rsp.pc = addr;
}

rsp_jal :: (ins: u32) {
    addr := decode_j(ins);
    rsp.gpr[31] = rsp.pc + 4; // TODO: verify
    rsp_execute_next(true);
    rsp.pc = (addr << 2) & 0xfff;
}

rsp_cop0 :: (ins: u32) {
    op, rt, imm := decode_i(ins);
    rd := imm >> 11;
    if op == {
        case 0;
            rsp_reg_dst(rt, read_4((rd * 4) | 0x04040000));
        case 4;
            write_4((rd * 4) | 0x04040000, rsp_reg_src(rt));
        case;
            assert(false, "TODO %", op);
    }
}

rsp_cop2 :: (ins: u32) {
    op, vt, imm := decode_i(ins);
    if op < 16 {
        vd := imm >> 11;
        e := (imm >> 7) & 0xf;
        if op == {
            case 0;
                // mfc2
                rsp_reg_dst(vt, sign_extend_2(rsp.v[vd]._16[e >> 1]));
            case 2;
                // cfc2
                if vd == {
                    case 1;
                        // TODO: verify this is the correct order of ge and le
                        ret: u32 = 0;
                        for 0..7 {
                            if rsp.greatereq[it] then ret |= xx 1 << it;
                            if rsp.lesseq[it] then ret |= xx 1 << (it + 8);
                        }
                        rsp_reg_dst(vt, ret);
                    case;
                        assert(false, "TODO %", vd);
                }
            case 4;
                // mtc2
                rsp.v[vd]._16[e >> 1] = xx (rsp_reg_src(vt) & 0xffff);
            case;
                assert(false, "TODO %", op);
        }
    } else {
        e := op & 0xf;
        vd := (imm >> 6) & 0x1f;
        vs := (imm >> 11) & 0x1f;
        if (imm & 0x3f) == {
            case 0;
                // vmulf
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] = xx (result & 0xffff);
                    rsp.acc[i]._16[2] = xx (result >> 16);
                    rsp.acc[i]._16[0] += 0x8000; // "rounding", effectively adds 0.5
                    rsp.v[vd]._16s[i] = cast,no_check(s16, result & 0xffff);
                }
            case 4;
                // vmudl
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] = xx ifx (result & 0x80000000) != 0 then 0xffff else 0;
                    rsp.acc[i]._16[0] = xx (result >> 16);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[0]);
                }
            case 5;
                // vmudm
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] = xx (result >> 16);
                    rsp.acc[i]._16[0] = xx (result & 0xffff);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[1]);
                }
            case 6;
                // vmudn
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] = xx (result >> 16);
                    rsp.acc[i]._16[0] = xx (result & 0xffff);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[0]);
                }
            case 7;
                // vmudh
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] = xx (result & 0xffff);
                    rsp.acc[i]._16[0] = 0;
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[1]);
                }
            case 8;
                // vmacf
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] += xx (result & 0xffff);
                    rsp.acc[i]._16[2] += xx (result >> 16);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, result & 0xffff);
                }
            case 12;
                // vmadl
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[0] += xx (result >> 16);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[0]);
                }
            case 13;
                // vmadm
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[0] += xx (result & 0xffff);
                    rsp.acc[i]._16[1] += xx (result >> 16);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[1]);
                }
            case 14;
                // vmadn
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[0] += xx (result & 0xffff);
                    rsp.acc[i]._16[1] += xx (result >> 16);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[0]);
                }
            case 15;
                // vmadh
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := cast,no_check(u32, cast(s32,rsp.v[vs]._16s[i]) * cast(s32,rsp.v[vt]._16s[j])) << 1;
                    rsp.acc[i]._16[1] += xx (result & 0xffff);
                    rsp.v[vd]._16s[i] = cast,no_check(s16, rsp.acc[i]._16[1]);
                }
            case 16;
                // vadd
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    first := rsp.v[vs]._16s[i];
                    second := rsp.v[vt]._16s[j];
                    result := first + second;
                    if rsp.carry[i] result += 1;
                    rsp.carry[i] = false;
                    rsp.acc[i]._16[0] = cast,no_check(u16,result);
                    rsp.v[vd]._16s[i] = result;
                }
            case 17;
                // vsub
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    first := rsp.v[vs]._16s[i];
                    second := rsp.v[vt]._16s[j];
                    result := first - second;
                    if rsp.carry[i] result -= 1;
                    rsp.carry[i] = false;
                    rsp.acc[i]._16[0] = cast,no_check(u16,result);
                    rsp.v[vd]._16s[i] = result;
                }
            case 20;
                // vaddc
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    first := rsp.v[vs]._16[i];
                    second := rsp.v[vt]._16[j];
                    result := first + second;
                    rsp.carry[i] = false;
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                    rsp.nonzero[i] = false;
                    rsp.carry[i] = cast(u32,first) + cast(u32,second) > 0xffff;
                }
            case 21;
                // vsubc
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    first := rsp.v[vs]._16s[i];
                    second := rsp.v[vt]._16s[j];
                    result := first - second;
                    rsp.acc[i]._16[0] = cast,no_check(u16,result);
                    rsp.v[vd]._16s[i] = result;
                    rsp.carry[i] = first < second;
                    rsp.nonzero[i] = first != second;
                }
            case 29;
                // vsar
                e &= 0x7;
                assert(e < 3, "% < 3", e);
                for i: 0..7 {
                    rsp.v[vd]._16[i] = rsp.acc[i]._16[2 - e];
                    rsp.acc[i]._16[2 - e] = rsp.v[vs]._16[i];
                }
            case 32;
                // vlt
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }

                    if rsp.v[vs]._16s[i] < rsp.v[vt]._16s[j] {
                        rsp.greatereq[i] = true;
                    } else if rsp.v[vs]._16s[i] == rsp.v[vt]._16s[j] && rsp.carry[i] && !rsp.compareex[i] {
                        rsp.greatereq[i] = true;
                    } else {
                        rsp.greatereq[i] = false;
                    }

                    result := ifx rsp.greatereq[i] then rsp.v[vs]._16[i] else rsp.v[vt]._16[j];
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                    rsp.lesseq[i] = false;
                    rsp.carry[i] = false;
                    rsp.nonzero[i] = false;
                    rsp.compareex[i] = false;
                }
            case 33;
                // veq
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }

                    if rsp.v[vs]._16s[i] == rsp.v[vt]._16s[j] && rsp.compareex[i] {
                        rsp.greatereq[i] = true;
                    } else {
                        rsp.greatereq[i] = false;
                    }

                    result := ifx rsp.greatereq[i] then rsp.v[vs]._16[i] else rsp.v[vt]._16[j];
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                    // top of vcc for some reason not cleared here?
                    // rsp.lesseq[i] = false;
                    rsp.carry[i] = false;
                    rsp.nonzero[i] = false;
                    rsp.compareex[i] = false;
                }
            case 34;
                // vne
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }

                    if rsp.v[vs]._16s[i] != rsp.v[vt]._16s[j] || !rsp.compareex[i] {
                        rsp.greatereq[i] = true;
                    } else {
                        rsp.greatereq[i] = false;
                    }

                    result := ifx rsp.greatereq[i] then rsp.v[vs]._16[i] else rsp.v[vt]._16[j];
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                    rsp.lesseq[i] = false;
                    rsp.carry[i] = false;
                    // top of vco for some reason not cleared here?
                    // rsp.nonzero[i] = false;
                    rsp.compareex[i] = false;
                }
            case 35;
                // vge
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }

                    if rsp.v[vs]._16s[i] > rsp.v[vt]._16s[j] {
                        rsp.greatereq[i] = true;
                    } else if rsp.v[vs]._16s[i] == rsp.v[vt]._16s[j] && (!rsp.carry[i] || rsp.compareex[i]) {
                        rsp.greatereq[i] = true;
                    } else {
                        rsp.greatereq[i] = false;
                    }

                    result := ifx rsp.greatereq[i] then rsp.v[vs]._16[i] else rsp.v[vt]._16[j];
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                    rsp.lesseq[i] = false;
                    rsp.carry[i] = false;
                    rsp.nonzero[i] = false;
                    rsp.compareex[i] = false;
                }
            case 36;
                // vcl
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    ge := rsp.greatereq[i];
                    le := rsp.lesseq[i];
                    vce := rsp.compareex[i];
                    eq := !rsp.nonzero[i];
                    sign := rsp.carry[i];
                    di: s16;
                    if sign {
                        di = rsp.v[vs]._16s[i] + rsp.v[vt]._16s[j];
                        carry := di < 0;
                        if eq {
                            le = (!vce && (di >= 0) && !carry) || (vce && (di >= 0 || !carry));
                        }
                        di = ifx le then -rsp.v[vt]._16s[j] else rsp.v[vs]._16s[i];
                        rsp.acc[i]._16[0] = cast,no_check(u16, di);
                    } else {
                        di = rsp.v[vs]._16s[i] - rsp.v[vt]._16s[j];
                        if eq {
                            ge = di >= 0;
                        }
                        di = ifx ge then rsp.v[vt]._16s[j] else rsp.v[vs]._16s[i];
                        rsp.acc[i]._16[0] = cast,no_check(u16, di);
                    }
                    rsp.v[vd]._16s[i] = di;
                    rsp.greatereq[i] = ge;
                    rsp.lesseq[i] = le;
                    rsp.compareex[i] = false;
                    rsp.carry[i] = false;
                    rsp.nonzero[i] = false;
                }
            case 37;
                // vch
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    ge: bool;
                    le: bool;
                    vce: bool;
                    eq: bool;
                    di: s16;
                    sign := (rsp.v[vs]._16s[i] ^ rsp.v[vt]._16s[j]) < 0;
                    if sign {
                        ge = rsp.v[vt]._16s[j] < 0;
                        le = (rsp.v[vs]._16s[i] + rsp.v[vt]._16s[j]) <= 0;
                        vce = (rsp.v[vs]._16s[i] + rsp.v[vt]._16s[j]) == -1;
                        eq = (rsp.v[vs]._16s[i] + rsp.v[vt]._16s[j]) == 0;
                        di = ifx le then -rsp.v[vt]._16s[j] else rsp.v[vs]._16s[i];
                        rsp.acc[i]._16[0] = cast,no_check(u16, di);
                    } else {
                        le = rsp.v[vt]._16s[j] < 0;
                        ge = (rsp.v[vs]._16s[i] - rsp.v[vt]._16s[j]) >= 0;
                        vce = false;
                        eq = (rsp.v[vs]._16s[i] + rsp.v[vt]._16s[j]) == 0;
                        di = ifx ge then rsp.v[vt]._16s[j] else rsp.v[vs]._16s[i];
                        rsp.acc[i]._16[0] = cast,no_check(u16, di);
                    }
                    rsp.v[vd]._16s[i] = di;
                    neq := !eq;
                    rsp.greatereq[i] = ge;
                    rsp.lesseq[i] = le;
                    rsp.carry[i] = sign;
                    rsp.nonzero[i] = neq;
                    rsp.compareex[i] = vce;
                }
            case 39;
                // vmrg
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }

                    result := ifx rsp.greatereq[i] then rsp.v[vs]._16[i] else rsp.v[vt]._16[j];
                    rsp.v[vd]._16[i] = result;
                    rsp.acc[i]._16[0] = result;
                }
            case 44;
                // vxor
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := rsp.v[vs]._16[i] ^ rsp.v[vt]._16[j];
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                }
            case 45;
                // vnxor
                for i: 0..7 {
                    j := 0;
                    if e == 0 {
                        j = i;
                    } else if e & 0b1110 == 0b10 {
                        j = (e & 0b1) + (i & 0b110);
                    } else if e & 0b1100 == 0b100 {
                        j = (e & 0b11) + (i & 0b100);
                    } else if e & 0b1000 == 0b1000 {
                        j = e & 0b111;
                    } else {
                        assert(false, "unreachable");
                    }
                    result := ~(rsp.v[vs]._16[i] ^ rsp.v[vt]._16[j]);
                    rsp.acc[i]._16[0] = result;
                    rsp.v[vd]._16[i] = result;
                }
            case 49;
                // vrcpl
                e &= 0x7;
                vs &= 0x7;
                rsp.divin &= 0xffff0000;
                rsp.divin |= rsp.v[vt]._16[e];
                temp := cast(float, rsp.divin) / 65536;
                temp = 1 / temp;
                result := cast(u32, temp * 32768);
                for i: 0..7 {
                    rsp.acc[i]._16[0] = rsp.v[vt]._16[e];
                }
                rsp.v[vd]._16[vs] = xx (rsp.divout & 0xffff);
            case 50;
                // vrcph
                e &= 0x7;
                vs &= 0x7;
                rsp.divin = cast(u32,rsp.v[vt]._16[e]) << 16;
                for i: 0..7 {
                    rsp.acc[i]._16[0] = rsp.v[vt]._16[e];
                }
                rsp.v[vd]._16[vs] = xx (rsp.divout >> 16);
            case;
                assert(false, "TODO %", imm & 0x3f);
        }
    }
}

rsp_lwc2 :: (ins: u32) {
    base, vt, rest := decode_i(ins);
    opcode := (rest >> 11) & 0x1f;
    element := (rest >> 7) & 0xf;
    offset := rest & 0x7f;
    offset = sign_extend_1(offset << 1) >> 1;
    if opcode == {
        case 1;
            rsp.v[vt]._16[element >> 1] = xx rsp_read_16(rsp_reg_src(base) + (offset << 1));
        case 2;
            rsp.v[vt]._32[element >> 2] = wswap(mem.dmem._32[((rsp_reg_src(base) >> 2) + offset) & 0x3ff]);
        case 3;
            rsp.v[vt]._64[element >> 3] = lswap(mem.dmem._64[((rsp_reg_src(base) >> 3) + offset) & 0x1ff]);
        case 4;
            addr := rsp_reg_src(base) + offset * 16;
            overshoot := addr % 16;
            val := U128.{lswap(mem.dmem._64[(addr >> 3) + 1]), lswap(mem.dmem._64[(addr >> 3)])};
            val >>= cast(u8,overshoot * 8);
            rsp.v[vt]._64[0] = val.low;
            rsp.v[vt]._64[1] = val.high;
        case 7;
            addr := rsp_reg_src(base) + offset;
            for 0..7 {
                rsp.v[vt]._16[it] = cast(u16,mem.dmem._8[(addr + it) & 0xfff]) << 7;
            }
        case;
            assert(false, "TODO %", opcode);
    }
}

rsp_swc2 :: (ins: u32) {
    base, vt, rest := decode_i(ins);
    opcode := (rest >> 11) & 0x1f;
    element := (rest >> 7) & 0xf;
    offset := rest & 0x7f;
    offset = sign_extend_1(offset << 1) >> 1;
    if opcode == {
        case 0;
            mem.dmem._8[rsp_reg_src(base) + offset] = rsp.v[vt]._8[element];
        case 1;
            mem.dmem._16[(rsp_reg_src(base) >> 1) + offset] = hswap(rsp.v[vt]._16[element >> 1]);
        case 2;
            mem.dmem._32[((rsp_reg_src(base) >> 2) + offset) & 0x3ff] = wswap(rsp.v[vt]._32[element >> 2]);
        case 3;
            mem.dmem._64[((rsp_reg_src(base) >> 3) + offset) & 0x1ff] = lswap(rsp.v[vt]._64[element >> 3]);
        case 4;
            addr := rsp_reg_src(base) + offset * 16;
            assert(addr % 16 == 0, "FIXME"); // for future reference
            mem.dmem._64[(addr >> 3) + 1] = lswap(rsp.v[vt]._64[0]);
            mem.dmem._64[(addr >> 3)] = lswap(rsp.v[vt]._64[1]);
        case 7;
            addr := rsp_reg_src(base) + offset;
            for 0..7 {
                mem.dmem._8[addr + it] = cast(u8,rsp.v[vt]._16[it] >> 7);
            }
        case;
            assert(false, "TODO %", opcode);
    }
}

rsp_break :: (ins: u32) {
    if ((ins >> 6) & 0xfffff) == 0 {
        rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.HALT;
        rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.BROKE;
        if rsp.cp0[Sp.STATUS] & xx Sp_Status_R.INTR_BREAK != 0 {
            mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.SP;
        }
    } else {
        if cpu.state == .RUNNING {
            cpu.state = .STOPPED;
            rsp.pc -= 4;
            cpu.remaining_cycles = 0;
            rsp.remaining_cycles = 0;
        } else {
            idx := ((ins >> 6) & 0xfffff) - 1;
            rsp_execute(rsp.bp[idx]);
        }
    }
}

#scope_file

rsp_read_32 :: inline (addr: u32) -> u32 {
    return wswap(mem.dmem._32[(addr & 0xfff) >> 2]);
}

rsp_read_16 :: inline (addr: u32) -> u32 {
    assert(addr & 3 != 3, "TODO: No idea what happens here");
    return (wswap(mem.dmem._32[(addr & 0xfff) >> 2]) >> ((2 - (addr & 3)) * 8)) & 0xffff;
}

rsp_branch :: inline (addr: u32, cond: bool) {
    rsp_execute_next(true);
    if cond {
        rsp.pc = addr & 0xfff;
    }
}

sign_extend_1 :: inline (val: u32) -> u32 {
    if val & 0x80 != 0 then val |= 0xffffff00;
    return val;
}

sign_extend_2 :: inline (val: u32) -> u32 {
    if val & 0x8000 != 0 then val |= 0xffff0000;
    return val;
}
