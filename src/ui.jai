FPS :: 60;
CPU_CYCLES_PER_SECOND :: 93_750_000;
CPU_CYCLES_PER_FRAME :: CPU_CYCLES_PER_SECOND / FPS;

ui :: () {
    rl.SetTraceLogLevel(.LOG_ERROR);
    rl.InitWindow(1280, 960, "n64");
    rl.SetTargetFPS(FPS);
    im.CreateContext();
    im.GetIO().Fonts.AddFontFromMemoryTTF(im.GetIO().Fonts, font.data, xx font.count, 24);
    rg.backend_setup();
    setup_catppuccin_mocha_theme();

    while(!rl.WindowShouldClose()) {
        rl.ClearBackground(rl.BLACK);
        rl.BeginDrawing();

        if cpu.state == {
            case .STOPPED;
            // this page intentionally left blank
            case .STARTED;
            execute_next();
            cpu.state = .RUNNING;
            #through;
            case .RUNNING;
            cpu.remaining_cycles += CPU_CYCLES_PER_FRAME;
            while cpu.remaining_cycles > 0 && cpu.state != .STOPPED execute_next();
            if disasm_state.follow disasm_state.scroll_state = cpu.pc;
        }

        rg.backend_frame_begin();

        cpu_window();
        disasm_window();

        rg.backend_frame_end();
        rl.EndDrawing();
    }
    rl.CloseWindow();
}

#scope_file

regs := string.["r0", "at", "v0", "v1", "a0", "a1", "a2", "a3",
    "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
    "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
    "t8", "t9", "k0", "k1", "gp", "sp", "fp", "ra"];

cpu_window :: () {
    im.Begin("cpu");
    im.SeparatorText("Control");
    if im.Button("Start") {
        cpu.state = .STARTED;
    }
    im.SameLine();
    if im.Button("Stop") {
        cpu.state = .STOPPED;
    }
    im.SameLine();
    if im.Button("Step") {
        cpu.state = .STOPPED;
        execute_next();
        if disasm_state.follow {
            disasm_state.scroll_state = cpu.pc;
        }
    }
    im.SeparatorText("Registers");
    im.Text_CFormat("PC: 0x%08x", cpu.pc);
    if im.TreeNode("GPRs") {
        for regs {
                im.Text_CFormat("%s: 0x%016x", it.data, cpu.gpr[it_index]);
            }
        im.TreePop();
    }
    im.SeparatorText("Coprocessor 0");
    if im.TreeNode("TLB") {
        im.Text("index: %", cpu.cp0[0] & 0x3f);
        im.Text("last probe success: %", cpu.cp0[0] >> 31);
        im.Text("random: %", cpu.cp0[1] & 0x3f);
        im.Text("even | odd PFN: % | %", cpu.cp0[2] >> 6, cpu.cp0[3] >> 6);
        im.Text("even | odd cache algorithm: % | %", (cpu.cp0[2] >> 3) & 0b111, (cpu.cp0[3] >> 3) & 0b111);
        im.Text("even | odd dirty: % | %", (cpu.cp0[2] >> 2) & 0b1, (cpu.cp0[3] >> 2) & 0b1);
        im.Text("even | odd valid: % | %", (cpu.cp0[2] >> 1) & 0b1, (cpu.cp0[3] >> 1) & 0b1);
        im.Text("even | odd global: % | %", cpu.cp0[2] & 0b1, cpu.cp0[3] & 0b1);
        im.Text("VPN: %", (cpu.cp0[10] >> 13) * 2);
        im.Text("ASID: %", cpu.cp0[10] & 0xff);
        im.Text("PTE base: %", cpu.cp0[4] >> 23);
        im.Text("bad VPN: %", ((cpu.cp0[4] >> 4) & 0x7ffff) * 2);
        im.Text("page mask: %", cpu.cp0[5] >> 13);
        im.Text("wired: %", cpu.cp0[6] & 0x3f);
        im.Text("bad vaddr: %", cpu.cp0[8]);

        im.TreePop();
    }
    im.Text("count: %", cpu.cp0[9]);
    im.Text("compare: %", cpu.cp0[11]);
    im.Text_CFormat("status: 0x%08x", cpu.cp0[12]);
    im.Text_CFormat("cause: 0x%08x", cpu.cp0[13]);
    im.Text_CFormat("exception program counter: 0x%08x", cpu.cp0[14]);
    im.Text_CFormat("revision: 0x%08x", cpu.cp0[15]);
    im.Text_CFormat("config: 0x%08x", cpu.cp0[16]);
    im.Text_CFormat("load linked address: 0x%08x", cpu.cp0[17]);
    im.End();
}

disasm :: (addr: u32) -> str: string, info: Disasm_Return {
    a, b := disasm_explicit(addr, read_4_v(addr));
    return a, b;
}

