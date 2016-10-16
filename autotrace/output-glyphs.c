/* output-glyphs.c: utility routines for Glyphs output. 

Copyright (C) 2015 Georg Seifert.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation; either version 2.1 of
the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA. */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* Def: HAVE_CONFIG_H */

#include "spline.h"
#include "color.h"
#include "output-glyphs.h"

static void out_splines (FILE * file, spline_list_array_type shape, int height) {
	unsigned this_list;
	spline_list_type list;
	color_type last_color = {0,0,0};
	fputs("(\n", file);
	for (this_list = 0; this_list < SPLINE_LIST_ARRAY_LENGTH (shape); this_list++) {
		unsigned this_spline;
		spline_type first;
		
		list = SPLINE_LIST_ARRAY_ELT (shape, this_list);
		first = SPLINE_LIST_ELT (list, 0);
		
		if (this_list > 0) {
			fputs("\t\t);\n", file);
			if (!(shape.centerline || list.open)) {
				fputs("\t\tclosed = 1;\n", file);
			}
			fputs("\t},\n", file);
		}
		fputs("\t{\n\t\tnodes = (\n", file);
		fprintf(file, "\t\t\t\"%g %g LINE\",\n", START_POINT(first).x, height - START_POINT(first).y);
		for (this_spline = 0; this_spline < SPLINE_LIST_LENGTH (list); this_spline++) {
			spline_type s = SPLINE_LIST_ELT (list, this_spline);
			
			if (SPLINE_DEGREE(s) == LINEARTYPE) {
				fprintf(file, "\t\t\t\"%g %g LINE\",\n", END_POINT(s).x, height - END_POINT(s).y);
			}
			else {
				fprintf(file, "\t\t\t\"%g %g OFFCURVE\",\n\t\t\t\"%g %g OFFCURVE\",\n\t\t\t\"%g %g CURVE\",\n",
						CONTROL1(s).x, height - CONTROL1(s).y,
						CONTROL2(s).x, height - CONTROL2(s).y,
						END_POINT(s).x, height - END_POINT(s).y);
			}
			last_color = list.color;
		}
	}
	if (SPLINE_LIST_ARRAY_LENGTH(shape) > 0) {
		fputs("\t\t);\n", file);
	}
	if (!(shape.centerline || list.open)) {
		if (!(shape.centerline || list.open)) {
			fputs("\t\tclosed = 1;\n", file);
		}
	}
	if (SPLINE_LIST_ARRAY_LENGTH(shape) > 0) {
		fputs("\t}\n", file);
	}
	fputs(")\n", file);
}


int output_glyphs_writer(FILE* file, at_string name,
	int llx, int lly, int urx, int ury, 
	at_output_opts_type * opts,
	spline_list_array_type shape,
	at_msg_func msg_func, 
	at_address msg_data)
{
	int height = ury - lly;
	file = stdout;
	out_splines(file, shape, height);

	return 0;
}