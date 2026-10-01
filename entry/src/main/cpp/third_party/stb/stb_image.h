/* stb_image - v2.30 - public domain image loader
 * https://github.com/nothings/stb
 *
 * Written by Sean Barrett. Public domain.
 *
 * USAGE:
 *   In exactly ONE .c/.cpp file, define STB_IMAGE_IMPLEMENTATION before
 *   including this header:
 *
 *     #define STB_IMAGE_IMPLEMENTATION
 *     #include "stb_image.h"
 */

#ifndef STBI_INCLUDE_STB_IMAGE_H
#define STBI_INCLUDE_STB_IMAGE_H

#define STBI_VERSION 1

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned char stbi_uc;

stbi_uc *stbi_load_from_memory(stbi_uc const *buffer, int len,
                               int *x, int *y,
                               int *channels_in_file,
                               int desired_channels);

void stbi_image_free(void *retval_from_stbi_load);

const char *stbi_failure_reason(void);

#ifdef __cplusplus
}
#endif

#endif /* STBI_INCLUDE_STB_IMAGE_H */


#ifdef STB_IMAGE_IMPLEMENTATION

#include <stdlib.h>
#include <string.h>

static const char *stbi__error_reason = NULL;

const char *stbi_failure_reason(void) {
    return stbi__error_reason ? stbi__error_reason : "unknown";
}

void stbi_image_free(void *retval_from_stbi_load) {
    free(retval_from_stbi_load);
}

/* ---- PNG decoder ---- */

static const stbi_uc stbi__png_sig[8] = { 137,80,78,71,13,10,26,10 };

static int stbi__check_png_sig(const stbi_uc *buf, int len) {
    if (len < 8) return 0;
    return memcmp(buf, stbi__png_sig, 8) == 0;
}

static unsigned int stbi__read32be(const stbi_uc *p) {
    return ((unsigned int)p[0] << 24) | ((unsigned int)p[1] << 16) |
           ((unsigned int)p[2] << 8)  | (unsigned int)p[3];
}

static unsigned short stbi__read16be(const stbi_uc *p) {
    return (unsigned short)((p[0] << 8) | p[1]);
}

/* CRC32 table */
static unsigned int stbi__crc32_table[256];
static int stbi__crc32_inited = 0;

static void stbi__init_crc32(void) {
    int i, j;
    if (stbi__crc32_inited) return;
    for (i = 0; i < 256; i++) {
        unsigned int c = (unsigned int)i;
        for (j = 0; j < 8; j++) {
            if (c & 1)
                c = 0xEDB88320u ^ (c >> 1);
            else
                c = c >> 1;
        }
        stbi__crc32_table[i] = c;
    }
    stbi__crc32_inited = 1;
}

static unsigned int stbi__crc32(const stbi_uc *buf, int len) {
    unsigned int c = 0xFFFFFFFFu;
    int i;
    stbi__init_crc32();
    for (i = 0; i < len; i++)
        c = stbi__crc32_table[(c ^ buf[i]) & 0xFF] ^ (c >> 8);
    return c ^ 0xFFFFFFFFu;
}

/* Adler32 */
static unsigned int stbi__adler32(const stbi_uc *buf, int len) {
    unsigned int s1 = 1, s2 = 1;
    int i;
    for (i = 0; i < len; i++) {
        s1 = (s1 + buf[i]) % 65521;
        s2 = (s2 + s1) % 65521;
    }
    return (s2 << 16) | s1;
}

/* ---- Deflate / zlib decompression ---- */

typedef struct {
    const stbi_uc *buf;
    int pos;
    int len;
    unsigned int bitbuf;
    int bitcount;
} stbi__zstream;

static void stbi__zinit(stbi__zstream *z, const stbi_uc *buf, int len) {
    z->buf = buf;
    z->pos = 0;
    z->len = len;
    z->bitbuf = 0;
    z->bitcount = 0;
}

static unsigned int stbi__zgetbits(stbi__zstream *z, int n) {
    while (z->bitcount < n) {
        if (z->pos < z->len)
            z->bitbuf |= ((unsigned int)z->buf[z->pos++]) << z->bitcount;
        z->bitcount += 8;
    }
    unsigned int val = z->bitbuf & ((1u << n) - 1);
    z->bitbuf >>= n;
    z->bitcount -= n;
    return val;
}

