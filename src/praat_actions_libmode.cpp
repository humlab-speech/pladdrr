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
 * praat_actions_libmode.cpp
 *
 * Minimal library-mode implementation of Praat's action system.
 * Provides action registration (praat_addAction*) and dispatch (praat_doAction)
 * without GUI dependencies.
 *
 * This replaces the full praat_actions.cpp and praat_menuCommands.cpp
 * which have heavy GUI/menu dependencies.
 */

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/sys/praatP.h"
#include "praat.github.io/sys/praat.h"

// Forward declarations for GUI types (not used in library mode)
struct structGuiWindow;
struct structGuiMenuItem;
typedef structGuiMenuItem *GuiMenuItem;

// Static storage for registered actions
static OrderedOf<structPraat_Command> theActions;
static OrderedOf<structPraat_Command> theCommands;

// Exit optimization (prevent cleanup on exit)
void praat_actions_exit_optimizeByLeaking () {
    theActions._ownItems = false;
}

void praat_menuCommands_exit_optimizeByLeaking () {
    theCommands._ownItems = false;
}

// Forward/background mode (no-op in library mode)
void praat_background () { /* No-op */ }
void praat_foreground () { /* No-op */ }

// Sorting actions (no-op in library mode, no menus to sort)
void praat_sortActions () { /* No-op */ }
void praat_sortMenuCommands () { /* No-op */ }

// Save/restore actions (no-op in library mode)
void praat_saveAddedActions (MelderString *) { /* No-op */ }
void praat_saveToggledActions (MelderString *) { /* No-op */ }
void praat_saveAddedMenuCommands (MelderString *) { /* No-op */ }
void praat_saveToggledMenuCommands (MelderString *) { /* No-op */ }

// Menu system stubs
void praat_actions_show () { /* No-op */ }
void praat_actions_createDynamicMenu (structGuiWindow *) { /* No-op */ }

// Find position in action list
static integer lookupAction (ClassInfo class1, integer n1, ClassInfo class2, integer n2,
                             ClassInfo class3, integer n3, ClassInfo class4, integer n4,
                             conststring32 title) {
    for (integer i = 1; i <= theActions.size; i++) {
        Praat_Command action = theActions.at[i];
        if (action->class1 == class1 && action->n1 == n1 &&
            action->class2 == class2 && action->n2 == n2 &&
            action->class3 == class3 && action->n3 == n3 &&
            action->class4 == class4 && action->n4 == n4 &&
            str32equ(action->title.get(), title)) {
            return i;
        }
    }
    return 0;
}

// Core action registration implementation - called by praat_addAction4_
static void praat_addAction4_internal (ClassInfo class1, integer n1, ClassInfo class2, integer n2,
    ClassInfo class3, integer n3, ClassInfo class4, integer n4,
    conststring32 title, conststring32 /*after*/, uint32 flags,
    UiCallback callback, conststring32 /*nameOfCallback*/)
{
    // Skip if already registered or null title
    if (!title || !title[0])
        return;
    if (lookupAction(class1, n1, class2, n2, class3, n3, class4, n4, title))
        return;

    // Parse depth from flags
    uint32 depth = (flags > 7) ? ((flags & 0x00070000) >> 16) : flags;

    // Create new action entry
    autoPraat_Command action = Thing_new(Praat_Command);
    action->class1 = class1;
    action->n1 = n1;
    action->class2 = class2;
    action->n2 = n2;
    action->class3 = class3;
    action->n3 = n3;
    action->class4 = class4;
    action->n4 = n4;
    action->title = Melder_dup(title);
    action->depth = depth;
    action->callback = callback;
    action->executable = (callback != nullptr);  // Executable if has callback
    action->visible = true;

    // Add to list
    theActions.addItem_move(action.move());
}

// Public registration functions matching praat.h signatures
void praat_addAction1_ (ClassInfo class1, integer n1,
    conststring32 title, conststring32 after, uint32 flags,
    UiCallback callback, conststring32 nameOfCallback)
{
    praat_addAction4_internal(class1, n1, nullptr, 0, nullptr, 0, nullptr, 0,
        title, after, flags, callback, nameOfCallback);
}

