/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2025 Fredrik Nylén
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
// sound_pool.cpp
// Object pool for Sound segments in batch processing
// pladdrr v2.2.1 - Phase 4 Memory Optimization
//
// Reduces allocation overhead by reusing Sound objects instead of
// creating/destroying for each segment extraction.
//
// IMPORTANT: This is a pure memory optimization. Numerical output is unchanged.

#include <Rcpp.h>
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

#include <vector>
#include <algorithm>
#include <mutex>

// ============================================================================
// Sound Pool Implementation
// ============================================================================

// Pool entry: stores Sound object and its specifications
struct PooledSound {
    structSound* sound;
    integer nx;       // number of samples
    double dx;        // sample period
    integer ny;       // number of channels
    bool in_use;

    PooledSound(structSound* s, integer samples, double period, integer channels)
        : sound(s), nx(samples), dx(period), ny(channels), in_use(false) {}
};

// Global sound pool (thread-safe for future multi-threading support)
class SoundPool {
private:
    std::vector<PooledSound> pool;
    std::mutex pool_mutex;
    size_t max_pool_size;
    size_t hits;
    size_t misses;

    // Check if specifications match (within tolerance for sample period)
    bool matches(const PooledSound& entry, integer nx, double dx, integer ny) {
        if (entry.in_use) return false;
        if (entry.ny != ny) return false;
        if (entry.nx != nx) return false;
        // Sample period must match within 0.01%
        if (std::abs(entry.dx - dx) > dx * 1e-4) return false;
        return true;
    }

public:
    SoundPool(size_t max_size = 100) : max_pool_size(max_size), hits(0), misses(0) {}

    ~SoundPool() {
        clear();
    }

    // Acquire a Sound from pool or create new one
    structSound* acquire(double xmin, double xmax, integer nx, double dx, double x1, integer ny) {
        std::lock_guard<std::mutex> lock(pool_mutex);

        // Look for matching Sound in pool
        for (auto& entry : pool) {
            if (matches(entry, nx, dx, ny)) {
                entry.in_use = true;
                hits++;

                // Update time bounds (these can change between uses)
                entry.sound->xmin = xmin;
                entry.sound->xmax = xmax;
                entry.sound->x1 = x1;

                // Zero out the sample data (important for clean reuse)
                for (integer ich = 1; ich <= ny; ich++) {
                    for (integer isamp = 1; isamp <= nx; isamp++) {
                        entry.sound->z[ich][isamp] = 0.0;
                    }
                }

                return entry.sound;
            }
        }

        // No match found, create new Sound
        misses++;

        try {
            autoSound newSound = Sound_create(ny, xmin, xmax, nx, dx, x1);
            structSound* rawPtr = newSound.releaseToAmbiguousOwner();

            // Add to pool if not full
            if (pool.size() < max_pool_size) {
                pool.emplace_back(rawPtr, nx, dx, ny);
                pool.back().in_use = true;
            }

            return rawPtr;
        } catch (...) {
            return nullptr;
        }
    }

    // Release a Sound back to pool
    void release(structSound* sound) {
        if (!sound) return;

        std::lock_guard<std::mutex> lock(pool_mutex);

        for (auto& entry : pool) {
            if (entry.sound == sound) {
                entry.in_use = false;
                return;
            }
        }

        // Sound not in pool - either pool was full when acquired, or external Sound
        // For safety, don't destroy - let R's garbage collector handle it
    }

    // Clear the pool (destroy all Sounds)
    void clear() {
        std::lock_guard<std::mutex> lock(pool_mutex);

        for (auto& entry : pool) {
            if (entry.sound) {
                try {
                    forget(entry.sound);
                } catch (...) {
                    // Ignore cleanup errors
                }
            }
        }
        pool.clear();
        hits = 0;
        misses = 0;
    }

    // Get pool statistics
    void get_stats(size_t& out_hits, size_t& out_misses, size_t& out_pool_size, size_t& out_in_use) {
        std::lock_guard<std::mutex> lock(pool_mutex);
        out_hits = hits;
        out_misses = misses;
        out_pool_size = pool.size();
        out_in_use = 0;
        for (const auto& entry : pool) {
            if (entry.in_use) out_in_use++;
        }
    }

