#pragma once
#include <Rcpp.h>
#include <string>
#include <vector>

// Melder_peek32to8() returns UTF-8 bytes, but Rcpp::wrap(std::string)
// creates R strings with unknown/native encoding — non-ASCII text
// (e.g. IPA symbols in TextGrid labels) gets mis-decoded downstream
// unless the CE_UTF8 flag is set explicitly.

inline Rcpp::String melder_utf8(const std::string& utf8) {
    Rcpp::String s(utf8);
    s.set_encoding(CE_UTF8);
    return s;
}

inline Rcpp::CharacterVector melder_utf8_vector(const std::vector<std::string>& utf8_strings) {
    Rcpp::CharacterVector out(utf8_strings.size());
    for (size_t i = 0; i < utf8_strings.size(); ++i) {
        out[i] = Rf_mkCharCE(utf8_strings[i].c_str(), CE_UTF8);
    }
    return out;
}
