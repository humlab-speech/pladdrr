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
// textgrid_wrappers.cpp
// C++ wrappers for Praat TextGrid objects
// Provides R interface to TextGrid, IntervalTier, and TextTier functionality

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "datatable_utils.h"
#include "melder_utf8.h"

// Praat headers - TextGrid uses C++ features so no extern "C"
#include "praat.github.io/sys/Data.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/TextGrid_Sound.h"
#include "praat.github.io/dwtools/TextGrid_extensions.h"

// Numeric library headers for initialization
#include "praat.github.io/dwsys/NUMmachar.h"
#include "praat.github.io/melder/NUMrandom.h"
#include "praat.github.io/melder/melder_alloc.h"  // For Melder_alloc_init()
#include "praat.github.io/melder/melder_alloc.h"  // For Melder_alloc_init()

// ============================================================================
// Melder Warning Handler
// ============================================================================

// Global flag to ensure we only initialize once
static bool warning_handler_initialized = false;

// Simple warning handler that prints to R console instead of showing GUI dialog
static void melder_warning_handler(conststring32 message) {
    // Convert UTF-32 to UTF-8 for R
    char32 const * p = message;
    std::string utf8;
    while (*p) {
        char32 c = *p++;
        if (c < 0x80) {
            utf8 += static_cast<char>(c);
        } else if (c < 0x800) {
            utf8 += static_cast<char>(0xC0 | (c >> 6));
            utf8 += static_cast<char>(0x80 | (c & 0x3F));
        } else if (c < 0x10000) {
            utf8 += static_cast<char>(0xE0 | (c >> 12));
            utf8 += static_cast<char>(0x80 | ((c >> 6) & 0x3F));
            utf8 += static_cast<char>(0x80 | (c & 0x3F));
        } else {
            utf8 += static_cast<char>(0xF0 | (c >> 18));
            utf8 += static_cast<char>(0x80 | ((c >> 12) & 0x3F));
            utf8 += static_cast<char>(0x80 | ((c >> 6) & 0x3F));
            utf8 += static_cast<char>(0x80 | (c & 0x3F));
        }
    }
    Rcpp::Rcerr << "Praat warning: " << utf8 << std::endl;
}

// Initialize warning handler (called before first use)
static void ensure_warning_handler() {
    if (!warning_handler_initialized) {
        Melder_setWarningProc(melder_warning_handler);
        warning_handler_initialized = true;
    }
}

// ============================================================================
// Numeric Library Initialization
// ============================================================================

// Global flag to ensure we only initialize numeric libraries once
static bool numeric_libs_initialized = false;

// Initialize numeric libraries (required for text parsing and data reading)
static void ensure_numeric_libs_initialized() {
    if (!numeric_libs_initialized) {
        NUMmachar();
        NUMrandom_initializeSafelyAndUnpredictably();
        Melder_alloc_init();  // Initialize emergency memory buffer
        numeric_libs_initialized = true;
    }
}

// ============================================================================
// TextGrid Creation & I/O
// ============================================================================

// [[Rcpp::export(.textgrid_read_from_file)]]
Rcpp::XPtr<structTextGrid> textgrid_read_from_file(std::string path) {
    try {
        // Initialize numeric libraries (required for text parsing)
        ensure_numeric_libs_initialized();
        
        structMelderFile file = {};
        
        const char32 *path32 = Melder_peek8to32(path.c_str());
        
        Melder_pathToFile(path32, &file);
        
        Rcpp::Rcout.flush();  // Force output
        autoDaata data = Data_readFromTextFile(&file);
        if (!data) {
            Rcpp::stop("Failed to read file as Praat data object");
        }
        if (!Thing_isa(data.get(), classTextGrid)) {
            Rcpp::stop("File is not a TextGrid");
        }
        autoTextGrid textgrid = data.static_cast_move<structTextGrid>();
        return create_xptr_from_auto<structTextGrid>(textgrid);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to read TextGrid from file: " + path);
    }
}

// [[Rcpp::export(.textgrid_create)]]
Rcpp::XPtr<structTextGrid> textgrid_create(
    double tmin,
    double tmax,
    std::string tier_names = "",
    std::string point_tiers = ""
) {
    try {
        autoTextGrid textgrid = TextGrid_create(
            tmin, tmax,
            Melder_peek8to32(tier_names.c_str()),
            Melder_peek8to32(point_tiers.c_str())
        );
        return create_xptr_from_auto<structTextGrid>(textgrid);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create TextGrid");
    }
}

// ============================================================================
// TextGrid Query - Basic Properties
// ============================================================================

// ============================================================================
// TextGrid Query - Tier Information
// ============================================================================