    // Resize pool (evict unused Sounds if needed)
    void resize(size_t new_max_size) {
        std::lock_guard<std::mutex> lock(pool_mutex);
        max_pool_size = new_max_size;

        // Evict unused Sounds if pool is too large
        while (pool.size() > max_pool_size) {
            auto it = std::find_if(pool.rbegin(), pool.rend(),
                [](const PooledSound& e) { return !e.in_use; });
            if (it != pool.rend()) {
                if (it->sound) {
                    try {
                        forget(it->sound);
                    } catch (...) {}
                }
                pool.erase(std::next(it).base());
            } else {
                break; // All in use, can't evict
            }
        }
    }
};

// Global pool instance
static SoundPool g_sound_pool(100);

// ============================================================================
// R Interface
// ============================================================================

//' @title Sound Object Pool for Batch Processing
//' @name sound_pool
//' @description
//' Memory optimization for batch operations that extract many Sound segments.
//' Reuses Sound object allocations instead of creating/destroying each time.
//'
//' **Numerical Impact:** None - output is identical to non-pooled version
//'
//' @return \code{sound_pool_stats()} returns a named list with elements
//'   \code{hits}, \code{misses}, \code{hit_rate}, \code{pool_size}, and
//'   \code{in_use}.
//'
//' @details
//' The pool automatically manages Sound object reuse:
//' - `sound_pool_acquire()` - get a Sound from pool (or create new)
//' - `sound_pool_release()` - return Sound to pool for reuse
//' - `sound_pool_stats()` - get hit/miss statistics
//' - `sound_pool_clear()` - clear the pool
//' - `sound_pool_resize()` - change pool capacity
//'
//' @examples
//' # Pool is used automatically by batch extraction functions
//' # For manual control:
//'
//' # Check pool statistics
//' stats <- sound_pool_stats()
//' stats$hits
//' stats$misses
//'
//' # Clear pool to free memory
//' sound_pool_clear()
//'
//' @export
// [[Rcpp::export]]
List sound_pool_stats() {
    size_t hits, misses, pool_size, in_use;
    g_sound_pool.get_stats(hits, misses, pool_size, in_use);

    double hit_rate = (hits + misses > 0) ? (double)hits / (hits + misses) * 100.0 : 0.0;

    return List::create(
        Named("hits") = (int)hits,
        Named("misses") = (int)misses,
        Named("hit_rate") = hit_rate,
        Named("pool_size") = (int)pool_size,
        Named("in_use") = (int)in_use
    );
}

//' @rdname sound_pool
//' @return Invisibly returns \code{NULL}.
//' @export
// [[Rcpp::export]]
void sound_pool_clear() {
    g_sound_pool.clear();
}

//' @rdname sound_pool
//' @param max_size Maximum number of Sound objects to keep in pool
//' @return Invisibly returns \code{NULL}.
//' @export
// [[Rcpp::export]]
void sound_pool_resize(int max_size) {
    if (max_size < 0) {
        Rcpp::stop("max_size must be non-negative");
    }
    g_sound_pool.resize((size_t)max_size);
}

// ============================================================================
// Internal Functions (used by batch extraction code)
// ============================================================================

//' Acquire pooled Sound for segment extraction
//'
//' @param xmin Start time
//' @param xmax End time
//' @param nx Number of samples
//' @param dx Sample period
//' @param x1 First sample time
//' @param ny Number of channels
//'
//' @return External pointer to Sound
//'
//' @examples
//' xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
//' pladdrr:::sound_pool_release(xptr)
//'
//' @keywords internal
// [[Rcpp::export]]
SEXP sound_pool_acquire(double xmin, double xmax, int nx, double dx, double x1, int ny) {
    structSound* sound = g_sound_pool.acquire(xmin, xmax, (integer)nx, dx, x1, (integer)ny);

    if (!sound) {
        Rcpp::stop("Failed to acquire Sound from pool");
    }

    return XPtr<structSound>(sound, false);  // Don't register destructor - pool manages
}

