// textgrid_module.cpp
// Rcpp Module exposing Praat TextGrid functionality (pladdrr 2.0)
//
// TextGrid: annotation structure with interval and point tiers

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/sys/Data.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/TextGrid_Sound.h"
#include "praat.github.io/dwtools/TextGrid_extensions.h"
#include "praat.github.io/stat/Table.h"

using namespace Rcpp;

class RTextGrid {
private:
    XPtr<structTextGrid> ptr;

public:
    RTextGrid() : ptr(R_NilValue) {}
    RTextGrid(XPtr<structTextGrid> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, TextGrid); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, TextGrid); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, TextGrid); return ptr->xmax - ptr->xmin; }

    // Tier properties
    int get_number_of_tiers() {
        VALIDATE_PTR(ptr, TextGrid);
        return static_cast<int>(ptr->tiers->size);
    }

    std::string get_tier_name(int tier_number) {
        VALIDATE_PTR(ptr, TextGrid);
        if (tier_number < 1 || tier_number > ptr->tiers->size) {
            Rcpp::stop("Tier number out of range");
        }
        ::Function tier = ptr->tiers->at[tier_number];
        return Melder_peek32to8(tier->name.get());
    }

    CharacterVector get_tier_names() {
        VALIDATE_PTR(ptr, TextGrid);
        CharacterVector result(ptr->tiers->size);
        for (integer i = 1; i <= ptr->tiers->size; i++) {
            ::Function tier = ptr->tiers->at[i];
            result[i-1] = Melder_peek32to8(tier->name.get());
        }
        return result;
    }

    void set_tier_name(int tier_number, std::string name) {
        VALIDATE_PTR(ptr, TextGrid);
        if (tier_number < 1 || tier_number > ptr->tiers->size) {
            Rcpp::stop("Tier number out of range");
        }
        try {
            ::Function tier = ptr->tiers->at[tier_number];
            Thing_setName(tier, Melder_peek8to32(name.c_str()));
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set tier name");
        }
    }

    bool is_interval_tier(int tier_number) {
        VALIDATE_PTR(ptr, TextGrid);
        if (tier_number < 1 || tier_number > ptr->tiers->size) {
            Rcpp::stop("Tier number out of range");
        }
        ::Function tier = ptr->tiers->at[tier_number];
        IntervalTier intervalTier = nullptr;
        TextTier textTier = nullptr;
        AnyTextGridTier_identifyClass(tier, &intervalTier, &textTier);
        return intervalTier != nullptr;
    }

    bool is_point_tier(int tier_number) {
        VALIDATE_PTR(ptr, TextGrid);
        if (tier_number < 1 || tier_number > ptr->tiers->size) {
            Rcpp::stop("Tier number out of range");
        }
        ::Function tier = ptr->tiers->at[tier_number];
        IntervalTier intervalTier = nullptr;
        TextTier textTier = nullptr;
        AnyTextGridTier_identifyClass(tier, &intervalTier, &textTier);
        return textTier != nullptr;
    }

    // IntervalTier queries
    int get_number_of_intervals(int tier_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(ptr.get(), tier_number);
            return static_cast<int>(tier->intervals.size);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get number of intervals (is this an interval tier?)");
        }
    }

    double get_interval_start_time(int tier_number, int interval_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(ptr.get(), tier_number);
            if (interval_number < 1 || interval_number > tier->intervals.size) {
                Rcpp::stop("Interval number out of range");
            }
            return tier->intervals.at[interval_number]->xmin;
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get interval start time");
        }
    }

    double get_interval_end_time(int tier_number, int interval_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(ptr.get(), tier_number);
            if (interval_number < 1 || interval_number > tier->intervals.size) {
                Rcpp::stop("Interval number out of range");
            }
            return tier->intervals.at[interval_number]->xmax;
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get interval end time");
        }
    }

    std::string get_interval_text(int tier_number, int interval_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(ptr.get(), tier_number);
            if (interval_number < 1 || interval_number > tier->intervals.size) {
                Rcpp::stop("Interval number out of range");
            }
            return Melder_peek32to8(tier->intervals.at[interval_number]->text.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get interval text");
        }
    }

    int get_interval_at_time(int tier_number, double time) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(ptr.get(), tier_number);
            return static_cast<int>(IntervalTier_timeToIndex(tier, time));
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get interval at time");
        }
    }

    std::string get_label_at_time(int tier_number, double time) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(ptr.get(), tier_number);
            integer index = IntervalTier_timeToIndex(tier, time);
            if (index == 0) return "";
            return Melder_peek32to8(tier->intervals.at[index]->text.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get label at time");
        }
    }

    // IntervalTier modifications
    void set_interval_text(int tier_number, int interval_number, std::string text) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextGrid_setIntervalText(
                ptr.get(), tier_number, interval_number,
                Melder_peek8to32(text.c_str())
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set interval text");
        }
    }

    void insert_boundary(int tier_number, double time) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextGrid_insertBoundary(ptr.get(), tier_number, time);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to insert boundary");
        }
    }

    void remove_boundary_at_time(int tier_number, double time) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextGrid_removeBoundaryAtTime(ptr.get(), tier_number, time);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove boundary");
        }
    }

    // PointTier queries
    int get_number_of_points(int tier_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(ptr.get(), tier_number);
            return static_cast<int>(tier->points.size);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get number of points (is this a point tier?)");
        }
    }

    double get_point_time(int tier_number, int point_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(ptr.get(), tier_number);
            if (point_number < 1 || point_number > tier->points.size) {
                Rcpp::stop("Point number out of range");
            }
            return tier->points.at[point_number]->number;
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get point time");
        }
    }

    std::string get_point_text(int tier_number, int point_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(ptr.get(), tier_number);
            if (point_number < 1 || point_number > tier->points.size) {
                Rcpp::stop("Point number out of range");
            }
            return Melder_peek32to8(tier->points.at[point_number]->mark.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get point text");
        }
    }

    // PointTier modifications
    void insert_point(int tier_number, double time, std::string mark) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextGrid_insertPoint(
                ptr.get(), tier_number, time,
                Melder_peek8to32(mark.c_str())
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to insert point");
        }
    }

    void set_point_text(int tier_number, int point_number, std::string text) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextGrid_setPointText(
                ptr.get(), tier_number, point_number,
                Melder_peek8to32(text.c_str())
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set point text");
        }
    }

    void remove_point(int tier_number, int point_number) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            TextTier tier = TextGrid_checkSpecifiedTierIsPointTier(ptr.get(), tier_number);
            if (point_number < 1 || point_number > tier->points.size) {
                Rcpp::stop("Point number out of range");
            }
            TextTier_removePoint(tier, point_number);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove point");
        }
    }

    // Tier management
    void add_interval_tier(std::string name) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            autoIntervalTier tier = IntervalTier_create(ptr->xmin, ptr->xmax);
            Thing_setName(tier.get(), Melder_peek8to32(name.c_str()));
            TextGrid_addTier_move(ptr.get(), tier.move());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to add interval tier");
        }
    }

    void add_point_tier(std::string name) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            autoTextTier tier = TextTier_create(ptr->xmin, ptr->xmax);
            Thing_setName(tier.get(), Melder_peek8to32(name.c_str()));
            TextGrid_addTier_move(ptr.get(), tier.move());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to add point tier");
        }
    }

    void remove_tier(int tier_number) {
        VALIDATE_PTR(ptr, TextGrid);
        if (tier_number < 1 || tier_number > ptr->tiers->size) {
            Rcpp::stop("Tier number out of range");
        }
        try {
            ptr->tiers->removeItem(tier_number);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove tier");
        }
    }

    // Extraction
    XPtr<structTextGrid> extract_part_ptr(double start_time, double end_time, bool preserve_times) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            autoTextGrid extracted = TextGrid_extractPart(
                ptr.get(), start_time, end_time, preserve_times
            );
            structTextGrid* raw = extracted.releaseToAmbiguousOwner();
            return XPtr<structTextGrid>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract part");
        }
    }

    // Conversion to Table
    XPtr<structTable> to_table_ptr(
        bool include_line_numbers, int time_decimals,
        bool include_tier_names, bool include_empty_intervals) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            autoTable table = TextGrid_downto_Table(
                ptr.get(), include_line_numbers,
                static_cast<integer>(time_decimals),
                include_tier_names, include_empty_intervals
            );
            structTable* raw = table.releaseToAmbiguousOwner();
            return XPtr<structTable>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert TextGrid to Table");
        }
    }

    // Export to data frame
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, TextGrid);

        std::vector<std::string> tier_names;
        std::vector<std::string> tier_types;
        std::vector<int> item_numbers;
        std::vector<double> start_times;
        std::vector<double> end_times;
        std::vector<std::string> labels;

        for (integer tier_num = 1; tier_num <= ptr->tiers->size; tier_num++) {
            ::Function tier = ptr->tiers->at[tier_num];
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

        return pladdrr::dt::create_datatable(
            List::create(
                Named("tier_name") = tier_names,
                Named("tier_type") = tier_types,
                Named("item_number") = item_numbers,
                Named("start_time") = start_times,
                Named("end_time") = end_times,
                Named("label") = labels
            ),
            CharacterVector::create("tier_name", "tier_type", "item_number", "start_time", "end_time", "label"),
            CharacterVector::create("tier_name", "start_time")
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, TextGrid);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("n_tiers") = ptr->tiers->size,
            Named("tier_names") = get_tier_names()
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, TextGrid);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save TextGrid");
        }
    }
};

