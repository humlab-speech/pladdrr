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
 * praat_fixed_buttons_libmode.cpp
 *
 * Library-mode versions of Praat's fixed-button commands (Rename..., Copy...,
 * Info, Remove) from praat_objectMenus.cpp. Without them a script line such as
 * `Rename: "x"` fails with "Command not available for current selection",
 * because the GUI file that registers them is not compiled. Callback bodies are
 * copied from upstream; "Inspect" needs a DataEditor GUI and is omitted.
 */

#include "praatP.h"
#include "praatM.h"

#define EDITOR  theCurrentPraatObjects -> list [IOBJECT]. editors

DIRECT (PRAAT_Remove) {
	WHERE_DOWN (SELECTED)
		praat_removeObject (IOBJECT);
	praat_show ();
	END_NO_NEW_DATA
}

FORM (MODIFY_Rename, U"Rename object", U"Rename...") {
	TEXTFIELD (newName, U"New name", U"", 3)
OK
	WHERE (SELECTED)
		SET_STRING (newName, NAME)
DO
	if (theCurrentPraatObjects -> totalSelection == 0)
		Melder_throw (U"Selection changed!\nNo object selected. Cannot rename.");
	if (theCurrentPraatObjects -> totalSelection > 1)
		Melder_throw (U"Selection changed!\nCannot rename more than one object at a time.");
	WHERE (SELECTED)
		break;
	static MelderString string;
	MelderString_copy (& string, newName);
	praat_cleanUpName (string.string);
	static MelderString fullName;
	MelderString_copy (& fullName, Thing_className (OBJECT), U" ", string.string);
	if (! str32equ (fullName.string, FULL_NAME)) {
		theCurrentPraatObjects -> list [IOBJECT]. name = Melder_dup_f (fullName.string);
		autoMelderString listName;
		MelderString_append (& listName, ID, U". ", fullName.string);
		praat_list_renameAndSelect (IOBJECT, listName.string);
		for (int ieditor = 0; ieditor < praat_MAXNUM_EDITORS; ieditor ++)
			if (EDITOR [ieditor])
				Thing_setName (EDITOR [ieditor], listName.string);
		Thing_setName (OBJECT, string.string);
	}
	END_NO_NEW_DATA
}

FORM (NEW1_Copy, U"Copy object", U"Copy...") {
	TEXTFIELD (newName, U"Name of new object", U"", 3)
OK
	WHERE (SELECTED)
		SET_STRING (newName, NAME)
DO
	if (theCurrentPraatObjects -> totalSelection == 0)
		Melder_throw (U"Selection changed!\nNo object selected. Cannot copy.");
	if (theCurrentPraatObjects -> totalSelection > 1)
		Melder_throw (U"Selection changed!\nCannot copy more than one object at a time.");
	if (interpreter)
		interpreter -> returnType = kInterpreter_ReturnType::OBJECT_;
	WHERE (SELECTED)
		praat_new (Data_copy ((Daata) OBJECT), newName);
	END_WITH_NEW_DATA
}

DIRECT (INFO_Info) {
	INFO_NONE
		if (theCurrentPraatObjects -> totalSelection == 0)
			Melder_throw (U"Selection changed!\nNo object selected. Cannot query.");
		if (theCurrentPraatObjects -> totalSelection > 1)
			Melder_throw (U"Selection changed!\nCannot query more than one object at a time.");
		WHERE (SELECTED) Thing_infoWithIdAndFile (OBJECT, ID, & theCurrentPraatObjects -> list [IOBJECT]. file);
	INFO_NONE_END
}


void praat_addFixedButtons (GuiWindow window) {
	praat_addFixedButtonCommand (window, U"Rename...", MODIFY_Rename, 8, 70);
	praat_addFixedButtonCommand (window, U"Copy...", NEW1_Copy, 98, 70);
	praat_addFixedButtonCommand (window, U"Info", INFO_Info, 98, 40);
	praat_addFixedButtonCommand (window, U"Remove", PRAAT_Remove, 8, 10);
}

/* End of praat_fixed_buttons_libmode.cpp */
