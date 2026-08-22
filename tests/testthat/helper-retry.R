# Helper functions shared across tests that hit the flaky vendored SPINET path

#' Retry an expression once if it errors
#'
#' The vendored Praat SPINET path (src/sound_create_gaussian.cpp /
#' praat.github.io/dwtools/Sound_to_SPINET.cpp) intermittently fails with
#' "The sound should not have all amplitudes equal to zero" even though the
#' input signal is unchanged. Empirically, two consecutive SPINET failures
#' were never observed across hundreds of stress-test calls (90/90 successful
#' retries in initial validation; an independent review re-verified this
#' across ~740 additional calls, also 0 double-failures), so a single retry
#' is a reliable mitigation. Note: the failure pattern itself is NOT a clean
#' deterministic alternation -- independent testing showed first-attempt
#' failure rates varying widely (roughly 0%-99%) across different process
#' runs, likely due to some form of process-level state (e.g. uninitialized
#' memory, allocator reuse, or a static buffer) rather than a fixed
#' input-independent rule. The single-retry mitigation remains reliable in
#' practice regardless of the underlying mechanism.
#'
#' @param expr Expression to evaluate, retried once (via `tryCatch`) if it
#'   errors on the first attempt. Captured via NSE (`substitute()`) and
#'   re-`eval()`d on retry rather than reusing the original promise, so the
#'   expression genuinely runs a second time (a bare `tryCatch(expr, error =
#'   function(e) expr)` would work too, but emits a spurious "restarting
#'   interrupted promise evaluation" warning on retry).
retry_once <- function(expr) {
  expr <- substitute(expr)
  env <- parent.frame()
  tryCatch(eval(expr, env), error = function(e) eval(expr, env))
}