void praat_addAction2_ (ClassInfo class1, integer n1, ClassInfo class2, integer n2,
    conststring32 title, conststring32 after, uint32 flags,
    UiCallback callback, conststring32 nameOfCallback)
{
    praat_addAction4_internal(class1, n1, class2, n2, nullptr, 0, nullptr, 0,
        title, after, flags, callback, nameOfCallback);
}

void praat_addAction3_ (ClassInfo class1, integer n1, ClassInfo class2, integer n2,
    ClassInfo class3, integer n3,
    conststring32 title, conststring32 after, uint32 flags,
    UiCallback callback, conststring32 nameOfCallback)
{
    praat_addAction4_internal(class1, n1, class2, n2, class3, n3, nullptr, 0,
        title, after, flags, callback, nameOfCallback);
}

void praat_addAction4_ (ClassInfo class1, integer n1, ClassInfo class2, integer n2,
    ClassInfo class3, integer n3, ClassInfo class4, integer n4,
    conststring32 title, conststring32 after, uint32 flags,
    UiCallback callback, conststring32 nameOfCallback)
{
    // Handle title with separators (title1 || title2)
    const char32 *separator = str32str(title, U" || ");
    if (!separator) {
        praat_addAction4_internal(class1, n1, class2, n2, class3, n3, class4, n4,
            title, after, flags, callback, nameOfCallback);
        return;
    }

    // Split and register both titles
    if (flags < 8)
        flags *= 0x00010000;  // Convert 1..7 to proper depth flags

    integer separatorPos = separator - title;
    autostring32 title1 = Melder_dup(title);
    title1[separatorPos] = U'\0';

    praat_addAction4_internal(class1, n1, class2, n2, class3, n3, class4, n4,
        title1.get(), after, flags, callback, nameOfCallback);
    praat_addAction4_internal(class1, n1, class2, n2, class3, n3, class4, n4,
        separator + 4, after, flags, callback, nameOfCallback);
}

// Remove action
void praat_removeAction (ClassInfo class1, ClassInfo class2, ClassInfo class3, conststring32 title) {
    integer found = lookupAction(class1, 0, class2, 0, class3, 0, nullptr, 0, title);
    if (found)
        theActions.removeItem(found);
}

// Action dispatch - the key function for script execution

// pladdrr: dispatch an action only when the current selection matches the
// action's class signature. Upstream Praat filters by the selected objects'
// classes; the previous title-only matching dispatched the FIRST action with
// the requested title regardless of the selection — for titles registered on
// several classes (e.g. "To Matrix" on PointProcess/Cochleagram/Harmonicity/
// Ltas/Pitch/Spectrogram/...) that ran the wrong callback on the selected
// object and segfaulted (e.g. PointProcess_to_Matrix on a Spectrogram).
static bool actionMatchesSelection (Praat_Command action) {
	ClassInfo classes [4] = { action->class1, action->class2, action->class3, action->class4 };
	integer required [4] = { action->n1, action->n2, action->n3, action->n4 };
	// Collect the classes of the selected objects, in object-list order.
	ClassInfo selectedClasses [4] = { nullptr, nullptr, nullptr, nullptr };
	integer nSelected = 0;
	for (integer i = 1; i <= theCurrentPraatObjects -> n; i ++)
		if (theCurrentPraatObjects -> list [i].isSelected) {
			if (nSelected < 4)
				selectedClasses [nSelected] = theCurrentPraatObjects -> list [i].klas;
			nSelected ++;
		}
	// No class constraint: matches any selection.
	bool anyClassSet = false;
	for (int k = 0; k < 4; k ++)
		if (classes [k])
			anyClassSet = true;
	if (! anyClassSet)
		return true;
	// Every selected object must belong to one of the action's classes.
	for (integer i = 0; i < nSelected; i ++) {
		bool ok = false;
		for (int k = 0; k < 4; k ++)
			if (classes [k] && selectedClasses [i] == classes [k])
				ok = true;
		if (! ok)
			return false;
	}
	// For each class with a required count > 0, the selection must match exactly.
	for (int k = 0; k < 4; k ++) {
		if (! classes [k] || required [k] == 0)
			continue;
		integer count = 0;
		for (integer i = 0; i < nSelected; i ++)
			if (selectedClasses [i] == classes [k])
				count ++;
		if (count != required [k])
			return false;
	}
	return true;
}