//' Release pooled Sound back to pool
//'
//' @param sound_xptr External pointer to Sound
//'
//' @return Invisibly returns \code{NULL}.
//'
//' @examples
//' xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
//' pladdrr:::sound_pool_release(xptr)
//'
//' @keywords internal
// [[Rcpp::export]]
void sound_pool_release(SEXP sound_xptr) {
    if (TYPEOF(sound_xptr) != EXTPTRSXP) {
        return;  // Not an external pointer, ignore
    }

    structSound* sound = reinterpret_cast<structSound*>(R_ExternalPtrAddr(sound_xptr));
    g_sound_pool.release(sound);
}

// ============================================================================
// Pooled Batch Extraction
// ============================================================================

//' Extract multiple Sound parts using object pool
//'
//' @description
//' Batch extraction using pooled memory reuse, for large numbers of
//' segments.
//'
//' @param sound_xptr External pointer to source Sound
//' @param start_times Numeric vector of start times
//' @param end_times Numeric vector of end times
//' @param use_pool Whether to use object pool (default TRUE)
//'
//' @return List of external pointers to extracted Sound segments
//'
//' @details
//' When use_pool is TRUE, Sound objects are acquired from a pool and
//' should be released back with sound_pool_release() when done.
//'
//' **Important:** Pool-acquired Sounds should not be modified as they
//' may be reused. Copy if modification is needed.
//'
//' @examples
//' sound <- Sound$create_tone(frequency = 200, duration = 2.0)
//' starts <- c(0.1, 0.5, 1.0)
//' ends <- c(0.3, 0.7, 1.2)
//'
//' # Batch extraction with pooling
//' segments <- sound_extract_parts_pooled(sound$.xptr, starts, ends)
//'
//' # Release back to pool when done
//' for (seg in segments) {
//'   pladdrr:::sound_pool_release(seg)
//' }
//'
//' @export
// [[Rcpp::export]]
List sound_extract_parts_pooled(
    SEXP sound_xptr,
    NumericVector start_times,
    NumericVector end_times,
    bool use_pool = true
) {
    BEGIN_RCPP

    // Validate input
    if (start_times.size() != end_times.size()) {
        Rcpp::stop("start_times and end_times must have same length");
    }

    // Get source Sound
    Rcpp::XPtr<structSound> source(sound_xptr);
    if (!source || source.get() == nullptr) {
        Rcpp::stop("Invalid Sound pointer");
    }

    int n = start_times.size();
    List result(n);

    for (int i = 0; i < n; i++) {
        double t1 = start_times[i];
        double t2 = end_times[i];

        // Clip to source bounds
        if (t1 < source->xmin) t1 = source->xmin;
        if (t2 > source->xmax) t2 = source->xmax;

        if (t1 >= t2) {
            result[i] = R_NilValue;
            continue;
        }

        try {
            // Extract part using Praat's function
            autoSound part = Sound_extractPart(
                source.get(),
                t1, t2,
                kSound_windowShape::RECTANGULAR,
                1.0,
                false  // preserveTimes
            );

            if (use_pool && part) {
                // Copy to pooled Sound
                integer nx = part->nx;
                double dx = part->dx;
                double x1 = part->x1;
                integer ny = part->ny;

                structSound* pooled = g_sound_pool.acquire(
                    part->xmin, part->xmax, nx, dx, x1, ny
                );

                if (pooled) {
                    // Copy sample data
                    for (integer ich = 1; ich <= ny; ich++) {
                        for (integer isamp = 1; isamp <= nx; isamp++) {
                            pooled->z[ich][isamp] = part->z[ich][isamp];
                        }
                    }
                    result[i] = XPtr<structSound>(pooled, false);
                } else {
                    // Pool failed, use original
                    result[i] = XPtr<structSound>(part.releaseToAmbiguousOwner());
                }
            } else {
                result[i] = XPtr<structSound>(part.releaseToAmbiguousOwner());
            }
        } catch (...) {
            result[i] = R_NilValue;
        }
    }

    return result;

    END_RCPP
}

// End of file sound_pool.cpp
