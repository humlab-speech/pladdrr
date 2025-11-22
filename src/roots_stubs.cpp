/* Roots stubs for LPC support
 * Roots.cpp is disabled in the Praat source (.disabled extension)
 * These stubs provide minimal error-throwing implementations
 */

#include "praat.github.io/dwsys/Roots.h"
#include "melder.h"

// Thing implementation required for class linkage
Thing_implement (Roots, Daata, 0);

// Provide the s_description field required by oo_DEFINE_CLASS
Data_Description structRoots :: s_description = nullptr;

// Required virtual method implementations
void structRoots :: v1_info () {
	structDaata :: v1_info ();
	MelderInfo_writeLine (U"Number of roots: ", numberOfRoots);
}

void structRoots :: v1_copy (Daata /* data_to */) const {
	Melder_throw (U"Roots objects cannot be copied: functionality is disabled.");
}

bool structRoots :: v1_equal (Daata /* other */) {
	return false;  // Roots objects cannot be compared
}

bool structRoots :: v1_canWriteAsEncoding (int /* outputEncoding */) {
	return false;  // Roots objects cannot be written in any encoding
}

void structRoots :: v1_readText (MelderReadText /* text */, int /* formatVersion */) {
	// Roots object cannot be read - functionality is disabled
	// We leave the object in an empty state
	numberOfRoots = 0;
	roots.resize (0);
}

void structRoots :: v1_readBinary (FILE * /* f */, int /* formatVersion */) {
	// Roots object cannot be read - functionality is disabled
	// We leave the object in an empty state
	numberOfRoots = 0;
	roots.resize (0);
}

void structRoots :: v1_writeText (MelderFile /* file */) {
	// Roots object cannot be written - functionality is disabled
	Melder_throw (U"Roots object cannot be written: functionality is disabled.");
}

void structRoots :: v1_writeBinary (FILE * /* f */) {
	// Roots object cannot be written - functionality is disabled
	Melder_throw (U"Roots object cannot be written: functionality is disabled.");
}

void structRoots :: v9_destroy () noexcept {
	structDaata :: v9_destroy ();
}

// Stub functions that throw errors

autoRoots Roots_create (integer numberOfRoots) {
	Melder_throw (U"Roots_create: Roots object is not available. "
	              U"The Praat Roots implementation is disabled.");
}

void Roots_fixIntoUnitCircle (mutableRoots me) {
	Melder_throw (U"Roots_fixIntoUnitCircle: Roots object is not available.");
}

void Roots_sort (mutableRoots me) {
	Melder_throw (U"Roots_sort: Roots object is not available.");
}

integer Roots_getNumberOfRoots (constRoots me) {
	Melder_throw (U"Roots_getNumberOfRoots: Roots object is not available.");
	return 0;   // Never reached
}

void Roots_draw (constRoots me, Graphics g, double rmin, double rmax, double imin, double imax,
    conststring32 symbol, double fontSize, bool garnish) {
	Melder_throw (U"Roots_draw: Roots object is not available.");
}

dcomplex Roots_getRoot (constRoots me, integer index) {
	Melder_throw (U"Roots_getRoot: Roots object is not available.");
	dcomplex zero = { 0.0, 0.0 };
	return zero;   // Never reached
}

void Roots_setRoot (mutableRoots me, integer index, dcomplex value) {
	Melder_throw (U"Roots_setRoot: Roots object is not available.");
}

autoRoots Polynomial_to_Roots_ev (constPolynomial me) {
	Melder_throw (U"Polynomial_to_Roots_ev: Roots conversion is not available. "
	              U"The Praat Roots implementation is disabled.");
}

autoRoots Polynomial_to_Roots (constPolynomial me) {
	Melder_throw (U"Polynomial_to_Roots: Roots conversion is not available. "
	              U"The Praat Roots implementation is disabled.");
}

// Forward declaration for SSCP (statistical object)
struct structSSCP;
typedef struct structSSCP *SSCP;
typedef struct structSSCP *autoSSCP;
struct structTableOfReal;

// Stub for TableOfReal_to_SSCP (used by Table.cpp)
autoSSCP TableOfReal_to_SSCP (struct structTableOfReal *, integer, integer, integer, integer) {
	Melder_throw (U"TableOfReal_to_SSCP: SSCP analysis is not available. "
	              U"This package does not include the full dwtools statistical library.");
}

// Stub for Polynomial_into_Roots
void Polynomial_into_Roots (constPolynomial, Roots, VEC) {
	Melder_throw (U"Polynomial_into_Roots: Roots conversion is not available. "
	              U"The Praat Roots implementation is disabled.");
}

// Eigen decomposition stubs
void SSCP_drawConcentrationEllipse (SSCP, Graphics, double, int, integer, integer, double, double, double, double, bool) {
    Melder_throw (U"SSCP_drawConcentrationEllipse: SSCP graphics are not available. "
                  U"This package does not include graphics support.");
}