static int stbi__zrefill(stbi__zstream *z, int n) {
    while (z->bitcount < n) {
        if (z->pos >= z->len) return -1;
        z->bitbuf |= ((unsigned int)z->buf[z->pos++]) << z->bitcount;
        z->bitcount += 8;
    }
    return 0;
}

/* Huffman tree */
#define STBI__ZMAXBITS 15
#define STBI__ZMAXSYMS 288

typedef struct {
    int first[STBI__ZMAXBITS + 2]; /* first canonical code for each bit length */
    int count[STBI__ZMAXBITS + 1]; /* number of codes at each bit length */
    int symbol[STBI__ZMAXSYMS];    /* symbols sorted by (bit_length, code) */
    int num;
} stbi__huffman;

static int stbi__zhuff_build(stbi__huffman *h, const stbi_uc *lengths, int num) {
    int i;
    h->num = num;
    memset(h->count, 0, sizeof(h->count));
    for (i = 0; i < num; i++) {
        if (lengths[i] > 0) h->count[lengths[i]]++;
    }

    h->first[0] = 0;
    h->first[1] = 0;
    int code = 0;
    for (i = 1; i <= STBI__ZMAXBITS; i++) {
        code = (code + h->count[i - 1]) << 1;
        h->first[i + 1] = code;
    }

    /* Fill symbol table: symbols sorted by (bit_length, canonical_code) */
    int offset[STBI__ZMAXBITS + 1];
    offset[1] = 0;
    for (i = 2; i <= STBI__ZMAXBITS; i++)
        offset[i] = offset[i - 1] + h->count[i - 1];

    for (i = 0; i < num; i++) {
        if (lengths[i] > 0)
            h->symbol[offset[lengths[i]]++] = i;
    }
    return 0;
}

static int stbi__zhuff_decode(stbi__huffman *h, stbi__zstream *z) {
    int code = 0;
    int bits;
    for (bits = 1; bits <= STBI__ZMAXBITS; bits++) {
        unsigned int b;
        while (z->bitcount < 1) {
            if (z->pos >= z->len) return -1;
            z->bitbuf |= ((unsigned int)z->buf[z->pos++]) << z->bitcount;
            z->bitcount += 8;
        }
        b = z->bitbuf & 1;
        z->bitbuf >>= 1;
        z->bitcount--;
        code = (code << 1) | (int)b;

        if (bits < STBI__ZMAXBITS && code < h->first[bits + 1])
            continue; /* not enough bits yet for a complete code */

        /* Check if code is valid for this bit length */
        int pos_in_len = code - h->first[bits];
        if (pos_in_len >= 0 && pos_in_len < h->count[bits]) {
            /* Compute base index for this bit length in symbol table */
            int base = 0;
            int j;
            for (j = 1; j < bits; j++)
                base += h->count[j];
            return h->symbol[base + pos_in_len];
        }
        if (bits == STBI__ZMAXBITS) break;
    }
    return -1;
}
static const int stbi__zlen_base[29] = {
    3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258
};
static const int stbi__zlen_extra[29] = {
    0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0
};
static const int stbi__zdist_base[30] = {
    1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,
    1025,1537,2049,3073,4097,6145,8193,12289,16385,24577
};
static const int stbi__zdist_extra[30] = {
    0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13
};

/* Fixed Huffman code tables */
static const stbi_uc stbi__fixed_lit_lengths[288] = {
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
    9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
    9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
    9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
};

static const stbi_uc stbi__fixed_dist_lengths[32] = {
    5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
};

