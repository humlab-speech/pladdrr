# test-affinity-thread-count.R - F-power-01 / F-power-04
# The automatic thread count must follow the CPUs this process may actually use
# (sched_getaffinity mask intersected with the cgroup CPU quota), not the number
# of cores the machine happens to have.

# Pure rule, no I/O: (hardware cores, affinity cores, quota us, period us) -> cap.
test_that(".pladdrr_cpus_for_limits() intersects the affinity mask and the cgroup quota", {
  cpus <- pladdrr:::.pladdrr_cpus_for_limits
  # Nothing known -> the machine's cores, i.e. exactly the pre-fix behaviour
  expect_identical(cpus(32L, 0L, 0L, 0L), 32L)
  expect_identical(cpus(8L, 0L, 0L, 0L), 8L)
  # Affinity mask wins over the machine
  expect_identical(cpus(32L, 8L, 0L, 0L), 8L)
  expect_identical(cpus(32L, 1L, 0L, 0L), 1L)
  # cgroup quota ("200000 100000" = 2 CPUs) caps below the mask
  expect_identical(cpus(32L, 8L, 200000L, 100000L), 2L)
  # fractional quota rounds up: 2.5 CPUs still let 3 threads make progress
  expect_identical(cpus(32L, 8L, 250000L, 100000L), 3L)
  # a quota larger than the mask does not raise the cap
  expect_identical(cpus(32L, 2L, 800000L, 100000L), 2L)
  # cgroup v1 "no quota" sentinel (-1) and a period without a quota are ignored
  expect_identical(cpus(32L, 4L, -1L, 100000L), 4L)
  expect_identical(cpus(32L, 0L, 0L, 100000L), 32L)
  # a quota below one core still runs one thread, and total ignorance too
  expect_identical(cpus(32L, 0L, 50000L, 100000L), 1L)
  expect_identical(cpus(0L, 0L, 0L, 0L), 1L)
})

# Expand /proc/self/status "Cpus_allowed_list" ("0-3,8" -> c(0L,1L,2L,3L,8L))
cpus_in_list <- function (allowed) {
  ranges <- strsplit(trimws(allowed), ",")[[1]]
  parts <- lapply(strsplit(ranges, "-"), as.integer)
  sort(unique(unlist(lapply(parts, function (p)
    if (length(p) == 2L) seq(p[1], p[2]) else p))))
}

allowed_cpus <- function () {
  status <- readLines("/proc/self/status", warn = FALSE)
  cpus_in_list(sub("^Cpus_allowed_list:[[:space:]]*", "",
    grep("^Cpus_allowed_list:", status, value = TRUE)))
}

# The end-to-end half needs both the affinity API (Linux) and taskset(1) to
# constrain a subprocess with it; elsewhere the rule above is the coverage.
have_affinity <- Sys.info()[["sysname"]] == "Linux" &&
  nzchar(Sys.which("taskset")) && file.exists("/proc/self/status")

