#include <stdio.h>
#include <assert.h>

#define SLOT_2_0 0x001fc07f
#define SLOT_4_2_0 0xf01fc07f

typedef unsigned char u8;
typedef unsigned long long u64;
typedef unsigned int u32;

/*
** The variable-length integer encoding is as follows:
**
** KEY:
**         A = 0xxxxxxx    7 bits of data and one flag bit
**         B = 1xxxxxxx    7 bits of data and one flag bit
**         C = xxxxxxxx    8 bits of data
**
**  7 bits - A
** 14 bits - BA
** 21 bits - BBA
** 28 bits - BBBA
** 35 bits - BBBBA
** 42 bits - BBBBBA
** 49 bits - BBBBBBA
** 56 bits - BBBBBBBA
** 64 bits - BBBBBBBBC
*/

/*
** Write a 64-bit variable-length integer to memory starting at p[0].
** The length of data write will be between 1 and 9 bytes.  The number
** of bytes written is returned.
**
** A variable-length integer consists of the lower 7 bits of each byte
** for all bytes that have the 8th bit set and one byte with the 8th
** bit clear.  Except, if we get to the 9th byte, it stores the full
** 8 bits and is the last byte.
*/
static int putVarint64(unsigned char *p, u64 v)
{
    int i, j, n;
    u8 buf[10];
    if (v & (((u64)0xff000000) << 32))
    {
        p[8] = (u8)v;
        v >>= 8;
        for (i = 7; i >= 0; i--)
        {
            p[i] = (u8)((v & 0x7f) | 0x80);
            v >>= 7;
        }
        return 9;
    }
    n = 0;
    do
    {
        buf[n++] = (u8)((v & 0x7f) | 0x80);
        v >>= 7;
    } while (v != 0);
    buf[0] &= 0x7f;
    assert(n <= 9);
    for (i = 0, j = n - 1; j >= 0; j--, i++)
    {
        p[i] = buf[j];
    }
    return n;
}

int sqlite3PutVarint(unsigned char *p, u64 v)
{
    if (v <= 0x7f)
    {
        p[0] = v & 0x7f;
        return 1;
    }
    if (v <= 0x3fff)
    {
        p[0] = ((v >> 7) & 0x7f) | 0x80;
        p[1] = v & 0x7f;
        return 2;
    }
    return putVarint64(p, v);
}

/*
** Read a 64-bit variable-length integer from memory starting at p[0].
** Return the number of bytes read.  The value is stored in *v.
*/
u8 sqlite3GetVarint(const unsigned char *p, u64 *v)
{
    u32 a, b, s;

    if (((signed char *)p)[0] >= 0)
    {
        *v = *p;
        return 1;
    }
    if (((signed char *)p)[1] >= 0)
    {
        *v = ((u32)(p[0] & 0x7f) << 7) | p[1];
        return 2;
    }

    /* Verify that constants are precomputed correctly */
    assert(SLOT_2_0 == ((0x7f << 14) | (0x7f)));
    assert(SLOT_4_2_0 == ((0xfU << 28) | (0x7f << 14) | (0x7f)));

    a = ((u32)p[0]) << 14;
    b = p[1];
    p += 2;
    a |= *p;
    /* a: p0<<14 | p2 (unmasked) */
    if (!(a & 0x80))
    {
        a &= SLOT_2_0;
        b &= 0x7f;
        b = b << 7;
        a |= b;
        *v = a;
        return 3;
    }

    /* CSE1 from below */
    a &= SLOT_2_0;
    p++;
    b = b << 14;
    b |= *p;
    /* b: p1<<14 | p3 (unmasked) */
    if (!(b & 0x80))
    {
        b &= SLOT_2_0;
        /* moved CSE1 up */
        /* a &= (0x7f<<14)|(0x7f); */
        a = a << 7;
        a |= b;
        *v = a;
        return 4;
    }

    /* a: p0<<14 | p2 (masked) */
    /* b: p1<<14 | p3 (unmasked) */
    /* 1:save off p0<<21 | p1<<14 | p2<<7 | p3 (masked) */
    /* moved CSE1 up */
    /* a &= (0x7f<<14)|(0x7f); */
    b &= SLOT_2_0;
    s = a;
    /* s: p0<<14 | p2 (masked) */

    p++;
    a = a << 14;
    a |= *p;
    /* a: p0<<28 | p2<<14 | p4 (unmasked) */
    if (!(a & 0x80))
    {
        /* we can skip these cause they were (effectively) done above
        ** while calculating s */
        /* a &= (0x7f<<28)|(0x7f<<14)|(0x7f); */
        /* b &= (0x7f<<14)|(0x7f); */
        b = b << 7;
        a |= b;
        s = s >> 18;
        *v = ((u64)s) << 32 | a;
        return 5;
    }

    /* 2:save off p0<<21 | p1<<14 | p2<<7 | p3 (masked) */
    s = s << 7;
    s |= b;
    /* s: p0<<21 | p1<<14 | p2<<7 | p3 (masked) */

    p++;
    b = b << 14;
    b |= *p;
    /* b: p1<<28 | p3<<14 | p5 (unmasked) */
    if (!(b & 0x80))
    {
        /* we can skip this cause it was (effectively) done above in calc'ing s */
        /* b &= (0x7f<<28)|(0x7f<<14)|(0x7f); */
        a &= SLOT_2_0;
        a = a << 7;
        a |= b;
        s = s >> 18;
        *v = ((u64)s) << 32 | a;
        return 6;
    }

    p++;
    a = a << 14;
    a |= *p;
    /* a: p2<<28 | p4<<14 | p6 (unmasked) */
    if (!(a & 0x80))
    {
        a &= SLOT_4_2_0;
        b &= SLOT_2_0;
        b = b << 7;
        a |= b;
        s = s >> 11;
        *v = ((u64)s) << 32 | a;
        return 7;
    }

    /* CSE2 from below */
    a &= SLOT_2_0;
    p++;
    b = b << 14;
    b |= *p;
    /* b: p3<<28 | p5<<14 | p7 (unmasked) */
    if (!(b & 0x80))
    {
        b &= SLOT_4_2_0;
        /* moved CSE2 up */
        /* a &= (0x7f<<14)|(0x7f); */
        a = a << 7;
        a |= b;
        s = s >> 4;
        *v = ((u64)s) << 32 | a;
        return 8;
    }

    p++;
    a = a << 15;
    a |= *p;
    /* a: p4<<29 | p6<<15 | p8 (unmasked) */

    /* moved CSE2 up */
    /* a &= (0x7f<<29)|(0x7f<<15)|(0xff); */
    b &= SLOT_2_0;
    b = b << 8;
    a |= b;

    s = s << 4;
    b = p[-4];
    b &= 0x7f;
    b = b >> 3;
    s |= b;
    *v = ((u64)s) << 32 | a;
    return 9;
}