Disasm_Return :: struct {
    type: enum {
        NORMAL;
        BRANCH;
        JUMP;
        CALL;
    }
    off: s32 = 0;
    cond: bool = false;
}

disasm_explicit :: (addr: u32, val: u32) -> (str: string, info: Disasm_Return = {.NORMAL, 0, false}) {
    to_reg :: (reg: u32) -> string {
        labels :: string.[
            "$zero", "$at",
            "$v0", "$v1",
            "$a0", "$a1", "$a2", "$a3",
            "$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7",
            "$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7",
            "$t8", "$t9",
            "$k0", "$k1",
            "$gp", "$sp", "$fp", "$ra"
        ];
        return ifx disasm_state.pretty_regs then labels[reg] else tprint("$r%", reg);
    }

    op := val >> 26;
    rs_idx := (val >> 21) & 0x1f;
    rs := to_reg(rs_idx);
    rt_idx := (val >> 16) & 0x1f;
    rt := to_reg(rt_idx);
    rd_idx := (val >> 11) & 0x1f;
    rd := to_reg(rd_idx);
    sa := (val >> 6) & 0x1f;
    funct := val & 0x3f;
    imm := val & 0xffff;
    if op == {
        case 0;
        if funct == {
            case 0;
            if rt_idx == 0 && rd_idx == 0 && sa == 0 return "NOP";
            return tprint("SLL %, %, 0x%", rd, rt, formatInt(sa, 16));
            case 2;
            return tprint("SRL %, %, 0x%", rd, rt, formatInt(sa, 16));
            case 4;
            return tprint("SLLV %, %, %", rd, rt, rs);
            case 6;
            return tprint("SLRV %, %, %", rd, rt, rs);
            case 8;
            return tprint("JR %", rs), .{type=.JUMP};
            case 13;
            idx := (val >> 6) & 0xfffff;
            if idx == 0 return "BREAK 0x0";
            return disasm_explicit(addr, cpu.bp[idx-1]);
            case 16;
            return tprint("MFHI %", rd);
            case 18;
            return tprint("MFLO %", rd);
            case 25;
            return tprint("MULTU %, %", rs, rt);
            case 33;
            return tprint("ADDU %, %, %", rd, rs, rt);
            case 35;
            return tprint("SUBU %, %, %", rd, rs, rt);
            case 36;
            return tprint("AND %, %, %", rd, rs, rt);
            case 37;
            return tprint("OR %, %, %", rd, rs, rt);
            case 38;
            return tprint("XOR %, %, %", rd, rs, rt);
            case 43;
            return tprint("SLTU %, %, %", rd, rs, rt);
            case;
            assert(false, "% %", funct, formatInt(addr, 16));
        }
        case 1;
        if rt_idx == {
            case 17;
            if imm & 0x8000 != 0 imm |= 0xffff0000;
            imm <<= 2;
            if rs_idx == 0 then return tprint("BAL 0x%", formatInt(addr + imm + 4, 16, 8)), .{.CALL, cast,no_check(s32,imm + 4), false};
            else return tprint("BGEZAL %, 0x%", rs, formatInt(addr + imm + 4, 16, 8)), .{.CALL, cast,no_check(s32,imm + 4), true};
            case;
            assert(false, "% %", rt_idx, formatInt(addr, 16));
        }
        case 4;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BEQ %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{.BRANCH, cast,no_check(s32,imm + 4), true};
        case 5;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BNE %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{.BRANCH, cast,no_check(s32,imm + 4), true};
        case 8;
        if imm & 0x8000 != 0 then imm |= 0xffff0000;
        return tprint("ADDI %, %, 0x%", rt, rs, formatInt(imm, 16));
        case 9;
        if imm & 0x8000 != 0 then imm |= 0xffff0000;
        return tprint("ADDIU %, %, 0x%", rt, rs, formatInt(imm, 16));
        case 12;
        return tprint("ANDI %, %, 0x%", rt, rs, formatInt(imm, 16));
        case 13;
        return tprint("ORI %, %, 0x%", rt, rs, formatInt(imm, 16));
        case 15;
        return tprint("LUI %, 0x%", rt, formatInt(imm, 16));
        case 16; #through;
        case 17; #through;
        case 18;
        if rs_idx == {
            case 4;
            return tprint("MTC% %, %", op - 16, rt, rd);
            case;
            assert(false, "% %", rs, formatInt(addr, 16));
        }
        case 20;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BEQL %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{.BRANCH, cast,no_check(s32,imm + 4), true};
        case 21;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BNEL %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{.BRANCH, cast,no_check(s32,imm + 4), true};
        case 35;
        return tprint("LW %, 0x%(%)", rt, formatInt(imm, 16), rs);
        case 43;
        return tprint("SW %, 0x%(%)", rt, formatInt(imm, 16), rs);
        case 63;
        return tprint("SD %, 0x%(%)", rt, formatInt(imm, 16), rs);
        case;
        assert(false, "% %", op, formatInt(addr, 16));
    }
    return "";
}