int praat_doAction (conststring32 title, conststring32 arguments, Interpreter interpreter) {
    for (integer i = 1; i <= theActions.size; i++) {
        Praat_Command action = theActions.at[i];
        if (action->executable && str32equ(action->title.get(), title) && actionMatchesSelection(action)) {
            // Found the action - call its callback
            action->callback(nullptr, 0, nullptr, arguments, interpreter, title, false, nullptr, nullptr);
            return 1;  // Success
        }
    }
    return 0;  // Not found
}

int praat_doAction (conststring32 title, integer narg, Stackel args, Interpreter interpreter) {
    for (integer i = 1; i <= theActions.size; i++) {
        Praat_Command action = theActions.at[i];
        if (action->executable && str32equ(action->title.get(), title) && actionMatchesSelection(action)) {
            // Found the action - call its callback
            action->callback(nullptr, narg, args, nullptr, interpreter, title, false, nullptr, nullptr);
            return 1;  // Success
        }
    }
    return 0;  // Not found
}

// Get action info (for introspection)
integer praat_getNumberOfActions () {
    return theActions.size;
}

Praat_Command praat_getAction (integer i) {
    return (i < 1 || i > theActions.size) ? nullptr : theActions.at[i];
}

// Menu command registration - matching praat.h signature
static integer lookupCommand (conststring32 window, conststring32 menu, conststring32 title) {
    for (integer i = 1; i <= theCommands.size; i++) {
        Praat_Command command = theCommands.at[i];
        if (str32equ(command->window.get(), window) &&
            str32equ(command->menu.get(), menu) &&
            str32equ(command->title.get(), title)) {
            return i;
        }
    }
    return 0;
}

GuiMenuItem praat_addMenuCommand_ (conststring32 window, conststring32 menu, conststring32 title,
    conststring32 /*after*/, uint32 flags, UiCallback callback, conststring32 /*nameOfCallback*/)
{
    // Skip if null or already registered
    if (!title || !title[0])
        return nullptr;
    if (lookupCommand(window, menu, title))
        return nullptr;

    // Parse depth from flags
    uint32 depth = (flags > 7) ? ((flags & 0x00070000) >> 16) : flags;

    // Create new command entry
    autoPraat_Command command = Thing_new(Praat_Command);
    command->window = Melder_dup(window);
    command->menu = Melder_dup(menu);
    command->title = Melder_dup(title);
    command->depth = depth;
    command->callback = callback;
    command->executable = (callback != nullptr);
    command->visible = true;

    theCommands.addItem_move(command.move());

    return nullptr;  // No GUI menu item in library mode
}

// Menu command dispatch
int praat_doMenuCommand (conststring32 title, conststring32 arguments, Interpreter interpreter) {
    for (integer i = 1; i <= theCommands.size; i++) {
        Praat_Command command = theCommands.at[i];
        if (command->executable && str32equ(command->title.get(), title) && actionMatchesSelection(command)) {
            command->callback(nullptr, 0, nullptr, arguments, interpreter, title, false, nullptr, nullptr);
            return 1;
        }
    }
    return 0;
}

int praat_doMenuCommand (conststring32 title, integer narg, Stackel args, Interpreter interpreter) {
    for (integer i = 1; i <= theCommands.size; i++) {
        Praat_Command command = theCommands.at[i];
        if (command->executable && str32equ(command->title.get(), title) && actionMatchesSelection(command)) {
            command->callback(nullptr, narg, args, nullptr, interpreter, title, false, nullptr, nullptr);
            return 1;
        }
    }
    return 0;
}

// Menu command introspection
integer praat_getNumberOfMenuCommands () {
    return theCommands.size;
}

Praat_Command praat_getMenuCommand (integer i) {
    return (i < 1 || i > theCommands.size) ? nullptr : theCommands.at[i];
}

// Add commands to editor (no-op in library mode)
void praat_addCommandsToEditor (Editor) { /* No-op */ }

/* End of praat_actions_libmode.cpp */
