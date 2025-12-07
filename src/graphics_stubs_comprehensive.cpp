// Comprehensive Graphics subsystem stubs for NO_GRAPHICS builds
// Auto-generated from Graphics.h function signatures

#include "praat.github.io/sys/Thing.h"
#include "praat.github.io/sys/Graphics.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/dwtools/Sound_extensions_enums.h"
#include "praat.github.io/fon/Matrix.h"

// Note: These are no-op stubs since we build with NO_GRAPHICS
// Graphics functionality is disabled in non-GUI builds

// Matrix extensions graphics stubs (for TableOfReal_extensions dependency)
void Matrix_drawDistribution (Matrix, Graphics, double, double, double, double, double, double, integer, double, double, bool, bool) {}

void Graphics_grey (Graphics, constMATVU const&, double, double, double, double, int, double []) {}
void Graphics_image (Graphics, constMATVU const&, double, double, double, double, double, double) {}
void Graphics_surface (Graphics, constMATVU const&, double, double, double, double, double, double, double, double) {}
void Graphics_contour (Graphics, constMATVU const&, double, double, double, double, double) {}
void Graphics_altitude (Graphics, constMATVU const&, double, double, double, double, int, double []) {}
void Graphics_cellArray (Graphics, constMATVU const&, double, double, double, double, double, double) {}

void Graphics_line (Graphics, double, double, double, double) {}
void Graphics_arrow (Graphics, double, double, double, double) {}
void Graphics_doubleArrow (Graphics, double, double, double, double) {}
void Graphics_arcArrow (Graphics, double, double, double, double, double, double, int) {}
void Graphics_arc (Graphics, double, double, double, double, double, double) {}

void Graphics_polyline (Graphics, integer, const double *, const double *) {}
void Graphics_polyline_closed (Graphics, integer, const double *, const double *) {}
void Graphics_function (Graphics, const double *, integer, integer, double, double) {}
void Graphics_function16 (Graphics, int16 *, int, integer, integer, double, double, int, double, double, double *, double *) {}
void Graphics_fillArea (Graphics, integer, const double *, const double *) {}

void Graphics_rectangle (Graphics, double, double, double, double) {}
void Graphics_fillRectangle (Graphics, double, double, double, double) {}
void Graphics_roundedRectangle (Graphics, double, double, double, double, double) {}
void Graphics_fillRoundedRectangle (Graphics, double, double, double, double, double) {}
void Graphics_rectangle_mm (Graphics, double, double, double, double) {}
void Graphics_fillRectangle_mm (Graphics, double, double, double, double) {}

void Graphics_circle (Graphics, double, double, double) {}
void Graphics_fillCircle (Graphics, double, double, double) {}
void Graphics_circle_mm (Graphics, double, double, double) {}
void Graphics_fillCircle_mm (Graphics, double, double, double) {}
void Graphics_ellipse (Graphics, double, double, double, double) {}
void Graphics_fillEllipse (Graphics, double, double, double, double) {}

void Graphics_mark (Graphics, double, double, double, conststring32) {}
void Graphics_markLeft (Graphics, double, bool, bool, bool, conststring32) {}
void Graphics_markRight (Graphics, double, bool, bool, bool, conststring32) {}
void Graphics_markBottom (Graphics, double, bool, bool, bool, conststring32) {}
void Graphics_markTop (Graphics, double, bool, bool, bool, conststring32) {}

void Graphics_marksLeft (Graphics, integer, bool, bool, bool) {}
void Graphics_marksRight (Graphics, integer, bool, bool, bool) {}
void Graphics_marksBottom (Graphics, integer, bool, bool, bool) {}
void Graphics_marksTop (Graphics, integer, bool, bool, bool) {}
void Graphics_marksLeftLogarithmic (Graphics, integer, bool, bool, bool) {}

void Graphics_text (Graphics, double, double, conststring32) {}
void Graphics_textLeft (Graphics, bool, conststring32) {}
void Graphics_textRight (Graphics, bool, conststring32) {}
void Graphics_textBottom (Graphics, bool, conststring32) {}
void Graphics_textTop (Graphics, bool, conststring32) {}

void Graphics_setInner (Graphics) {}
void Graphics_unsetInner (Graphics) {}
void Graphics_setViewport (Graphics, double, double, double, double) {}
void Graphics_resetViewport (Graphics, int) {}
void Graphics_setWindow (Graphics, double, double, double, double) {}

void Graphics_setColour (Graphics, MelderColour) {}
void Graphics_setGrey (Graphics, double) {}
void Graphics_setLineType (Graphics, int) {}
void Graphics_setLineWidth (Graphics, double) {}
void Graphics_setArrowSize (Graphics, double) {}
void Graphics_setSpeckleSize (Graphics, double) {}
void Graphics_setFont (Graphics, kGraphics_font) {}
void Graphics_setFontSize (Graphics, double) {}
void Graphics_setFontStyle (Graphics, int) {}
void Graphics_setBold (Graphics, bool) {}
void Graphics_setItalic (Graphics, bool) {}
void Graphics_setCode (Graphics, bool) {}
void Graphics_setTextAlignment (Graphics, kGraphics_horizontalAlignment, int) {}
void Graphics_setTextRotation (Graphics, double) {}
void Graphics_setTextRotation_vector (Graphics, double, double) {}
void Graphics_setWrapWidth (Graphics, double) {}
void Graphics_setSecondIndent (Graphics, double) {}

