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
int gsl_sf_gamma_inc_P_e (double, double, gsl_sf_result*) { return 0; }
int gsl_sf_gamma_inc_Q_e (double, double, gsl_sf_result*) { return 0; }
int gsl_sf_lngamma_e (double, gsl_sf_result*) { return 0; }
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

}
