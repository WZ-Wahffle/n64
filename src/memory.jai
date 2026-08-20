Memory :: struct {
    Mem :: union (size: int) {
        _8: [size]u8;
        _16: [size/2]u16;
        _32: [size/4]u32;
        _64: [size/8]u64;
    }

    ram : Mem(0x800000);
    boot_rom : Mem(0x7c0);
    boot_ram : Mem(0x40);
    imem : Mem(0x1000);
    dmem : Mem(0x1000);
    tmem: Mem(0x1000);
    ri : Mem(0x20);
    mi : Mem(0x10);
    si : Mem(0x1c);
    pi : Mem(0x34);
    vi : Mem(0x38);
    ai : Mem(0x18);
    rdp_cmd : Mem(0x20);
    rom : Mem(0xfc00000);
    eeprom : Mem(0x800);
}

Sp :: enum {
    MEM_ADDR;
    DRAM_ADDR;
    RD_LEN;
    WR_LEN;
    STATUS;
    DMA_FULL;
    DMA_BUSY;
    SEMAPHORE;
    CMD_START;
    CMD_END;
    CMD_CURRENT;
    CMD_STATUS;
    CMD_CLOCK;
    CMD_BUSY;
    CMD_PIPE_BUSY;
    CMD_TMEM_BUSY;
}

Sp_Status_W :: enum {
    CLR_HALT :: 0x1;
    SET_HALT :: 0x2;
    CLR_BROKE :: 0x4;
    CLR_INTR :: 0x8;
    SET_INTR :: 0x10;
    CLR_SSTEP :: 0x20;
    SET_SSTEP :: 0x40;
    CLR_INTR_BREAK :: 0x80;
    SET_INTR_BREAK :: 0x100;
    CLR_SIG0 :: 0x200;
    SET_SIG0 :: 0x400;
    CLR_SIG1 :: 0x800;
    SET_SIG1 :: 0x1000;
    CLR_SIG2 :: 0x2000;
    SET_SIG2 :: 0x4000;
    CLR_SIG3 :: 0x8000;
    SET_SIG3 :: 0x10000;
    CLR_SIG4 :: 0x20000;
    SET_SIG4 :: 0x40000;
    CLR_SIG5 :: 0x80000;
    SET_SIG5 :: 0x100000;
    CLR_SIG6 :: 0x200000;
    SET_SIG6 :: 0x400000;
    CLR_SIG7 :: 0x800000;
    SET_SIG7 :: 0x1000000;
}

Sp_Status_R :: enum {
    HALT :: 0x1;
    BROKE :: 0x2;
    DMA_BUSY :: 0x4;
    DMA_FULL :: 0x8;
    IO_FULL :: 0x10;
    SSTEP :: 0x20;
    INTR_BREAK :: 0x40;
    SIG0 :: 0x80;
    SIG1 :: 0x100;
    SIG2 :: 0x200;
    SIG3 :: 0x400;
    SIG4 :: 0x800;
    SIG5 :: 0x1000;
    SIG6 :: 0x2000;
    SIG7 :: 0x4000;
}

Dp_Cmd_Status_W :: enum u32 {
    CLR_XBUS_DMEM_DMA :: 0x1;
    SET_XBUS_DMEM_DMA :: 0x2;
    CLR_FREEZE :: 0x4;
    SET_FREEZE :: 0x8;
    CLR_FLUSH :: 0x10;
    SET_FLUSH :: 0x20;
    CLR_TMEM_CTR :: 0x40;
    CLR_PIPE_CTR :: 0x80;
    CLR_CMD_CTR :: 0x100;
    CLR_CLOCK_CTR :: 0x200;
}

Dp_Cmd_Status_R :: enum u32 {
    XBUS_DMEM_DMA :: 0x1;
    FREEZE :: 0x2;
    FLUSH :: 0x4;
    START_GCLK :: 0x8;
    TMEM_BUSY :: 0x10;
    PIPE_BUSY :: 0x20;
    CMD_BUSY :: 0x40;
    CBUF_READY :: 0x80;
    DMA_BUSY :: 0x100;
    END_VALID :: 0x200;
    START_VALID :: 0x400;
}

