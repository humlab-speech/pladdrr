// textgrid_wrappers.cpp
// C++ wrappers for Praat TextGrid objects
// Provides R interface to TextGrid, IntervalTier, and TextTier functionality

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers - TextGrid uses C++ features so no extern "C"
#include "praat.github.io/sys/Data.h"
#include "praat.github.io/fon/TextGrid.h"

// ============================================================================
// TextGrid Creation & I/O
// ============================================================================

// [[Rcpp::export(.textgrid_read_from_file)]]
Rcpp::XPtr<structTextGrid> textgrid_read_from_file(std::string path) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        autoDaata data = Data_readFromFile(&file);
        if (!data) {
            Rcpp::stop("Failed to read file as Praat data object");
        }
        // Check if it's actually a TextGrid
        if (!Thing_isa(data.get(), classTextGrid)) {
            Rcpp::stop("File is not a TextGrid");
        }
        // Cast to TextGrid
        TextGrid textgrid = static_cast<TextGrid>(data.get());
        // Create XPtr with custom finalizer
        auto deleter = [](structTextGrid* thing) {
            if (thing != nullptr) {
                forget(thing);
            }
        };
        data.releaseToAmbiguousOwner();  // Transfer ownership
        return Rcpp::XPtr<structTextGrid>(textgrid, deleter);
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

// [[Rcpp::export(.textgrid_save)]]
void textgrid_save(Rcpp::XPtr<structTextGrid> xptr, std::string path) {
    if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(xptr.get(), &file);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to write TextGrid to file: " + path);
    }
}

// ============================================================================
// TextGrid Query - Basic Properties
// ============================================================================

// [[Rcpp::export(.textgrid_get_start_time)]]
double textgrid_get_start_time(Rcpp::XPtr<structTextGrid> xptr) {
    if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
    return xptr->xmin;
}

// [[Rcpp::export(.textgrid_get_end_time)]]
double textgrid_get_end_time(Rcpp::XPtr<structTextGrid> xptr) {
    if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
    return xptr->xmax;
}

// [[Rcpp::export(.textgrid_get_total_duration)]]
double textgrid_get_total_duration(Rcpp::XPtr<structTextGrid> xptr) {
    if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
    return xptr->xmax - xptr->xmin;
}

// [[Rcpp::export(.textgrid_get_number_of_tiers)]]
int textgrid_get_number_of_tiers(Rcpp::XPtr<structTextGrid> xptr) {
    if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
    return xptr->tiers->size;
}

// ============================================================================
// TextGrid Query - Tier Information
// ============================================================================

// [[Rcpp::export(.textgrid_get_tier_name)]]
std::string textgrid_get_tier_name(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        Function tier = xptr->tiers->at[tier_number];
        return Melder_peek32to8(tier->name.get());
    }, "Failed to get tier name");
}

// [[Rcpp::export(.textgrid_get_tier_names)]]
std::vector<std::string> textgrid_get_tier_names(Rcpp::XPtr<structTextGrid> xptr) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        std::vector<std::string> names;
        for (integer i = 1; i <= xptr->tiers->size; i++) {
            Function tier = xptr->tiers->at[i];
            names.push_back(Melder_peek32to8(tier->name.get()));
        }
        return names;
    }, "Failed to get tier names");
}

// [[Rcpp::export(.textgrid_tier_is_interval_tier)]]
bool textgrid_tier_is_interval_tier(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        if (tier_number < 1 || tier_number > xptr->tiers->size)
            Rcpp::stop("Tier number out of range");
        
        Function tier = xptr->tiers->at[tier_number];
        IntervalTier intervalTier = nullptr;
        TextTier textTier = nullptr;
        AnyTextGridTier_identifyClass(tier, &intervalTier, &textTier);
        
        return intervalTier != nullptr;
    }, "Failed to check tier type");
}

// [[Rcpp::export(.textgrid_tier_is_point_tier)]]
bool textgrid_tier_is_point_tier(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        if (tier_number < 1 || tier_number > xptr->tiers->size)
            Rcpp::stop("Tier number out of range");
        
        Function tier = xptr->tiers->at[tier_number];
        IntervalTier intervalTier = nullptr;
        TextTier textTier = nullptr;
        AnyTextGridTier_identifyClass(tier, &intervalTier, &textTier);
        
        return textTier != nullptr;
    }, "Failed to check tier type");
}

// ============================================================================
// IntervalTier Query
// ============================================================================

// [[Rcpp::export(.textgrid_get_number_of_intervals)]]
int textgrid_get_number_of_intervals(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(xptr.get(), tier_number);
        return tier->intervals.size;
    }, "Failed to get number of intervals");
}

// [[Rcpp::export(.textgrid_get_interval_start_time)]]
double textgrid_get_interval_start_time(Rcpp::XPtr<structTextGrid> xptr, int tier_number, int interval_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(xptr.get(), tier_number);
        if (interval_number < 1 || interval_number > tier->intervals.size)
            Rcpp::stop("Interval number out of range");
        TextInterval interval = tier->intervals.at[interval_number];
        return interval->xmin;
    }, "Failed to get interval start time");
}

