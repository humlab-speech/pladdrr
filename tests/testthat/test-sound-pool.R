# Regression test for SoundPool::clear() use-after-free (src/sound_pool.cpp):
# clear() used to forget() every pooled Sound regardless of `in_use`, freeing
# memory still referenced by an XPtr an R caller was holding.

test_that("sound_pool_clear() does not free an in-use acquired Sound", {
  pladdrr:::sound_pool_clear()

  xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
  sound <- Sound(.xptr = xptr)

  # Would use-after-free (crash or garbage) pre-fix, since clear() forgot
  # in-use entries too.
  pladdrr:::sound_pool_clear()

  expect_equal(sound$get_number_of_samples(), 4410)
  expect_equal(sound$get_number_of_channels(), 1)

  pladdrr:::sound_pool_release(xptr)
})

test_that("sound_pool_clear() still reclaims unused pooled Sounds", {
  pladdrr:::sound_pool_clear()

  xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
  pladdrr:::sound_pool_release(xptr)

  stats_before <- pladdrr:::sound_pool_stats()
  expect_gte(stats_before$pool_size, 1)

  pladdrr:::sound_pool_clear()

  stats_after <- pladdrr:::sound_pool_stats()
  expect_equal(stats_after$pool_size, 0)
})
