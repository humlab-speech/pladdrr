// sampled_object_traits.h - Traits for time-domain sampled Praat objects
//
// Provides common functionality for objects with time domain (xmin, xmax)
// and sampling (nx, dx, x1) properties: Sound, Pitch, Formant, Intensity, etc.

#ifndef SAMPLED_OBJECT_TRAITS_H
#define SAMPLED_OBJECT_TRAITS_H

#include <Rcpp.h>
#include "praat_object_traits.h"

// ============================================================================
// Time Domain Traits (for Function objects: xmin, xmax)
// ============================================================================
//
// For objects that have a time domain but aren't necessarily sampled.
// PraatType must have xmin, xmax fields.
//
template<typename Derived, typename PraatType>
class TimeDomainTraits : public PraatObjectTraits<Derived, PraatType> {
public:
    using Base = PraatObjectTraits<Derived, PraatType>;

    double get_xmin() const {
        if (!Base::is_valid()) return NA_REAL;
        return Base::get_ptr()->xmin;
    }

    double get_xmax() const {
        if (!Base::is_valid()) return NA_REAL;
        return Base::get_ptr()->xmax;
    }

    double get_duration() const {
        if (!Base::is_valid()) return NA_REAL;
        return get_xmax() - get_xmin();
    }

    // Check if a time is within the object's domain
    bool time_in_domain(double time) const {
        if (!Base::is_valid()) return false;
        return time >= get_xmin() && time <= get_xmax();
    }
};

// ============================================================================
// Sampled Object Traits (for Sampled objects: nx, dx, x1)
// ============================================================================
//
// For objects that are sampled in time (Sound, Pitch, Formant, Intensity, etc.)
// PraatType must have xmin, xmax, nx, dx, x1 fields.
//
template<typename Derived, typename PraatType>
class SampledObjectTraits : public TimeDomainTraits<Derived, PraatType> {
public:
    using Base = TimeDomainTraits<Derived, PraatType>;

    // Number of samples/frames
    int get_nx() const {
        if (!Base::is_valid()) return NA_INTEGER;
        return Base::get_ptr()->nx;
    }

    // Sample/frame step (time between samples)
    double get_dx() const {
        if (!Base::is_valid()) return NA_REAL;
        return Base::get_ptr()->dx;
    }

    // Time of first sample/frame center
    double get_x1() const {
        if (!Base::is_valid()) return NA_REAL;
        return Base::get_ptr()->x1;
    }

    // Convert frame/sample index to time
    double index_to_x(int index) const {
        if (!Base::is_valid()) return NA_REAL;
        // Praat formula: x1 + (index - 1) * dx
        return get_x1() + (index - 1) * get_dx();
    }

    // Convert time to nearest frame/sample index
    int x_to_nearest_index(double x) const {
        if (!Base::is_valid()) return NA_INTEGER;
        // Praat formula: 1 + round((x - x1) / dx)
        return 1 + (int)round((x - get_x1()) / get_dx());
    }

    // Convert time to low frame/sample index
    int x_to_low_index(double x) const {
        if (!Base::is_valid()) return NA_INTEGER;
        return 1 + (int)floor((x - get_x1()) / get_dx());
    }

    // Convert time to high frame/sample index
    int x_to_high_index(double x) const {
        if (!Base::is_valid()) return NA_INTEGER;
        return 1 + (int)ceil((x - get_x1()) / get_dx());
    }

    // Check if frame index is valid
    bool is_valid_index(int index) const {
        return index >= 1 && index <= get_nx();
    }
};

// ============================================================================
// Matrix Object Traits (for SampledXY objects: ny, dy, y1)
// ============================================================================
//
// For 2D sampled objects (Spectrogram, etc.)
// PraatType must have xmin, xmax, nx, dx, x1, ny, dy, y1 fields.
//
template<typename Derived, typename PraatType>
class MatrixObjectTraits : public SampledObjectTraits<Derived, PraatType> {
public:
    using Base = SampledObjectTraits<Derived, PraatType>;

    // Number of rows (frequency bins, channels, etc.)
    int get_ny() const {
        if (!Base::is_valid()) return NA_INTEGER;
        return Base::get_ptr()->ny;
    }

    // Row step
    double get_dy() const {
        if (!Base::is_valid()) return NA_REAL;
        return Base::get_ptr()->dy;
    }

    // First row center value
    double get_y1() const {
        if (!Base::is_valid()) return NA_REAL;
        return Base::get_ptr()->y1;
    }

    // Convert row index to y value
    double row_to_y(int row) const {
        if (!Base::is_valid()) return NA_REAL;
        return get_y1() + (row - 1) * get_dy();
    }

    // Convert y value to nearest row index
    int y_to_nearest_row(double y) const {
        if (!Base::is_valid()) return NA_INTEGER;
        return 1 + (int)round((y - get_y1()) / get_dy());
    }
};

#endif // SAMPLED_OBJECT_TRAITS_H