// ============================================================================
// IntervalTier Query
// ============================================================================

// ============================================================================
// IntervalTier Modification
// ============================================================================

// ============================================================================
// PointTier (TextTier) Query
// ============================================================================

// [[Rcpp::export(.textgrid_get_all_points)]]
Rcpp::DataFrame textgrid_get_all_points(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(xptr.get(), tier_number);
        
        int n = tier->points.size;
        Rcpp::NumericVector times(n);
        Rcpp::CharacterVector texts(n);
        
        for (int i = 1; i <= n; i++) {
            TextPoint point = tier->points.at[i];
            times[i-1] = point->number;
            texts[i-1] = melder_utf8(Melder_peek32to8(point->mark.get()));
        }
        
        return pladdrr::dt::create_datatable(
            Rcpp::List::create(
                Rcpp::Named("time") = times,
                Rcpp::Named("text") = texts
            ),
            Rcpp::CharacterVector::create("time", "text"),
            Rcpp::CharacterVector::create("time")
        );
    }, "Failed to get all points");
}

// ============================================================================
// PointTier Modification
// ============================================================================

// ============================================================================
// Tier Management
// ============================================================================

// [[Rcpp::export(.textgrid_duplicate_tier)]]
void textgrid_duplicate_tier(Rcpp::XPtr<structTextGrid> xptr, int tier_number, std::string new_name) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        if (tier_number < 1 || tier_number > xptr->tiers->size)
            Rcpp::stop("Tier number out of range");
        
        Function tier = xptr->tiers->at[tier_number];
        
        // Determine tier type and duplicate
        IntervalTier intervalTier = nullptr;
        TextTier textTier = nullptr;
        AnyTextGridTier_identifyClass(tier, &intervalTier, &textTier);
        
        if (intervalTier) {
            // Duplicate interval tier
            autoIntervalTier newTier = Data_copy(intervalTier).static_cast_move<structIntervalTier>();
            Thing_setName(newTier.get(), Melder_peek8to32(new_name.c_str()));
            TextGrid_addTier_move(xptr.get(), newTier.move());
        } else if (textTier) {
            // Duplicate point/text tier
            autoTextTier newTier = Data_copy(textTier).static_cast_move<structTextTier>();
            Thing_setName(newTier.get(), Melder_peek8to32(new_name.c_str()));
            TextGrid_addTier_move(xptr.get(), newTier.move());
        } else {
            Rcpp::stop("Unknown tier type");
        }
    }, "Failed to duplicate tier");
}

// ============================================================================
// Extraction
// ============================================================================

// ============================================================================
// Export to R Data Structures
// ============================================================================

// ============================================================================
// TextGrid Extensions (from dwtools/TextGrid_extensions.h)
// ============================================================================

// ==============================================================================
// Conversion Methods
// ==============================================================================

// [[Rcpp::export(.textgrid_sound_extract_intervals_where)]]
Rcpp::List textgrid_sound_extract_intervals_where(
    Rcpp::XPtr<structTextGrid> textgrid,
    Rcpp::XPtr<structSound> sound,
    int tier_number,
    int which_criterion,
    std::string text,
    bool preserve_times
) {
    if (!textgrid) Rcpp::stop("Invalid TextGrid pointer");
    
    // Initialize warning handler before any Praat calls
    ensure_warning_handler();
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    
    structTextGrid* tg = get_ptr(textgrid, "TextGrid");
    structSound* snd = get_ptr(sound, "Sound");
    
    try {
        // Validate TextGrid has tiers
        if (tg->tiers->size < 1) {
            Rcpp::stop("TextGrid has no tiers");
        }
        if (tier_number < 1 || tier_number > tg->tiers->size) {
            Rcpp::stop("Tier number out of range");
        }
        
        // CRITICAL: Validate criterion value BEFORE cast
        // kMelder_string enum is 1-based: 1=EQUAL_TO, 2=NOT_EQUAL_TO, etc.
        // Value 0 = UNDEFINED which calls Melder_fatal()
        if (which_criterion < 1 || which_criterion > 19) {
            Rcpp::stop("Invalid criterion value: must be 1-19, got " + std::to_string(which_criterion));
        }
        
        kMelder_string criterion = static_cast<kMelder_string>(which_criterion);
        
        autoSoundList sounds = TextGrid_Sound_extractIntervalsWhere(
            tg,
            snd,
            static_cast<integer>(tier_number),
            criterion,
            Melder_peek8to32(text.c_str()),
            preserve_times
        );
        return move_collection_to_xptr_list(sounds);


    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract intervals from TextGrid and Sound");
    }
}
