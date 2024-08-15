# Bitmasks used by sqlite3GetVarint
SLOT_2_0 = 0x001fc07f
SLOT_4_2_0 = 0xf01fc07f

def sqlite3GetVarint(p: bytes) -> tuple[int, int]:
    a = b = s = 0

    if p[0] < 0x80:
        return p[0], 1

    if p[1] < 0x80:
        v = ((p[0] & 0x7f) << 7) | p[1]
        return v, 2

    a = (p[0] << 14)
    b = p[1]
    p = p[2:]
    a |= p[0]

    if not (a & 0x80):
        a &= SLOT_2_0
        b &= 0x7f
        b = b << 7
        a |= b
        return a, 3

    a &= SLOT_2_0
    p = p[1:]
    b = b << 14
    b |= p[0]

    if not (b & 0x80):
        b &= SLOT_2_0
        a = a << 7
        a |= b
        return a, 4

    b &= SLOT_2_0
    s = a

    a = (a << 14) | p[1]
    p = p[1:]

    if not (a & 0x80):
        b = b << 7
        a |= b
        s = s >> 18
        return (s << 32) | a, 5

    s = (s << 7) | b

    b = (b << 14) | p[1]
    p = p[1:]

    if not (b & 0x80):
        a &= SLOT_2_0
        a = a << 7
        a |= b
        s = s >> 18
        return (s << 32) | a, 6

    a = (a << 14) | p[1]
    p = p[1:]

    if not (a & 0x80):
        a &= SLOT_4_2_0
        b &= SLOT_2_0
        b = b << 7
        a |= b
        s = s >> 11
        return (s << 32) | a, 7

    a &= SLOT_2_0
    b = (b << 14) | p[1]
    p = p[1:]

    if not (b & 0x80):
        b &= SLOT_4_2_0
        a = a << 7
        a |= b
        s = s >> 4
        return (s << 32) | a, 8

    p = p[1:]
    a = (a << 15) | p[0]

    b &= SLOT_2_0
    b = b << 8
    a |= b

    s = s << 4

    # Ensure we don't access out of range
    if len(p) >= 4:
        b = p[-4]
        b &= 0x7f
        b = b >> 3
        s |= b

    return (s << 32) | a, 9

print(sqlite3GetVarint(bytes([0x69])))        # Expecting (105, 1)
print(sqlite3GetVarint(bytes([0x7f])))        # Expecting (127, 1)
print(sqlite3GetVarint(bytes([0x80, 0x01])))  # Expecting (1, 2)
print(sqlite3GetVarint(bytes([0x81, 0x00])))  # Expecting (128, 2)
print(sqlite3GetVarint(bytes([0x82, 0x24])))  # Expecting (292, 2)
print(sqlite3GetVarint(bytes([0xAC, 0x02])))  # Expecting (5634, 2)
print(sqlite3GetVarint(bytes([0x82, 0x81, 0x34])))  # Expecting (32948, 3)
print(sqlite3GetVarint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])))  # Expecting (72057594037927809, 8)
print(sqlite3GetVarint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F])))  # Expecting (72057594037927935, 8)
print(sqlite3GetVarint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])))  # Expecting (18446744073709551361, 9)
print(sqlite3GetVarint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])))  # Expecting (18446744073709551615, 9)

print(sqlite3GetVarint(bytes([0x81, 0x11])))
