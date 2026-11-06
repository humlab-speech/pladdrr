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

// defined in melderthread_impl.cpp; declared here rather than in a vendored
// header because only this shim and the regression test call it
extern integer MelderThread_availableProcessorsForLimits (
    integer numberOfHardwareCores, integer numberOfAffinityCores,
    integer quotaMicroseconds, integer periodMicroseconds);

//' Usable CPU count for synthetic limits (internal)
//'
//' The pure rule behind `MelderThread_getNumberOfProcessors()`, exposed so the
//' precedence between hardware cores, the CPU affinity mask and a cgroup CPU
//' quota can be tested without cgroups. 0 (or negative) means "unknown".
//'
//' @param hardware_cores logical cores as reported by the machine
//' @param affinity_cores CPUs in the process affinity mask
//' @param quota_microseconds cgroup CPU quota (`cpu.max` field 1)
//' @param period_microseconds cgroup quota period (`cpu.max` field 2)
//' @return Number of CPUs the process may use, at least 1
//' @keywords internal
//' @noRd
// [[Rcpp::export(.pladdrr_cpus_for_limits)]]
int pladdrr_cpus_for_limits(int hardware_cores, int affinity_cores,
                            int quota_microseconds, int period_microseconds) {
    return (int) MelderThread_availableProcessorsForLimits(
        (integer) hardware_cores, (integer) affinity_cores,
        (integer) quota_microseconds, (integer) period_microseconds);
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
