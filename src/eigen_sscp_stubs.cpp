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
