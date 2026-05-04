#import "Basic";
#import "File";
#import "Math";
rg :: #import "RlImGui";
im :: #import "ImGui";
rl :: #import "Raylib";
_ :: #library,system,link_always "libSDL3";
font :: #run read_entire_file("../in/BrassMono.ttf");
boot_rom :: #run read_entire_file("../in/boot_rom.bin");

cpu: Cpu;
rsp: Rsp;
mem: Memory;

main :: () {
    assert(mem.boot_rom._8.count == boot_rom.count, "Incorrect boot rom size");
    memcpy(mem.boot_rom._8.data, boot_rom.data, boot_rom.count);
    rsp_reset_registers();
    ui();
}

#load "style.jai";
#load "ui.jai";
#load "cpu.jai";
#load "rsp.jai";
#load "memory.jai";
#load "cpu-instrs.jai";
