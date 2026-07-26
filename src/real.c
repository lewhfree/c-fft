#include "real.h"
#include <math.h>

void lhf_imag_pair_to_real(int nfft, kiss_fft_cpx *freqdata, kiss_fft_scalar *magdata) {
  for (int i = 0; i < nfft / 2 + 1; i++) {
    kiss_fft_cpx current_struct = freqdata[i];
    magdata[i] = hypotf(current_struct.i, current_struct.r);
  }
}