Mi :: enum {
    INIT_MODE;
    VERSION;
    INTR;
    INTR_MASK;
}

Mi_Mode_W :: enum u32 {
    CLR_INIT :: 0x80;
    SET_INIT :: 0x100;
    CLR_EBUS :: 0x200;
    SET_EBUS :: 0x400;
    CLR_DP_INTR :: 0x800;
    CLR_RDRAM :: 0x1000;
    SET_RDRAM :: 0x2000;
}

Mi_Mode_R :: enum u32 {
    INIT :: 0x80;
    EBUS :: 0x100;
    RDRAM :: 0x200;
}

Mi_Intr_Mask_W :: enum u32 {
    CLR_SP :: 0x1;
    SET_SP :: 0x2;
    CLR_SI :: 0x4;
    SET_SI :: 0x8;
    CLR_AI :: 0x10;
    SET_AI :: 0x20;
    CLR_VI :: 0x40;
    SET_VI :: 0x80;
    CLR_PI :: 0x100;
    SET_PI :: 0x200;
    CLR_DP :: 0x400;
    SET_DP :: 0x800;
}

Mi_Intr_R :: enum u32 {
    SP :: 0x1;
    SI :: 0x2;
    AI :: 0x4;
    VI :: 0x8;
    PI :: 0x10;
    DP :: 0x20;
}

Vi :: enum {
    STATUS;
    ORIGIN;
    WIDTH;
    INTR;
    CURRENT;
    BURST;
    V_SYNC;
    H_SYNC;
    LEAP;
    H_START;
    V_START;
    V_BURST;
    X_SCALE;
    Y_SCALE;
}

Si :: enum {
    DRAM_ADDR :: 0;
    DMA_READ :: 1;
    DMA_WRITE :: 4;
    STATUS :: 6;
}

Si_Status :: enum {
    DMA_BUSY :: 0x1;
    RD_BUSY :: 0x2;
    DMA_ERROR :: 0x8;
    INTERRUPT :: 0x1000;
}

lswap :: inline (val: u64) -> u64 {
    #asm {
        bswap.64 val;
    }
    return val;
}

wswap :: inline (val: u32) -> u32 {
    #asm {
        bswap.32 val;
    }
    return val;
}

hswap :: inline (val: u16) -> u16 {
    return ((val & 0xff) << 8) | (val >> 8);
}

read_1 :: (addr: u32) -> u8 {
    if addr < 0x00800000 {
        return mem.ram._8[addr];
    }
    if addr >= 0x04000000 && addr < 0x04001000 {
        return mem.dmem._8[addr & 0xfff];
    }
    if addr >= 0x04001000 && addr < 0x04002000 {
        return mem.imem._8[addr & 0xfff];
    }
    assert(false, "TODO: implement more 8-bit reads at 0x%", formatInt(addr, 16));
    return 0;
}

read_2 :: (addr: u32) -> u16 {
    if addr < 0x00800000 {
        return hswap(mem.ram._16[addr >> 1]);
    }
    if addr >= 0x04000000 && addr < 0x04001000 {
        return hswap(mem.dmem._16[(addr & 0xfff) >> 1]);
    }
    if addr >= 0x04001000 && addr < 0x04002000 {
        return hswap(mem.imem._16[(addr & 0xfff) >> 1]);
    }
    assert(false, "TODO: implement more 16-bit reads at 0x%", formatInt(addr, 16));
    return 0;
}

