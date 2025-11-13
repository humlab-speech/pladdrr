/* SVD stubs for LPC support
 * These functions are stubs that throw errors when called
 * LPC synthesis requires SVD from CLAPACK which is not included
 */

#include "praat.github.io/dwsys/SVD.h"
#include "melder.h"

autoSVD SVD_create (integer numberOfRows, integer numberOfColumns) {
	Melder_throw (U"SVD_create: LPC with SVD decomposition is not available. "
	              U"This package does not include CLAPACK. "
	              U"Use other analysis methods instead.");
	return autoSVD();   // Never reached, but needed for compilation
}

autoSVD SVD_createFromGeneralMatrix (constMATVU const& m) {
	Melder_throw (U"SVD_createFromGeneralMatrix: LPC with SVD decomposition is not available. "
	              U"This package does not include CLAPACK. "
	              U"Use other analysis methods instead.");
	return autoSVD();   // Never reached, but needed for compilation
}

autoGSVD GSVD_create (integer numberOfColumns) {
	Melder_throw (U"GSVD_create: Generalized SVD is not available. "
	              U"This package does not include CLAPACK.");
	return autoGSVD();  // Never reached, but needed for compilation
}

autoGSVD GSVD_create (constMATVU const& m1, constMATVU const& m2) {
	Melder_throw (U"GSVD_create: Generalized SVD is not available. "
	              U"This package does not include CLAPACK.");
	return autoGSVD();  // Never reached, but needed for compilation
}
