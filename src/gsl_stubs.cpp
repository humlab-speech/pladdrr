// GSL (GNU Scientific Library) stubs  
// These functions are not available in this build

extern "C" {

void* gsl_set_error_handler_off () { return nullptr; }
void* gsl_set_error_handler (void*) { return nullptr; }
void gsl_error (char const*, char const*, int, int) {}

// GSL special functions stubs
struct gsl_sf_result { double val; double err; };

int gsl_sf_bessel_In_e (int, double, gsl_sf_result*) { return 0; }
int gsl_sf_bessel_Kn_e (int, double, gsl_sf_result*) { return 0; }
double gsl_sf_bessel_I0 (double) { return 0.0; }
double gsl_sf_bessel_K0 (double) { return 0.0; }
double gsl_sf_bessel_I1 (double) { return 0.0; }
double gsl_sf_bessel_K1 (double) { return 0.0; }
int gsl_sf_beta_inc_e (double, double, double, gsl_sf_result*) { return 0; }
int gsl_sf_beta_e (double, double, gsl_sf_result*) { return 0; }
double gsl_sf_beta (double, double) { return 0.0; }
int gsl_sf_lnbeta_e (double, double, gsl_sf_result*) { return 0; }
double gsl_sf_lnbeta (double, double) { return 0.0; }
int gsl_sf_gamma_inc_P_e (double, double, gsl_sf_result*) { return 0; }
int gsl_sf_gamma_inc_Q_e (double, double, gsl_sf_result*) { return 0; }
int gsl_sf_lngamma_e (double, gsl_sf_result*) { return 0; }
int gsl_sf_lngamma_complex_e (double, double, gsl_sf_result*, gsl_sf_result*) { return 0; }
double gsl_sf_gamma (double) { return 0.0; }
double gsl_sf_lngamma (double) { return 0.0; }
int gsl_sf_erfc_e (double, gsl_sf_result*) { return 0; }
double gsl_sf_erfc (double) { return 0.0; }
double gsl_sf_erf (double) { return 0.0; }
int gsl_sf_erf_e (double, gsl_sf_result*) { return 0; }
double gsl_sf_hyperg_2F1 (double, double, double, double) { return 0.0; }
int gsl_sf_hyperg_2F1_e (double, double, double, double, gsl_sf_result*) { return 0; }
double gsl_sf_psi_n (int, double) { return 0.0; }
double gsl_sf_psi (double) { return 0.0; }
double gsl_sf_psi_1 (double) { return 0.0; }
int gsl_sf_sinc_e (double, gsl_sf_result*) { return 0; }
double gsl_sf_sinc (double) { return 0.0; }

// GSL CDF functions
double gsl_cdf_fdist_Q (double, double, double) { return 0.0; }
double gsl_cdf_fdist_Qinv (double, double, double) { return 0.0; }
double gsl_cdf_lognormal_P (double, double, double) { return 0.0; }
double gsl_cdf_lognormal_Q (double, double, double) { return 0.0; }
double gsl_cdf_lognormal_Pinv (double, double, double) { return 0.0; }
double gsl_cdf_lognormal_Qinv (double, double, double) { return 0.0; }
double gsl_cdf_gaussian_P (double, double) { return 0.0; }
double gsl_cdf_gaussian_Q (double, double) { return 0.0; }
double gsl_cdf_gaussian_Pinv (double, double) { return 0.0; }
double gsl_cdf_gaussian_Qinv (double, double) { return 0.0; }
double gsl_cdf_beta_P (double, double, double) { return 0.0; }
double gsl_cdf_beta_Q (double, double, double) { return 0.0; }
double gsl_cdf_beta_Pinv (double, double, double) { return 0.0; }
double gsl_cdf_beta_Qinv (double, double, double) { return 0.0; }
double gsl_cdf_chisq_P (double, double) { return 0.0; }
double gsl_cdf_chisq_Q (double, double) { return 0.0; }
double gsl_cdf_chisq_Pinv (double, double) { return 0.0; }
double gsl_cdf_chisq_Qinv (double, double) { return 0.0; }
double gsl_cdf_tdist_P (double, double) { return 0.0; }
double gsl_cdf_tdist_Q (double, double) { return 0.0; }
double gsl_cdf_tdist_Pinv (double, double) { return 0.0; }
double gsl_cdf_tdist_Qinv (double, double) { return 0.0; }
double gsl_cdf_ugaussian_P (double) { return 0.0; }
double gsl_cdf_ugaussian_Q (double) { return 0.0; }
double gsl_cdf_ugaussian_Pinv (double) { return 0.0; }
double gsl_cdf_ugaussian_Qinv (double) { return 0.0; }

// GSL polynomial solvers
int gsl_poly_solve_quadratic (double, double, double, double*, double*) { return 0; }
int gsl_poly_solve_cubic (double, double, double, double*, double*, double*) { return 0; }

}
