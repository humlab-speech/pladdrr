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
// GLPK (GNU Linear Programming Kit) stubs
// These functions are not available in this build

#include "melder/melder.h"

extern "C" {

void glp_add_cols (void*, int) {}
void glp_add_rows (void*, int) {}
void glp_set_col_bnds (void*, int, int, double, double) {}
void glp_set_row_bnds (void*, int, int, double, double) {}
void glp_set_obj_coef (void*, int, double) {}
void glp_set_obj_dir (void*, int) {}
void glp_set_mat_row (void*, int, int, int const*, double const*) {}
void glp_set_mat_col (void*, int, int, int const*, double const*) {}
int glp_simplex (void*, void*) { return 0; }
double glp_get_col_prim (void*, int) { return 0.0; }
double glp_get_obj_val (void*) { return 0.0; }
void* glp_create_prob () { return nullptr; }
void glp_delete_prob (void*) {}
void glp_init_smcp (void*) {}
int glp_get_status (void*) { return 0; }
int glp_get_num_rows (void*) { return 0; }
int glp_get_num_cols (void*) { return 0; }
void glp_load_matrix (void*, int, int const*, int const*, double const*) {}

}
