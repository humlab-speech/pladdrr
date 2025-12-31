// Stubs for Table functions that require statistical modules (SSCP, etc.)
#include "praat.github.io/sys/Thing.h"
#include "praat.github.io/sys/Graphics.h"
#include "praat.github.io/stat/Table.h"
#include "praat.github.io/stat/TableOfReal.h"

// Declare SSCP struct (inherits from TableOfReal in reality)
struct structSSCP : structTableOfReal {
    // Minimal stub - just inherit from TableOfReal
};
typedef structSSCP *SSCP;

// Stub for TableOfReal_to_SSCP (required by Table.cpp)
autoThing TableOfReal_to_SSCP (TableOfReal me, integer rowb, integer rowe, integer colb, integer cole) {
    (void) me; (void) rowb; (void) rowe; (void) colb; (void) cole;
    Melder_throw (U"TableOfReal_to_SSCP: SSCP statistical module not available.");
}

// Stub for SSCP_drawConcentrationEllipse
void SSCP_drawConcentrationEllipse (SSCP me, Graphics g, double scale,
    int confidence, integer d1, integer d2, double xmin, double xmax, double ymin, double ymax, bool garnish)
{
    (void) me; (void) g; (void) scale; (void) confidence; (void) d1; (void) d2;
    (void) xmin; (void) xmax; (void) ymin; (void) ymax; (void) garnish;
    Melder_throw (U"SSCP_drawConcentrationEllipse: SSCP statistical module not available.");
}