// [[Rcpp::export(.textgrid_get_interval_end_time)]]
double textgrid_get_interval_end_time(Rcpp::XPtr<structTextGrid> xptr, int tier_number, int interval_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(xptr.get(), tier_number);
        if (interval_number < 1 || interval_number > tier->intervals.size)
            Rcpp::stop("Interval number out of range");
        TextInterval interval = tier->intervals.at[interval_number];
        return interval->xmax;
    }, "Failed to get interval end time");
}

// [[Rcpp::export(.textgrid_get_interval_text)]]
std::string textgrid_get_interval_text(Rcpp::XPtr<structTextGrid> xptr, int tier_number, int interval_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(xptr.get(), tier_number);
        if (interval_number < 1 || interval_number > tier->intervals.size)
            Rcpp::stop("Interval number out of range");
        TextInterval interval = tier->intervals.at[interval_number];
        return Melder_peek32to8(interval->text.get());
    }, "Failed to get interval text");
}

// [[Rcpp::export(.textgrid_get_interval_at_time)]]
int textgrid_get_interval_at_time(Rcpp::XPtr<structTextGrid> xptr, int tier_number, double time) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(xptr.get(), tier_number);
        integer index = IntervalTier_timeToIndex(tier, time);
        return static_cast<int>(index);
    }, "Failed to get interval at time");
}

// [[Rcpp::export(.textgrid_get_label_at_time)]]
std::string textgrid_get_label_at_time(Rcpp::XPtr<structTextGrid> xptr, int tier_number, double time) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(xptr.get(), tier_number);
        integer index = IntervalTier_timeToIndex(tier, time);
        if (index == 0) return "";
        TextInterval interval = tier->intervals.at[index];
        return Melder_peek32to8(interval->text.get());
    }, "Failed to get label at time");
}

// ============================================================================
// IntervalTier Modification
// ============================================================================

// [[Rcpp::export(.textgrid_set_interval_text)]]
void textgrid_set_interval_text(
    Rcpp::XPtr<structTextGrid> xptr,
    int tier_number,
    int interval_number,
    std::string text
) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextGrid_setIntervalText(
            xptr.get(),
            tier_number,
            interval_number,
            Melder_peek8to32(text.c_str())
        );
    }, "Failed to set interval text");
}

// [[Rcpp::export(.textgrid_insert_boundary)]]
void textgrid_insert_boundary(Rcpp::XPtr<structTextGrid> xptr, int tier_number, double time) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextGrid_insertBoundary(xptr.get(), tier_number, time);
    }, "Failed to insert boundary");
}

// [[Rcpp::export(.textgrid_remove_boundary)]]
void textgrid_remove_boundary(Rcpp::XPtr<structTextGrid> xptr, int tier_number, double time) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextGrid_removeBoundaryAtTime(xptr.get(), tier_number, time);
    }, "Failed to remove boundary");
}

// ============================================================================
// PointTier (TextTier) Query
// ============================================================================

// [[Rcpp::export(.textgrid_get_number_of_points)]]
int textgrid_get_number_of_points(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(xptr.get(), tier_number);
        return tier->points.size;
    }, "Failed to get number of points");
}

// [[Rcpp::export(.textgrid_get_point_time)]]
double textgrid_get_point_time(Rcpp::XPtr<structTextGrid> xptr, int tier_number, int point_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(xptr.get(), tier_number);
        if (point_number < 1 || point_number > tier->points.size)
            Rcpp::stop("Point number out of range");
        TextPoint point = tier->points.at[point_number];
        return point->number;
    }, "Failed to get point time");
}

// [[Rcpp::export(.textgrid_get_point_text)]]
std::string textgrid_get_point_text(Rcpp::XPtr<structTextGrid> xptr, int tier_number, int point_number) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(xptr.get(), tier_number);
        if (point_number < 1 || point_number > tier->points.size)
            Rcpp::stop("Point number out of range");
        TextPoint point = tier->points.at[point_number];
        return Melder_peek32to8(point->mark.get());
    }, "Failed to get point text");
}

// ============================================================================
// PointTier Modification
// ============================================================================

// [[Rcpp::export(.textgrid_insert_point)]]
void textgrid_insert_point(
    Rcpp::XPtr<structTextGrid> xptr,
    int tier_number,
    double time,
    std::string mark
) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextGrid_insertPoint(
            xptr.get(),
            tier_number,
            time,
            Melder_peek8to32(mark.c_str())
        );
    }, "Failed to insert point");
}

// [[Rcpp::export(.textgrid_set_point_text)]]
void textgrid_set_point_text(
    Rcpp::XPtr<structTextGrid> xptr,
    int tier_number,
    int point_number,
    std::string text
) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextGrid_setPointText(
            xptr.get(),
            tier_number,
            point_number,
            Melder_peek8to32(text.c_str())
        );
    }, "Failed to set point text");
}

