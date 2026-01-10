#ifndef PLADDRR_DATATABLE_UTILS_H
#define PLADDRR_DATATABLE_UTILS_H

#include <Rcpp.h>

namespace pladdrr {
namespace dt {

/**
 * Create a data.table from Rcpp vectors
 * 
 * Sets class to c("data.table", "data.frame") and required attributes.
 * Optionally sets key columns for fast operations.
 * 
 * @param columns List of column vectors
 * @param names Column names
 * @param key Optional vector of key column names for sorting/fast lookups
 * @return DataFrame with data.table class and attributes
 */
inline Rcpp::DataFrame create_datatable(
    const Rcpp::List& columns,
    const Rcpp::CharacterVector& names,
    const Rcpp::CharacterVector& key = Rcpp::CharacterVector()
) {
    Rcpp::DataFrame df(columns);
    df.names() = names;
    
    // Set data.table class (must be before data.frame)
    Rcpp::CharacterVector classes = Rcpp::CharacterVector::create("data.table", "data.frame");
    df.attr("class") = classes;
    
    // Set key if provided (for fast operations)
    if (key.length() > 0) {
        df.attr("sorted") = key;
    }
    
    // Required data.table attribute (internal pointer, set to NULL initially)
    // This will be properly initialized when accessed from R
    df.attr(".internal.selfref") = R_NilValue;
    
    return df;
}

/**
 * Overload for common 2-column case
 */
inline Rcpp::DataFrame create_datatable(
    const Rcpp::NumericVector& col1,
    const Rcpp::NumericVector& col2,
    const std::string& name1,
    const std::string& name2,
    const Rcpp::CharacterVector& key = Rcpp::CharacterVector()
) {
    return create_datatable(
        Rcpp::List::create(col1, col2),
        Rcpp::CharacterVector::create(name1, name2),
        key
    );
}

/**
 * Overload for common 3-column case
 */
inline Rcpp::DataFrame create_datatable(
    const Rcpp::NumericVector& col1,
    const Rcpp::IntegerVector& col2,
    const Rcpp::NumericVector& col3,
    const std::string& name1,
    const std::string& name2,
    const std::string& name3,
    const Rcpp::CharacterVector& key = Rcpp::CharacterVector()
) {
    return create_datatable(
        Rcpp::List::create(col1, col2, col3),
        Rcpp::CharacterVector::create(name1, name2, name3),
        key
    );
}

/**
 * Overload for 4-column case (common for formant data)
 */
inline Rcpp::DataFrame create_datatable(
    const Rcpp::NumericVector& col1,
    const Rcpp::IntegerVector& col2,
    const Rcpp::NumericVector& col3,
    const Rcpp::NumericVector& col4,
    const std::string& name1,
    const std::string& name2,
    const std::string& name3,
    const std::string& name4,
    const Rcpp::CharacterVector& key = Rcpp::CharacterVector()
) {
    return create_datatable(
        Rcpp::List::create(col1, col2, col3, col4),
        Rcpp::CharacterVector::create(name1, name2, name3, name4),
        key
    );
}

/**
 * Helper to create data.table with Named syntax (like DataFrame::create)
 * 
 * Usage:
 *   return dt_create(
 *       Named("time") = times,
 *       Named("frequency") = freqs,
 *       Key("time")
 *   );
 */
template<typename... Args>
inline Rcpp::DataFrame dt_create(Args... args) {
    Rcpp::List columns = Rcpp::List::create(args...);
    Rcpp::CharacterVector col_names = columns.names();
    
    Rcpp::DataFrame df(columns);
    df.names() = col_names;
    
    // Set data.table class
    Rcpp::CharacterVector classes = Rcpp::CharacterVector::create("data.table", "data.frame");
    df.attr("class") = classes;
    df.attr(".internal.selfref") = R_NilValue;
    
    return df;
}

/**
 * Helper for setting key columns after creation
 * This is useful when you can't determine the key at creation time
 */
inline void set_key(Rcpp::DataFrame& df, const Rcpp::CharacterVector& key) {
    if (key.length() > 0) {
        df.attr("sorted") = key;
    }
}

} // namespace dt
} // namespace pladdrr

#endif // PLADDRR_DATATABLE_UTILS_H
