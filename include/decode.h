#ifndef DECODE_H
#define DECODE_H

#include <stdint.h>
#include <stdlib.h>

typedef struct {
  float* audio_ptr;
  uint32_t count;
  uint32_t sr;
} audio;

audio decode_wav(const void*, size_t);
audio decode_mp3(const void*, size_t);
audio decode_flac(const void*, size_t);
audio resample_audio(audio);

#endif