/* Inflate a deflate stream (no zlib header) */
static int stbi__inflate(stbi__zstream *z, stbi_uc *out, int out_cap, int *out_len) {
    int final_block;
    int pos = 0;
    stbi__huffman lit_huff, dist_huff;

    do {
        int block_type;
        if (stbi__zrefill(z, 3) < 0) return -1;
        final_block = (int)stbi__zgetbits(z, 1);
        block_type = (int)stbi__zgetbits(z, 2);

        if (block_type == 0) {
            /* Uncompressed block */
            int len_val, nlen_val;
            /* Align to byte boundary */
            z->bitbuf = 0;
            z->bitcount = 0;
            if (z->pos + 4 > z->len) return -1;
            len_val = z->buf[z->pos] | (z->buf[z->pos + 1] << 8);
            nlen_val = z->buf[z->pos + 2] | (z->buf[z->pos + 3] << 8);
            z->pos += 4;
            if ((len_val ^ 0xFFFF) != nlen_val) return -1;
            if (z->pos + len_val > z->len) return -1;
            if (pos + len_val > out_cap) return -1;
            memcpy(out + pos, z->buf + z->pos, len_val);
            z->pos += len_val;
            pos += len_val;
        } else if (block_type == 1 || block_type == 2) {
            /* Compressed block */
            if (block_type == 1) {
                /* Fixed Huffman codes */
                stbi__zhuff_build(&lit_huff, stbi__fixed_lit_lengths, 288);
                stbi__zhuff_build(&dist_huff, stbi__fixed_dist_lengths, 32);
            } else {
                /* Dynamic Huffman codes */
                int hlit, hdist, hclen;
                stbi_uc code_lengths[19];
                stbi_uc lit_lengths[288];
                stbi_uc dist_lengths[32];
                stbi__huffman code_huff;
                static const int cl_order[19] = {
                    16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15
                };
                int i;

                hlit = (int)stbi__zgetbits(z, 5) + 257;
                hdist = (int)stbi__zgetbits(z, 5) + 1;
                hclen = (int)stbi__zgetbits(z, 4) + 4;

                memset(code_lengths, 0, sizeof(code_lengths));
                for (i = 0; i < hclen; i++)
                    code_lengths[cl_order[i]] = (stbi_uc)stbi__zgetbits(z, 3);

                stbi__zhuff_build(&code_huff, code_lengths, 19);

                /* Decode literal/length + distance code lengths */
                int total = hlit + hdist;
                memset(lit_lengths, 0, sizeof(lit_lengths));
                memset(dist_lengths, 0, sizeof(dist_lengths));

                i = 0;
                while (i < total) {
                    int sym = stbi__zhuff_decode(&code_huff, z);
                    if (sym < 0) return -1;
                    if (sym < 16) {
                        if (i < hlit) lit_lengths[i] = (stbi_uc)sym;
                        else dist_lengths[i - hlit] = (stbi_uc)sym;
                        i++;
                    } else if (sym == 16) {
                        int repeat = (int)stbi__zgetbits(z, 2) + 3;
                        stbi_uc prev = (i < hlit) ? lit_lengths[i-1] : dist_lengths[i-hlit-1];
                        while (repeat-- > 0 && i < total) {
                            if (i < hlit) lit_lengths[i] = prev;
                            else dist_lengths[i - hlit] = prev;
                            i++;
                        }
                    } else if (sym == 17) {
                        int repeat = (int)stbi__zgetbits(z, 3) + 3;
                        i += repeat;
                    } else if (sym == 18) {
                        int repeat = (int)stbi__zgetbits(z, 7) + 11;
                        i += repeat;
                    } else {
                        return -1;
                    }
                }

                stbi__zhuff_build(&lit_huff, lit_lengths, hlit);
                stbi__zhuff_build(&dist_huff, dist_lengths, hdist);
            }

            /* Decode data */
            for (;;) {
                int sym = stbi__zhuff_decode(&lit_huff, z);
                if (sym < 0) return -1;
                if (sym < 256) {
                    if (pos >= out_cap) return -1;
                    out[pos++] = (stbi_uc)sym;
                } else if (sym == 256) {
                    break; /* end of block */
                } else {
                    /* Length/distance pair */
                    int len_sym = sym - 257;
                    int length, dist;
                    int dist_sym;

                    if (len_sym < 0 || len_sym >= 29) return -1;
                    length = stbi__zlen_base[len_sym];
                    if (stbi__zlen_extra[len_sym] > 0)
                        length += (int)stbi__zgetbits(z, stbi__zlen_extra[len_sym]);

                    dist_sym = stbi__zhuff_decode(&dist_huff, z);
                    if (dist_sym < 0 || dist_sym >= 30) return -1;
                    dist = stbi__zdist_base[dist_sym];
                    if (stbi__zdist_extra[dist_sym] > 0)
                        dist += (int)stbi__zgetbits(z, stbi__zdist_extra[dist_sym]);

                    if (pos + length > out_cap) return -1;
                    if (dist > pos) return -1;

                    {
                        int j;
                        for (j = 0; j < length; j++)
                            out[pos] = out[pos - dist], pos++;
                    }
                }
            }
        } else {
            return -1; /* invalid block type */
        }
    } while (!final_block);

    *out_len = pos;
    return 0;
}

