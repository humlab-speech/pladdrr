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
// praat_object_traits.h - Base traits for all Praat objects
//
// Provides common functionality inherited by all Praat object module classes
// via CRTP (Curiously Recurring Template Pattern).

#ifndef PRAAT_OBJECT_TRAITS_H
#define PRAAT_OBJECT_TRAITS_H

#include <Rcpp.h>

// ============================================================================
// Base Praat Object Traits
// ============================================================================
//
// Use via CRTP:
//   class RPitch : public PraatObjectTraits<RPitch, structPitch> { ... };
//
// Derived class must have:
//   - Rcpp::XPtr<PraatType> ptr;
//
template<typename Derived, typename PraatType>
class PraatObjectTraits {
public:
    // Check if the underlying pointer is valid
    bool is_valid() const {
        const Derived* self = static_cast<const Derived*>(this);
        // Use explicit nullptr check - XPtr doesn't have implicit bool conversion
        PraatType* raw = self->ptr.get();
        return raw != nullptr;
    }

    // Get class name for error messages
    std::string get_class_name() const {
        return typeid(Derived).name();
    }

protected:
    // Validate pointer and throw if invalid
    void check_valid(const char* method_name = nullptr) const {
        if (!is_valid()) {
            if (method_name) {
                Rcpp::stop("Cannot call %s on invalid object", method_name);
            } else {
                Rcpp::stop("Invalid Praat object pointer");
            }
        }
    }

    // Get raw pointer with validation
    PraatType* get_ptr() const {
        check_valid();
        const Derived* self = static_cast<const Derived*>(this);
        return self->ptr.get();
    }
};

#endif // PRAAT_OBJECT_TRAITS_H
