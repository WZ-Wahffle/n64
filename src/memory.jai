Memory :: struct {
    ram : union {
        _8: [0x800000]u8;
        _16: [0x400000]u16;
        _32: [0x200000]u32;
        _64: [0x100000]u64;
    }

    boot_rom : union {
        _8: [1984]u8;
        _16: [992]u16;
        _32: [496]u32;
        _64: [248]u64;
    }

    boot_ram : union {
        _8: [64]u8;
        _16: [32]u16;
        _32: [16]u32;
        _64: [8]u64;
    }

    imem : union {
        _8: [0x1000]u8;
        _16: [0x800]u16;
        _32: [0x400]u32;
        _64: [0x200]u64;
    }

    dmem : union {
        _8: [0x1000]u8;
        _16: [0x800]u16;
        _32: [0x400]u32;
        _64: [0x200]u64;
    }

    ri : union {
        _8: [0x20]u8;
        _16: [0x10]u16;
        _32: [0x8]u32;
    }

    mi : union {
        _8: [0x10]u8;
        _16: [0x8]u16;
        _32: [0x4]u32;
    }

    si : union {
        _8: [0x1c]u8;
        _16: [0xe]u16;
        _32: [0x7]u32;
    }

    pi : union {
        _8: [0x34]u8;
        _16: [0x1a]u16;
        _32: [0xd]u32;
    }

    vi : union {
        _8: [0x38]u8;
        _16: [0x1c]u16;
        _32: [0xe]u32;
    }

    ai : union {
        _8: [0x18]u8;
        _16: [0xc]u16;
        _32: [0x6]u32;
    }

    rdp_cmd : union {
        _8: [0x20]u8;
        _16: [0x10]u16;
        _32: [0x8]u32;
    }

    rom : union {
        _8: [0xfc00000]u8;
        _16: [0x7e00000]u16;
        _32: [0x3f00000]u32;
        _64: [0x1f8000]u64;
    }
}

bswap :: inline (val: u32) -> u32 {
    #asm {
        bswap.32 val;
    }
    return val;
}

read_4 :: (addr: u32) -> u32 {
    if addr < 0x00800000 {
        return bswap(mem.ram._32[addr >> 2]);
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
                return bswap(mem.dmem._32[(addr & 0xfff) >> 2]);
            }
            if addr < 0x04002000 {
                return bswap(mem.imem._32[(addr & 0xfff) >> 2]);
            }
            if addr < 0x04040000 {
                assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
            }
            if addr < 0x04040020 {
                return rsp.cp0[(addr & 0x1f) >> 2];
            }
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
            assert(false, "TODO: Read VI Registers at 0x%", formatInt(addr, 16));
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
        return bswap(mem.rom._32[(addr - 0x10000000) >> 2]);
    }
    if addr < 0x1fc007c0 {
        return bswap(mem.boot_rom._32[(addr - 0x1fc00000) >> 2]);
    }
    if addr < 0x1fc00800 {
        return bswap(mem.boot_ram._32[(addr - 0x1fc007c0) >> 2]);
    }

    assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
    return 0;
}

write_4 :: (addr: u32, val: u32, override := false) {
    if addr < 0x00800000 {
        mem.ram._32[addr >> 2] = bswap(val);
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
                mem.dmem._32[(addr & 0xfff) >> 2] = bswap(val);
            }
            else if addr < 0x04002000 {
                mem.imem._32[(addr & 0xfff) >> 2] = bswap(val);
            }
            else if addr < 0x04040000 {
                assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
            }
            else if addr < 0x04040020 {
                rsp.cp0[(addr & 0x1f) >> 2] = val;
            }
        }
        else if addr < 0x04200000 {
            assert(false, "TODO: Write DP Command Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        }
        else if addr < 0x04300000 {
            assert(false, "TODO: Write DP Span Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        }
        else if addr < 0x04400000 {
            off := (addr - 0x04300000) >> 2;
            mem.mi._32[off] = val;
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
                    mem.pi._32[4] = 0;
                }
            }
        }
        else if addr < 0x04800000 {
            off := (addr - 0x04700000) >> 2;
            mem.ri._32[off] = val;
        }
        else if addr < 0x04900000 {
            assert(false, "TODO: Write SI Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
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
        mem.rom._32[(addr - 0x10000000) >> 2] = bswap(val);
    }
    else if addr < 0x1fc007c0 {
        if !override assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
        mem.boot_rom._32[(addr - 0x1fc00000) >> 2] = bswap(val);
    }
    else if addr < 0x1fc00800 {
        off := (addr - 0x1fc007c0) >> 2;
        mem.boot_ram._32[off] = bswap(val);
        if off == 12 mem.boot_ram._32[15] = bswap(0x80);
    }
    else assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
}
