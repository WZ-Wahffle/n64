ui :: () {
    rl.SetTraceLogLevel(.LOG_ERROR);
    rl.InitWindow(1280, 960, "n64");
    rl.SetTargetFPS(60);
    im.CreateContext();
    im.GetIO().Fonts.AddFontFromMemoryTTF(im.GetIO().Fonts, font.data, xx font.count, 24);
    rg.backend_setup();
    setup_catppuccin_mocha_theme();

    while(!rl.WindowShouldClose()) {
        rl.ClearBackground(rl.BLACK);
        rl.BeginDrawing();
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
    if im.Button("Step") {
        execute_next();
        disasm_scroll_state = cpu.pc;
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

disassemble_instruction :: (ins: u32) -> string {
    return "";
}

disasm :: (addr: u32) -> string {
    to_reg :: (val: u32) -> string {
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
        return labels[val];
    }

    val := read_4_v(addr);
    #asm {
        bswap.32 val;
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
            return tprint("JR %", rs);
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
            if rs_idx == 0 then return tprint("BAL 0x%", formatInt(addr + imm + 4, 16, 8));
            else return tprint("BEQ %, 0x%", rs, formatInt(addr + imm + 4, 16, 8));
            case;
            assert(false, "% %", rt_idx, formatInt(addr, 16));
        }
        case 4;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BEQ %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8));
        case 5;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BNE %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8));
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
        return tprint("BEQL %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8));
        case 21;
        if imm & 0x8000 != 0 imm |= 0xffff0000;
        imm <<= 2;
        return tprint("BNEL %, %, 0x%", rs, rt, formatInt(addr + imm + 4, 16, 8));
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

disasm_scroll_state := 0xbfc00000;
disasm_window :: () {
    im.Begin("disasm", null, .NoScrollbar | .NoScrollWithMouse);
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            disasm_scroll_state += 4;
        } else if im.GetIO().MouseWheel > 0 {
            disasm_scroll_state -= 4;
            disasm_scroll_state = max(disasm_scroll_state, 0);
        }
    }

    for 0..(cast(int)im.GetWindowSize().y / 24) {
        addr : u32 = xx (disasm_scroll_state + xx it * 4);
        col := im.ImVec4.{1., 0., 0., 1.};
        if addr == cpu.pc im.TextColored_CFormat(*col, "0x%08x: %s", addr, disasm(addr).data);
        else im.Text_CFormat("0x%08x: %s", addr, disasm(addr).data);
    }

    im.End();
}
