/*
Port of rlImGui (imgui backend for Raylib: https://github.com/raylib-extras/rlImGui).
I made it, because I couldn't figure out how to overcome absurd amount of linking errors.
Some functions are untested, but at least it works.
Requires newest ImGui. Developed with a custom Raylib module,
that strips rl prefixes from rlgl.h
License of original library below:
LICENSE: ZLIB
Copyright (c) 2020 Jeffery Myers
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#scope_module

key_map          : Table(rl.KeyboardKey, im.Key);
mouse_cursor_map : Table(im.MouseCursor, rl.MouseCursor);

current_mouse_cursor := im.MouseCursor.COUNT;

font_texture : rl.Texture2D;

last_frame_focused   := false;
last_control_pressed := false;
last_shift_pressed   := false;
last_alt_pressed     := false;
last_super_pressed   := false;

backend_get_clip_text :: (user_data: *void) -> *u8 #c_call {
	return rl.GetClipboardText();
}

backend_set_clip_text :: (user_data: *void, text: *u8) #c_call {
	rl.SetClipboardText(text);
}

setup_keymap :: () {
	table_add(*key_map, rl.KeyboardKey.KEY_APOSTROPHE,    im.Key.Apostrophe     );
	table_add(*key_map, rl.KeyboardKey.KEY_COMMA,         im.Key.Comma          );
	table_add(*key_map, rl.KeyboardKey.KEY_MINUS,         im.Key.Minus          );
	table_add(*key_map, rl.KeyboardKey.KEY_PERIOD,        im.Key.Period         );
	table_add(*key_map, rl.KeyboardKey.KEY_SLASH,         im.Key.Slash          );
	table_add(*key_map, rl.KeyboardKey.KEY_ZERO,          im.Key._0             );
	table_add(*key_map, rl.KeyboardKey.KEY_ONE,           im.Key._1             );
	table_add(*key_map, rl.KeyboardKey.KEY_TWO,           im.Key._2             );
	table_add(*key_map, rl.KeyboardKey.KEY_THREE,         im.Key._3             );
	table_add(*key_map, rl.KeyboardKey.KEY_FOUR,          im.Key._4             );
	table_add(*key_map, rl.KeyboardKey.KEY_FIVE,          im.Key._5             );
	table_add(*key_map, rl.KeyboardKey.KEY_SIX,           im.Key._6             );
	table_add(*key_map, rl.KeyboardKey.KEY_SEVEN,         im.Key._7             );
	table_add(*key_map, rl.KeyboardKey.KEY_EIGHT,         im.Key._8             );
	table_add(*key_map, rl.KeyboardKey.KEY_NINE,          im.Key._9             );
	table_add(*key_map, rl.KeyboardKey.KEY_SEMICOLON,     im.Key.Semicolon      );
	table_add(*key_map, rl.KeyboardKey.KEY_EQUAL,         im.Key.Equal          );
	table_add(*key_map, rl.KeyboardKey.KEY_A,             im.Key.A              );
	table_add(*key_map, rl.KeyboardKey.KEY_B,             im.Key.B              );
	table_add(*key_map, rl.KeyboardKey.KEY_C,             im.Key.C              );
	table_add(*key_map, rl.KeyboardKey.KEY_D,             im.Key.D              );
	table_add(*key_map, rl.KeyboardKey.KEY_E,             im.Key.E              );
	table_add(*key_map, rl.KeyboardKey.KEY_F,             im.Key.F              );
	table_add(*key_map, rl.KeyboardKey.KEY_G,             im.Key.G              );
	table_add(*key_map, rl.KeyboardKey.KEY_H,             im.Key.H              );
	table_add(*key_map, rl.KeyboardKey.KEY_I,             im.Key.I              );
	table_add(*key_map, rl.KeyboardKey.KEY_J,             im.Key.J              );
	table_add(*key_map, rl.KeyboardKey.KEY_K,             im.Key.K              );
	table_add(*key_map, rl.KeyboardKey.KEY_L,             im.Key.L              );
	table_add(*key_map, rl.KeyboardKey.KEY_M,             im.Key.M              );
	table_add(*key_map, rl.KeyboardKey.KEY_N,             im.Key.N              );
	table_add(*key_map, rl.KeyboardKey.KEY_O,             im.Key.O              );
	table_add(*key_map, rl.KeyboardKey.KEY_P,             im.Key.P              );
	table_add(*key_map, rl.KeyboardKey.KEY_Q,             im.Key.Q              );
	table_add(*key_map, rl.KeyboardKey.KEY_R,             im.Key.R              );
	table_add(*key_map, rl.KeyboardKey.KEY_S,             im.Key.S              );
	table_add(*key_map, rl.KeyboardKey.KEY_T,             im.Key.T              );
	table_add(*key_map, rl.KeyboardKey.KEY_U,             im.Key.U              );
	table_add(*key_map, rl.KeyboardKey.KEY_V,             im.Key.V              );
	table_add(*key_map, rl.KeyboardKey.KEY_W,             im.Key.W              );
	table_add(*key_map, rl.KeyboardKey.KEY_X,             im.Key.X              );
	table_add(*key_map, rl.KeyboardKey.KEY_Y,             im.Key.Y              );
	table_add(*key_map, rl.KeyboardKey.KEY_Z,             im.Key.Z              );
	table_add(*key_map, rl.KeyboardKey.KEY_SPACE,         im.Key.Space          );
	table_add(*key_map, rl.KeyboardKey.KEY_ESCAPE,        im.Key.Escape         );
	table_add(*key_map, rl.KeyboardKey.KEY_ENTER,         im.Key.Enter          );
	table_add(*key_map, rl.KeyboardKey.KEY_TAB,           im.Key.Tab            );
	table_add(*key_map, rl.KeyboardKey.KEY_BACKSPACE,     im.Key.Backspace      );
	table_add(*key_map, rl.KeyboardKey.KEY_INSERT,        im.Key.Insert         );
	table_add(*key_map, rl.KeyboardKey.KEY_DELETE,        im.Key.Delete         );
	table_add(*key_map, rl.KeyboardKey.KEY_RIGHT,         im.Key.RightArrow     );
	table_add(*key_map, rl.KeyboardKey.KEY_LEFT,          im.Key.LeftArrow      );
	table_add(*key_map, rl.KeyboardKey.KEY_DOWN,          im.Key.DownArrow      );
	table_add(*key_map, rl.KeyboardKey.KEY_UP,            im.Key.UpArrow        );
	table_add(*key_map, rl.KeyboardKey.KEY_PAGE_UP,       im.Key.PageUp         );
	table_add(*key_map, rl.KeyboardKey.KEY_PAGE_DOWN,     im.Key.PageDown       );
	table_add(*key_map, rl.KeyboardKey.KEY_HOME,          im.Key.Home           );
	table_add(*key_map, rl.KeyboardKey.KEY_END,           im.Key.End            );
	table_add(*key_map, rl.KeyboardKey.KEY_CAPS_LOCK,     im.Key.CapsLock       );
	table_add(*key_map, rl.KeyboardKey.KEY_SCROLL_LOCK,   im.Key.ScrollLock     );
	table_add(*key_map, rl.KeyboardKey.KEY_NUM_LOCK,      im.Key.NumLock        );
	table_add(*key_map, rl.KeyboardKey.KEY_PRINT_SCREEN,  im.Key.PrintScreen    );
	table_add(*key_map, rl.KeyboardKey.KEY_PAUSE,         im.Key.Pause          );
	table_add(*key_map, rl.KeyboardKey.KEY_F1,            im.Key.F1             );
	table_add(*key_map, rl.KeyboardKey.KEY_F2,            im.Key.F2             );
	table_add(*key_map, rl.KeyboardKey.KEY_F3,            im.Key.F3             );
	table_add(*key_map, rl.KeyboardKey.KEY_F4,            im.Key.F4             );
	table_add(*key_map, rl.KeyboardKey.KEY_F5,            im.Key.F5             );
	table_add(*key_map, rl.KeyboardKey.KEY_F6,            im.Key.F6             );
	table_add(*key_map, rl.KeyboardKey.KEY_F7,            im.Key.F7             );
	table_add(*key_map, rl.KeyboardKey.KEY_F8,            im.Key.F8             );
	table_add(*key_map, rl.KeyboardKey.KEY_F9,            im.Key.F9             );
	table_add(*key_map, rl.KeyboardKey.KEY_F10,           im.Key.F10            );
	table_add(*key_map, rl.KeyboardKey.KEY_F11,           im.Key.F11            );
	table_add(*key_map, rl.KeyboardKey.KEY_F12,           im.Key.F12            );
	table_add(*key_map, rl.KeyboardKey.KEY_LEFT_SHIFT,    im.Key.LeftShift      );
	table_add(*key_map, rl.KeyboardKey.KEY_LEFT_CONTROL,  im.Key.LeftCtrl       );
	table_add(*key_map, rl.KeyboardKey.KEY_LEFT_ALT,      im.Key.LeftAlt        );
	table_add(*key_map, rl.KeyboardKey.KEY_LEFT_SUPER,    im.Key.LeftSuper      );
	table_add(*key_map, rl.KeyboardKey.KEY_RIGHT_SHIFT,   im.Key.RightShift     );
	table_add(*key_map, rl.KeyboardKey.KEY_RIGHT_CONTROL, im.Key.RightCtrl      );
	table_add(*key_map, rl.KeyboardKey.KEY_RIGHT_ALT,     im.Key.RightAlt       );
	table_add(*key_map, rl.KeyboardKey.KEY_RIGHT_SUPER,   im.Key.RightSuper     );
	table_add(*key_map, rl.KeyboardKey.KEY_KB_MENU,       im.Key.Menu           );
	table_add(*key_map, rl.KeyboardKey.KEY_LEFT_BRACKET,  im.Key.LeftBracket    );
	table_add(*key_map, rl.KeyboardKey.KEY_BACKSLASH,     im.Key.Backslash      );
	table_add(*key_map, rl.KeyboardKey.KEY_RIGHT_BRACKET, im.Key.RightBracket   );
	table_add(*key_map, rl.KeyboardKey.KEY_GRAVE,         im.Key.GraveAccent    );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_0,          im.Key.Keypad0        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_1,          im.Key.Keypad1        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_2,          im.Key.Keypad2        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_3,          im.Key.Keypad3        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_4,          im.Key.Keypad4        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_5,          im.Key.Keypad5        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_6,          im.Key.Keypad6        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_7,          im.Key.Keypad7        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_8,          im.Key.Keypad8        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_9,          im.Key.Keypad9        );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_DECIMAL,    im.Key.KeypadDecimal  );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_DIVIDE,     im.Key.KeypadDivide   );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_MULTIPLY,   im.Key.KeypadMultiply );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_SUBTRACT,   im.Key.KeypadSubtract );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_ADD,        im.Key.KeypadAdd      );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_ENTER,      im.Key.KeypadEnter    );
	table_add(*key_map, rl.KeyboardKey.KEY_KP_EQUAL,      im.Key.KeypadEqual    );
}

setup_mouse_cursors :: () {
    table_add(*mouse_cursor_map, im.MouseCursor.Arrow,      rl.MouseCursor.MOUSE_CURSOR_ARROW         );
	table_add(*mouse_cursor_map, im.MouseCursor.TextInput,  rl.MouseCursor.MOUSE_CURSOR_IBEAM         );
	table_add(*mouse_cursor_map, im.MouseCursor.Hand,       rl.MouseCursor.MOUSE_CURSOR_POINTING_HAND );
	table_add(*mouse_cursor_map, im.MouseCursor.ResizeAll,  rl.MouseCursor.MOUSE_CURSOR_RESIZE_ALL    );
	table_add(*mouse_cursor_map, im.MouseCursor.ResizeEW,   rl.MouseCursor.MOUSE_CURSOR_RESIZE_EW     );
	table_add(*mouse_cursor_map, im.MouseCursor.ResizeNESW, rl.MouseCursor.MOUSE_CURSOR_RESIZE_NESW   );
	table_add(*mouse_cursor_map, im.MouseCursor.ResizeNS,   rl.MouseCursor.MOUSE_CURSOR_RESIZE_NS     );
	table_add(*mouse_cursor_map, im.MouseCursor.ResizeNWSE, rl.MouseCursor.MOUSE_CURSOR_RESIZE_NWSE   );
	table_add(*mouse_cursor_map, im.MouseCursor.NotAllowed, rl.MouseCursor.MOUSE_CURSOR_NOT_ALLOWED   );
}

#scope_export

backend_setup :: (dark_theme := true) {
	last_frame_focused   = rl.IsWindowFocused();
	last_control_pressed = false;
	last_shift_pressed   = false;
	last_alt_pressed     = false;
	last_super_pressed   = false;

	setup_keymap();

	io := im.GetIO();
	im.ImFontAtlas.AddFontDefault(io.Fonts);

	if dark_theme {
		im.StyleColorsDark();
	} else {
		im.StyleColorsLight();
	}

	setup_mouse_cursors();

	io.BackendFlags_ |= im.BackendFlags.HasMouseCursors;
	io.BackendPlatformName = "imgui_impl_raylib";
	io.MousePos            = im.ImVec2.{0, 0};
	io.SetClipboardTextFn  = backend_set_clip_text;
	io.GetClipboardTextFn  = backend_get_clip_text;
	io.ClipboardUserData   = null;

	pixels: *u8 = null;
	width, height : s32;
	im.ImFontAtlas.GetTexDataAsRGBA32(io.Fonts, *pixels, *width, *height);
	image := rl.GenImageColor(width, height, rl.BLANK);
	memcpy(image.data, pixels, width * height * 4);

	if (font_texture.id != 0) {
		rl.UnloadTexture(font_texture);
	}

	font_texture = rl.LoadTextureFromImage(image);
	rl.UnloadImage(image);
	io.Fonts.TexID = *font_texture;
}

#scope_module

new_frame :: () {
	io := im.GetIO();

	if rl.IsWindowFullscreen() {
		monitor := rl.GetCurrentMonitor();
		io.DisplaySize.x = cast(float) rl.GetMonitorWidth(monitor);
		io.DisplaySize.y = cast(float) rl.GetMonitorHeight(monitor);
	} else {
		io.DisplaySize.x = cast(float) rl.GetScreenWidth();
		io.DisplaySize.y = cast(float) rl.GetScreenHeight();
	}

	width  := cast(s32) io.DisplaySize.x;
	height := cast(s32) io.DisplaySize.y;

	// #ifdef PLATFORM_DESKTOP
	// 	glfwGetFramebufferSize(glfwGetCurrentContext(), &width, &height);
	// #endif

	if width > 0 && height > 0 {
		io.DisplayFramebufferScale = im.ImVec2.{width / io.DisplaySize.x, height / io.DisplaySize.y};
	} else {
		io.DisplayFramebufferScale = im.ImVec2.{1.0, 1.0};
	}

	io.DeltaTime = rl.GetFrameTime();

	if io.WantSetMousePos {
		rl.SetMousePosition(cast(s32) io.MousePos.x, cast(s32) io.MousePos.y);
	} else {
		io.MousePos.x = cast(float) rl.GetMouseX();
		io.MousePos.y = cast(float) rl.GetMouseY();
	}

	io.MouseDown[0] = rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_LEFT);
	io.MouseDown[1] = rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_RIGHT);
	io.MouseDown[2] = rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_MIDDLE);

	if rl.GetMouseWheelMove() > 0 {
		io.MouseWheel += 1;
	} else if rl.GetMouseWheelMove() < 0 {
		io.MouseWheel -= 1;
	}

	if (io.ConfigFlags_ & im.ConfigFlags.NoMouseCursorChange) == 0 {
		imgui_cursor := im.GetMouseCursor();

		if imgui_cursor != current_mouse_cursor || io.MouseDrawCursor {
			current_mouse_cursor = imgui_cursor;

			if io.MouseDrawCursor || imgui_cursor == .None {
				rl.HideCursor();
			} else {
				rl.ShowCursor();

				if !(io.ConfigFlags_ & im.ConfigFlags.NoMouseCursorChange) {
					rl.SetMouseCursor(
						xx ifx imgui_cursor > -1 && imgui_cursor < im.MouseCursor.COUNT
						then cast(s32) table_find_pointer(*mouse_cursor_map, imgui_cursor).*
						else cast(s32) rl.MouseCursor.MOUSE_CURSOR_DEFAULT);
				}
			}
		}
	}
}

process_events :: () {
	io := im.GetIO();

	focused := rl.IsWindowFocused();
	if focused != last_frame_focused {
		im.IO.AddFocusEvent(io, focused);
	}
	last_frame_focused = focused;

	// handle the modifyer key events so that shortcuts work
	ctrl_down := rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT_CONTROL) || rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT_CONTROL);
	if ctrl_down != last_control_pressed {
		im.IO.AddKeyEvent(io, im.Key.Mod_Ctrl, ctrl_down);
	}
	last_control_pressed = ctrl_down;

	shift_down := rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT_SHIFT) || rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT_SHIFT);
	if shift_down != last_shift_pressed {
		im.IO.AddKeyEvent(io, im.Key.Mod_Shift, ctrl_down);
	}
	last_shift_pressed = shift_down;

	alt_down := rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT_ALT) || rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT_ALT);
	if alt_down != last_alt_pressed {
		im.IO.AddKeyEvent(io, im.Key.Mod_Alt, alt_down);
	}
	last_alt_pressed = alt_down;

	super_down := rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT_SUPER) || rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT_SUPER);
	if super_down != last_super_pressed {
		im.IO.AddKeyEvent(io, im.Key.Mod_Super, ctrl_down);
	}
	last_super_pressed = super_down;

	// get the pressed keys, they are in event order
	key_id := cast(rl.KeyboardKey) rl.GetKeyPressed();
	while key_id != 0 {
		found, value := table_find(*key_map, key_id);
		if found then im.IO.AddKeyEvent(io, value, true);
		key_id = cast(rl.KeyboardKey) rl.GetKeyPressed();
	}

 	for key_map {
 		io.KeysData[it].Down = rl.IsKeyDown(it_index);
 	}

	// look for any keys that were down last frame and see if they were down and are released
	for key_map {
		if rl.IsKeyReleased(it_index) then im.IO.AddKeyEvent(io, it, false);
	}

	// add the text input in order
	pressed := rl.GetCharPressed();
	while pressed != 0 {
		im.IO.AddInputCharacter(io, cast(u32) pressed);
		pressed = rl.GetCharPressed();
	}
}

#scope_export

backend_frame_begin :: () {
	new_frame();
	process_events();
	im.NewFrame();
}

#scope_module

render_triangles :: (count: u32, index_start: u32, index_buffer: []im.ImDrawIdx, vert_buffer: []im.ImDrawVert, texture_ptr: *void) {
	if (count < 3) return;

	texture    := cast(*rl.Texture) texture_ptr;
	texture_id := ifx texture == null then 0 else texture.id;

	rl.rlBegin(rl.RL_TRIANGLES);
	rl.rlSetTexture(texture_id);

	i : u32 = 0;
	while i <= (count - 3) {
		defer i += 3;

		if rl.rlCheckRenderBatchLimit(3) {
			rl.rlBegin(rl.RL_TRIANGLES);
			rl.rlSetTexture(texture_id);
		}

		index_a := index_buffer[index_start + i];
		index_b := index_buffer[index_start + i + 1];
		index_c := index_buffer[index_start + i + 2];

		vertex_a := vert_buffer[index_a];
		vertex_b := vert_buffer[index_b];
		vertex_c := vert_buffer[index_c];

		triangle_vert :: (idx_vert : im.ImDrawVert) {
			c := cast(*rl.Color) *idx_vert.col;
			rl.rlColor4ub(c.r, c.g, c.b, c.a);
			rl.rlTexCoord2f(idx_vert.uv.x, idx_vert.uv.y);
			rl.rlVertex2f(idx_vert.pos.x, idx_vert.pos.y);
		}

		triangle_vert(vertex_a);
		triangle_vert(vertex_b);
		triangle_vert(vertex_c);
	}

	rl.rlEnd();
}

enable_scissor :: (x: float, y: float, width: float, height: float) {
	rl.rlEnableScissorTest();

	io := im.GetIO();
	rl.rlScissor(
		cast(s32) (x      * io.DisplayFramebufferScale.x),
		cast(s32) ((rl.GetScreenHeight() - cast(s32) (y + height)) * io.DisplayFramebufferScale.y),
		cast(s32) (width  * io.DisplayFramebufferScale.x),
		cast(s32) (height * io.DisplayFramebufferScale.y));
}

#scope_export

backend_frame_end :: () {
	im.Render();
	data := im.GetDrawData();

	rl.rlDrawRenderBatchActive();
	rl.rlDisableBackfaceCulling();

	command_lists: []*im.ImDrawList;
	command_lists.data  = data.CmdLists;
	command_lists.count = data.CmdListsCount;

	for command_list: command_lists {
		command_buffer : []im.ImDrawCmd;
		command_buffer.data  = command_list.CmdBuffer.Data;
		command_buffer.count = command_list.CmdBuffer.Size;

		for cmd: command_buffer {

			enable_scissor(
				cmd.ClipRect.x - data.DisplayPos.x,
				cmd.ClipRect.y - data.DisplayPos.y,
				cmd.ClipRect.z - (cmd.ClipRect.x - data.DisplayPos.x),
				cmd.ClipRect.w - (cmd.ClipRect.y - data.DisplayPos.y));

			if cmd.UserCallback != null {
				cmd.UserCallback(command_list, *cmd);
				continue;
			}

			index_buffer : []im.ImDrawIdx;
			index_buffer.data  = command_list.IdxBuffer.Data;
			index_buffer.count = command_list.IdxBuffer.Size;

			vert_buffer : []im.ImDrawVert;
			vert_buffer.data  = command_list.VtxBuffer.Data;
			vert_buffer.count = command_list.VtxBuffer.Size;

			render_triangles(cmd.ElemCount, cmd.IdxOffset, index_buffer, vert_buffer, cmd.TextureId);
			rl.rlDrawRenderBatchActive();
		}
	}

	rl.rlSetTexture(0);
	rl.rlDisableScissorTest();
	rl.rlEnableBackfaceCulling();
}

backend_shutdown :: () {
	rl.UnloadTexture(font_texture);
	im.DestroyContext();

	deinit(*key_map);
	deinit(*mouse_cursor_map);
}

/*
NOTE: Function below were NOT tested, they might even not compile!
*/

