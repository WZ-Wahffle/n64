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
    ri : Mem(0x20);
    mi : Mem(0x10);
    si : Mem(0x1c);
    pi : Mem(0x34);
    vi : Mem(0x38);
    ai : Mem(0x18);
    rdp_cmd : Mem(0x20);
    rom : Mem(0xfc00000);
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
        assert(false, "TODO: Read RDRAM Registers at 0x%", formatInt(addr, 16));
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
            if addr < 0x04040020 {
                return rsp.cp0[(addr & 0x1f) >> 2];
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
            assert(false, "TODO: Read AI Registers at 0x%", formatInt(addr, 16));
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
            else if addr < 0x04040020 {
                rsp.cp0[(addr & 0x1f) >> 2] = val;
            }
            else if addr == 0x04080000 {
                rsp.pc = val;
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
            if off == 3 {
                if val & 0x1 != 0 then mem.mi._32[3] &= 0xfffe;
                if val & 0x2 != 0 then mem.mi._32[3] |= 0x1;
                if val & 0x4 != 0 then mem.mi._32[3] &= 0xfffd;
                if val & 0x8 != 0 then mem.mi._32[3] |= 0x2;
                if val & 0x10 != 0 then mem.mi._32[3] &= 0xfffb;
                if val & 0x20 != 0 then mem.mi._32[3] |= 0x4;
                if val & 0x40 != 0 then mem.mi._32[3] &= 0xfff7;
                if val & 0x80 != 0 then mem.mi._32[3] |= 0x8;
                if val & 0x100 != 0 then mem.mi._32[3] &= 0xffef;
                if val & 0x200 != 0 then mem.mi._32[3] |= 0x10;
                if val & 0x400 != 0 then mem.mi._32[3] &= 0xffdf;
                if val & 0x800 != 0 then mem.mi._32[3] |= 0x20;
            } else {
                mem.mi._32[off] = val;
            }
        }
        else if addr < 0x04500000 {
            off := (addr - 0x04400000) >> 2;
            mem.vi._32[off] = val;
        }
        else if addr < 0x04600000 {
            off := (addr - 0x04500000) >> 2;
            mem.ai._32[off] = val;
            if off == 1 print("TODO: Audio channel playing 0x% bytes from 0x%\n",
                formatInt(mem.ai._32[1], 16), formatInt(mem.ai._32[0], 16));
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
                // TODO: set interrupt
            }
            if off == 4 {
                if val & 0b10 != 0 {
                    // TODO: clear interrupt if bit 1
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

            if off == 1 assert(false, "TODO: SI DMA Write 0x% bytes", formatInt(val, 16, 8));
            if off == 4 assert(false, "TODO: SI DMA Read 0x% bytes", formatInt(val, 16, 8));
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
