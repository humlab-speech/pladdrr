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
// praat_xptr_utils.h - Utilities for managing Praat object external pointers
//
// This header provides utilities for creating and managing XPtr objects
// that wrap Praat C++ objects with automatic memory management via finalizers.

#ifndef PRAAT_XPTR_UTILS_H
#define PRAAT_XPTR_UTILS_H

#include <Rcpp.h>
#include <type_traits>
#include "sys/Thing.h"
#include "melder/melder.h"

// Create an XPtr from an auto* Praat object with proper finalizer
// Uses a custom deleter that wraps Praat's forget() function
template<typename T, typename AutoType>
Rcpp::XPtr<T> create_xptr_from_auto(AutoType& auto_obj) {
    T* ptr = auto_obj.releaseToAmbiguousOwner();
    
    // Custom deleter as lambda that calls forget()
    auto deleter = [](T* thing) {
        if (thing != nullptr) {
            forget(thing);
        }
    };
    
    return Rcpp::XPtr<T>(ptr, deleter);
}

// Validate XPtr before use
template<typename T>
void validate_xptr(const Rcpp::XPtr<T>& xptr, const char* object_type = "Praat object") {
    if (!xptr) {
        Rcpp::stop(std::string("Invalid ") + object_type + " pointer (NULL)");
    }
}

// Get raw pointer from XPtr with validation
template<typename T>
T* get_ptr(const Rcpp::XPtr<T>& xptr, const char* object_type = "Praat object") {
    validate_xptr(xptr, object_type);
    return xptr.get();
}

// Move every element of a Praat collection (e.g. autoSoundList) into an
// R list of XPtrs. Iterates back-to-front so subtractItem_move never
// shifts remaining elements.
template<typename AutoCollection>
Rcpp::List move_collection_to_xptr_list(AutoCollection& items) {
    const integer n = items->size;
    Rcpp::List result(n);
    for (integer i = n; i >= 1; i--) {
        auto extracted = items->subtractItem_move(i);
        using ElemT = std::remove_pointer_t<decltype(extracted.get())>;
        result[i - 1] = create_xptr_from_auto<ElemT>(extracted);
    }
    return result;
}

#endif // PRAAT_XPTR_UTILS_H
