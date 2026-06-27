FPS :: 60;
CPU_CYCLES_PER_SECOND :: 93_750_000;
CPU_CYCLES_PER_FRAME :: CPU_CYCLES_PER_SECOND / FPS;
SCREEN_WIDTH :: 640;
SCREEN_HEIGHT :: 480;

WINDOW_WIDTH :: 1280;
WINDOW_HEIGHT :: 960;
#run assert(cast(float,WINDOW_WIDTH) / WINDOW_HEIGHT == cast(float,SCREEN_WIDTH) / SCREEN_HEIGHT, "Resolution must be 4:3!");
#run assert(WINDOW_WIDTH % SCREEN_WIDTH == 0 && WINDOW_HEIGHT % SCREEN_HEIGHT == 0, "Resolution must be multiple of 640x480!");

step :: (cycles: float) {
    if rsp.cp0[Sp.STATUS] & xx Sp_Status_R.HALT != 0 {
        cpu.remaining_cycles += cycles;
        while cpu.remaining_cycles > 0 && cpu.state != .STOPPED cpu_execute_next();
    } else {
        cpu.remaining_cycles += cycles;
        rsp.remaining_cycles += (cycles * 2) / 3;
        while (cpu.remaining_cycles > 0 || rsp.remaining_cycles > 0) && cpu.state != .STOPPED {
            cpu_execute_next();
            cpu_execute_next();
            rsp_execute_next();
            cpu_execute_next();
            rsp_execute_next();
        }
    }
}

