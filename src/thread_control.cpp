/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2026 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
// thread_control.cpp
// Runtime control of Praat MelderThread parallelization

// [[Rcpp::plugins(cpp17)]]

#include <Rcpp.h>
#include "melder/melder.h"

using namespace Rcpp;

//' Set MelderThread parallelization preferences (internal)
//'
//' @param use_multithreading Enable/disable all MelderThread parallelism
//' @param max_threads Maximum concurrent threads; 0 = auto (all processors)
//' @param min_elements_per_thread Minimum elements per thread; 0 = per-function factory tuning
//' @keywords internal
//' @noRd
// [[Rcpp::export(.pladdrr_set_threads_cpp)]]
void pladdrr_set_threads_cpp(bool use_multithreading, int max_threads,
                             int min_elements_per_thread) {
    MelderThread_debugMultithreading(use_multithreading,
        (integer) max_threads, (integer) min_elements_per_thread, false);
}

//' Get MelderThread parallelization state (internal)
//'
//' @return List with processors, enabled, max_threads, min_elements_per_thread
//' @keywords internal
//' @noRd
// [[Rcpp::export(.pladdrr_get_threads_cpp)]]
List pladdrr_get_threads_cpp() {
    return List::create(
        _["processors"] = (int) MelderThread_getNumberOfProcessors(),
        _["enabled"] = MelderThread_getUseMultithreading(),
        _["max_threads"] = (int) MelderThread_getMaximumNumberOfConcurrentThreads(),
        _["min_elements_per_thread"] = (int) MelderThread_getMinimumNumberOfElementsPerThread()
    );
}
