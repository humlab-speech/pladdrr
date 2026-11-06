# Runtime control of multi-threaded Praat analyses

#' Control multi-threading of Praat analyses
#'
#' Praat's compute kernels (pitch, formant, spectrogram, CPPS, ...) run
#' multi-threaded by default, using every CPU the process may actually use. Use
#' this function to cap or disable threading, or to restore the default.
#'
#' "Every CPU the process may use" is narrower than the machine's core count
#' wherever the process is confined: on Linux the automatic count is the CPU
#' affinity mask (container cpusets, \code{taskset(1)}, SLURM allocations)
#' intersected with the cgroup CPU quota visible to the process
#' (\code{/sys/fs/cgroup/cpu.max}, or cgroup v1 \code{cpu.cfs_quota_us} /
#' \code{cpu.cfs_period_us} — what \code{docker --cpus} sets). A quota placed on an
#' ancestor cgroup is not readable from inside the process's own cgroup view and
#' is therefore not subtracted. Where the platform exposes neither mask nor
#' quota (Windows, macOS), it is the number of logical cores.
#' Sizing the pool from the machine instead would leave threads with no CPU to
#' run on, which costs both time and energy.
#'
#' The package's own batch helpers (\code{analyze_files_parallel()},
#' \code{process_sounds_parallel()}, \code{batch_process()}) already cap each
#' worker's threads automatically, so you only need this when running your own
#' parallel loop (e.g. a hand-written \code{mclapply()} where each worker should stay
#' single-threaded).
#'
#' Threading never changes results: threads partition analysis frames and each
#' frame is computed exactly as in single-threaded mode.
#'
#' @param n Maximum number of concurrent threads. Use \code{1} to disable
#'   threading, \code{NULL} (default) to leave the setting unchanged and just
#'   return the current state, or \code{0} to restore automatic mode (all CPUs this
#'   process may use). An explicit \code{n} always wins over the automatic count.
#'
#' @return Invisibly, a list describing the current state:
#'   \describe{
#'     \item{processors}{Number of CPUs this process may use (see Details).}
#'     \item{enabled}{Whether multi-threading is enabled.}
#'     \item{max_threads}{Effective maximum concurrent threads.}
#'     \item{min_elements_per_thread}{Minimum work per thread; 0 means each
#'       analysis routine uses its own tuned threshold.}
#'   }
#'
#' @examples
#' pladdrr_threads()      # query current state
#' pladdrr_threads(1)     # single-threaded (e.g. inside mclapply workers)
#' pladdrr_threads(0)     # back to automatic (all usable CPUs)
#' @export
pladdrr_threads <- function(n = NULL) {
  if (!is.null(n)) {
    n <- as.integer(n)
    if (length(n) != 1L || is.na(n) || n < 0L) {
      stop("n must be a single non-negative integer (0 = automatic)")
    }
    .pladdrr_set_threads_cpp(
      use_multithreading = n != 1L,
      max_threads = n,
      min_elements_per_thread = 0L
    )
  }
  invisible(.pladdrr_get_threads_cpp())
}
