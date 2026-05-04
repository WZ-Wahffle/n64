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
}

read_4 :: (addr: u32) -> u32 {
    if addr < 0x00800000 {
        return mem.ram._32[addr >> 2];
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
                return mem.dmem._32[(addr & 0xfff) >> 2];
            }
            if addr < 0x04002000 {
                return mem.imem._32[(addr & 0xfff) >> 2];
            }
            if addr < 0x04040000 {
                assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
            }
            if addr < 0x04040020 {
                return rsp.cp0[(addr & 0x1f) >> 2];
            }
        }
        if addr < 0x04200000 {
            assert(false, "TODO: Read DP Command Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04300000 {
            assert(false, "TODO: Read DP Span Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04400000 {
            assert(false, "TODO: Read MI Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04500000 {
            assert(false, "TODO: Read VI Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04600000 {
            assert(false, "TODO: Read AI Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04700000 {
            assert(false, "TODO: Read PI Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04800000 {
            assert(false, "TODO: Read RI Registers at 0x%", formatInt(addr, 16));
        }
        if addr < 0x04900000 {
            assert(false, "TODO: Read SI Registers at 0x%", formatInt(addr, 16));
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
        assert(false, "TODO: Read Game Pak at 0x%", formatInt(addr, 16));
    }
    if addr < 0x1fc007c0 {
        return mem.boot_rom._32[(addr - 0x1fc00000) >> 2];
    }
    if addr < 0x1fc00800 {
        return mem.boot_ram._32[(addr - 0x1fc007c0) >> 2];
    }

    assert(false, "Read Reserved at 0x%", formatInt(addr, 16));
    return 0;
}

write_4 :: (addr: u32, val: u32) {
    if addr < 0x00800000 {
        mem.ram._32[addr >> 2] = val;
    }
    else if addr < 0x03f00000 {
        assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x04000000 {
        assert(false, "TODO: Write RDRAM Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x05000000 {
        if addr < 0x04100000 {
            if addr < 0x04001000 {
                mem.dmem._32[(addr & 0xfff) >> 2] = val;
            }
            else if addr < 0x04002000 {
                mem.imem._32[(addr & 0xfff) >> 2] = val;
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
            assert(false, "TODO: Write MI Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
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
            if off == 2 assert(false, "TODO: PI DMA Read 0x% bytes");
            if off == 3 assert(false, "TODO: PI DMA Write 0x% bytes");
        }
        else if addr < 0x04800000 {
            assert(false, "TODO: Write RI Registers 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
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
        assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x1fc007c0 {
        assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
    }
    else if addr < 0x1fc00800 {
        mem.boot_ram._32[(addr - 0x1fc007c0) >> 2] = val;
    }
    else assert(false, "Write Reserved 0x% at 0x%", formatInt(val, 16), formatInt(addr, 16));
}
