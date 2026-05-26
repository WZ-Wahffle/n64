draw_scanline :: (y: int, fb_ram_addr: u32, line_width: u32, pixel_format: u32) {
    if pixel_format < 2 return;
    im: rl.Image;
    im.data = *mem.ram._8[fb_ram_addr];
    im.width = xx line_width;
    im.height = 1;
    im.format = ifx pixel_format == 2 then rl.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 else rl.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R5G5B5A1;
    tx := rl.LoadTextureFromImage(im);
    rl.DrawTexture(tx, 0, xx y, rl.WHITE);
    rl.DrawTexturePro(tx, .{0, 0, xx line_width, 1}, .{0, 0, WINDOW_WIDTH, 1}, .{0, xx y}, 0, rl.WHITE);
}
