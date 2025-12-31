/* Eigen_SSCP stubs for statistical analysis
 * These functions are stubs that throw errors when called
 * Full statistical analysis requires more Praat modules
 */

#include "praat.github.io/dwsys/Eigen.h"
#include "praat.github.io/dwtools/SSCP.h"
#include "praat.github.io/melder/melder.h"

autoEigen Eigen_SSCP_project (Eigen /* me */, SSCP /* thee */) {
	Melder_throw (U"Eigen_SSCP_project: SSCP projection is not available. "
		"This is a statistical analysis function not yet fully integrated.");
	return autoEigen();  // Never reached, but needed for compilation
}
