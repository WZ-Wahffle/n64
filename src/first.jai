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

main :: () {
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
