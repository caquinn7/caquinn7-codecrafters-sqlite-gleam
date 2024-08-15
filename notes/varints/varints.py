def decode_varint(bytes: bytes) -> tuple[int, int]:
    value = 0
    for i in range(len(bytes)):
        if i < 8:
            value = (value << 7) | (bytes[i] & 0x7F)
        else:
            value = (value << 8) | bytes[i]
    return value, i + 1

# print(decode_varint(bytes([0x69])))        # Expecting (105, 1)
# print(decode_varint(bytes([0x7f])))        # Expecting (127, 1)
# print(decode_varint(bytes([0x80, 0x01])))  # Expecting (1, 2)
# print(decode_varint(bytes([0x81, 0x00])))  # Expecting (128, 2)
# print(decode_varint(bytes([0x82, 0x24])))  # Expecting (292, 2)
# print(decode_varint(bytes([0xAC, 0x02])))  # Expecting (5634, 2)
# print(decode_varint(bytes([0x82, 0x81, 0x34])))  # Expecting (32948, 3)
# print(decode_varint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])))  # Expecting (72057594037927809, 8)
# print(decode_varint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F])))  # Expecting (72057594037927935, 8)
# print(decode_varint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])))  # Expecting (18446744073709551361, 9)
# print(decode_varint(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])))  # Expecting (18446744073709551615, 9)

def parse_hex_bytes(arg):
    # Split the input by spaces to get individual hex values
    hex_values = arg.split()
    # Convert each hex value to an integer and then to bytes
    byte_values = bytes(int(hv, 16) for hv in hex_values)
    return byte_values

if (__name__ == '__main__'):
    import sys

    for arg in sys.argv[1:]:
        byte_sequence = parse_hex_bytes(arg)
        print(arg, ' = ', decode_varint(byte_sequence))