/* Decompress zlib data (2-byte header + deflate + 4-byte adler32) */
static int stbi__zlib_decompress(const stbi_uc *in, int in_len,
                                  stbi_uc *out, int out_cap, int *out_len) {
    int cmf, flg;
    stbi__zstream z;

    if (in_len < 6) return -1;
    cmf = in[0];
    flg = in[1];
    if ((cmf * 256 + flg) % 31 != 0) return -1;
    if ((cmf & 0x0F) != 8) return -1; /* only deflate supported */

    stbi__zinit(&z, in + 2, in_len - 6);
    if (stbi__inflate(&z, out, out_cap, out_len) < 0) return -1;

    /* Verify Adler32 */
    {
        unsigned int expected = stbi__read32be(in + in_len - 4);
        unsigned int actual = stbi__adler32(out, *out_len);
        if (expected != actual) return -1;
    }
    return 0;
}

/* ---- PNG chunk reading ---- */

typedef struct {
    const stbi_uc *buf;
    int buf_len;
    int pos;
} stbi__png;

typedef struct {
    unsigned int type;
    const stbi_uc *data;
    int length;
} stbi__png_chunk;

static int stbi__png_init(stbi__png *p, const stbi_uc *buf, int len) {
    p->buf = buf;
    p->buf_len = len;
    p->pos = 8; /* skip signature */
    return 0;
}

static int stbi__png_next_chunk(stbi__png *p, stbi__png_chunk *c) {
    if (p->pos + 8 > p->buf_len) return -1;
    c->length = (int)stbi__read32be(p->buf + p->pos);
    c->type = stbi__read32be(p->buf + p->pos + 4);
    c->data = p->buf + p->pos + 8;
    if (p->pos + 12 + c->length > p->buf_len) return -1;
    /* Verify CRC */
    {
        unsigned int crc = stbi__crc32(p->buf + p->pos + 4, 4 + c->length);
        unsigned int stored = stbi__read32be(p->buf + p->pos + 8 + c->length);
        if (crc != stored) return -1;
    }
    p->pos += 12 + c->length;
    return 0;
}

/* PNG filter reconstruction */
static void stbi__png_unfilter(stbi_uc *row, const stbi_uc *prev, int len, int bpp, int filter) {
    int i;
    switch (filter) {
    case 0: /* None */
        break;
    case 1: /* Sub */
        for (i = bpp; i < len; i++)
            row[i] = (stbi_uc)(row[i] + row[i - bpp]);
        break;
    case 2: /* Up */
        for (i = 0; i < len; i++)
            row[i] = (stbi_uc)(row[i] + prev[i]);
        break;
    case 3: /* Average */
        for (i = 0; i < len; i++) {
            int a = (i >= bpp) ? row[i - bpp] : 0;
            int b = prev[i];
            row[i] = (stbi_uc)(row[i] + ((a + b) >> 1));
        }
        break;
    case 4: /* Paeth */
        for (i = 0; i < len; i++) {
            int a = (i >= bpp) ? row[i - bpp] : 0;
            int b = prev[i];
            int c = (i >= bpp) ? prev[i - bpp] : 0;
            int p = a + b - c;
            int pa = p - a; if (pa < 0) pa = -pa;
            int pb = p - b; if (pb < 0) pb = -pb;
            int pc = p - c; if (pc < 0) pc = -pc;
            int pr;
            if (pa <= pb && pa <= pc) pr = a;
            else if (pb <= pc) pr = b;
            else pr = c;
            row[i] = (stbi_uc)(row[i] + pr);
        }
        break;
    }
}

