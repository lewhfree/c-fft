#include "decode.h"
#include "dr_flac.h"
#include "dr_wav.h"
#include "dr_mp3.h"
#include "speex_resampler.h"
#include "xxh64.h"
// #include "real.h"
// #include "kiss_fftr.h"

#include <stdlib.h>

audio decode_wav(const void* data, size_t size){
  drwav wav;

  //NULL in init just uses the default callbacks line 1909
  drwav_init_memory(&wav, data, size, NULL);

  drwav_uint64 frames = wav.totalPCMFrameCount;
  int channels = wav.channels;
  drwav_uint32 sample = wav.sampleRate;
  float *pBufferOut = malloc(frames * channels * sizeof(float));

  drwav_uint64 frames_read = drwav_read_pcm_frames_f32(&wav, frames, pBufferOut);

  //turn to mono audio.
  float* audio_buffer_for_mono = malloc(frames_read * sizeof(float));
  for(drwav_uint64 i = 0; i < frames_read; i += channels){
    float tmpsum = 0.0;

    for(int j = 0; j < channels; j++){
      tmpsum += pBufferOut[i+j];
    }
    
    audio_buffer_for_mono[i/channels] = tmpsum / channels;
  }
  audio ret;
  ret.audio_ptr = audio_buffer_for_mono;
  ret.count = frames_read / channels;
  ret.sr = sample;
  return ret;
}

// Same as wav except find and replace wav->mp3
audio decode_mp3(const void* data, size_t size){
  drmp3 mp3;
  drmp3_init_memory(&mp3, data, size, NULL);
  drmp3_uint64 frames = mp3.totalPCMFrameCount;
  int channels = mp3.channels;
  drmp3_uint32 sample = mp3.sampleRate;
  float *pBufferOut = malloc(frames * channels * sizeof(float));
  drmp3_uint64 frames_read = drmp3_read_pcm_frames_f32(&mp3, frames, pBufferOut);
  float* audio_buffer_for_mono = malloc(frames_read * sizeof(float));
  for(drmp3_uint64 i = 0; i < frames_read; i += channels){
    float tmpsum = 0.0;
    for(int j = 0; j < channels; j++){
      tmpsum += pBufferOut[i+j];
    }
    audio_buffer_for_mono[i/channels] = tmpsum / channels;
  }
  audio ret;
  ret.audio_ptr = audio_buffer_for_mono;
  ret.count = frames_read / channels;
  ret.sr = sample;
  return ret;
}

//Different, no init_memory, but this should work
audio decode_flac(const void* data, size_t size){
  drflac* flac;
  // drflac_init_memory(&flac, data, size, NULL);
  flac = drflac_open_memory(data, size, NULL);

  drflac_uint64 frames = flac->totalPCMFrameCount;
  int channels = flac->channels;
  drflac_uint32 sample = flac->sampleRate;
  float *pBufferOut = malloc(frames * channels * sizeof(float));
  drflac_uint64 frames_read = drflac_read_pcm_frames_f32(flac, frames, pBufferOut);
  float* audio_buffer_for_mono = malloc(frames_read * sizeof(float));
  for(drflac_uint64 i = 0; i < frames_read; i += channels){
    float tmpsum = 0.0;
    for(int j = 0; j < channels; j++){
      tmpsum += pBufferOut[i+j];
    }
    audio_buffer_for_mono[i/channels] = tmpsum / channels;
  }
  audio ret;
  ret.audio_ptr = audio_buffer_for_mono;
  ret.count = frames_read / channels;
  ret.sr = sample;
  return ret;
}

//Unhardcode this. Should make a struct to hold all networked variables
#define OUTSAMPLERATE 8000
audio resample_audio(audio decoded_audio){
  SpeexResamplerState* resampler;
  resampler = speex_resampler_init(1, decoded_audio.sr, OUTSAMPLERATE, 10, NULL);
  unsigned int length = decoded_audio.count/decoded_audio.sr;

  float* outBuffer = malloc(sizeof(float) * length * OUTSAMPLERATE);
  unsigned int tmp = length*OUTSAMPLERATE;
  
  int err = speex_resampler_process_float(resampler, 0, decoded_audio.audio_ptr, &decoded_audio.count, outBuffer, &tmp);
  audio ret;
  //ignore errors for now hehe
  (void)err;
  ret.sr = OUTSAMPLERATE;
  ret.audio_ptr = outBuffer;
  ret.count = tmp;
  return ret;
}
