#import "Basic";
#import "File";
#import "Math";
rg :: #import "RlImGui";
im :: #import "ImGui";
rl :: #import "Raylib";
_ :: #library,system,link_always "libSDL3";
font :: #run read_entire_file("../in/BrassMono.ttf");

main :: () {
    rl.SetTraceLogLevel(.LOG_ERROR);
    rl.InitWindow(1280, 960, "n64");
    im.CreateContext();
    im.GetIO().Fonts.AddFontFromMemoryTTF(im.GetIO().Fonts, font.data, xx font.count, 24);
    rg.backend_setup();
    setup_catppuccin_mocha_theme();

    while(!rl.WindowShouldClose()) {
        rl.ClearBackground(rl.BLACK);
        rl.BeginDrawing();
        rg.backend_frame_begin();
        rg.backend_frame_end();

        rl.EndDrawing();
    }
    rl.CloseWindow();
}

#load "style.jai";
