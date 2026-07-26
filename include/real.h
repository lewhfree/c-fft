#ifndef REAL_H
#define REAL_H

#include "kiss_fft.h"

void KISS_FFT_API lhf_imag_pair_to_real(int nfft, kiss_fft_cpx *freqdata, kiss_fft_scalar *magdata);

#endif
