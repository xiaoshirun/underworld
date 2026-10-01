/* stb_image - v2.30 - public domain image loader
 * https://github.com/nothings/stb
 *
 * PLACEHOLDER HEADER - minimal API declarations for compilation.
 * Replace with the full stb_image.h from the official repository
 * before shipping.
 *
 * USAGE:
 *   In exactly ONE .c file, define STB_IMAGE_IMPLEMENTATION before
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

/* Load an image from memory.
 *
 * @param buffer          Pointer to the encoded image data.
 * @param len             Length of buffer in bytes.
 * @param x               [out] Image width in pixels.
 * @param y               [out] Image height in pixels.
 * @param channels_in_file [out] Number of channels in the source image.
 * @param desired_channels  Requested channel count (0 = use source count).
 * @return Pointer to decoded pixel data (RGBA/RGB/etc.), or NULL on failure.
 *         Caller must free with stbi_image_free().
 */
stbi_uc *stbi_load_from_memory(stbi_uc const *buffer, int len,
                               int *x, int *y,
                               int *channels_in_file,
                               int desired_channels);

/* Free pixel data returned by stbi_load_from_memory. */
void stbi_image_free(void *retval_from_stbi_load);

/* Return a human-readable error string for the last failed load. */
const char *stbi_failure_reason(void);

#ifdef __cplusplus
}
#endif

#endif /* STBI_INCLUDE_STB_IMAGE_H */
