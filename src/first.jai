#import "Basic";
#import "File";
#import "Math";
#import "String";
rg :: #import "RlImGui";
im :: #import "ImGui";
rl :: #import "Raylib";
_ :: #library,system,link_always "libSDL3";
font :: #run read_entire_file("../in/BrassMono.ttf");
boot_rom :: #run read_entire_file("../in/boot_rom.bin");

cpu: Cpu;
rsp: Rsp;
rdp: Rdp;
mem: Memory;
ai: Ai;

assertion_handler :: (loc: Source_Code_Location, msg: string) -> bool {
    print("%:%,%: Assertion failed", loc.fully_pathed_filename, loc.line_number, loc.character_number);
    if msg {
        print(": %\n", msg);
    } else {
        print("!\n");
    }
    print("\nStack trace:\n");
    print_stack_trace(context.stack_trace);
    print("\nCPU PC: 0x%\n", formatInt(cpu.pc, 16, 8));
    print("RSP PC: 0x%\n", formatInt(rsp.pc, 16, 8));
    print("CPU Registers:\n");
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
    for 0..15 {
        print("%:\t0x% %:\t0x%\n",
            labels[it * 2], formatInt(cpu.gpr[it * 2], 16, 16),
            labels[it * 2 + 1], formatInt(cpu.gpr[it * 2 + 1], 16, 16)
        );
    }
    print("RSP Registers:\n");
    for 0..15 {
        print("$r%:\t0x% $r%:\t0x%\n",
            it * 2, formatInt(rsp.gpr[it * 2], 16, 8),
            it * 2 + 1, formatInt(rsp.gpr[it * 2 + 1], 16, 8)
        );
    }
    __runtime_support_disable_stack_trace = true;
    return true;
}

main :: () {
    context.assertion_failed = assertion_handler;
    assert(mem.boot_rom._8.count == boot_rom.count, "Incorrect boot rom size");
    memcpy(mem.boot_rom._8.data, boot_rom.data, boot_rom.count);
    args := get_command_line_arguments();
    if args.count == 1 {
        print("Please provide a ROM image\n");
        exit(1);
    } else if args.count > 2 {
        print("Too many parameters provided, expected 1 but found %\n", args.count - 1);
        exit(1);
    } else if !ends_with(args[1], ".z64") {
        print("Incorrect file extension, expected .z64\n");
        exit(1);
    }

    rom := read_entire_file(args[1]);
    rom_name := string.{20, rom.data + 0x20};
    rom_country := string.{1, rom.data + 0x3e};
    rom_version := cast(*u8, rom.data + 0x3f).*;
    rom_crc1 := cast(*u32, rom.data + 0x10).*;
    rom_crc2 := cast(*u32, rom.data + 0x14).*;
    print("ROM Name: %\n", rom_name);
    print("ROM Region: %\n", rom_country);
    print("ROM Version: %\n", rom_version);
    print("ROM CRC1/CRC2: 0x%/0x%\n", formatInt(rom_crc1, 16, 8), formatInt(rom_crc2, 16, 8));
    print("ROM Size: %MB\n", rom.count / 1000000);

    if rom.count > 0xfc00000 {
        print("ROM size too large! Must be less than ~264MB\n");
        exit(1);
    }

    memcpy(mem.rom._8.data, rom.data, rom.count);

    // bypass checksum to allow breakpoints
    mem.rom._32[0x688 >> 2] = 0;

    cpu_reset();
    rsp_reset();
    ui();
}

#load "rounding.jai";
#load "ai.jai";
#load "vi.jai";
#load "style.jai";
#load "ui.jai";
#load "cpu.jai";
#load "rsp.jai";
#load "rdp.jai";
#load "memory.jai";
#load "cpu-instrs.jai";
#load "rsp-instrs.jai";