disasm_state : struct {
    scroll_state := 0xbfc00000;

    physical_addr := false;
    follow := true;
    pretty_regs := true;
};

disasm_window :: () {
    im.Begin("disasm", null, .NoScrollbar | .NoScrollWithMouse);
    if im.CollapsingHeader("Options", .OpenOnArrow) {
        im.Checkbox("Physical addresses", *disasm_state.physical_addr);
        im.Checkbox("Follow PC", *disasm_state.follow);
        im.Checkbox("Register Names", *disasm_state.pretty_regs);
    }
    im.Separator();
    im.BeginChild("disasm_view", flags=.NoScrollbar | .NoScrollWithMouse);
    if im.IsWindowHovered() {
        if (im.GetIO().MouseWheel < 0) {
            disasm_state.scroll_state += 4;
        } else if (im.GetIO().MouseWheel > 0) {
            disasm_state.scroll_state -= 4;
            disasm_state.scroll_state = max(disasm_state.scroll_state, 0);
        }
    }
    line_count : int = xx ((im.GetWindowContentRegionMax().y - im.GetCursorPosY()) / im.GetTextLineHeightWithSpacing());

    every_other := true;
    for line : 0..line_count {
        addr : u32 = xx (disasm_state.scroll_state + (line - line_count / 2) * 4);
        green := im.ImVec4.{0., 1., 0., 1.};
        red := im.ImVec4.{1., 0., 0., 1.};
        ins := read_4_v(addr);
        has_bp := (ins & 0xfc00003f == 0xd) && (ins >> 6) & 0xfffff != 0;

        disp_addr := ifx disasm_state.physical_addr then virt2phys(addr) else addr;
        mnem, info := disasm(addr);
        if addr == cpu.pc im.TextColored_CFormat(*green, "  0x%08x: %s", disp_addr, mnem.data);
        else if has_bp im.TextColored_CFormat(*red, "  0x%08x: %s", disp_addr, mnem.data);
        else im.Text_CFormat("  0x%08x: %s", disp_addr, mnem.data);
        if info.type == {
            case .BRANCH;
            draw_arrow :: (src_y: float, dst_y: float, min_x: float, max_x: float, color: u32) {
                im.ImDrawList.AddLine(im.GetWindowDrawList(), .{min_x, src_y}, .{max_x, src_y}, color);
                im.ImDrawList.AddLine(im.GetWindowDrawList(), .{min_x, src_y}, .{min_x, dst_y}, color);
                im.ImDrawList.AddLine(im.GetWindowDrawList(), .{min_x, dst_y}, .{(min_x + max_x) / 2, dst_y}, color);
                im.ImDrawList.AddTriangleFilled(im.GetWindowDrawList(), .{max_x, dst_y}, .{(min_x + max_x) / 2, dst_y + 10}, .{(min_x + max_x) / 2, dst_y - 10}, color);
            }
            quickhash :: (in: u32) -> u32 {
                in ^= in << 13;
                in ^= in >> 17;
                in ^= in << 5;
                return in;
            }
            item_rect := im.GetItemRectMin();
            src_y := (item_rect.y + im.GetTextLineHeightWithSpacing() + im.GetTextLineHeight() / 2);
            dst_y := src_y + im.GetTextLineHeightWithSpacing() * info.off / 4;
            min_x := item_rect.x;
            max_x := min_x + 20;
            if every_other min_x += 5;
            every_other ^= true;
            draw_arrow(src_y, dst_y, min_x, max_x, (quickhash(addr) & 0xffffff) | 0x80404040);
            case .JUMP;
            im.Separator();
            case;
        }

        if im.IsItemClicked() {
            if im.IsKeyDown(.LeftCtrl) {
                if info.type == .BRANCH {
                    disasm_state.scroll_state = xx addr + cast,no_check(u32,info.off);
                }
            } else {
                if has_bp {
                    idx := ((ins >> 6) & 0xfffff) - 1;
                    write_4_v(addr, cpu.bp[idx], true);
                    cpu.bp[idx] = 0xffffffff;
                } else {
                    idx := 0;
                    for cpu.bp if it == 0xffffffff {
                        idx = it_index;
                        break;
                    }
                    cpu.bp[idx] = ins;
                    write_4_v(addr, xx 0xd | ((idx + 1) << 6), true);
                }
            }
        }
    }

    im.EndChild();
    im.End();
}