// [[Rcpp::export(.textgrid_remove_point)]]
void textgrid_remove_point(Rcpp::XPtr<structTextGrid> xptr, int tier_number, int point_number) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(xptr.get(), tier_number);
        if (point_number < 1 || point_number > tier->points.size)
            Rcpp::stop("Point number out of range");
        TextTier_removePoint(tier, point_number);
    }, "Failed to remove point");
}

// ============================================================================
// Tier Management
// ============================================================================

// [[Rcpp::export(.textgrid_add_interval_tier)]]
void textgrid_add_interval_tier(Rcpp::XPtr<structTextGrid> xptr, std::string name) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        autoIntervalTier tier = IntervalTier_create(xptr->xmin, xptr->xmax);
        Thing_setName(tier.get(), Melder_peek8to32(name.c_str()));
        TextGrid_addTier_move(xptr.get(), tier.move());
    }, "Failed to add interval tier");
}

// [[Rcpp::export(.textgrid_add_point_tier)]]
void textgrid_add_point_tier(Rcpp::XPtr<structTextGrid> xptr, std::string name) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        autoTextTier tier = TextTier_create(xptr->xmin, xptr->xmax);
        Thing_setName(tier.get(), Melder_peek8to32(name.c_str()));
        TextGrid_addTier_move(xptr.get(), tier.move());
    }, "Failed to add point tier");
}

// [[Rcpp::export(.textgrid_remove_tier)]]
void textgrid_remove_tier(Rcpp::XPtr<structTextGrid> xptr, int tier_number) {
    praat_try([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        if (tier_number < 1 || tier_number > xptr->tiers->size)
            Rcpp::stop("Tier number out of range");
        xptr->tiers->removeItem(tier_number);
    }, "Failed to remove tier");
}

// ============================================================================
// Extraction
// ============================================================================

// [[Rcpp::export(.textgrid_extract_part)]]
Rcpp::XPtr<structTextGrid> textgrid_extract_part(
    Rcpp::XPtr<structTextGrid> xptr,
    double start_time,
    double end_time,
    bool preserve_times
) {
    try {
        validate_xptr(xptr, "TextGrid");
        autoTextGrid extracted = TextGrid_extractPart(
            xptr.get(),
            start_time,
            end_time,
            preserve_times
        );
        return create_xptr_from_auto<structTextGrid>(extracted);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract part");
    }
}

// ============================================================================
// Export to R Data Structures
// ============================================================================

// [[Rcpp::export(.textgrid_to_data_frame)]]
Rcpp::DataFrame textgrid_to_data_frame(
    Rcpp::XPtr<structTextGrid> xptr,
    Rcpp::Nullable<Rcpp::IntegerVector> tier_numbers = R_NilValue
) {
    return praat_try_return([&]() {
        if (!xptr) Rcpp::stop("Invalid TextGrid pointer");
        
        std::vector<int> tiers_to_export;
        if (tier_numbers.isNotNull()) {
            Rcpp::IntegerVector tn(tier_numbers);
            tiers_to_export = Rcpp::as<std::vector<int>>(tn);
        } else {
            for (int i = 1; i <= xptr->tiers->size; i++) {
                tiers_to_export.push_back(i);
            }
        }
        
        std::vector<std::string> tier_names;
        std::vector<std::string> tier_types;
        std::vector<int> item_numbers;
        std::vector<double> start_times;
        std::vector<double> end_times;
        std::vector<std::string> labels;
        
        for (int tier_num : tiers_to_export) {
            if (tier_num < 1 || tier_num > xptr->tiers->size) continue;
            
            Function tier = xptr->tiers->at[tier_num];
            std::string tier_name = Melder_peek32to8(tier->name.get());
            
            IntervalTier intervalTier = nullptr;
            TextTier textTier = nullptr;
            AnyTextGridTier_identifyClass(tier, &intervalTier, &textTier);
            
            if (intervalTier) {
                for (integer i = 1; i <= intervalTier->intervals.size; i++) {
                    TextInterval interval = intervalTier->intervals.at[i];
                    tier_names.push_back(tier_name);
                    tier_types.push_back("interval");
                    item_numbers.push_back(i);
                    start_times.push_back(interval->xmin);
                    end_times.push_back(interval->xmax);
                    labels.push_back(Melder_peek32to8(interval->text.get()));
                }
            } else if (textTier) {
                for (integer i = 1; i <= textTier->points.size; i++) {
                    TextPoint point = textTier->points.at[i];
                    tier_names.push_back(tier_name);
                    tier_types.push_back("point");
                    item_numbers.push_back(i);
                    start_times.push_back(point->number);
                    end_times.push_back(NA_REAL);
                    labels.push_back(Melder_peek32to8(point->mark.get()));
                }
            }
        }
        
        return Rcpp::DataFrame::create(
            Rcpp::Named("tier_name") = tier_names,
            Rcpp::Named("tier_type") = tier_types,
            Rcpp::Named("item_number") = item_numbers,
            Rcpp::Named("start_time") = start_times,
            Rcpp::Named("end_time") = end_times,
            Rcpp::Named("label") = labels,
            Rcpp::Named("stringsAsFactors") = false
        );
    }, "Failed to convert TextGrid to data frame");
}