void Graphics_setPercentSignIsItalic (Graphics, bool) {}
void Graphics_setNumberSignIsBold (Graphics, bool) {}
void Graphics_setCircumflexIsSuperscript (Graphics, bool) {}
void Graphics_setUnderscoreIsSubscript (Graphics, bool) {}
void Graphics_setDollarSignIsCode (Graphics, bool) {}
void Graphics_setAtSignIsLink (Graphics, bool) {}
void Graphics_setBackquoteIsVerbatim (Graphics, bool) {}

void Graphics_setColourScale (Graphics, int) {}
void Graphics_setWsViewport (Graphics, double, double, double, double) {}
void Graphics_resetWsViewport (Graphics, int) {}
void Graphics_setWsWindow (Graphics, double, double, double, double) {}
void Graphics_inqViewport (Graphics, double *, double *, double *, double *) {}
void Graphics_inqWindow (Graphics, double *, double *, double *, double *) {}
void Graphics_inqWsViewport (Graphics, double *, double *, double *, double *) {}
void Graphics_inqWsWindow (Graphics, double *, double *, double *, double *) {}

double Graphics_dxMMtoWC (Graphics, double) { return 0.0; }
double Graphics_dyMMtoWC (Graphics, double) { return 0.0; }
double Graphics_distanceWCtoMM (Graphics, double, double, double, double) { return 0.0; }
void Graphics_WCtoDC (Graphics, double, double, double *, double *) {}
void Graphics_DCtoWC (Graphics, double, double, double *, double *) {}

void Graphics_clearWs (Graphics) {}
void Graphics_updateWs (Graphics) {}
void Graphics_beginMovieFrame (Graphics, MelderColour *) {}
void Graphics_endMovieFrame (Graphics, double) {}

void Graphics_highlight (Graphics, double, double, double, double) {}
void Graphics_highlight2 (Graphics, double, double, double, double, double, double, double, double) {}
void Graphics_innerRectangle (Graphics, double, double, double, double) {}
void Graphics_drawInnerBox (Graphics) {}
void Graphics_button (Graphics, double, double, double, double) {}
void Graphics_speckle (Graphics, double, double) {}

MelderColour Graphics_inqColour (Graphics) { return Melder_BLACK; }

void Graphics_rectangleText_wrapAndTruncate (Graphics, double, double, double, double, conststring32) {}
void Graphics_rectangleText_maximalFit (Graphics, double, double, double, double, conststring32) {}

void Graphics_xorOn (Graphics, MelderColour) {}
void Graphics_xorOff (Graphics) {}

double Graphics_textWidth (Graphics, conststring32) { return 0.0; }

double Graphics_textWidth_ps (Graphics, conststring32, bool) { return 0.0; }

double Graphics_inqFontSize (Graphics) { return 10.0; }

int Graphics_inqLineType (Graphics) { return 0; }

double Graphics_inqLineWidth (Graphics) { return 1.0; }

double Graphics_inqSpeckleSize (Graphics) { return 1.0; }

void Graphics_marksLeftEvery (Graphics, double, double, bool, bool, bool) {}
void Graphics_marksRightEvery (Graphics, double, double, bool, bool, bool) {}
void Graphics_marksBottomEvery (Graphics, double, double, bool, bool, bool) {}
void Graphics_marksTopEvery (Graphics, double, double, bool, bool, bool) {}


void Graphics_markLeftLogarithmic (Graphics, double, bool, bool, bool, conststring32) {}
void Graphics_markRightLogarithmic (Graphics, double, bool, bool, bool, conststring32) {}
void Graphics_markBottomLogarithmic (Graphics, double, bool, bool, bool, conststring32) {}
void Graphics_markTopLogarithmic (Graphics, double, bool, bool, bool, conststring32) {}



void Graphics_marksRightLogarithmic (Graphics, integer, bool, bool, bool) {}
void Graphics_marksBottomLogarithmic (Graphics, integer, bool, bool, bool) {}
void Graphics_marksTopLogarithmic (Graphics, integer, bool, bool, bool) {}

void Sound_draw_btlr (Sound me, Graphics g, double xmin, double xmax, double ymin, double ymax, kSoundDrawingDirection direction, bool garnish) {
    (void) me; (void) g; (void) xmin; (void) xmax; (void) ymin; (void) ymax; (void) direction; (void) garnish;
    Melder_throw (U"Sound_draw_btlr: Graphics functions are not available in this build.");
}
