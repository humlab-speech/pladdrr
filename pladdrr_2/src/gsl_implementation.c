/*
 * GSL Implementation for speaker package
 * 
 * This file provides real implementations of GSL functions using
 * the GSL 2.8 source code present in src/gsl-2.8/
 * 
 * Instead of linking against libgsl, we directly include the necessary
 * GSL source files to make the package self-contained and CRAN-compliant.
 */

#define HAVE_INLINE  /* Enable GSL inline functions */

/* Include GSL headers */
#include "gsl-2.8/gsl/gsl_sf_bessel.h"
#include "gsl-2.8/gsl/gsl_sf_gamma.h"
#include "gsl-2.8/gsl/gsl_sf_erf.h"
#include "gsl-2.8/gsl/gsl_sf_hyperg.h"
#include "gsl-2.8/gsl/gsl_sf_psi.h"
#include "gsl-2.8/gsl/gsl_sf_trig.h"
#include "gsl-2.8/gsl/gsl_cdf.h"
#include "gsl-2.8/gsl/gsl_poly.h"
#include "gsl-2.8/gsl/gsl_errno.h"

/*
 * This file acts as a bridge between Praat's expectations and GSL's implementation.
 * The actual GSL function implementations are in the .c files that will be compiled
 * as part of the package (specified in Makevars).
 * 
 * This wrapper ensures:
 * 1. Correct header inclusion order
 * 2. Proper GSL configuration
 * 3. Error handler setup
 */

/* GSL error handling - use GSL's default handlers */
void speaker_gsl_error_handler_off(void) {
    gsl_set_error_handler_off();
}

void speaker_gsl_error_handler_restore(void) {
    gsl_set_error_handler(NULL);  /* Restore default */
}

