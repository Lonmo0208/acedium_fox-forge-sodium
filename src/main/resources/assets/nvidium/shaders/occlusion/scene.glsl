struct Section {
    ivec4 header;
    ivec4 renderRanges;
};

struct Region {
    uint64_t a;
    uint64_t b;
};

ivec3 unpackRegionSize(Region region) {
    return ivec3(
    int((region.a >> 59u) & 7u),
    int(region.a >> 62u),
    int((region.a >> 56u) & 7u)
    );
}

uint unpackRegionTransformId(Region region) {
    return uint((region.b >> (64u-24u-10u)) & 0x3FFu);
}

ivec3 unpackRegionPosition(Region region) {
    int x = int((region.a << (64u-24u-24u)) >> (64u-24u));
    int y = int(region.a & 0xFFFFFF00u) >> 8;
    int z = int(region.b >> (64u-24u));
    return ivec3(x, y, z);
}

int unpackRegionCount(Region region) {
    return int((region.a >> 48u) & 0xFFu);
}

bool sectionEmpty(ivec4 header) {
    header.y &= ~int(0x1FFu << 17u);
    return header == ivec4(0);
}

// Uniform buffer declarations保持原样