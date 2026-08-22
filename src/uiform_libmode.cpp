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
/*
 * uiform_libmode.cpp
 *
 * Library-mode implementation of UiForm functions.
 * Provides form creation and argument parsing without GUI dependencies.
 * Extracted and adapted from Praat's Ui.cpp.
 */
// NOTE (2026-08-16, test-coverage-expansion Task 2): 0% test coverage is expected, not
// dead code. `Interpreter.cpp` and `praat_script.cpp` (both compiled unconditionally,
// see src/Makevars.in) reference UiForm_create/UiForm_add*/UiForm_call/UiForm_parseString
// from Interpreter_createForm() (used only by the GUI "form...endform" argument-prompt
// dialog path, e.g. praat_script.cpp's firstPassThroughScript) and
// Interpreter_getArgumentsFromDialog(). Deleting this file breaks the link. pladdrr's own
// script-execution entry point (praat_run_script() -> interpreter_wrappers.cpp's call to
// Interpreter_run()) never goes through Interpreter_createForm, so these symbols are
// link-required but runtime-unreachable from R in library mode — not obsolete scaffolding.

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/sys/Ui.h"
#include "praat.github.io/sys/Interpreter.h"

// Library-mode stubs for UiForm functions (GUI-only, never executed from R)
// see lines 26-34 for full explanation of why these are link-required but unreachable
// Whole file excluded from coverage measurement via .covrignore (see repo root).

// ============================================================================
// UiField creation (from Ui.cpp)
// ============================================================================

Thing_implement (UiField, Thing, 0);
Thing_implement (UiOption, Thing, 0);
Thing_implement (UiForm, Thing, 0);

// Required virtual function implementation to generate vtable
void structUiForm :: v9_destroy () noexcept {
    // No GUI dialog to destroy in library mode
    our UiForm_Parent :: v9_destroy ();
}

static autoUiField UiField_create (_kUiField_type type, conststring32 labelTextOrNull) {
    autoUiField me = Thing_new (UiField);
    my type = type;
    if (labelTextOrNull) {
        my labelText = Melder_dup (labelTextOrNull);
        char32 shortName [1+100], *p;
        str32ncpy (shortName, labelTextOrNull, 100);
        shortName [100] = U'\0';
        if (!! (p = (char32 *) str32chr (shortName, U'('))) {
            *p = U'\0';
            if (p - shortName > 0 && p [-1] == U' ')
                p [-1] = U'\0';
        }
        p = shortName;
        if (*p != U'\0' && p [Melder_length (p) - 1] == U':')
            p [Melder_length (p) - 1] = U'\0';
        Thing_setName (me.get(), shortName);
    }
    return me;
}

static autoUiOption UiOption_create (conststring32 optionText) {
    autoUiOption me = Thing_new (UiOption);
    Thing_setName (me.get(), optionText);
    return me;
}

// ============================================================================
// UiForm creation (from Ui.cpp)
// ============================================================================

autoUiForm UiForm_create (GuiWindow /* parent */, Editor optionalEditor, conststring32 title,
    UiCallback okCallback, void *buttonClosure,
    conststring32 invokingButtonTitle, conststring32 helpTitle)
{
    autoUiForm me = Thing_new (UiForm);
    my d_dialogParent = nullptr;  // No GUI parent in library mode
    my optionalEditor = optionalEditor;
    Thing_setName (me.get(), title);
    my okCallback = okCallback;
    my buttonClosure = buttonClosure;
    my invokingButtonTitle = Melder_dup (invokingButtonTitle);
    my helpTitle = Melder_dup (helpTitle);
    return me;
}

void UiForm_finish (UiForm /* me */) {
    // No-op in library mode - no GUI to finalize
}

// ============================================================================
// UiForm field addition (from Ui.cpp)
// ============================================================================

