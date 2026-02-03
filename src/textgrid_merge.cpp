// textgrid_merge.cpp - Batch TextGrid merging wrapper
//
// Wraps Praat's TextGrids_merge() for O(n) batch merging
// instead of O(n²) manual tier copying.
//
// Performance: Manual merge requires save/reload + O(n²) insert_boundary calls.
// Batch merge is single-pass O(n).
//
// Use case: VUV analysis merges original TextGrid with VUV tier (17x speedup)


#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/TextGrid.h"
#include "melder/melder.h"

using namespace Rcpp;

//' Merge multiple TextGrid objects efficiently (internal)
//'
//' Batch merging using Praat's O(n) algorithm instead of O(n²) manual tier copy.
//'
//' @param textgrids List of TextGrid objects (external pointers or R6 objects)
//' @param equalize_domains If TRUE, all tiers will have the same domain (default: FALSE)
//' @return External pointer to merged TextGrid
//'
//' @details
//' Manual merge workflow:
//'   1. Save/reload original TextGrid (disk I/O)
//'   2. Add empty tier
//'   3. Insert boundaries one-by-one (each shifts all later intervals: O(n²))
//'   4. Set labels (O(n))
//'   Total: O(n²) + disk I/O
//'
//' Batch merge:
//'   Single-pass merge with proper interval handling: O(n)
//'
//' Performance gain: 17x for VUV (100 intervals), scales with N
//'
//' Domain handling:
//'   - If equalize_domains=FALSE (default):
//'     New domain runs from min(xmin) to max(xmax) of all input TextGrids.
//'     Tiers retain their original domains.
//'
//'   - If equalize_domains=TRUE:
//'     All tiers extended to the new domain.
//'     Empty intervals added at edges if needed.
//'
//' @keywords internal
// [[Rcpp::export(.textgrid_merge)]]
SEXP textgrid_merge(List textgrids, bool equalize_domains = false) {
    if (textgrids.size() == 0) {
        stop("Cannot merge empty TextGrid list");
    }
    
    if (textgrids.size() == 1) {
        // Single TextGrid - just return copy
        SEXP first = textgrids[0];
        if (TYPEOF(first) == EXTPTRSXP) {
            return first;
        } else if (Rf_inherits(first, "TextGrid")) {
            // TextGrid wrapper (structured list) - extract .xptr
            List tg_list(first);
            SEXP xptr_val = tg_list[".xptr"];
            if (xptr_val == R_NilValue || TYPEOF(xptr_val) != EXTPTRSXP) {
                stop("TextGrid object missing .xptr field");
            }
            return xptr_val;
        } else {
            stop("Invalid TextGrid object type");
        }
    }
    
    try {
        // Create OrderedOf<structTextGrid> collection
        // Note: Praat uses OrderedOf template, not a named Collection type
        OrderedOf<structTextGrid> collection;
        
        // Add all TextGrids to collection
        for (int i = 0; i < textgrids.size(); i++) {
            SEXP tg_sexp = textgrids[i];

            // Extract external pointer SEXP from various input types
            SEXP xptr_sexp;
            if (TYPEOF(tg_sexp) == EXTPTRSXP) {
                xptr_sexp = tg_sexp;
            } else if (Rf_inherits(tg_sexp, "TextGrid")) {
                // TextGrid wrapper (structured list) - extract .xptr
                List tg_list(tg_sexp);
                xptr_sexp = tg_list[".xptr"];
                if (xptr_sexp == R_NilValue || TYPEOF(xptr_sexp) != EXTPTRSXP) {
                    stop("TextGrid object at index " + std::to_string(i) + " missing .xptr field");
                }
            } else {
                stop("Invalid TextGrid object at index " + std::to_string(i));
            }

            // Wrap as typed pointer and validate
            XPtr<structTextGrid> tg_xptr(xptr_sexp);
            if (tg_xptr.get() == nullptr) {
                stop("Null TextGrid pointer at index " + std::to_string(i));
            }

            // Add reference to collection (no copy needed - Praat will copy internally)
            collection.addItem_ref(tg_xptr.get());
        }
        
        // Call Praat's O(n) batch merge
        autoTextGrid result = TextGrids_merge(&collection, equalize_domains);
        
        // Return as external pointer
        return create_xptr_from_auto<structTextGrid>(result);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to merge TextGrids");
    }
}