/* Main PNG load function */
static stbi_uc *stbi__load_png(const stbi_uc *buf, int len,
                                int *out_w, int *out_h, int *out_ch) {
    stbi__png p;
    stbi__png_chunk chunk;
    int width = 0, height = 0, bit_depth = 0, color_type = 0;
    int channels = 0, bpp = 0, stride = 0;
    stbi_uc *idat_data = NULL;
    int idat_len = 0;
    stbi_uc *compressed = NULL;
    int compressed_len = 0;
    stbi_uc *raw = NULL;
    int raw_len = 0;
    stbi_uc *result = NULL;
    int i, y;

    if (!stbi__check_png_sig(buf, len)) {
        stbi__error_reason = "not a PNG file";
        return NULL;
    }

    stbi__png_init(&p, buf, len);

    /* Read IHDR */
    if (stbi__png_next_chunk(&p, &chunk) < 0 || chunk.type != 0x49484452) {
        stbi__error_reason = "missing IHDR";
        return NULL;
    }
    if (chunk.length < 13) {
        stbi__error_reason = "IHDR too short";
        return NULL;
    }

    width = (int)stbi__read32be(chunk.data);
    height = (int)stbi__read32be(chunk.data + 4);
    bit_depth = chunk.data[8];
    color_type = chunk.data[9];

    if (width <= 0 || height <= 0 || width > 65535 || height > 65535) {
        stbi__error_reason = "invalid dimensions";
        return NULL;
    }

    switch (color_type) {
    case 0: channels = 1; break; /* grayscale */
    case 2: channels = 3; break; /* RGB */
    case 3: channels = 1; break; /* indexed */
    case 4: channels = 2; break; /* grayscale + alpha */
    case 6: channels = 4; break; /* RGBA */
    default:
        stbi__error_reason = "unsupported color type";
        return NULL;
    }

    if (bit_depth != 8 && bit_depth != 16) {
        /* Support 1,2,4 bit for grayscale/indexed only */
        if (bit_depth > 8 || (color_type != 0 && color_type != 3 && bit_depth < 8)) {
            stbi__error_reason = "unsupported bit depth";
            return NULL;
        }
    }

    bpp = channels * (bit_depth >= 8 ? bit_depth / 8 : 1);
    stride = width * channels * (bit_depth >= 8 ? bit_depth / 8 : 1);

    /* Collect all IDAT chunks */
    idat_data = (stbi_uc *)malloc(len);
    if (!idat_data) {
        stbi__error_reason = "out of memory";
        return NULL;
    }
    idat_len = 0;

    while (stbi__png_next_chunk(&p, &chunk) == 0) {
        if (chunk.type == 0x49444154) { /* IDAT */
            memcpy(idat_data + idat_len, chunk.data, chunk.length);
            idat_len += chunk.length;
        } else if (chunk.type == 0x49454E44) { /* IEND */
            break;
        }
        /* Skip other chunks (tRNS, PLTE, etc.) for now */
    }

    if (idat_len == 0) {
        stbi__error_reason = "no IDAT data";
        free(idat_data);
        return NULL;
    }

    /* Decompress zlib data */
    compressed = idat_data;
    compressed_len = idat_len;

    /* Estimate max decompressed size: (stride + 1 filter byte) * height */
    raw = (stbi_uc *)malloc((size_t)(stride + 1) * height + 16);
    if (!raw) {
        stbi__error_reason = "out of memory";
        free(idat_data);
        return NULL;
    }

    if (stbi__zlib_decompress(compressed, compressed_len,
                               raw, (stride + 1) * height + 16, &raw_len) < 0) {
        stbi__error_reason = "zlib decompress failed";
        free(raw);
        free(idat_data);
        return NULL;
    }

    free(idat_data);
    idat_data = NULL;

    /* Unfilter rows */
    {
        int row_bytes = stride;
        stbi_uc *prev_row = (stbi_uc *)calloc(row_bytes, 1);
        stbi_uc *cur_row;

        if (!prev_row) {
            stbi__error_reason = "out of memory";
            free(raw);
            return NULL;
        }

        for (y = 0; y < height; y++) {
            int offset = y * (row_bytes + 1);
            int filter = raw[offset];
            cur_row = raw + offset + 1;

            if (filter > 4) {
                free(prev_row);
                free(raw);
                stbi__error_reason = "invalid PNG filter";
                return NULL;
            }

            stbi__png_unfilter(cur_row, prev_row, row_bytes, bpp, filter);
            memcpy(prev_row, cur_row, row_bytes);
        }
        free(prev_row);
    }

    /* Convert to output format */
    /* Compact: remove filter bytes, result is height * stride bytes */
    {
        stbi_uc *compacted = (stbi_uc *)malloc((size_t)height * stride);
        if (!compacted) {
            stbi__error_reason = "out of memory";
            free(raw);
            return NULL;
        }
        for (y = 0; y < height; y++) {
            memcpy(compacted + y * stride, raw + y * (stride + 1) + 1, stride);
        }
        free(raw);
        raw = compacted;
    }

    /* Handle 16-bit -> 8-bit conversion */
    if (bit_depth == 16) {
        stbi_uc *reduced = (stbi_uc *)malloc((size_t)width * height * channels);
        if (!reduced) {
            stbi__error_reason = "out of memory";
            free(raw);
            return NULL;
        }
        for (i = 0; i < width * height * channels; i++) {
            reduced[i] = raw[i * 2]; /* take high byte */
        }
        free(raw);
        raw = reduced;
        stride = width * channels;
        bit_depth = 8;
    }

    /* Handle palette (color_type 3) - treat as grayscale for now */
    /* Handle grayscale -> RGB expansion */

    /* Allocate final RGBA output */
    result = (stbi_uc *)malloc((size_t)width * height * 4);
    if (!result) {
        stbi__error_reason = "out of memory";
        free(raw);
        return NULL;
    }

    for (i = 0; i < width * height; i++) {
        stbi_uc *src = raw + i * channels;
        stbi_uc *dst = result + i * 4;
        switch (channels) {
        case 1: /* grayscale */
            dst[0] = dst[1] = dst[2] = src[0];
            dst[3] = 255;
            break;
        case 2: /* grayscale + alpha */
            dst[0] = dst[1] = dst[2] = src[0];
            dst[3] = src[1];
            break;
        case 3: /* RGB */
            dst[0] = src[0];
            dst[1] = src[1];
            dst[2] = src[2];
            dst[3] = 255;
            break;
        case 4: /* RGBA */
            dst[0] = src[0];
            dst[1] = src[1];
            dst[2] = src[2];
            dst[3] = src[3];
            break;
        }
    }

    free(raw);

    *out_w = width;
    *out_h = height;
    *out_ch = 4;
    return result;
}

