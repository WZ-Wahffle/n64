rsp_special :: (ins: u32) {
    rsp_special_lut[ins & 0x3f](ins);
}

rsp_regimm :: (ins: u32) {
    rsp_regimm_lut[(ins >> 16) & 0x1f](ins);
}
