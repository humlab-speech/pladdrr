// cochleagram_wrappers.cpp
// Wrapper functions for Praat Cochleagram object

#include <Rcpp.h>
#include "praat.github.io/fon/Cochleagram.h"
#include "praat.github.io/fon/Sound_to_Cochleagram.h"
#include "praat.github.io/fon/Cochleagram_and_Excitation.h"
#include "praat.github.io/fon/Sound.h"

// [[Rcpp::export(.cochleagram_create)]]
SEXP cochleagram_create(double tmin, double tmax, int nt, double dt, double t1,
                        double df, int nf) {
  try {
    autoCochleagram result = Cochleagram_create(tmin, tmax, nt, dt, t1, df, nf);
    if (!result) {
      Rcpp::stop("Failed to create Cochleagram object");
    }
    Rcpp::XPtr<structCochleagram> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Cochleagram_create");
  }
}

// [[Rcpp::export(.sound_to_cochleagram)]]
SEXP sound_to_cochleagram(SEXP sound_xptr, double dt, double df,
                          double window_length, double forward_masking_time) {
  try {
    Rcpp::XPtr<structSound> sound(sound_xptr);
    if (!sound) {
      Rcpp::stop("Invalid Sound object");
    }
    
    autoCochleagram result = Sound_to_Cochleagram(
      sound, dt, df, window_length, forward_masking_time
    );
    
    if (!result) {
      Rcpp::stop("Failed to create Cochleagram from Sound");
    }
    
    Rcpp::XPtr<structCochleagram> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Sound_to_Cochleagram");
  }
}

// [[Rcpp::export(.sound_to_cochleagram_edb)]]
SEXP sound_to_cochleagram_edb(SEXP sound_xptr, double dtime, double dfreq,
                               bool has_synapse, double replenishment_rate,
                               double loss_rate, double return_rate,
                               double reprocessing_rate) {
  try {
    Rcpp::XPtr<structSound> sound(sound_xptr);
    if (!sound) {
      Rcpp::stop("Invalid Sound object");
    }
    
    autoCochleagram result = Sound_to_Cochleagram_edb(
      sound, dtime, dfreq, has_synapse ? 1 : 0,
      replenishment_rate, loss_rate, return_rate, reprocessing_rate
    );
    
    if (!result) {
      Rcpp::stop("Failed to create Cochleagram (EDB method) from Sound");
    }
    
    Rcpp::XPtr<structCochleagram> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Sound_to_Cochleagram_edb");
  }
}

// [[Rcpp::export(.cochleagram_get_value_at_time_and_frequency)]]
double cochleagram_get_value_at_time_and_frequency(SEXP xptr, double time, double freq_bark) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    // Use Matrix functions to get value (Cochleagram inherits from Matrix)
    double value = cochleagram->z.at[
      Melder_iround((freq_bark - cochleagram->y1) / cochleagram->dy + 1)
    ][
      Melder_iround((time - cochleagram->x1) / cochleagram->dx + 1)
    ];
    
    return value;
  } catch (MelderError) {
    Rcpp::stop("Praat error getting value at time and frequency");
  }
}

// [[Rcpp::export(.cochleagram_get_time_from_column)]]
double cochleagram_get_time_from_column(SEXP xptr, int i_col) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    if (i_col < 1 || i_col > cochleagram->nx) {
      Rcpp::stop("Column index out of range");
    }
    
    return cochleagram->x1 + (i_col - 1) * cochleagram->dx;
  } catch (...) {
    Rcpp::stop("Error getting time from column");
  }
}

// [[Rcpp::export(.cochleagram_get_frequency_from_row)]]
double cochleagram_get_frequency_from_row(SEXP xptr, int i_row) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    if (i_row < 1 || i_row > cochleagram->ny) {
      Rcpp::stop("Row index out of range");
    }
    
    return cochleagram->y1 + (i_row - 1) * cochleagram->dy;
  } catch (...) {
    Rcpp::stop("Error getting frequency from row");
  }
}

// [[Rcpp::export(.cochleagram_to_excitation)]]
SEXP cochleagram_to_excitation(SEXP xptr, double time) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    autoExcitation result = Cochleagram_to_Excitation(cochleagram, time);
    
    if (!result) {
      Rcpp::stop("Failed to create Excitation from Cochleagram");
    }
    
    Rcpp::XPtr<structExcitation> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Cochleagram_to_Excitation");
  }
}

// [[Rcpp::export(.cochleagram_difference)]]
double cochleagram_difference(SEXP xptr1, SEXP xptr2, double tmin, double tmax) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram1(xptr1);
    Rcpp::XPtr<structCochleagram> cochleagram2(xptr2);
    
    if (!cochleagram1 || !cochleagram2) {
      Rcpp::stop("Invalid Cochleagram object(s)");
    }
    
    double difference = Cochleagram_difference(cochleagram1, cochleagram2, tmin, tmax);
    return difference;
  } catch (MelderError) {
    Rcpp::stop("Praat error calculating cochleagram difference");
  }
}

// [[Rcpp::export(.cochleagram_as_matrix)]]
Rcpp::List cochleagram_as_matrix(SEXP xptr) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    int nrow = cochleagram->ny;
    int ncol = cochleagram->nx;
    
    Rcpp::NumericMatrix mat(nrow, ncol);
    Rcpp::NumericVector times(ncol);
    Rcpp::NumericVector freqs(nrow);
    
    // Fill matrix
    for (int i = 1; i <= nrow; i++) {
      for (int j = 1; j <= ncol; j++) {
        mat(i-1, j-1) = cochleagram->z[i][j];
      }
    }
    
    // Fill time and frequency vectors
    for (int j = 1; j <= ncol; j++) {
      times(j-1) = cochleagram->x1 + (j - 1) * cochleagram->dx;
    }
    
    for (int i = 1; i <= nrow; i++) {
      freqs(i-1) = cochleagram->y1 + (i - 1) * cochleagram->dy;
    }
    
    return Rcpp::List::create(
      Rcpp::Named("values") = mat,
      Rcpp::Named("times") = times,
      Rcpp::Named("frequencies") = freqs,
      Rcpp::Named("tmin") = cochleagram->xmin,
      Rcpp::Named("tmax") = cochleagram->xmax,
      Rcpp::Named("fmin") = cochleagram->ymin,
      Rcpp::Named("fmax") = cochleagram->ymax
    );
  } catch (...) {
    Rcpp::stop("Error converting Cochleagram to matrix");
  }
}

// [[Rcpp::export(.cochleagram_get_info)]]
Rcpp::List cochleagram_get_info(SEXP xptr) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    return Rcpp::List::create(
      Rcpp::Named("xmin") = cochleagram->xmin,
      Rcpp::Named("xmax") = cochleagram->xmax,
      Rcpp::Named("nx") = cochleagram->nx,
      Rcpp::Named("dx") = cochleagram->dx,
      Rcpp::Named("x1") = cochleagram->x1,
      Rcpp::Named("ymin") = cochleagram->ymin,
      Rcpp::Named("ymax") = cochleagram->ymax,
      Rcpp::Named("ny") = cochleagram->ny,
      Rcpp::Named("dy") = cochleagram->dy,
      Rcpp::Named("y1") = cochleagram->y1
    );
  } catch (...) {
    Rcpp::stop("Error getting Cochleagram info");
  }
}

// Finalizer for Cochleagram objects
// [[Rcpp::export(.cochleagram_finalizer)]]
void cochleagram_finalizer(SEXP xptr) {
  Rcpp::XPtr<structCochleagram> ptr(xptr);
  if (ptr) {
    forget(ptr.get());
  }
}
