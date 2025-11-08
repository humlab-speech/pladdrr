// praat_xptr_utils.h - Utilities for managing Praat object external pointers
//
// This header provides utilities for creating and managing XPtr objects
// that wrap Praat C++ objects with automatic memory management via finalizers.

#ifndef PRAAT_XPTR_UTILS_H
#define PRAAT_XPTR_UTILS_H

#include <Rcpp.h>
#include "praat/sys/Thing.h"
#include "praat/sys/melder.h"

// Finalizer template for Praat Thing objects
// This is called automatically by R's garbage collector when the XPtr is no longer referenced
template<typename T>
void praat_thing_finalizer(T* thing) {
    if (thing != nullptr) {
        forget(thing);  // Praat's memory management function
    }
}

// Create an XPtr from an auto* Praat object with proper finalizer
template<typename T>
Rcpp::XPtr<T> create_xptr_from_auto(auto*& auto_obj) {
    T* ptr = auto_obj.releaseToAmbiguousOwner();
    return Rcpp::XPtr<T>(ptr, true, praat_thing_finalizer<T>);
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

#endif // PRAAT_XPTR_UTILS_H