ui :: () {
    rl.SetTraceLogLevel(.LOG_ERROR);
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "n64");
    rl.SetTargetFPS(FPS);
    im.CreateContext();
    im.GetIO().Fonts.AddFontFromMemoryTTF(im.GetIO().Fonts, font.data, xx font.count, 24);
    rg.backend_setup();
    setup_catppuccin_mocha_theme();

    cpu_disasm_state.bp_addr = *cpu.bp;
    rsp_disasm_state.bp_addr = *rsp.bp;

    show_header := false;
    show_cpu := false;
    show_disasm := false;
    show_rsp := false;
    show_rsp_disasm := false;
    show_rdp := false;
    show_mem := false;

    while(!rl.WindowShouldClose()) {
        rl.ClearBackground(rl.BLACK);
        rl.BeginDrawing();

        if rl.IsKeyPressed(rl.KeyboardKey.KEY_F9) cpu.state = .STOPPED;
        if rl.IsKeyDown(rl.KeyboardKey.KEY_F10) cpu.state = .STARTED;
        if rl.IsKeyPressed(rl.KeyboardKey.KEY_F11) cpu.state = .STARTED;
        if rl.IsKeyPressed(rl.KeyboardKey.KEY_TAB) show_header = !show_header;
        if rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT_SHIFT) {
            if rl.IsKeyPressed(rl.KeyboardKey.KEY_C) show_cpu = !show_cpu;
            if rl.IsKeyPressed(rl.KeyboardKey.KEY_D) show_disasm = !show_disasm;
            if rl.IsKeyPressed(rl.KeyboardKey.KEY_R) show_rsp = !show_rsp;
            if rl.IsKeyPressed(rl.KeyboardKey.KEY_S) show_rsp_disasm = !show_rsp_disasm;
            if rl.IsKeyPressed(rl.KeyboardKey.KEY_G) show_rdp = !show_rdp;
            if rl.IsKeyPressed(rl.KeyboardKey.KEY_M) show_mem = !show_mem;
        }

        if cpu.state == {
            case .STOPPED;
                // this page intentionally left blank
            case .STARTED;
                step(-cpu.remaining_cycles + 1);
                cpu.state = .RUNNING;
                #through;
            case .RUNNING;
                half_scanline_count := mem.vi._32[Vi.V_SYNC] & 0x3ff;
                if half_scanline_count == 0 {
                    step(CPU_CYCLES_PER_FRAME);
                } else {
                    cycles_per_half_scanline := CPU_CYCLES_PER_FRAME / half_scanline_count;
                    active_start := (mem.vi._32[Vi.V_START] >> 16) & 0x3ff;
                    active_end := mem.vi._32[Vi.V_START] & 0x3ff;
                    for 0..half_scanline_count-1 {
                        mem.vi._32[Vi.CURRENT] += 1;
                        if mem.vi._32[Vi.CURRENT] == half_scanline_count {
                            mem.vi._32[Vi.CURRENT] = 0;
                        }
                        if mem.vi._32[Vi.CURRENT] >= active_start && mem.vi._32[Vi.CURRENT] < active_end {
                            draw_scanline(mem.vi._32[Vi.CURRENT] - active_start, mem.vi._32[Vi.ORIGIN] & 0xffffff, mem.vi._32[Vi.WIDTH] & 0xfff, mem.vi._32[Vi.STATUS] & 0x3);
                        }

                        if mem.vi._32[Vi.CURRENT] == mem.vi._32[Vi.INTR] {
                            mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.VI;
                        }

                        check_rcp_interrupts();

                        step(xx cycles_per_half_scanline);

                        if cpu.state == .STOPPED {
                            mem.vi._32[Vi.CURRENT] = 0;
                            break;
                        }
                    }
                }
                if cpu_disasm_state.follow cpu_disasm_state.scroll_state = cpu.pc;
                if rsp_disasm_state.follow rsp_disasm_state.scroll_state = rsp.pc | 0x84001000;
        }
        rdp_process_display_list();

        rg.backend_frame_begin();

        if show_header
            if im.BeginMainMenuBar() {
                if im.BeginMenu("Tools") {
                    if im.MenuItem("cpu", "shift+c") {
                        show_cpu = !show_cpu;
                    }
                    if im.MenuItem("cpudisasm", "shift+d") {
                        show_disasm = !show_disasm;
                    }
                    if im.MenuItem("rsp", "shift+r") {
                        show_rsp = !show_rsp;
                    }
                    if im.MenuItem("rspdisasm", "shift+s") {
                        show_rsp_disasm = !show_rsp_disasm;
                    }
                    if im.MenuItem("rdp", "shift+g") {
                        show_rdp = !show_rdp;
                    }
                    if im.MenuItem("memory", "shift+m") {
                        show_mem = !show_mem;
                    }
                    im.EndMenu();
                }
                im.EndMainMenuBar();
            }

        if show_cpu cpu_window();
        if show_disasm disasm_window(*cpu_disasm_state);
        if show_rsp rsp_window();
        if show_rsp_disasm disasm_window(*rsp_disasm_state);
        if show_rdp rdp_window();
        if show_mem memory_window();

        rg.backend_frame_end();
        rl.EndDrawing();

        reset_temporary_storage();
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
        cpu.state = .RUNNING;
        step(-cpu.remaining_cycles + 1);
        cpu.state = .STOPPED;
        if cpu_disasm_state.follow cpu_disasm_state.scroll_state = cpu.pc;
        if rsp_disasm_state.follow rsp_disasm_state.scroll_state = rsp.pc | 0x84001000;
    }
    im.SeparatorText("Registers");
    im.Text_CFormat("PC: 0x%08x", cpu.pc);
    if im.TreeNode("GPRs") {
        for 0..15 {
                im.Text_CFormat("%s: 0x%016llx %s: 0x%016llx", regs[it*2].data, cpu.gpr[it*2], regs[it*2+1].data, cpu.gpr[it*2+1]);
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

rsp_window :: () {
    im.Begin("rsp");
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
        cpu.state = .RUNNING;
        step(-rsp.remaining_cycles + 1);
        cpu.state = .STOPPED;
        if cpu_disasm_state.follow cpu_disasm_state.scroll_state = cpu.pc;
        if rsp_disasm_state.follow rsp_disasm_state.scroll_state = rsp.pc | 0x84001000;
    }
    im.SeparatorText("Registers");
    im.Text_CFormat("PC: 0x%08x", rsp.pc);
    if im.TreeNode("GPRs") {
        for 0..15 {
                im.Text_CFormat("%s: 0x%08x %s: 0x%08x", regs[it*2].data, rsp.gpr[it*2], regs[it*2+1].data, rsp.gpr[it*2+1]);
            }
        im.TreePop();
    }
    im.End();
}

disasm :: (addr: u32, state: *Disasm_State) -> str: string, info: Disasm_Return, ins: u32 {
    ins := read_4_v(addr);
    a, b := disasm_explicit(addr, ins, state);
    return a, b, ins;
}

Disasm_Return :: struct {
    type: enum {
        NORMAL;
        BRANCH;
        JUMP;
        CALL;
        BREAK;
    }
    off: s32 = 0;
    cond: bool = false;
    bp_idx : u32 = 0;
}

disasm_explicit :: (addr: u32, val: u32, state: *Disasm_State) -> (str: string, info: Disasm_Return = {.NORMAL, 0, false, 0}) {
    to_reg :: (reg: u32, state: *Disasm_State) -> string {
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
        return ifx state.pretty_regs then labels[reg] else tprint("$r%", reg);
    }

    op := val >> 26;
    rs_idx := (val >> 21) & 0x1f;
    rs := to_reg(rs_idx, state);
    rt_idx := (val >> 16) & 0x1f;
    rt := to_reg(rt_idx, state);
    rd_idx := (val >> 11) & 0x1f;
    rd := to_reg(rd_idx, state);
    sa := (val >> 6) & 0x1f;
    funct := val & 0x3f;
    imm := val & 0xffff;
    dest := val & 0x3ffffff;
    if op == {
        case 0;
        if funct == {
            case 0;
            if rt_idx == 0 && rd_idx == 0 && sa == 0 return "NOP\0";
            return tprint("SLL %, %, 0x%\0", rd, rt, formatInt(sa, 16));
            case 2;
            return tprint("SRL %, %, 0x%\0", rd, rt, formatInt(sa, 16));
            case 3;
            return tprint("SRA %, %, 0x%\0", rd, rt, formatInt(sa, 16));
            case 4;
            return tprint("SLLV %, %, %\0", rd, rt, rs);
            case 6;
            return tprint("SLRV %, %, %\0", rd, rt, rs);
            case 8;
            return tprint("JR %\0", rs), .{type=.JUMP};
            case 9;
            return tprint("JALR %\0", rs), .{type=.JUMP};
            case 13;
            idx := (val >> 6) & 0xfffff;
            if idx == 0 return "BREAK 0x0\0";
            if idx == 0x1800 return "BREAK 0x1800\0";
            if idx == 0x1c00 return "BREAK 0x1c00\0";
            return disasm_explicit(addr, state.bp_addr.*[idx-1], state), .{type=.BREAK, bp_idx=idx-1};
            case 16;
            return tprint("MFHI %\0", rd);
            case 17;
            return tprint("MTHI %\0", rs);
            case 18;
            return tprint("MFLO %\0", rd);
            case 19;
            return tprint("MTLO %\0", rs);
            case 25;
            return tprint("MULTU %, %\0", rs, rt);
            case 26;
            return tprint("DIV %, %\0", rs, rt);
            case 27;
            return tprint("DIVU %, %\0", rs, rt);
            case 29;
            return tprint("DMULTU %, %\0", rs, rt);
            case 31;
            return tprint("DDIVU %, %\0", rs, rt);
            case 32;
            return tprint("ADD %, %, %\0", rd, rs, rt);
            case 33;
            return tprint("ADDU %, %, %\0", rd, rs, rt);
            case 34;
            return tprint("SUB %, %, %\0", rd, rs, rt);
            case 35;
            return tprint("SUBU %, %, %\0", rd, rs, rt);
            case 36;
            return tprint("AND %, %, %\0", rd, rs, rt);
            case 37;
            return tprint("OR %, %, %\0", rd, rs, rt);
            case 38;
            return tprint("XOR %, %, %\0", rd, rs, rt);
            case 39;
            return tprint("NOR %, %, %\0", rd, rs, rt);
            case 42;
            return tprint("SLT %, %, %\0", rd, rs, rt);
            case 43;
            return tprint("SLTU %, %, %\0", rd, rs, rt);
            case 60;
            return tprint("DSLL32 %, %, 0x%\0", rd, rt, formatInt(sa, 16));
            case 63;
            return tprint("DSRA32 %, %, 0x%\0", rd, rt, formatInt(sa, 16));
            case;
            return tprint("!SPECIAL %\0", funct);
        }
        case 1;
        if rt_idx == {
            case 0;
            if imm & 0x8000 != 0 imm |= 0xffff0000;
            imm <<= 2;
            return tprint("BLTZ %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
            case 1;
            if imm & 0x8000 != 0 imm |= 0xffff0000;
            imm <<= 2;
            return tprint("BGEZ %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
            case 2;
            if imm & 0x8000 != 0 imm |= 0xffff0000;
            imm <<= 2;
            return tprint("BLTZL %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
            case 3;
            if imm & 0x8000 != 0 imm |= 0xffff0000;
            imm <<= 2;
            return tprint("BGEZL %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
            case 17;
            if imm & 0x8000 != 0 imm |= 0xffff0000;
            imm <<= 2;
            if rs_idx == 0 then return tprint("BAL 0x%\0", formatInt(addr + imm + 4, 16, 8)), .{type=.CALL, off=cast,no_check(s32,imm + 4), cond=false};
            else return tprint("BGEZAL %, 0x%\0", rs, formatInt(addr + imm + 4, 16, 8)), .{type=.CALL, off=cast,no_check(s32,imm + 4), cond=true};
            case;
            return tprint("!REGIMM %\0", rt_idx);
        }
        case 2;
        return tprint("J 0x%\0", formatInt((addr & 0xf0000000) | (dest << 2), 16, 8));
        case 3;
        return tprint("JAL 0x%\0", formatInt((addr & 0xf0000000) | (dest << 2), 16, 8));
        case 4;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BEQ %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 5;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BNE %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 6;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BLEZ %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 7;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BGTZ %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 8;
        if imm & 0x8000 != 0 then imm |= 0xffff0000;
        return tprint("ADDI %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 9;
        if imm & 0x8000 != 0 then imm |= 0xffff0000;
        return tprint("ADDIU %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 10;
        return tprint("SLTI %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 11;
        return tprint("SLTIU %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 12;
        return tprint("ANDI %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 13;
        return tprint("ORI %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 14;
        return tprint("XORI %, %, 0x%\0", rt, rs, formatInt(imm, 16));
        case 15;
        return tprint("LUI %, 0x%\0", rt, formatInt(imm, 16));
        case 16; #through;
        case 17; #through;
        case 18;
        if rs_idx == {
            case 0;
            return tprint("MFC% %, %\0", op - 16, rt, rd);
            case 4;
            return tprint("MTC% %, %\0", op - 16, rt, rd);
            case 16;
            if (imm & 0x3f) == {
                case 1;
                return "TLBR";
                case 2;
                return "TLBWI";
                case 8;
                return "TLBP";
                case 24;
                return "ERET";
                case;
                return tprint("!CP0 %\0", imm & 0x3f);
            }
            case;
            return tprint("!COP% %\0", op - 16, rs_idx);
        }
        case 20;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BEQL %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 21;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BNEL %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 22;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BLEZL %, %, 0x%\0", rs, rt, formatInt(addr + imm + 4, 16, 8)), .{type=.BRANCH, off=cast,no_check(s32,imm + 4), cond=true};
        case 32;
        return tprint("LB %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 33;
        return tprint("LH %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 34;
        return tprint("LWL %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 35;
        return tprint("LW %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 36;
        return tprint("LBU %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 37;
        return tprint("LHU %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 38;
        return tprint("LWR %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 40;
        return tprint("SB %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 41;
        return tprint("SH %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 42;
        return tprint("SWL %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 43;
        return tprint("SW %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 46;
        return tprint("SWR %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 47;
        return tprint("CACHE %, 0x%(%)\0", rt_idx, formatInt(imm, 16), rs);
        case 55;
        return tprint("LD %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case 63;
        return tprint("SD %, 0x%(%)\0", rt, formatInt(imm, 16), rs);
        case;
        return tprint("!INS %\0", funct);
    }
}

Disasm_State :: struct {
    name: string;
    scroll_state: int;
    disasm_jump_buffer: [9]u8;
    bp_addr: *[32]u32;

    physical_addr := false;
    follow := true;
    pretty_regs := true;
};

cpu_disasm_state := Disasm_State.{name="cpudisasm", scroll_state=0xbfc00000};
rsp_disasm_state := Disasm_State.{name="rspdisasm", scroll_state=0x84001000};

disasm_window :: (state: *Disasm_State) {
    im.Begin(state.name.data, null, .NoScrollbar | .NoScrollWithMouse);
    if im.CollapsingHeader("Options", .OpenOnArrow) {
        im.Checkbox("Physical addresses", *state.physical_addr);
        im.Checkbox("Follow PC", *state.follow);
        im.Checkbox("Register Names", *state.pretty_regs);
    }
    im.Text("0x");
    im.SameLine();
    im.InputText(tprint("##%_jump_buffer\0", state.name).data, state.disasm_jump_buffer.data, 9);
    im.SameLine();
    if im.Button("Jump to...") {
        str := string.{8, state.disasm_jump_buffer.data};
        parsed := string_to_int(str, 16);
        state.scroll_state = parsed;
    }
    im.Separator();
    im.BeginChild(tprint("%_view\0", state.name).data, flags=.NoScrollbar | .NoScrollWithMouse);
    if im.IsWindowHovered() {
        if (im.GetIO().MouseWheel < 0) {
            state.scroll_state += 4;
        } else if (im.GetIO().MouseWheel > 0) {
            state.scroll_state -= 4;
            state.scroll_state = max(state.scroll_state, 0);
        }
    }
    line_count : int = xx ((im.GetWindowContentRegionMax().y - im.GetCursorPosY()) / im.GetTextLineHeightWithSpacing());
    view : [100] struct {virt_addr: u32; ins: u32; text: string; info: Disasm_Return; is_branch_delay: bool;};

    for 0..line_count {
        if state.scroll_state + (it - line_count / 2) * 4 < 0 {
            view[it] = .{0, 0, "", {}, false};
        } else {
            addr : u32 = xx (state.scroll_state + (it - line_count / 2) * 4);
            mnem, info, ins := disasm(addr, state);
            is_branch_delay := info.type == .BRANCH;
            view[it] = .{addr, ins, mnem, info, is_branch_delay};
        }
    }

    every_other := true;
    for line : 0..line_count {
        green := im.ImVec4.{0., 1., 0., 1.};
        red := im.ImVec4.{1., 0., 0., 1.};
        blue := im.ImVec4.{0., 0., 1., 1.};

        disp_addr := ifx state.physical_addr then virt2phys(view[line].virt_addr) else view[line].virt_addr;
        if view[line].virt_addr == cpu.pc im.TextColored_CFormat(*green, "  0x%08x: %s", disp_addr, view[line].text.data);
        else if virt2phys(view[line].virt_addr) == rsp.pc | 0x04001000 im.TextColored_CFormat(*blue, "  0x%08x: %s", disp_addr, view[line].text.data);
        else if view[line].info.type == .BREAK im.TextColored_CFormat(*red, "  0x%08x: %s", disp_addr, view[line].text.data);
        else im.Text_CFormat("  0x%08x: %s", disp_addr, view[line].text.data);

        if view[line].info.type == {
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
            src_y := (item_rect.y + (im.GetTextLineHeightWithSpacing()) + (im.GetTextLineHeight() / 2));
            dst_y := src_y + (im.GetTextLineHeightWithSpacing()) * view[line].info.off / 4;
            min_x := item_rect.x;
            max_x := min_x + 20;
            if every_other min_x += 5;
            every_other ^= true;
            draw_arrow(src_y, dst_y, min_x, max_x, (quickhash(view[line].virt_addr) & 0xffffff) | 0x80404040);
            case .JUMP;
            im.Separator();
            case;
        }

        if im.IsItemClicked() {
            if im.IsKeyDown(.LeftCtrl) {
                if view[line].info.type == .BRANCH {
                    state.scroll_state = xx view[line].virt_addr + cast,no_check(u32,view[line].info.off);
                }
            } else {
                if view[line].info.type == .BREAK {
                    write_4_v(view[line].virt_addr, state.bp_addr.*[view[line].info.bp_idx], true);
                    state.bp_addr.*[view[line].info.bp_idx] = 0xffffffff;
                } else {
                    idx := 0;
                    for state.bp_addr.* if it == 0xffffffff {
                        idx = it_index;
                        break;
                    }
                    state.bp_addr.*[idx] = view[line].ins;
                    write_4_v(view[line].virt_addr, xx 0xd | ((idx + 1) << 6), true);
                }
            }
        }
    }

    im.EndChild();
    im.End();
}

mem_state : struct {
    Mem_Region :: enum {
        NONE;
        RAM;
        DMEM;
        IMEM;
        RSP;
        RDP_CMD;
        RDP_SPAN;
        MI;
        VI;
        AI;
        PI;
        RI;
        SI;
        CART;
        BOOT_ROM;
        BOOT_RAM;
    };

    Mem_Size :: enum {
        _8;
        _16;
        _32;
        _64;
    }

    elem : [..]struct {
        region : Mem_Region;
        size : Mem_Size;
        scroll_state := 0;
        jump_buffer: [8]u8;
    };
};

memory_window :: () {
    region_names :: string.[
        "None",
        "RAM",
        "DMEM",
        "IMEM",
        "RSP",
        "RDP command",
        "RDP span",
        "MI",
        "VI",
        "AI",
        "PI",
        "RI",
        "SI",
        "Cartridge",
        "Boot ROM",
        "Boot RAM",
    ];

    size_names :: string.[
        "8-Bit",
        "16-Bit",
        "32-Bit",
        "64-Bit",
    ];

    get_region :: (region: mem_state.Mem_Region) -> (addr: *u8, size: int) {
        if #complete region == {
        case .NONE;
            return null, 0;
        case .RAM;
            return mem.ram._8.data, mem.ram._8.count;
        case .DMEM;
            return mem.dmem._8.data, mem.dmem._8.count;
        case .IMEM;
            return mem.imem._8.data, mem.imem._8.count;
        case .RSP;
            return xx rsp.cp0.data, rsp.cp0.count * 4;
        case .RDP_CMD;
            return mem.rdp_cmd._8.data, mem.rdp_cmd._8.count;
        case .RDP_SPAN;
            return null, 0;
        case .MI;
            return mem.mi._8.data, mem.mi._8.count;
        case .VI;
            return mem.vi._8.data, mem.vi._8.count;
        case .AI;
            return mem.ai._8.data, mem.ai._8.count;
        case .PI;
            return mem.pi._8.data, mem.pi._8.count;
        case .RI;
            return mem.ri._8.data, mem.ri._8.count;
        case .SI;
            return mem.si._8.data, mem.si._8.count;
        case .CART;
            return mem.rom._8.data, mem.rom._8.count;
        case .BOOT_ROM;
            return mem.boot_rom._8.data, mem.boot_rom._8.count;
        case .BOOT_RAM;
            return mem.boot_ram._8.data, mem.boot_ram._8.count;
        }
    }

    im.Begin("memory", flags=.NoScrollbar | .NoScrollWithMouse);
    im.BeginTabBar("##memtabbar");
    for * mem_state.elem {
        if im.BeginTabItem(tprint("%\0", it_index + 1).data) {
            if im.BeginCombo(tprint("##memregion%\0", it_index).data, region_names[it.region].data) {
                for region, idx : region_names {
                    is_selected := idx == xx it.region;
                    if im.Selectable(region.data, is_selected) {
                        it.region = xx idx;
                    }
                    if is_selected {
                        im.SetItemDefaultFocus();
                    }
                }
                im.EndCombo();
            }

            im.SameLine();

            if im.BeginCombo(tprint("##memsize%\0", it_index).data, size_names[it.size].data) {
                for size, idx : size_names {
                    is_selected := idx == xx it.size;
                    if im.Selectable(size.data, is_selected) {
                        it.size = xx idx;
                    }
                    if is_selected {
                        im.SetItemDefaultFocus();
                    }
                }
                im.EndCombo();
            }

            im.Text("0x");
            im.SameLine();
            if im.InputText("Jump to...", it.jump_buffer.data, 8) {
                str := string.{7, it.jump_buffer.data};
                parsed := string_to_int(str, 16);
                it.scroll_state = parsed / 16;
            }

            if it.region != .NONE {
                im.Separator();
                im.BeginChild(tprint("##memchild%\0", it_index).data, flags=.NoScrollbar | .NoScrollWithMouse);
                if im.IsWindowHovered() {
                    if (im.GetIO().MouseWheel) < 0 {
                        it.scroll_state += 1;
                    } else if (im.GetIO().MouseWheel) > 0 {
                        it.scroll_state -= 1;
                        it.scroll_state = max(it.scroll_state, 0);
                    }
                }
                addr, size := get_region(it.region);
                line_count : int = xx ceil(size / 16.0);
                word_size : int = xx pow(2.0, xx it.size);
                table_line_width : int = xx (16 / word_size);
                im.BeginTable(tprint("##memview%\0", it_index).data, xx (table_line_width + 1), .SizingFixedFit);
                im.TableNextRow();
                for y_off : 0..cast(int, im.GetWindowSize().y) {
                    if y_off + it.scroll_state > line_count {
                        break;
                    }
                    im.TableNextColumn();
                    im.Text_CFormat("0x%08x", (y_off + it.scroll_state) * 16);
                    for x_idx : 0..table_line_width-1 {
                        im.TableNextColumn();
                        formats :: string.["%02llx", "%04llx", "%08llx", "%016llx"];
                        masks :: u64.[0xff, 0xffff, 0xffffffff, 0xffffffffffffffff];
                        im.Text_CFormat(formats[it.size].data, (cast(*u64, addr + (y_off + it.scroll_state) * 16 + x_idx * word_size)).* & masks[it.size]);
                    }
                }
                im.EndTable();
                im.EndChild();
            }

            im.EndTabItem();
        }
    }
    if im.TabItemButton("+") {
        array_add(*mem_state.elem, .{});
    }
    im.EndTabBar();
    im.End();
}

rdp_window :: () {
    im.Begin("rdp");
    start := rsp.cp0[Sp.CMD_START];
    end := rsp.cp0[Sp.CMD_END];
    im.Text_CFormat("Display List Start: %08x", start);
    im.Text_CFormat("Display List End: %08x", end);
    im.Text_CFormat("RDP Status: %08x", rsp.cp0[Sp.CMD_STATUS]);
    im.Separator();

    xbus := rsp.cp0[Sp.CMD_STATUS] & xx Dp_Cmd_Status_R.XBUS_DMEM_DMA;
    addr := start;
    get_val :: (a: u32, x: u32) -> u64 {
        if x {
            return lswap(mem.dmem._64[a >> 3]);
        } else {
            return lswap(mem.ram._64[a >> 3]);
        }
    }
    while addr != end {
        val := get_val(addr, xbus);
        idx := (addr - start) / 8;
        cmd := (val >> 56) & 0x3f;

        if cmd == {
            case 0x27;
                im.Text("Sync Pipe");
            case 0x29;
                im.Text("Sync Full");
            case 0x2d;
                if im.CollapsingHeader(tprint("Set Scissor##%\0", idx).data, .OpenOnArrow) {
                    yl := val & 0xfff;
                    xl := (val >> 12) & 0xfff;
                    o := (val >> 24) & 1;
                    f := (val >> 25) & 1;
                    yh := (val >> 32) & 0xfff;
                    xh := (val >> 44) & 0xfff;

                    im.Indent();
                    im.Text("X top left: %", cast(float, xh) / 4);
                    im.Text("Y top left: %", cast(float, yh) / 4);
                    im.Text("X bottom right: %", cast(float, xl) / 4);
                    im.Text("Y bottom right: %", cast(float, yl) / 4);
                    im.Unindent();
                }
            case 0x2f;
                // prevent drawing multiple mode sets in a row
                if ((get_val(addr + 8, xbus) >> 56) & 0x3f) != 0x2f || addr + 8 == end {
                    if im.CollapsingHeader(tprint("Set Other Modes##%\0", idx).data, .OpenOnArrow) {
                        A := (val) & 0x1;
                        B := (val >> 1) & 0x1;
                        C := (val >> 2) & 0x1;
                        D := (val >> 3) & 0x1;
                        E := (val >> 4) & 0x1;
                        F := (val >> 5) & 0x1;
                        G := (val >> 6) & 0x1;
                        H := (val >> 7) & 0x1;
                        I := (val >> 8) & 0x3;
                        J := (val >> 10) & 0x3;
                        K := (val >> 12) & 0x1;
                        L := (val >> 13) & 0x1;
                        M := (val >> 14) & 0x1;
                        _ := (val >> 15) & 0x1;
                        O := (val >> 16) & 0x3;
                        P := (val >> 18) & 0x3;
                        Q := (val >> 20) & 0x3;
                        R := (val >> 22) & 0x3;
                        S := (val >> 24) & 0x3;
                        T := (val >> 26) & 0x3;
                        U := (val >> 28) & 0x3;
                        V := (val >> 30) & 0x3;
                        V1 := (val >> 36) & 0x3;
                        V2 := (val >> 38) & 0x3;
                        W := (val >> 40) & 0x1;
                        X := (val >> 41) & 0x1;
                        Y := (val >> 42) & 0x1;
                        Z := (val >> 43) & 0x1;
                        a := (val >> 44) & 0x1;
                        b := (val >> 45) & 0x1;
                        c := (val >> 46) & 0x1;
                        d := (val >> 47) & 0x1;
                        e := (val >> 48) & 0x1;
                        f := (val >> 49) & 0x1;
                        g := (val >> 50) & 0x1;
                        h := (val >> 51) & 0x1;
                        i := (val >> 52) & 0x3;
                        _ := (val >> 54) & 0x1;
                        k := (val >> 55) & 0x1;

                        im.Indent();
                        im.Text("Alpha Compare: %", cast(bool, A));
                        im.Text("Dither Alpha: %", cast(bool, B));
                        im.Text("Z Source: %", string.["Primitive Z", "Pixel Z"][C]);
                        im.Text("Antialiasing: %", cast(bool, D));
                        im.Text("Z Compare: %", cast(bool, E));
                        im.Text("Z Update: %", cast(bool, F));
                        im.Text("Image Read: %", cast(bool, G));
                        im.Text("Color On Coverage: %", cast(bool, H));
                        im.Text("Coverage Write: %", string.["clamp", "wrap", "zap", "save"][I]);
                        im.Text("Z Mode: %", string.["opaque", "interpenetrating", "transparent", "decal"][J]);
                        im.Text("Coverage Times Alpha: %", cast(bool, K));
                        im.Text("Alpha Coverage Select: %", cast(bool, L));
                        im.Text("Force Blend: %", cast(bool, M));
                        im.Text("Blend Multiply 2b Cycle 1: %", O);
                        im.Text("Blend Multiply 2b Cycle 0: %", P);
                        im.Text("Blend Multiply 2a Cycle 1: %", Q);
                        im.Text("Blend Multiply 2a Cycle 0: %", R);
                        im.Text("Blend Multiply 1b Cycle 1: %", S);
                        im.Text("Blend Multiply 1b Cycle 0: %", T);
                        im.Text("Blend Multiply 1a Cycle 1: %", U);
                        im.Text("Blend Multiply 1a Cycle 0: %", V);
                        im.Text("Alpha Dither Select: %", string.["pattern", "NOT pattern", "noise", "no dither"][V1]);
                        im.Text("RGB Dither Select: %", string.["magic square matrix", "bayer matrix", "noise", "no dither"][V2]);
                        im.Text("Chroma Keying: %", cast(bool, W));
                        im.Text("Color Convert Texel: %", cast(bool, X));
                        im.Text("Bilerp 1: %", cast(bool, Y));
                        im.Text("Bilerp 0: %", cast(bool, Z));
                        im.Text("Half Texel Interpolation: %", cast(bool, a));
                        im.Text("2x2 Texture Sampling: %", cast(bool, b));
                        im.Text("TLUT Type: %", string.["R5G5B5A1", "I8A8"][c]);
                        im.Text("TLUT: %", cast(bool, d));
                        im.Text("Texture LOD: %", cast(bool, e));
                        im.Text("Sharpened Texture: %", cast(bool, f));
                        im.Text("Detail Texture: %", cast(bool, g));
                        im.Text("Perspective Correction: %", cast(bool, h));
                        im.Text("Cycle Type: %", string.["1 cycle", "2 cycle", "copy", "fill"][i]);
                        im.Text("Atomic Primitives: %", cast(bool, k));
                        im.Unindent();
                    }
                }
            case 0x36;
                if im.CollapsingHeader(tprint("Fill Rectangle##%\0", idx).data, .OpenOnArrow) {
                    yh := val & 0xfff;
                    xh := (val >> 12) & 0xfff;
                    yl := (val >> 32) & 0xfff;
                    xl := (val >> 44) & 0xfff;
                    im.Indent();
                    im.Text("X top left: %", cast(float, xh) / 4);
                    im.Text("Y top left: %", cast(float, yh) / 4);
                    im.Text("X bottom right: %", cast(float, xl) / 4);
                    im.Text("Y bottom right: %", cast(float, yl) / 4);
                    im.Unindent();
                }
            case 0x37;
                if im.CollapsingHeader(tprint("Set Fill Color##%\0", idx).data, .OpenOnArrow) {
                    fill_color := val & 0xffffffff;
                    im.Indent();
                    im.Text_CFormat("Fill Color: 0x%08x", fill_color);
                    im.Unindent();
                }
            case 0x3c;
                if im.CollapsingHeader(tprint("Set Combine Mode##%\0", idx).data, .OpenOnArrow) {
                    add_a_1 := val & 0x7;
                    sub_b_a_1 := (val >> 3) & 0x7;
                    add_r_1 := (val >> 6) & 0x7;
                    add_a_0 := (val >> 9) & 0x7;
                    sub_b_a_0 := (val >> 12) & 0x7;
                    add_r_0 := (val >> 15) & 0x7;
                    mul_a_1 := (val >> 18) & 0x7;
                    sub_a_a_1 := (val >> 21) & 0x7;
                    sub_b_r_1 := (val >> 24) & 0xf;
                    sub_b_r_0 := (val >> 28) & 0xf;
                    mul_r_1 := (val >> 32) & 0x1f;
                    sub_a_r_1 := (val >> 37) & 0xf;
                    mul_a_0 := (val >> 41) & 0x7;
                    sub_a_a_0 := (val >> 44) & 0x7;
                    mul_r_0 := (val >> 47) & 0x1f;
                    sub_a_r_0 := (val >> 52) & 0xf;

                    im.Indent();
                    im.Text("Cycle 0 RGB A: %", sub_a_r_0);
                    im.Text("Cycle 0 RGB B: %", sub_b_r_0);
                    im.Text("Cycle 0 RGB C: %", mul_r_0);
                    im.Text("Cycle 0 RGB D: %", add_r_0);
                    im.Text("Cycle 0 Alpha A: %", sub_a_a_0);
                    im.Text("Cycle 0 Alpha B: %", sub_b_a_0);
                    im.Text("Cycle 0 Alpha C: %", mul_a_0);
                    im.Text("Cycle 0 Alpha D: %", add_a_0);
                    im.Text("Cycle 1 RGB A: %", sub_a_r_1);
                    im.Text("Cycle 1 RGB B: %", sub_b_r_1);
                    im.Text("Cycle 1 RGB C: %", mul_r_1);
                    im.Text("Cycle 1 RGB D: %", add_r_1);
                    im.Text("Cycle 1 Alpha A: %", sub_a_a_1);
                    im.Text("Cycle 1 Alpha B: %", sub_b_a_1);
                    im.Text("Cycle 1 Alpha C: %", mul_a_1);
                    im.Text("Cycle 1 Alpha D: %", add_a_1);
                    im.Unindent();
                }
            case 0x3e;
                if im.CollapsingHeader(tprint("Set Z Image##%\0", idx).data, .OpenOnArrow) {
                    dram_addr := val & 0x3ffffff;
                    im.Indent();
                    im.Text_CFormat("DRAM Address: 0x%07x", dram_addr);
                    im.Unindent();
                }
            case 0x3f;
                if im.CollapsingHeader(tprint("Set Color Image##%\0", idx).data, .OpenOnArrow) {
                    dram_addr := val & 0x3ffffff;
                    width := (val >> 32) & 0x3ff;
                    size := (val >> 51) & 0x3;
                    format := (val >> 53) & 0x7;
                    im.Indent();
                    im.Text_CFormat("DRAM Address: 0x%07x", dram_addr);
                    im.Text("Width: %", width + 1);
                    im.Text("Pixel Size: %", string.["4b", "8b", "16b", "32b"][size]);
                    im.Text("Image Format: %", string.["rgba", "yuv", "color index", "ia", "i"][format]);
                    im.Unindent();
                }
            case;
                assert(false, "TODO: Visualize unimplemented RDP command 0x%", formatInt(cmd, 16));
        }
        addr += 8;
    }
    im.End();
}
