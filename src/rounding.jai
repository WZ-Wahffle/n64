Rounding_Mode :: enum u32 {
    NEAREST :: 0; // round to nearest (even)
    DOWN :: 1; // round toward negative infinity
    UP :: 2; // round toward positive infinity
    ZERO :: 3; // round toward zero
}

get_rounding_mode :: () -> Rounding_Mode {
    mxcsr: u32 #align 16;
    mxcsr_ := *mxcsr;
    #asm {
        stmxcsr [mxcsr_];
    }
    return xx ((mxcsr >> 13) & 0x3);
}

set_rounding_mode :: (mode: Rounding_Mode) {
    mxcsr: u32 #align 16;
    mxcsr_ := *mxcsr;
    #asm {
        stmxcsr [mxcsr_];
    }
    mxcsr &= ~cast(u32,0x6000); // clear rounding mode
    mxcsr |= cast(u32,mode) << 13; // set new rounding mode
    #asm {
        ldmxcsr [mxcsr_];
    }
}

round_f32_to_i32 :: (val: float32) -> s32 {
    out : s32;
    #asm {
        thing_ : vec;
        movd thing_, val;
        cvtss2si out, thing_;
    }
    return out;
}

round_f64_to_i32 :: (val: float64) -> s32 {
    out : s32;
    #asm {
        thing_ : vec;
        movd thing_, val;
        cvtsd2si out, thing_;
    }
    return out;
}