// Factory functions
static XPtr<structTextGrid> Module_TextGrid_create(
    double tmin, double tmax,
    std::string tier_names, std::string point_tiers) {
    try {
        autoTextGrid tg = TextGrid_create(
            tmin, tmax,
            Melder_peek8to32(tier_names.c_str()),
            Melder_peek8to32(point_tiers.c_str())
        );
        structTextGrid* raw = tg.releaseToAmbiguousOwner();
        return XPtr<structTextGrid>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create TextGrid");
    }
}

static XPtr<structTextGrid> Module_TextGrid_read(std::string path) {
    try {
        structMelderFile file = {};
        Melder_pathToFile(Melder_peek8to32(path.c_str()), &file);
        autoDaata data = Data_readFromTextFile(&file);
        if (!data || !Thing_isa(data.get(), classTextGrid)) {
            Rcpp::stop("File is not a TextGrid");
        }
        autoTextGrid tg = data.static_cast_move<structTextGrid>();
        structTextGrid* raw = tg.releaseToAmbiguousOwner();
        return XPtr<structTextGrid>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to read TextGrid from file");
    }
}

RCPP_MODULE(textgrid_module) {
    class_<RTextGrid>("RTextGrid")
        .constructor()
        .constructor<XPtr<structTextGrid>>()
        .method("is_valid", &RTextGrid::is_valid)
        // Time domain
        .method("get_xmin", &RTextGrid::get_xmin)
        .method("get_xmax", &RTextGrid::get_xmax)
        .method("get_duration", &RTextGrid::get_duration)
        // Tier properties
        .method("get_number_of_tiers", &RTextGrid::get_number_of_tiers)
        .method("get_tier_name", &RTextGrid::get_tier_name)
        .method("get_tier_names", &RTextGrid::get_tier_names)
        .method("set_tier_name", &RTextGrid::set_tier_name)
        .method("is_interval_tier", &RTextGrid::is_interval_tier)
        .method("is_point_tier", &RTextGrid::is_point_tier)
        // IntervalTier queries
        .method("get_number_of_intervals", &RTextGrid::get_number_of_intervals)
        .method("get_interval_start_time", &RTextGrid::get_interval_start_time)
        .method("get_interval_end_time", &RTextGrid::get_interval_end_time)
        .method("get_interval_text", &RTextGrid::get_interval_text)
        .method("get_interval_at_time", &RTextGrid::get_interval_at_time)
        .method("get_label_at_time", &RTextGrid::get_label_at_time)
        // IntervalTier modifications
        .method("set_interval_text", &RTextGrid::set_interval_text)
        .method("insert_boundary", &RTextGrid::insert_boundary)
        .method("remove_boundary_at_time", &RTextGrid::remove_boundary_at_time)
        // PointTier queries
        .method("get_number_of_points", &RTextGrid::get_number_of_points)
        .method("get_point_time", &RTextGrid::get_point_time)
        .method("get_point_text", &RTextGrid::get_point_text)
        // PointTier modifications
        .method("insert_point", &RTextGrid::insert_point)
        .method("set_point_text", &RTextGrid::set_point_text)
        .method("remove_point", &RTextGrid::remove_point)
        // Tier management
        .method("add_interval_tier", &RTextGrid::add_interval_tier)
        .method("add_point_tier", &RTextGrid::add_point_tier)
        .method("remove_tier", &RTextGrid::remove_tier)
        // Extraction/Conversion
        .method("extract_part_ptr", &RTextGrid::extract_part_ptr)
        .method("to_table_ptr", &RTextGrid::to_table_ptr)
        // Export
        .method("as_data_frame", &RTextGrid::as_data_frame)
        .method("get_info", &RTextGrid::get_info)
        .method("save", &RTextGrid::save)
    ;

    // Factory functions
    function("TextGrid_create", &Module_TextGrid_create);
    function("TextGrid_read", &Module_TextGrid_read);
}