im_image :: (image: *rl.Texture) {
	im.Image(cast(im.ImTextureID) image, im.ImVec2.{cast(float) image.width, cast(float) image.height});
}

im_image :: (image: *rl.Texture, size: im.ImVec2) {
	im.Image(cast(im.ImTextureID) image, size);
}

im_image :: (image: *rl.Texture, dest_width: s32, dest_height: s32, source_rect: rl.Rectangle) {
	uv0, uv1: im.ImVec2;

	if source_rect.width < 0 {
		uv0.x = -1 * cast(float) (source_rect.x / image.width);
		uv1.x = uv0.x - cast(float) (abs(source_rect.width) / image.width);
	} else {
		uv0.x = cast(float) source_rect.x / image.width;
		uv1.x = uv0.x + cast(float) (source_rect.width / image.width);
	}

	if source_rect.height < 0 {
		uv0.y = -1 * (cast(float) source_rect.y / image.height);
		uv1.y = uv0.y - cast(float) (abs(source_rect.height) / image.height);
	} else {
		uv0.y = cast(float) source_rect.y / image.height;
		uv1.y = uv0.y + cast(float) (source_rect.height / image.height);
	}

	im.Image(cast(im.ImTextureID) image, im.ImVec2.{cast(float) dest_width, cast(float) dest_height}, uv0, uv1);
}

im_image_button :: (name: *u8, image: *rl.Texture) -> bool {
	return im.ImageButton(name, cast(im.ImTextureID) image, im.ImVec2.{cast(float) image.width, cast(float) image.height});
}

im_image_button :: (name: *u8, image: *rl.Texture, size: im.ImVec2) -> bool {
	return im.ImageButton(name, cast(im.ImTextureID) image, size);
}

#scope_module

rl :: #import "Raylib";
im :: #import "ImGui";

#import "Basic";
#import "Hash_Table";
#import "Math";