static UiField UiForm_addField (UiForm me, _kUiField_type type, conststring32 labelText) {
    if (my numberOfFields == MAXIMUM_NUMBER_OF_FIELDS)
        Melder_throw (U"Cannot have more than ", MAXIMUM_NUMBER_OF_FIELDS, U" fields in a form.");
    my field [++ my numberOfFields] = UiField_create (type, labelText);
    return my field [my numberOfFields].get();
}

UiField UiForm_addReal (UiForm me, double *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::REAL_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy realVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addRealOrUndefined (UiForm me, double *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::REAL_OR_UNDEFINED_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy realVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addPositive (UiForm me, double *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::POSITIVE_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy realVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addInteger (UiForm me, integer *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::INTEGER_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy integerVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addNatural (UiForm me, integer *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::NATURAL_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy integerVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addChannel (UiForm me, integer *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::CHANNEL_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy integerVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addWord (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::WORD_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addSentence (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::SENTENCE_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addText (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::TEXT_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addFormula (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::FORMULA_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addInfile (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::INFILE_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addOutfile (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::OUTFILE_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addFolder (UiForm me, conststring32 *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::FOLDER_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy stringVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addBoolean (UiForm me, bool *variable, conststring32 variableName,
    conststring32 labelText, bool defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::BOOLEAN_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy integerDefaultValue = defaultValue;
    thy boolVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addHeading (UiForm me, conststring32 *variable, conststring32 labelText) {
    UiField thee = UiForm_addField (me, _kUiField_type::HEADING_, U"");
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringVariable = variable;
    thy stringValue = Melder_dup (labelText);
    return thee;
}

UiField UiForm_addComment (UiForm me, conststring32 *variable, conststring32 labelText) {
    UiField thee = UiForm_addField (me, _kUiField_type::COMMENT_, U"");
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringVariable = variable;
    thy stringValue = Melder_dup (labelText);
    return thee;
}

UiField UiForm_addCaption (UiForm me, conststring32 *variable, conststring32 labelText) {
    UiField thee = UiForm_addField (me, _kUiField_type::CAPTION_, U"");
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringVariable = variable;
    thy stringValue = Melder_dup (labelText);
    return thee;
}

void UiForm_addLabel (UiForm me, conststring32 *variable, conststring32 labelText) {
    UiField thee = UiForm_addField (me, _kUiField_type::COMMENT_, U"");
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringVariable = variable;
    thy stringValue = Melder_dup (labelText);
}

UiOption UiForm_addOption (UiForm me, conststring32 optionText) {
    if (! me)
        return nullptr;
    UiField you = my referenceToLatestUsedChoiceOrOptionMenu;
    if (! you)
        return nullptr;
    Melder_assert (your type == _kUiField_type::CHOICE_ || your type == _kUiField_type::OPTIONMENU_);
    autoUiOption option = UiOption_create (optionText);
    return your options. addItem_move (option.move());
}

UiField UiForm_addChoice (UiForm me, int *intVariable, conststring32 *stringVariable, conststring32 variableName,
    conststring32 labelText, int defaultValue, int subtract)
{
    UiField thee = UiForm_addField (me, _kUiField_type::CHOICE_, labelText);
    thy intVariable = intVariable;
    thy stringVariable = stringVariable;
    thy variableName = variableName;
    thy integerDefaultValue = defaultValue;
    thy subtract = subtract;
    my referenceToLatestUsedChoiceOrOptionMenu = thee;
    return thee;
}

UiField UiForm_addOptionMenu (UiForm me, int *intVariable, conststring32 *stringVariable, conststring32 variableName,
    conststring32 labelText, int defaultValue, int subtract)
{
    UiField thee = UiForm_addField (me, _kUiField_type::OPTIONMENU_, labelText);
    thy intVariable = intVariable;
    thy stringVariable = stringVariable;
    thy variableName = variableName;
    thy integerDefaultValue = defaultValue;
    thy subtract = subtract;
    my referenceToLatestUsedChoiceOrOptionMenu = thee;
    return thee;
}

UiField UiForm_addChoiceEnum (UiForm me, int *intVariable, conststring32 *stringVariable, conststring32 variableName,
    conststring32 labelText, int defaultValue, int subtract, int (*getValueFunction) (conststring32))
{
    UiField thee = UiForm_addChoice (me, intVariable, stringVariable, variableName, labelText, defaultValue, subtract);
    thy getValueFunction = getValueFunction;
    return thee;
}

UiField UiForm_addOptionMenuEnum (UiForm me, int *intVariable, conststring32 *stringVariable, conststring32 variableName,
    conststring32 labelText, int defaultValue, int subtract, int (*getValueFunction) (conststring32))
{
    UiField thee = UiForm_addOptionMenu (me, intVariable, stringVariable, variableName, labelText, defaultValue, subtract);
    thy getValueFunction = getValueFunction;
    return thee;
}

void UiForm_addRadio (UiForm me, int *intVariable, conststring32 *stringVariable, conststring32 variableName,
    conststring32 labelText, int defaultValue, int subtract)
{
    UiForm_addChoice (me, intVariable, stringVariable, variableName, labelText, defaultValue, subtract);
}

UiField UiForm_addColour (UiForm me, MelderColour *variable, conststring32 variableName,
    conststring32 labelText, conststring32 defaultValue)
{
    UiField thee = UiForm_addField (me, _kUiField_type::COLOUR_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy colourVariable = variable;
    thy variableName = variableName;
    return thee;
}

UiField UiForm_addRealVector (UiForm me, constVEC *variable, conststring32 variableName,
    conststring32 labelText, kUi_realVectorFormat defaultFormat, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::REALVECTOR_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy realVectorDefaultFormat = defaultFormat;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy realVectorVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addPositiveVector (UiForm me, constVEC *variable, conststring32 variableName,
    conststring32 labelText, kUi_realVectorFormat defaultFormat, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::POSITIVEVECTOR_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy realVectorDefaultFormat = defaultFormat;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy realVectorVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addIntegerVector (UiForm me, constINTVEC *variable, conststring32 variableName,
    conststring32 labelText, kUi_integerVectorFormat defaultFormat, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::INTEGERVECTOR_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy integerVectorDefaultFormat = defaultFormat;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy integerVectorVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addNaturalVector (UiForm me, constINTVEC *variable, conststring32 variableName,
    conststring32 labelText, kUi_integerVectorFormat defaultFormat, conststring32 defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::NATURALVECTOR_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy integerVectorDefaultFormat = defaultFormat;
    thy stringDefaultValue = Melder_dup (defaultValue);
    thy integerVectorVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addRealMatrix (UiForm me, constMAT *variable, conststring32 variableName,
    conststring32 labelText, constMATVU defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::REALMATRIX_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy numericMatrixDefaultValue = copy_MAT (defaultValue);
    thy numericMatrixVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

UiField UiForm_addStringArray (UiForm me, constSTRVEC *variable, conststring32 variableName,
    conststring32 labelText, constSTRVEC defaultValue, integer numberOfLines)
{
    UiField thee = UiForm_addField (me, _kUiField_type::STRINGARRAY_, labelText);
    my referenceToLatestUsedChoiceOrOptionMenu = nullptr;
    thy stringArrayDefaultValue = copy_STRVEC (defaultValue);
    thy stringArrayVariable = variable;
    thy variableName = variableName;
    thy numberOfLines = Melder_clipped (1_integer, numberOfLines, 33_integer);
    return thee;
}

void UiForm_addList (UiForm me, integer *intVariable, conststring32 *stringVariable,
    conststring32 variableName, integer /* numberOfStrings */, conststring32 /* strings */ [])
{
    UiField thee = UiForm_addField (me, _kUiField_type::LIST_, U"");
    my referenceToLatestUsedChoiceOrOptionMenu = thee;
    thy integerVariable = intVariable;
    thy stringVariable = stringVariable;
    thy variableName = variableName;
    // Note: numberOfStrings and strings not stored in library mode
}

// ============================================================================
// Argument parsing (UiForm_call and UiForm_parseString)
// ============================================================================

static void UiField_argToValue (UiField me, Stackel arg, Interpreter /* interpreter */) {
    switch (my type)
    {
        case _kUiField_type::REAL_:
        case _kUiField_type::REAL_OR_UNDEFINED_:
        case _kUiField_type::POSITIVE_:
        {
            if (arg -> which != Stackel_NUMBER)
                Melder_throw (U"Argument '", my name.get(), U"' should be a number, not ", arg -> whichText(), U".");
            my realValue = arg -> number;
            if (isundef (my realValue) && my type != _kUiField_type::REAL_OR_UNDEFINED_)
                Melder_throw (U"Argument '", my name.get(), U"' has the value 'undefined'.");
            if (my type == _kUiField_type::POSITIVE_ && my realValue <= 0.0)
                Melder_throw (U"Argument '", my name.get(), U"' must be greater than 0.");
            if (my realVariable)
                *my realVariable = my realValue;
        }
        break;
        case _kUiField_type::INTEGER_:
        case _kUiField_type::NATURAL_:
        case _kUiField_type::CHANNEL_:
        {
            if (arg -> which == Stackel_STRING) {
                if (my type == _kUiField_type::CHANNEL_) {
                    if (str32equ (arg -> getString(), U"All") || str32equ (arg -> getString(), U"Average")) {
                        my integerValue = 0;
                    } else if (str32equ (arg -> getString(), U"Left") || str32equ (arg -> getString(), U"Mono")) {
                        my integerValue = 1;
                    } else if (str32equ (arg -> getString(), U"Right") || str32equ (arg -> getString(), U"Stereo")) {
                        my integerValue = 2;
                    } else {
                        Melder_throw (U"Channel argument '", my name.get(),
                            U"' can only be a number or one of the strings All, Average, Left, Right, Mono or Stereo.");
                    }
                } else {
                    Melder_throw (U"Argument '", my name.get(), U"' should be a number, not ", arg -> whichText(), U".");
                }
            } else if (arg -> which == Stackel_NUMBER) {
                double realValue = arg -> number;
                my integerValue = Melder_iround (realValue);
                Melder_require (my integerValue == realValue,
                    U"Argument '", my name.get(), U"' should be a whole number.");
                if (my type == _kUiField_type::NATURAL_ && my integerValue < 1)
                    Melder_throw (U"Argument '", my name.get(), U"' should be a positive whole number.");
            } else {
                Melder_throw (U"Argument '", my name.get(), U"' should be a number, not ", arg -> whichText(), U".");
            }
            if (my integerVariable)
                *my integerVariable = my integerValue;
        }
        break;
        case _kUiField_type::WORD_:
        case _kUiField_type::SENTENCE_:
        case _kUiField_type::TEXT_:
        case _kUiField_type::FORMULA_:
        case _kUiField_type::INFILE_:
        case _kUiField_type::OUTFILE_:
        case _kUiField_type::FOLDER_:
        {
            if (arg -> which != Stackel_STRING)
                Melder_throw (U"Argument '", my name.get(), U"' should be a string, not ", arg -> whichText(), U".");
            my stringValue = Melder_dup (arg -> getString());
            if (my stringVariable)
                *my stringVariable = my stringValue.get();
        }
        break;
        case _kUiField_type::REALVECTOR_:
        case _kUiField_type::POSITIVEVECTOR_:
        {
            if (arg -> which != Stackel_NUMERIC_VECTOR && arg -> which != Stackel_STRING)
                Melder_throw (U"Argument '", my name.get(), U"' should be a numeric vector, not ", arg -> whichText(), U".");
            if (arg -> which == Stackel_STRING) {
                my realVectorValue = splitByWhitespace_VEC (arg -> getString());
            } else {
                my realVectorValue = copy_VEC (arg -> numericVector);
            }
            if (my type == _kUiField_type::POSITIVEVECTOR_)
                for (integer i = 1; i <= my realVectorValue.size; i ++)
                    if (my realVectorValue [i] <= 0.0)
                        Melder_throw (U"Element ", i, U" of vector '", my name.get(), U"' is ", my realVectorValue [i], U" but should be greater than 0.0.");
            if (my realVectorVariable)
                *my realVectorVariable = my realVectorValue.get();
        }
        break;
        case _kUiField_type::INTEGERVECTOR_:
        case _kUiField_type::NATURALVECTOR_:
        {
            if (arg -> which != Stackel_NUMERIC_VECTOR && arg -> which != Stackel_STRING)
                Melder_throw (U"Argument '", my name.get(), U"' should be a numeric vector, not ", arg -> whichText(), U".");
            if (arg -> which == Stackel_STRING) {
                my integerVectorValue = splitByWhitespaceWithRanges_INTVEC (arg -> getString());
            } else {
                my integerVectorValue = raw_INTVEC (arg -> numericVector.size);
                for (integer i = 1; i <= arg -> numericVector.size; i ++) {
                    my integerVectorValue [i] = Melder_iround (arg -> numericVector [i]);
                    Melder_require (my integerVectorValue [i] == arg -> numericVector [i],
                        U"Element ", i, U" of vector '", my name.get(), U"' is ", arg -> numericVector [i], U" but should be a whole number.");
                }
            }
            if (my type == _kUiField_type::NATURALVECTOR_)
                for (integer i = 1; i <= my integerVectorValue.size; i ++)
                    if (my integerVectorValue [i] <= 0)
                        Melder_throw (U"Element ", i, U" of vector '", my name.get(), U"' is ", my integerVectorValue [i], U" but should be greater than 0.");
            if (my integerVectorVariable)
                *my integerVectorVariable = my integerVectorValue.get();
        }
        break;
        case _kUiField_type::STRINGARRAY_:
        {
            if (arg -> which != Stackel_STRING_ARRAY && arg -> which != Stackel_STRING)
                Melder_throw (U"Argument '", my name.get(), U"' should be a string array, not ", arg -> whichText(), U".");
            if (arg -> which == Stackel_STRING) {
                my stringArrayValue = splitByWhitespace_STRVEC (arg -> getString());
            } else {
                my stringArrayValue = copy_STRVEC (arg -> stringArray);
            }
            if (my stringArrayVariable)
                *my stringArrayVariable = my stringArrayValue.get();
        }
        break;
        case _kUiField_type::BOOLEAN_:
        {
            if (arg -> which == Stackel_STRING) {
                conststring32 s = arg -> getString();
                if (str32equ (s, U"1") || str32equ (s, U"yes") || str32equ (s, U"on") ||
                    str32equ (s, U"Yes") || str32equ (s, U"On") ||
                    str32equ (s, U"YES") || str32equ (s, U"ON") ||
                    str32equ (s, U"true") || str32equ (s, U"True") || str32equ (s, U"TRUE"))
                    my integerValue = 1;
                else if (str32equ (s, U"0") || str32equ (s, U"no") || str32equ (s, U"off") ||
                    str32equ (s, U"No") || str32equ (s, U"Off") ||
                    str32equ (s, U"NO") || str32equ (s, U"OFF") ||
                    str32equ (s, U"false") || str32equ (s, U"False") || str32equ (s, U"FALSE"))
                    my integerValue = 0;
                else
                    Melder_throw (U"Boolean argument '", my name.get(), U"' should be yes or no, not '", s, U"'.");
            } else if (arg -> which == Stackel_NUMBER) {
                my integerValue = (arg -> number != 0.0);
            } else {
                Melder_throw (U"Argument '", my name.get(), U"' should be a number or string, not ", arg -> whichText(), U".");
            }
            if (my boolVariable)
                *my boolVariable = my integerValue;
        }
        break;
        case _kUiField_type::CHOICE_:
        case _kUiField_type::OPTIONMENU_:
        {
            if (arg -> which == Stackel_STRING) {
                conststring32 string = arg -> getString();
                if (my getValueFunction) {
                    int value = my getValueFunction (string);
                    my integerValue = (value == -1) ? 0 : value + my subtract;
                } else {
                    my integerValue = 0;
                    for (int i = 1; i <= my options.size; i ++) {
                        UiOption b = my options.at [i];
                        if (str32equ (string, b -> name.get()))
                            my integerValue = i;
                    }
                    if (my integerValue == 0) {
                        for (int i = 1; i <= my options.size; i ++) {
                            UiOption b = my options.at [i];
                            if (Melder_equ_firstCharacterCaseInsensitive (string, b -> name.get()))
                                my integerValue = i;
                        }
                    }
                }
                if (my integerValue == 0)
                    Melder_throw (U"Field '", my name.get(), U"' must not have the value '", string, U"'.");
            } else if (arg -> which == Stackel_NUMBER) {
                my integerValue = Melder_iround (arg -> number);
            } else {
                Melder_throw (U"Argument '", my name.get(), U"' should be a string or number, not ", arg -> whichText(), U".");
            }
            if (my intVariable)
                *my intVariable = int (my integerValue) - my subtract;
            if (my stringVariable && my integerValue >= 1 && my integerValue <= my options.size)
                *my stringVariable = my options.at [my integerValue] -> name.get();
        }
        break;
        case _kUiField_type::REALMATRIX_:
        {
            if (arg -> which != Stackel_NUMERIC_MATRIX)
                Melder_throw (U"Argument '", my name.get(), U"' should be a numeric matrix, not ", arg -> whichText(), U".");
            my numericMatrixValue = copy_MAT (arg -> numericMatrix);
            if (my numericMatrixVariable)
                *my numericMatrixVariable = my numericMatrixValue.get();
        }
        break;
        default:
            break;
    }
}

void UiForm_call (UiForm me, integer narg, Stackel args, Interpreter interpreter) {
    integer size = my numberOfFields, iarg = 0;
    for (integer ifield = 1; ifield <= size; ifield ++) {
        if (_kUiField_type_isComment (my field [ifield] -> type))
            continue;
        iarg ++;
        if (iarg > narg)
            Melder_throw (U"Command requires more than the given ", narg, U" arguments: argument '", my field [ifield] -> name.get(), U"' not given.");
        UiField_argToValue (my field [ifield].get(), & args [iarg], interpreter);
    }
    if (iarg < narg)
        Melder_throw (U"Command requires only ", iarg, U" arguments, not the ", narg, U" given.");
    my okCallback (me, 0, nullptr, nullptr, interpreter, nullptr, false, my buttonClosure, my optionalEditor);
}

static void UiField_stringToValue (UiField me, conststring32 string, Interpreter interpreter) {
    switch (my type)
    {
        case _kUiField_type::REAL_:
        case _kUiField_type::REAL_OR_UNDEFINED_:
        case _kUiField_type::POSITIVE_:
        {
            if (str32spn (string, U" \t") == Melder_length (string))
                Melder_throw (U"Argument '", my name.get(), U"' empty.");
            Interpreter_numericExpression (interpreter, string, & my realValue);
            if (isundef (my realValue) && my type != _kUiField_type::REAL_OR_UNDEFINED_)
                Melder_throw (U"'", my name.get(), U"' has the value 'undefined'.");
            if (my type == _kUiField_type::POSITIVE_ && my realValue <= 0.0)
                Melder_throw (U"'", my name.get(), U"' must be greater than 0.");
            if (my realVariable)
                *my realVariable = my realValue;
        }
        break;
        case _kUiField_type::INTEGER_:
        case _kUiField_type::NATURAL_:
        case _kUiField_type::CHANNEL_: {
            if (str32spn (string, U" \t") == Melder_length (string))
                Melder_throw (U"Argument '", my name.get(), U"' empty.");
            if (my type == _kUiField_type::CHANNEL_ && (str32equ (string, U"All") || str32equ (string, U"Average"))) {
                my integerValue = 0;
            } else if (my type == _kUiField_type::CHANNEL_ && (str32equ (string, U"Left") || str32equ (string, U"Mono"))) {
                my integerValue = 1;
            } else if (my type == _kUiField_type::CHANNEL_ && (str32equ (string, U"Right") || str32equ (string, U"Stereo"))) {
                my integerValue = 2;
            } else {
                double realValue;
                Interpreter_numericExpression (interpreter, string, & realValue);
                my integerValue = Melder_iround (realValue);
            }
            if (my type == _kUiField_type::NATURAL_ && my integerValue < 1)
                Melder_throw (U"'", my name.get(), U"' should be a positive whole number.");
            if (my integerVariable)
                *my integerVariable = my integerValue;
        }
        break;
        case _kUiField_type::WORD_:
        case _kUiField_type::SENTENCE_:
        case _kUiField_type::TEXT_:
        case _kUiField_type::FORMULA_:
        case _kUiField_type::INFILE_:
        case _kUiField_type::OUTFILE_:
        case _kUiField_type::FOLDER_:
        {
            my stringValue = Melder_dup (string);
            if (my stringVariable)
                *my stringVariable = my stringValue.get();
        }
        break;
        case _kUiField_type::BOOLEAN_:
        {
            if (! string [0])
                Melder_throw (U"Empty argument for toggle button.");
            my integerValue = string [0] == U'1' || string [0] == U'y' || string [0] == U'Y' ||
                string [0] == U't' || string [0] == U'T';
            if (my boolVariable)
                *my boolVariable = my integerValue;
        }
        break;
        case _kUiField_type::CHOICE_:
        case _kUiField_type::OPTIONMENU_:
        {
            if (my getValueFunction) {
                int value = my getValueFunction (string);
                my integerValue = (value == -1) ? 0 : value + my subtract;
            } else {
                my integerValue = 0;
                for (int i = 1; i <= my options.size; i ++) {
                    UiOption b = my options.at [i];
                    if (str32equ (string, b -> name.get()))
                        my integerValue = i;
                }
                if (my integerValue == 0) {
                    for (int i = 1; i <= my options.size; i ++) {
                        UiOption b = my options.at [i];
                        if (Melder_equ_firstCharacterCaseInsensitive (string, b -> name.get()))
                            my integerValue = i;
                    }
                }
            }
            if (my integerValue == 0)
                Melder_throw (U"Field '", my name.get(), U"' must not have the value '", string, U"'.");
            if (my intVariable)
                *my intVariable = int (my integerValue) - my subtract;
            if (my stringVariable && my integerValue >= 1 && my integerValue <= my options.size)
                *my stringVariable = my options.at [my integerValue] -> name.get();
        }
        break;
        default:
            break;
    }
}

void UiForm_parseString (UiForm me, conststring32 arguments, Interpreter interpreter) {
    integer size = my numberOfFields;
    const char32 *p = arguments;

    for (integer ifield = 1; ifield <= size; ifield ++) {
        if (_kUiField_type_isComment (my field [ifield] -> type))
            continue;

        while (*p == U' ' || *p == U'\t') p++;
        if (*p == U'\0')
            break;

        const char32 *start = p;
        bool inQuotes = (*p == U'"');
        if (inQuotes) {
            start = ++p;
            while (*p && *p != U'"') p++;
        } else {
            while (*p && *p != U',' && *p != U' ' && *p != U'\t') p++;
        }

        autostring32 arg = Melder_dup (start);
        arg [p - start] = U'\0';

        if (inQuotes && *p == U'"') p++;
        while (*p == U' ' || *p == U'\t') p++;
        if (*p == U',') p++;

        UiField_stringToValue (my field [ifield].get(), arg.get(), interpreter);
    }

    my okCallback (me, 0, nullptr, nullptr, interpreter, nullptr, false, my buttonClosure, my optionalEditor);
}

/* End of uiform_libmode.cpp */