void writeEncodedVarint(int length, unsigned char *p)
{
    printf("(");
    for (int j = 0; j < length; j++)
    {
        printf("%02x", p[j]);
        if (j < length - 1)
        {
            printf(" ");
        }
    }
    printf(", %d)\n", length);
}

int main()
{
    // Array of arrays with varint-encoded data
    const unsigned char *dataArrays[] = {
        (unsigned char[]){0x69},
        (unsigned char[]){0x7f},
        (unsigned char[]){0x80, 0x01},
        (unsigned char[]){0x81, 0x00},
        (unsigned char[]){0x82, 0x24},
        (unsigned char[]){0xAC, 0x02},
        (unsigned char[]){0x82, 0x81, 0x34},
        (unsigned char[]){0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01},
        (unsigned char[]){0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F},
        (unsigned char[]){0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01},
        (unsigned char[]){0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF},
    };

    // Number of arrays
    int numArrays = sizeof(dataArrays) / sizeof(dataArrays[0]);

    // Array to store decoded varints
    u64 decodedValues[numArrays];

    // Loop through each array and test
    for (int i = 0; i < numArrays; i++)
    {
        u64 value;
        u8 bytesRead;
        bytesRead = sqlite3GetVarint(dataArrays[i], &value);
        decodedValues[i] = value;
        printf("(%llu, %d)\n", value, bytesRead);
    }

    printf("\n");

    for (int i = 0; i < numArrays; i++)
    {
        unsigned char encoded[9];
        int bytesWritten;
        bytesWritten = sqlite3PutVarint(encoded, decodedValues[i]);
        writeEncodedVarint(bytesWritten, encoded);
    }

    unsigned char encoded[9];
    int bytesWritten;
    bytesWritten = sqlite3PutVarint(encoded, 10);
    writeEncodedVarint(bytesWritten, encoded);


    return 0;
}

/*
To decode the SQLite varint 0x82 0x24, follow these steps:

1.	Extract the bytes:
    •	First byte: 0x82 (binary: 10000010)
    •	Second byte: 0x24 (binary: 00100100)
2.	Remove the most significant bit (MSB) from each byte:
    •	First byte without MSB: 0000010 (2 in decimal)
    •	Second byte without MSB: 0100100 (36 in decimal)
3.	Concatenate the 7-bit groups:
    •	Combine the 7-bit groups into a single binary number:
        0000010 0100100
        100100100
        292
*/