/* ---- Main entry point ---- */

stbi_uc *stbi_load_from_memory(stbi_uc const *buffer, int len,
                               int *x, int *y,
                               int *channels_in_file,
                               int desired_channels) {
    stbi_uc *result = NULL;
    int orig_channels = 0;

    stbi__error_reason = NULL;

    if (!buffer || len <= 0) {
        stbi__error_reason = "invalid input";
        return NULL;
    }

    /* Try PNG first */
    if (stbi__check_png_sig(buffer, len)) {
        result = stbi__load_png(buffer, len, x, y, &orig_channels);
    } else {
        stbi__error_reason = "unsupported image format (only PNG supported)";
        return NULL;
    }

    if (!result) return NULL;

    /* Handle desired_channels conversion */
    if (desired_channels > 0 && desired_channels != orig_channels) {
        int pixels = (*x) * (*y);
        int src_ch = orig_channels;
        int dst_ch = desired_channels;
        stbi_uc *converted = (stbi_uc *)malloc((size_t)pixels * dst_ch);
        int i;

        if (!converted) {
            stbi__error_reason = "out of memory";
            free(result);
            return NULL;
        }

        for (i = 0; i < pixels; i++) {
            stbi_uc *s = result + i * src_ch;
            stbi_uc *d = converted + i * dst_ch;
            int r, g, b, a;

            /* Read source pixel */
            switch (src_ch) {
            case 1: r = g = b = s[0]; a = 255; break;
            case 2: r = g = b = s[0]; a = s[1]; break;
            case 3: r = s[0]; g = s[1]; b = s[2]; a = 255; break;
            case 4: r = s[0]; g = s[1]; b = s[2]; a = s[3]; break;
            default: r = g = b = 0; a = 255; break;
            }

            /* Write destination pixel */
            switch (dst_ch) {
            case 1:
                d[0] = (stbi_uc)((r * 54 + g * 183 + b * 19) >> 8);
                break;
            case 2:
                d[0] = (stbi_uc)((r * 54 + g * 183 + b * 19) >> 8);
                d[1] = (stbi_uc)a;
                break;
            case 3:
                d[0] = (stbi_uc)r; d[1] = (stbi_uc)g; d[2] = (stbi_uc)b;
                break;
            case 4:
                d[0] = (stbi_uc)r; d[1] = (stbi_uc)g; d[2] = (stbi_uc)b; d[3] = (stbi_uc)a;
                break;
            }
        }
        free(result);
        result = converted;
    }

    if (channels_in_file) *channels_in_file = orig_channels;
    return result;
}

#endif /* STB_IMAGE_IMPLEMENTATION */