read_4 :: (addr: u32) -> u32 {
    if addr < 0x00800000 {
        return wswap(mem.ram._32[addr >> 2]);
    }
    if addr < 0x03f00000 {
        assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
    }
    if addr < 0x04000000 {
        print("Read RDRAM at %\n", formatInt(addr, 16));
        return 0; // surely nothing could go wrong here
        // assert(false, "TODO: Read RDRAM Registers at 0x%", formatInt(addr, 16));
    }
    if addr < 0x05000000 {
        if addr < 0x04100000 {
            if addr < 0x04001000 {
                return wswap(mem.dmem._32[(addr & 0xfff) >> 2]);
            }
            if addr < 0x04002000 {
                return wswap(mem.imem._32[(addr & 0xfff) >> 2]);
            }
            if addr < 0x04040000 {
                assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
            }
            if addr < 0x04040040 {
                off := (addr - 0x04040000) >> 2;
                ret := rsp.cp0[off];
                if off == xx Sp.SEMAPHORE {
                    // semaphore is set on read if cleared or already set
                    rsp.cp0[Sp.SEMAPHORE] = 1;
                }
                return ret;
            }
            if addr == 0x04080000 {
                return rsp.pc;
            }
            assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04200000 {
            off := (addr - 0x04100000) >> 2;
            return mem.rdp_cmd._32[off];
        }
        if addr < 0x04300000 {
            assert(false, "TODO: Read DP Span Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04400000 {
            off := (addr - 0x04300000) >> 2;
            return mem.mi._32[off];
        }
        if addr < 0x04500000 {
            off := (addr - 0x04400000) >> 2;
            return mem.vi._32[off];
        }
        if addr < 0x04600000 {
            off := (addr - 0x04500000) >> 2;
            if off == 1 {
                return ai.cnt;
            } else {
                return mem.ai._32[off];
            }
        }
        if addr < 0x04700000 {
            off := (addr - 0x04600000) >> 2;
            return mem.pi._32[off];
        }
        if addr < 0x04800000 {
            off := (addr - 0x04700000) >> 2;
            return mem.ri._32[off];
        }
        if addr < 0x04900000 {
            off := (addr - 0x04800000) >> 2;
            return mem.si._32[off];
        }
        assert(false, "TODO: Read RCP Registers at 0x%", formatInt(addr, 16));
    }
    if addr < 0x08000000 {
        assert(false, "TODO: Read N64DD at 0x%", formatInt(addr, 16));
    }
    if addr < 0x10000000 {
        assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
    }
    if addr < 0x1fc00000 {
        return wswap(mem.rom._32[(addr - 0x10000000) >> 2]);
    }
    if addr < 0x1fc007c0 {
        return wswap(mem.boot_rom._32[(addr - 0x1fc00000) >> 2]);
    }
    if addr < 0x1fc00800 {
        val := wswap(mem.boot_ram._32[(addr - 0x1fc007c0) >> 2]);
        print("Read BRAM % at %\n", formatInt(val, 16), formatInt(addr, 16));
        return val;
    }

    assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
    return 0;
}

write_1 :: (addr: u32, val: u8, override := false) {
    if addr < 0x00800000 {
        mem.ram._8[addr] = val;
    }
    else if addr >= 0x04000000 && addr < 0x04001000 {
        mem.dmem._8[addr & 0xfff] = val;
    }
    else if addr >= 0x04001000 && addr < 0x04002000 {
        mem.imem._8[addr & 0xfff] = val;
    }
    else assert(false, "TODO: implement more 8-bit writes at 0x%", formatInt(addr, 16));
}

write_2 :: (addr: u32, val: u16, override := false) {
    if addr < 0x00800000 {
        mem.ram._16[addr >> 1] = hswap(val);
    }
    else if addr >= 0x04000000 && addr < 0x04001000 {
        mem.dmem._16[(addr & 0xfff) >> 1] = hswap(val);
    }
    else if addr >= 0x04001000 && addr < 0x04002000 {
        mem.imem._16[(addr & 0xfff) >> 1] = hswap(val);
    }
    else assert(false, "TODO: implement more 16-bit writes at 0x%", formatInt(addr, 16));
}

write_4 :: (addr: u32, val: u32, override := false) {
    if addr < 0x00800000 {
        mem.ram._32[addr >> 2] = wswap(val);
    }
    else if addr < 0x03f00000 {
        assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x04000000 {
        // probably not important
    }
    else if addr < 0x05000000 {
        if addr < 0x04100000 {
            if addr < 0x04001000 {
                mem.dmem._32[(addr & 0xfff) >> 2] = wswap(val);
            }
            else if addr < 0x04002000 {
                mem.imem._32[(addr & 0xfff) >> 2] = wswap(val);
            }
            else if addr < 0x04040000 {
                assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
            }
            else if addr < 0x04040040 {
                off := (addr - 0x04040000) >> 2;
                if off == xx Sp.STATUS {
                    if val & xx Sp_Status_W.CLR_HALT != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.HALT;
                    if val & xx Sp_Status_W.SET_HALT != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.HALT;
                    if val & xx Sp_Status_W.CLR_BROKE != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.BROKE;
                    if val & xx Sp_Status_W.CLR_INTR != 0 then mem.mi._32[Mi.INTR] &= xx ~Mi_Intr_R.SP;
                    if val & xx Sp_Status_W.SET_INTR != 0 then mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.SP;
                    if val & xx Sp_Status_W.CLR_SSTEP != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SSTEP;
                    if val & xx Sp_Status_W.SET_SSTEP != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SSTEP;
                    if val & xx Sp_Status_W.CLR_INTR_BREAK != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.INTR_BREAK;
                    if val & xx Sp_Status_W.SET_INTR_BREAK != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.INTR_BREAK;
                    if val & xx Sp_Status_W.CLR_SIG0 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG0;
                    if val & xx Sp_Status_W.SET_SIG0 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG0;
                    if val & xx Sp_Status_W.CLR_SIG1 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG1;
                    if val & xx Sp_Status_W.SET_SIG1 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG1;
                    if val & xx Sp_Status_W.CLR_SIG2 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG2;
                    if val & xx Sp_Status_W.SET_SIG2 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG2;
                    if val & xx Sp_Status_W.CLR_SIG3 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG3;
                    if val & xx Sp_Status_W.SET_SIG3 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG3;
                    if val & xx Sp_Status_W.CLR_SIG4 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG4;
                    if val & xx Sp_Status_W.SET_SIG4 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG4;
                    if val & xx Sp_Status_W.CLR_SIG5 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG5;
                    if val & xx Sp_Status_W.SET_SIG5 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG5;
                    if val & xx Sp_Status_W.CLR_SIG6 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG6;
                    if val & xx Sp_Status_W.SET_SIG6 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG6;
                    if val & xx Sp_Status_W.CLR_SIG7 != 0 then rsp.cp0[Sp.STATUS] &= xx ~Sp_Status_R.SIG7;
                    if val & xx Sp_Status_W.SET_SIG7 != 0 then rsp.cp0[Sp.STATUS] |= xx Sp_Status_R.SIG7;
                } else if off == xx Sp.SEMAPHORE {
                    if val == 0 rsp.cp0[Sp.SEMAPHORE] = 0;
                } else if off == xx Sp.CMD_STATUS {
                    if val & xx Dp_Cmd_Status_W.CLR_XBUS_DMEM_DMA != 0 then rsp.cp0[Sp.CMD_STATUS] &= xx ~Dp_Cmd_Status_R.XBUS_DMEM_DMA;
                    if val & xx Dp_Cmd_Status_W.SET_XBUS_DMEM_DMA != 0 then rsp.cp0[Sp.CMD_STATUS] |= xx Dp_Cmd_Status_R.XBUS_DMEM_DMA;
                    if val & xx Dp_Cmd_Status_W.CLR_FREEZE != 0 then rsp.cp0[Sp.CMD_STATUS] &= xx ~Dp_Cmd_Status_R.FREEZE;
                    if val & xx Dp_Cmd_Status_W.SET_FREEZE != 0 then rsp.cp0[Sp.CMD_STATUS] |= xx Dp_Cmd_Status_R.FREEZE;
                    if val & xx Dp_Cmd_Status_W.CLR_FLUSH != 0 then rsp.cp0[Sp.CMD_STATUS] &= xx ~Dp_Cmd_Status_R.FLUSH;
                    if val & xx Dp_Cmd_Status_W.SET_FLUSH != 0 then rsp.cp0[Sp.CMD_STATUS] |= xx Dp_Cmd_Status_R.FLUSH;
                    if val & xx Dp_Cmd_Status_W.CLR_TMEM_CTR != 0 then rsp.cp0[Sp.CMD_TMEM_BUSY] = 0;
                    if val & xx Dp_Cmd_Status_W.CLR_PIPE_CTR != 0 then rsp.cp0[Sp.CMD_PIPE_BUSY] = 0;
                    if val & xx Dp_Cmd_Status_W.CLR_CMD_CTR != 0 then rsp.cp0[Sp.CMD_BUSY] = 0;
                    if val & xx Dp_Cmd_Status_W.CLR_CLOCK_CTR != 0 then rsp.cp0[Sp.CMD_CLOCK] = 0;
                } else {
                    rsp.cp0[off] = val;
                    if off == xx Sp.RD_LEN {
                        src := rsp.cp0[Sp.DRAM_ADDR];
                        dst := rsp.cp0[Sp.MEM_ADDR] & 0xfff;
                        region := rsp.cp0[Sp.MEM_ADDR] & 0x1000;

                        len := (val & 0xff8) + 8;
                        count := ((val >> 12) & 0xff) + 1;
                        skip_bytes := (val >> 20) & 0xff8;

                        for 0..count-1 {
                            for 0..(len/8)-1 {
                                if region != 0 {
                                    mem.imem._64[dst >> 3] = mem.ram._64[src >> 3];
                                } else {
                                    mem.dmem._64[dst >> 3] = mem.ram._64[src >> 3];
                                }
                                dst += 8;
                                src += 8;
                            }

                            src += skip_bytes;
                            dst += skip_bytes;
                        }
                    }
                    if off == xx Sp.WR_LEN {
                        dst := rsp.cp0[Sp.DRAM_ADDR];
                        src := rsp.cp0[Sp.MEM_ADDR] & 0xfff;
                        region := rsp.cp0[Sp.MEM_ADDR] & 0x1000;

                        len := (val & 0xff8) + 8;
                        count := ((val >> 12) & 0xff) + 1;
                        skip_bytes := (val >> 20) & 0xff8;

                        for 0..count-1 {
                            for 0..(len/8)-1 {
                                if region != 0 {
                                    mem.ram._64[dst >> 3] = mem.imem._64[src >> 3];
                                } else {
                                    mem.ram._64[dst >> 3] = mem.dmem._64[src >> 3];
                                }
                                dst += 8;
                                src += 8;
                            }

                            src += skip_bytes;
                            dst += skip_bytes;
                        }
                    }
                    if off == xx Sp.CMD_START {
                        rsp.cp0[Sp.CMD_CURRENT] = val;
                    }
                }
            }
            else if addr == 0x04080000 {
                rsp.pc = val & 0xfff;
            }
            else assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        }
        else if addr < 0x04200000 {
            assert(false, "TODO: Write DP Command Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        }
        else if addr < 0x04300000 {
            assert(false, "TODO: Write DP Span Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        }
        else if addr < 0x04400000 {
            off := (addr - 0x04300000) >> 2;
            if off == xx Mi.INTR_MASK {
                if val & xx Mi_Intr_Mask_W.CLR_SP != 0 then mem.mi._32[Mi.INTR_MASK] &= xx ~Mi_Intr_R.SP;
                if val & xx Mi_Intr_Mask_W.SET_SP != 0 then mem.mi._32[Mi.INTR_MASK] |= xx Mi_Intr_R.SP;
                if val & xx Mi_Intr_Mask_W.CLR_SI != 0 then mem.mi._32[Mi.INTR_MASK] &= xx ~Mi_Intr_R.SI;
                if val & xx Mi_Intr_Mask_W.SET_SI != 0 then mem.mi._32[Mi.INTR_MASK] |= xx Mi_Intr_R.SI;
                if val & xx Mi_Intr_Mask_W.CLR_AI != 0 then mem.mi._32[Mi.INTR_MASK] &= xx ~Mi_Intr_R.AI;
                if val & xx Mi_Intr_Mask_W.SET_AI != 0 then mem.mi._32[Mi.INTR_MASK] |= xx Mi_Intr_R.AI;
                if val & xx Mi_Intr_Mask_W.CLR_VI != 0 then mem.mi._32[Mi.INTR_MASK] &= xx ~Mi_Intr_R.VI;
                if val & xx Mi_Intr_Mask_W.SET_VI != 0 then mem.mi._32[Mi.INTR_MASK] |= xx Mi_Intr_R.VI;
                if val & xx Mi_Intr_Mask_W.CLR_PI != 0 then mem.mi._32[Mi.INTR_MASK] &= xx ~Mi_Intr_R.PI;
                if val & xx Mi_Intr_Mask_W.SET_PI != 0 then mem.mi._32[Mi.INTR_MASK] |= xx Mi_Intr_R.PI;
                if val & xx Mi_Intr_Mask_W.CLR_DP != 0 then mem.mi._32[Mi.INTR_MASK] &= xx ~Mi_Intr_R.DP;
                if val & xx Mi_Intr_Mask_W.SET_DP != 0 then mem.mi._32[Mi.INTR_MASK] |= xx Mi_Intr_R.DP;
            } else if off == xx Mi.INIT_MODE {
                mem.mi._32[Mi.INTR] &= xx ~Mi_Intr_R.DP;
            } else {
                mem.mi._32[off] = val;
            }
        }
        else if addr < 0x04500000 {
            off := (addr - 0x04400000) >> 2;
            if off == xx Vi.CURRENT {
                mem.mi._32[Mi.INTR] &= xx ~Mi_Intr_R.VI;
            } else {
                mem.vi._32[off] = val;
            }
        }
        else if addr < 0x04600000 {
            off := (addr - 0x04500000) >> 2;
            if off == 3 {
                mem.mi._32[Mi.INTR] &= xx ~Mi_Intr_R.AI;
            } else {
                mem.ai._32[off] = val;
                if off == 1 {
                    if ai.cnt == 0 {
                        ai.ptr = mem.ai._32[0];
                        ai.cnt = mem.ai._32[1];
                    } else {
                        ai.ptr_back = mem.ai._32[0];
                        ai.cnt_back = mem.ai._32[1];
                    }
                }
            }
        }
        else if addr < 0x04700000 {
            off := (addr - 0x04600000) >> 2;
            mem.pi._32[off] = val;
            if off == 2 assert(false, "TODO: PI DMA Read 0x% bytes", formatInt(val, 16, 8));
            if off == 3 {
                src := mem.pi._32[1];
                dst := mem.pi._32[0];
                assert((val + 1) % 4 == 0);
                for 0..(val/4) {
                    write_4(dst, read_4(src));
                    dst += 4;
                    src += 4;
                }

                mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.PI;
            }
            if off == 4 {
                if val & 0b10 != 0 {
                    mem.mi._32[Mi.INTR] &= xx ~Mi_Intr_R.PI;
                }
                if val & 0b1 != 0 {
                    // TODO: reset controller
                }
                mem.pi._32[4] = 0;
            }
        }
        else if addr < 0x04800000 {
            off := (addr - 0x04700000) >> 2;
            mem.ri._32[off] = val;
        }
        else if addr < 0x04900000 {
            off := (addr - 0x04800000) >> 2;
            mem.si._32[off] = val;

            if off == xx Si.DMA_READ {
                dst := mem.si._32[Si.DRAM_ADDR];
                for 0..15 {
                    write_4(dst, mem.boot_ram._32[it]);
                    dst += 4;
                }
                mem.si._32[Si.STATUS] |= xx Si_Status.INTERRUPT;
                mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.SI;
            }
            if off == xx Si.DMA_WRITE {
                src := mem.si._32[Si.DRAM_ADDR];
                for 0..15 {
                    mem.boot_ram._32[it] = read_4(src);
                    src += 4;
                }

                if mem.boot_ram._32[0] == 0xff0103ff && mem.boot_ram._32[1] == 0xffffffff {
                    // controller reset / init?
                    mem.boot_ram._32[0] = 0; // no errors
                    mem.boot_ram._16[2] = 5; // normal controller
                    mem.boot_ram._16[3] = 0; // no status
                } else if mem.boot_ram._32[0] == 0xff010401 && mem.boot_ram._32[1] == 0xffffffff {
                    // controller get buttons
                    mem.boot_ram._32[0] = 0; // no errors
                    keymap := cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN)) << 1) |
                    (cast(u16,rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_TRIGGER) > 0.5) << 2) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_MIDDLE_RIGHT)) << 3) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP)) << 4) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN)) << 5) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT)) << 6) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT)) << 7) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_LEFT_TRIGGER_1)) << 10) |
                    (cast(u16,rl.IsGamepadButtonDown(0, rl.GamepadButton.GAMEPAD_BUTTON_RIGHT_TRIGGER_1)) << 11) |
                    (cast(u16,(rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_Y) < -0.5)) << 12) |
                    (cast(u16,(rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_Y) > 0.5)) << 13) |
                    (cast(u16,(rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_X) < -0.5)) << 14) |
                    (cast(u16,(rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_X) > 0.5)) << 15);
                    mem.boot_ram._16[2] = keymap;
                    mem.boot_ram._8[6] = xx ((rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_X) + 1.0) * 128);
                    mem.boot_ram._8[7] = xx ((rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_Y) + 1.0) * 128);
                } else if mem.boot_ram._32[0] == 0x0 && mem.boot_ram._32[1] == 0xff010300 {
                    // eeprom status
                    mem.boot_ram._32[1] = 0; // no errors
                    mem.boot_ram._32[2] = 0x00800000; // 4k eeprom
                    mem.boot_ram._32[3] = 0; // no status
                } else if mem.boot_ram._32[0] == 0x0 && mem.boot_ram._32[1] & 0xffffff00 == 0x02080400 {
                    // eeprom read
                    addr := mem.boot_ram._32[1] & 0xff;
                    mem.boot_ram._32[1] = 0; // no errors
                    mem.boot_ram._32[2] = mem.eeprom._32[addr << 1];
                    mem.boot_ram._32[3] = mem.eeprom._32[(addr << 1) + 1];
                } else if mem.boot_ram._32[0] == 0x0 && mem.boot_ram._32[1] & 0xffffff00 == 0x0a010500 {
                    // eeprom write
                    addr := mem.boot_ram._32[1] & 0xff;
                    mem.eeprom._32[addr << 1] = mem.boot_ram._32[2];
                    mem.eeprom._32[(addr << 1) + 1] = mem.boot_ram._32[3];
                } else {
                    assert(false, "Unhandled CIC bus command %\n", mem.boot_ram._32);
                }

                mem.si._32[Si.STATUS] |= xx Si_Status.INTERRUPT;
                mem.mi._32[Mi.INTR] |= xx Mi_Intr_R.SI;
            }
            if off == xx Si.STATUS {
                mem.si._32[Si.STATUS] &= xx ~Si_Status.INTERRUPT;
                mem.mi._32[Mi.INTR] &= xx ~Mi_Intr_R.SI;
            }
        }
        else assert(false, "TODO: Write RCP Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x08000000 {
        assert(false, "TODO: Write N64DD 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x10000000 {
        assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x1fc00000 {
        if !override assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        mem.rom._32[(addr - 0x10000000) >> 2] = wswap(val);
    }
    else if addr < 0x1fc007c0 {
        if !override assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        mem.boot_rom._32[(addr - 0x1fc00000) >> 2] = wswap(val);
    }
    else if addr < 0x1fc00800 {
        off := (addr - 0x1fc007c0) >> 2;
        mem.boot_ram._32[off] = wswap(val);
        print("Write BRAM % at %\n", formatInt(val, 16), formatInt(addr, 16));
        if off == 12 mem.boot_ram._32[15] = wswap(0x80);
    }
    else assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
}
