setup_catppuccin_mocha_theme :: () {
    style := im.GetStyle();
    colors := *style.Colors;
    // Catppuccin Mocha Palette
    // --------------------------------------------------------
    base       := im.ImVec4.{0.117, 0.117, 0.172, 1.0}; // #1e1e2e
    mantle     := im.ImVec4.{0.109, 0.109, 0.156, 1.0}; // #181825
    surface0   := im.ImVec4.{0.200, 0.207, 0.286, 1.0}; // #313244
    surface1   := im.ImVec4.{0.247, 0.254, 0.337, 1.0}; // #3f4056
    surface2   := im.ImVec4.{0.290, 0.301, 0.388, 1.0}; // #4a4d63
    overlay0   := im.ImVec4.{0.396, 0.403, 0.486, 1.0}; // #65677c
    overlay2   := im.ImVec4.{0.576, 0.584, 0.654, 1.0}; // #9399b2
    text       := im.ImVec4.{0.803, 0.815, 0.878, 1.0}; // #cdd6f4
    subtext0   := im.ImVec4.{0.639, 0.658, 0.764, 1.0}; // #a3a8c3
    mauve      := im.ImVec4.{0.796, 0.698, 0.972, 1.0}; // #cba6f7
    peach      := im.ImVec4.{0.980, 0.709, 0.572, 1.0}; // #fab387
    yellow     := im.ImVec4.{0.980, 0.913, 0.596, 1.0}; // #f9e2af
    green      := im.ImVec4.{0.650, 0.890, 0.631, 1.0}; // #a6e3a1
    teal       := im.ImVec4.{0.580, 0.886, 0.819, 1.0}; // #94e2d5
    sapphire   := im.ImVec4.{0.458, 0.784, 0.878, 1.0}; // #74c7ec
    blue       := im.ImVec4.{0.533, 0.698, 0.976, 1.0}; // #89b4fa
    lavender   := im.ImVec4.{0.709, 0.764, 0.980, 1.0}; // #b4befe

    // Main window and backgrounds
    colors.*[im.Col.ImGuiCol_WindowBg]             = base;
    colors.*[im.Col.ImGuiCol_ChildBg]              = base;
    colors.*[im.Col.ImGuiCol_PopupBg]              = surface0;
    colors.*[im.Col.ImGuiCol_Border]               = surface1;
    colors.*[im.Col.ImGuiCol_BorderShadow]         = im.ImVec4.{0.0, 0.0, 0.0, 0.0};
    colors.*[im.Col.ImGuiCol_FrameBg]              = surface0;
    colors.*[im.Col.ImGuiCol_FrameBgHovered]       = surface1;
    colors.*[im.Col.ImGuiCol_FrameBgActive]        = surface2;
    colors.*[im.Col.ImGuiCol_TitleBg]              = mantle;
    colors.*[im.Col.ImGuiCol_TitleBgActive]        = surface0;
    colors.*[im.Col.ImGuiCol_TitleBgCollapsed]     = mantle;
    colors.*[im.Col.ImGuiCol_MenuBarBg]            = mantle;
    colors.*[im.Col.ImGuiCol_ScrollbarBg]          = surface0;
    colors.*[im.Col.ImGuiCol_ScrollbarGrab]        = surface2;
    colors.*[im.Col.ImGuiCol_ScrollbarGrabHovered] = overlay0;
    colors.*[im.Col.ImGuiCol_ScrollbarGrabActive]  = overlay2;
    colors.*[im.Col.ImGuiCol_CheckMark]            = green;
    colors.*[im.Col.ImGuiCol_SliderGrab]           = sapphire;
    colors.*[im.Col.ImGuiCol_SliderGrabActive]     = blue;
    colors.*[im.Col.ImGuiCol_Button]               = surface0;
    colors.*[im.Col.ImGuiCol_ButtonHovered]        = surface1;
    colors.*[im.Col.ImGuiCol_ButtonActive]         = surface2;
    colors.*[im.Col.ImGuiCol_Header]               = surface0;
    colors.*[im.Col.ImGuiCol_HeaderHovered]        = surface1;
    colors.*[im.Col.ImGuiCol_HeaderActive]         = surface2;
    colors.*[im.Col.ImGuiCol_Separator]            = surface1;
    colors.*[im.Col.ImGuiCol_SeparatorHovered]     = mauve;
    colors.*[im.Col.ImGuiCol_SeparatorActive]      = mauve;
    colors.*[im.Col.ImGuiCol_ResizeGrip]           = surface2;
    colors.*[im.Col.ImGuiCol_ResizeGripHovered]    = mauve;
    colors.*[im.Col.ImGuiCol_ResizeGripActive]     = mauve;
    colors.*[im.Col.ImGuiCol_Tab]                  = surface0;
    colors.*[im.Col.ImGuiCol_TabHovered]           = surface2;
    colors.*[im.Col.ImGuiCol_TabActive]            = surface1;
    colors.*[im.Col.ImGuiCol_TabUnfocused]         = surface0;
    colors.*[im.Col.ImGuiCol_TabUnfocusedActive]   = surface1;
    colors.*[im.Col.ImGuiCol_PlotLines]            = blue;
    colors.*[im.Col.ImGuiCol_PlotLinesHovered]     = peach;
    colors.*[im.Col.ImGuiCol_PlotHistogram]        = teal;
    colors.*[im.Col.ImGuiCol_PlotHistogramHovered] = green;
    colors.*[im.Col.ImGuiCol_TableHeaderBg]        = surface0;
    colors.*[im.Col.ImGuiCol_TableBorderStrong]    = surface1;
    colors.*[im.Col.ImGuiCol_TableBorderLight]     = surface0;
    colors.*[im.Col.ImGuiCol_TableRowBg]           = im.ImVec4.{0.0, 0.0, 0.0, 0.0};
    colors.*[im.Col.ImGuiCol_TableRowBgAlt]        = im.ImVec4.{1.0, 1.0, 1.0, 0.06};
    colors.*[im.Col.ImGuiCol_TextSelectedBg]       = surface2;
    colors.*[im.Col.ImGuiCol_DragDropTarget]       = yellow;
    colors.*[im.Col.ImGuiCol_NavHighlight]         = lavender;
    colors.*[im.Col.ImGuiCol_NavWindowingHighlight]= im.ImVec4.{1.0, 1.0, 1.0, 0.7};
    colors.*[im.Col.ImGuiCol_NavWindowingDimBg]    = im.ImVec4.{0.8, 0.8, 0.8, 0.2};
    colors.*[im.Col.ImGuiCol_ModalWindowDimBg]     = im.ImVec4.{0.0, 0.0, 0.0, 0.35};
    colors.*[im.Col.ImGuiCol_Text]                 = text;
    colors.*[im.Col.ImGuiCol_TextDisabled]         = subtext0;

    // Rounded corners
    style.WindowRounding    = 6.0;
    style.ChildRounding     = 6.0;
    style.FrameRounding     = 4.0;
    style.PopupRounding     = 4.0;
    style.ScrollbarRounding = 9.0;
    style.GrabRounding      = 4.0;
    style.TabRounding       = 4.0;

    // Padding and spacing
    style.WindowPadding     = im.ImVec2.{8.0, 8.0};
    style.FramePadding      = im.ImVec2.{5.0, 3.0};
    style.ItemSpacing       = im.ImVec2.{8.0, 4.0};
    style.ItemInnerSpacing  = im.ImVec2.{4.0, 4.0};
    style.IndentSpacing     = 21.0;
    style.ScrollbarSize     = 14.0;
    style.GrabMinSize       = 10.0;

    // Borders
    style.WindowBorderSize  = 1.0;
    style.ChildBorderSize   = 1.0;
    style.PopupBorderSize   = 1.0;
    style.FrameBorderSize   = 0.0;
    style.TabBorderSize     = 0.0;

}
