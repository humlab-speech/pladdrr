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

void SVD_compute (SVD me) {
	Melder_throw (U"SVD_compute: SVD decomposition is not available. "
	              U"This package does not include CLAPACK/LAPACK.");
}

void SVD_compute (SVD me, VEC const& workspace) {
	Melder_throw (U"SVD_compute: SVD decomposition is not available. "
	              U"This package does not include CLAPACK/LAPACK.");
}

void SVD_setTolerance (SVD me, double tolerance) {
	Melder_throw (U"SVD_setTolerance: SVD decomposition is not available. "
	              U"This package does not include CLAPACK/LAPACK.");
}

integer SVD_getWorkspaceSize (SVD) {
	Melder_throw (U"SVD_getWorkspaceSize: SVD decomposition is not available. "
	              U"This package does not include CLAPACK/LAPACK.");
}

void SVD_solve_preallocated (SVD, constVECVU const&, VECVU const&, VEC const&) {
	Melder_throw (U"SVD_solve_preallocated: SVD decomposition is not available. "
	              U"This package does not include CLAPACK/LAPACK.");
}

void SVD_resizeWithinOldBounds (SVD, integer, integer, integer, integer) {
Melder_throw (U"SVD_resizeWithinOldBounds: SVD decomposition is not available. "
              U"This package does not include CLAPACK/LAPACK.");
}

