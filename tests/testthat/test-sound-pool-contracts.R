# SoundPool acquire/release accounting. The existing pool tests cover
# clear()/resize() and the use-after-free regression; these cover hit/miss
# accounting across a release and re-acquire.

test_that("sound pool statistics track misses, releases and hits", {
  pladdrr:::sound_pool_clear()
  on.exit(pladdrr:::sound_pool_clear(), add = TRUE)

  before <- pladdrr:::sound_pool_stats()
  expect_named(before, c("hits", "misses", "hit_rate", "pool_size", "in_use"))

  xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
  acquired <- pladdrr:::sound_pool_stats()
  expect_equal(acquired$misses, before$misses + 1)
  expect_equal(acquired$in_use, before$in_use + 1)
  expect_equal(acquired$pool_size, before$pool_size + 1)

  pladdrr:::sound_pool_release(xptr)
  released <- pladdrr:::sound_pool_stats()
  expect_equal(released$in_use, before$in_use)
  expect_equal(released$pool_size, acquired$pool_size)

  reused <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
  reacquired <- pladdrr:::sound_pool_stats()
  expect_equal(reacquired$hits, released$hits + 1)
  expect_equal(reacquired$misses, released$misses)
  expect_equal(reacquired$in_use, before$in_use + 1)

  pladdrr:::sound_pool_release(reused)
})

test_that("sound pool resize keeps the pool usable", {
  pladdrr:::sound_pool_clear()
  on.exit(pladdrr:::sound_pool_clear(), add = TRUE)

  expect_invisible(pladdrr:::sound_pool_resize(4))
  expect_equal(pladdrr:::sound_pool_stats()$pool_size, 0)

  xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
  expect_equal(pladdrr:::sound_pool_stats()$in_use, 1)
  pladdrr:::sound_pool_release(xptr)
})
