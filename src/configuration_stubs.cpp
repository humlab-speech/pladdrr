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
/* Configuration stubs for statistical analysis
 * These functions are stubs that throw errors when called
 * Configuration is part of advanced statistical/MDS functionality  
 */

#include "praat.github.io/sys/Thing.h"
#include "praat.github.io/melder/melder.h"

// Minimal Configuration struct definition for stub purposes
struct structConfiguration : structThing {
	integer numberOfPoints;
	integer numberOfDimensions;
};
typedef autoSomeThing<structConfiguration> autoConfiguration;

// Forward declare TableOfReal
struct structTableOfReal;
typedef structTableOfReal* TableOfReal;

autoConfiguration Configuration_create (integer numberOfPoints, integer numberOfDimensions) {
	Melder_throw (U"Configuration_create: Configuration objects are not available. "
		"This is a statistical analysis function for multidimensional scaling.");
}

autoConfiguration TableOfReal_to_Configuration (TableOfReal /* me */, integer /* numberOfDimensions */) {
	Melder_throw (U"TableOfReal_to_Configuration: Configuration conversion is not available. "
		"This is a statistical analysis function for multidimensional scaling.");
}

autoConfiguration TableOfReal_to_Configuration_pca (TableOfReal /* me */, integer /* numberOfDimensions */) {
	Melder_throw (U"TableOfReal_to_Configuration_pca: PCA-based Configuration is not available. "
		"This is a statistical analysis function for multidimensional scaling.");
}