test_that("automatic thread count and batch defaults follow a taskset CPU mask", {
  skip_if_not(have_affinity, "no sched_getaffinity/taskset on this platform")
  pool <- allowed_cpus()
  skip_if(length(pool) < 2L, "this process is confined to one CPU already")

  # Probe with subsets of whatever the test process itself may use, so the test
  # is meaningful even when the whole suite already runs inside a cpuset.
  for (maskSize in c(4L, 2L)) {
    if (maskSize > length(pool)) next
    mask <- paste(pool[seq_len(maskSize)], collapse = ",")
    child <- paste0(
      '.libPaths(c("', dirname(getNamespaceInfo("pladdrr", "path")), '", .libPaths()))\n',
      "suppressPackageStartupMessages(library(pladdrr))\n",
      "Sys.setenv('_R_CHECK_LIMIT_CORES_' = 'false')\n",  # that clamp has its own tests
      "status <- readLines('/proc/self/status', warn = FALSE)\n",
      "cat(sub('^Cpus_allowed_list:[[:space:]]*', '', ",
      "grep('^Cpus_allowed_list:', status, value = TRUE)), '|',\n",
      "  pladdrr_threads(0)$processors, '|', pladdrr_threads(0)$max_threads, '|',\n",
      "  pladdrr_threads(1)$max_threads, '|',\n",
      "  pladdrr:::.default_n_cores(), '|',\n",
      "  pladdrr:::.pladdrr_worker_thread_budget(2L), '\\n', sep = ' ')\n"
    )
    out <- system2(Sys.which("taskset"),
      c("-c", mask, shQuote(file.path(R.home("bin"), "R")), "--quiet", "--slave",
        "-e", shQuote(child)),
      stdout = TRUE, stderr = FALSE)
    fields <- strsplit(trimws(paste(out, collapse = " ")), " \\| ")[[1]]
    expect_length(fields, 6L)
    # guard: taskset really did constrain the child, else the test is vacuous
    expect_identical(cpus_in_list(fields[[1]]), sort(pool[seq_len(maskSize)]))
    # F-power-01: reported and automatic processor count == the mask, not the machine
    expect_identical(as.integer(fields[[2]]), maskSize)
    expect_identical(as.integer(fields[[3]]), maskSize)
    # explicit override still wins over the affinity count (precedence rule)
    expect_identical(as.integer(fields[[4]]), 1L)
    # F-power-04: the batch helpers' defaults follow the mask too
    expect_identical(as.integer(fields[[5]]), if (maskSize > 2L) maskSize - 1L else maskSize)
    expect_identical(as.integer(fields[[6]]), max(1L, maskSize %/% 2L))
  }
})

test_that("a cgroup CPU quota narrower than the affinity mask is honoured", {
  skip_if_not(have_affinity, "no /proc or cgroup v2 on this platform")
  skip_if_not(file.exists("/sys/fs/cgroup/cpu.max"), "no cgroup v2 cpu.max here")
  quota <- strsplit(trimws(readLines("/sys/fs/cgroup/cpu.max", warn = FALSE)[1]),
    "[[:space:]]+")[[1]]
  skip_if(quota[[1]] == "max", "no cgroup CPU quota on this machine")
  expect_lte(pladdrr_threads()$processors,
    max(1L, ceiling(as.numeric(quota[[1]]) / as.numeric(quota[[2]]))))
})

# The count comes from a .Call that also runs inside worker processes; if it
# fails it must degrade to the machine's core count, never become an error out
# of a batch helper.
test_that("a failing thread getter falls back to detectCores()", {
  good <- pladdrr:::.pladdrr_get_threads_cpp
  on.exit(assignInNamespace(".pladdrr_get_threads_cpp", good, "pladdrr"))
  assignInNamespace(".pladdrr_get_threads_cpp",
    function() stop("simulated .Call failure"), "pladdrr")
  expect_identical(pladdrr:::.pladdrr_available_cpus(), parallel::detectCores())
  expect_identical(pladdrr:::.pladdrr_worker_thread_budget(2L),
    max(1L, parallel::detectCores() %/% 2L))
  expect_no_error(n <- pladdrr:::.default_n_cores())
  expect_gte(n, 1L)
})

# Threads only partition frames: changing the cap must never change a number.
test_that("affinity-aware thread count leaves DSP output bit-identical", {
  sound <- Sound$create_tone(frequency = 120, duration = 1.5, sampling_rate = 22050)
  on.exit(pladdrr_threads(0))
  dfsum <- function (x) sum(as.numeric(unlist(as.data.frame(x))), na.rm = TRUE)
  run <- function () {
    pitch <- sound$to_pitch()
    list(
      pitch = c(dfsum(pitch), pitch$get_mean(), pitch$count_voiced_frames()),
      formant = dfsum(sound$to_formant_burg()),
      cepstrogram = dfsum(sound$to_powercepstrogram()),
      batch = sum(get_pitch_at_times(pitch, seq(0.2, 1.3, by = 0.01)), na.rm = TRUE)
    )
  }
  pladdrr_threads(1)
  one <- run()
  pladdrr_threads(0)
  auto <- run()
  # Windows (MinGW) formant sums differ at ~1e-11 relative between thread
  # counts; elsewhere the output is bit-identical.
  tol <- if (.Platform$OS.type == "windows") 1e-8 else 0
  if (tol == 0) expect_identical(one, auto)
  for (nm in names(one)) {
    expect_equal(one[[nm]], auto[[nm]], tolerance = tol)
  }
})
