Rdp :: struct {
    other_modes : u64 = 0;
    scissor_x_min : u64 = 0;
    scissor_x_max : u64 = 0;
    scissor_y_min : u64 = 0;
    scissor_y_max : u64 = 0;
    combine_mode : u64 = 0;
    z_base_addr : u32 = 0;
    color_image : u64 = 0;
    fill_color : u64 = 0;
}

rdp_process_display_list :: () {
    start := rsp.cp0[Sp.CMD_CURRENT];
    end := rsp.cp0[Sp.CMD_END];
    xbus := rsp.cp0[Sp.CMD_STATUS] & xx Dp_Cmd_Status_R.XBUS_DMEM_DMA;

    if start == end return;
    if cpu.state != .RUNNING return;
    addr := start;
    while addr < end {
        val : u64;
        if xbus {
            val = lswap(mem.dmem._64[addr >> 3]);
        } else {
            val = lswap(mem.ram._64[addr >> 3]);
        }

        cmd := (val >> 56) & 0x3f;

        if cmd == {
            case 0x27; // sync pipe
            case 0x29; // sync full
                // I assume these syncs don't mean much
            case 0x2d; // set scissor
                rdp.scissor_y_max = (val & 0xfff) >> 2;
                rdp.scissor_x_max = ((val >> 12) & 0xfff) >> 2;
                rdp.scissor_y_min = ((val >> 32) & 0xfff) >> 2;
                rdp.scissor_x_min = ((val >> 44) & 0xfff) >> 2;
                // ignoring the scanline peculiarities
            case 0x2f; // set other modes
                rdp.other_modes = val & 0xffffffffffffff;
            case 0x36; // fill rectangle
                y := (val & 0xfff) >> 2;
                x_min := ((val >> 12) & 0xfff) >> 2;
                y_max := ((val >> 32) & 0xfff) >> 2;
                x_max := ((val >> 44) & 0xfff) >> 2;
                cycle_mode := (rdp.other_modes >> 52) & 0x3;
                if cycle_mode == {
                    case 3; // fill mode
                        addr := rdp.color_image & 0x3ffffff;
                        width := ((rdp.color_image >> 32) & 0x3ff) + 1;
                        size := (rdp.color_image >> 51) & 0x3;
                        line_width_bytes := (width * u64.[1, 2, 4, 8][size]) / 2;
                        line_offset_bytes := (x_min * u64.[1, 2, 4, 8][size]) / 2;
                        line_end_bytes := (x_max * u64.[1, 2, 4, 8][size]) / 2;
                        col := lswap(rdp.fill_color | (rdp.fill_color << 32));
                        while y <= y_max {
                            x := line_offset_bytes;
                            while x <= line_end_bytes {
                                // mem.ram._64[(addr + y * line_width_bytes + x) >> 3] = col;
                                x += 8;
                            }
                            y += 1;
                        }
                    case;
                        assert(false, "TODO: unimplemented cycle mode for fill rect %", cycle_mode);
                }
            case 0x37; // set fill color
                rdp.fill_color = val & 0xffffffff;
            case 0x3c; // set combine mode
                rdp.combine_mode = val & 0xffffffffffffff;
            case 0x3e; // set z image
                rdp.z_base_addr = xx (val & 0x1ffffff);
            case 0x3f; // set color image
                rdp.color_image = val & 0xffffffffffffff;
            case;
                assert(false, "TODO: Unimplemented RDP command 0x%", formatInt(cmd, 16));
        }

        addr += 8;
    }
    rsp.cp0[Sp.CMD_CURRENT] = addr;
    mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.DP;
    rsp.cp0[Sp.CMD_STATUS] |= xx Dp_Cmd_Status_R.CBUF_READY;
}
