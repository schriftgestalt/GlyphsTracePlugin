/* Copyright (C) 2001-2015 Georg Seifert, Peter Selinger.
It is free software and it is covered
by the GNU General Public License. See the file COPYING for details. */

/* The Glyphs backend of Potrace. */

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>

#include "potracelib.h"
#include "curve.h"
#include "main.h"
#include "backend_Glyphs.h"
#include "lists.h"
#include "auxiliary.h"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

/* ---------------------------------------------------------------------- */
/* path-drawing auxiliary functions */

/* coordinate quantization */
// static inline point_t unit(dpoint_t p) {
// 	point_t q;
// 	q.x = (long)(floor(p.x*info.unit+.5));
// 	q.y = (long)(floor(p.y*info.unit+.5));
// 	return q;
// }

// static point_t cur;
static char lastop = 0;
// static int column = 0;
static int newline = 1;

// static void shiptoken(FILE *fout, char *token) {
// 	int c = strlen(token);
// 	if (!newline && column+c+1 > 75) {
// 		print( "\n");
// 		column = 0;
// 		newline = 1;
// 	} else if (!newline) {
// 		print( " ");
// 		column++;
// 	}
// 	print( "%s", token);
// 	column += c;
// 	newline = 0;
// }

// static void ship(FILE *fout, char *fmt, ...) {
// 	va_list args;
// 	static char buf[4096]; /* static string limit is okay here because
// 	we only use constant format strings - for
// 	the same reason, it is okay to use
// 	vsprintf instead of vsnprintf below. */
// 	char *p, *q;
//
// va_start(args, fmt);
// vsprintf(buf, fmt, args);
// buf[4095] = 0;
// va_end(args);
//
// p = buf;
// while ((q = strchr(p, ' ')) != NULL) {
// 	*q = 0;
// 	shiptoken(fout, p);
// 	p = q+1;
// }
// shiptoken(fout, p);
// }

static void Glyphs_moveto(FILE *fout, dpoint_t p) {
	// p = unit(p);
	if (lastop != '0') {
		fprintf(fout, "		);\n	},\n");
	}
	fprintf(fout, "	{\n		closed = 1;\n		nodes = (\n");
	fprintf(fout, "			\"%.3f %.3f LINE\",\n", p.x, p.y);
	lastop = 'M';
}

static void Glyphs_rmoveto(FILE *fout, dpoint_t p) {
	// point_t q;

	// q = unit(p);
	if (lastop != '0') {
		fprintf(fout, "		);\n	},\n");
	}

	fprintf(fout, "	{\n		closed = 1;\n		nodes = (\n");
	fprintf(fout, "			\"%.3f %.3f LINE\",\n", p.x, p.y);
	// cur = q;
	lastop = 'm';
}

static void Glyphs_lineto(FILE *fout, dpoint_t p) {
	// point_t q;

	// q = unit(p);
	fprintf(fout, "			\"%.3f %.3f LINE\",\n", p.x, p.y);
	// if (lastop != 'l') {
	// 	fprintf(fout, "l%.3f %.3f", p.x, p.y);
	// } else {
	// 	fprintf(fout, "%.3f %.3f", p.x, p.y);
	// }
	// cur = q;
	lastop = 'l';
}

static void Glyphs_curveto(FILE *fout, dpoint_t p1, dpoint_t p2, dpoint_t p3) {
	// point_t q1, q2, q3;

	// q1 = unit(p1);
	// q2 = unit(p2);
	// q3 = unit(p3);

	fprintf(fout, "			\"%.3f %.3f OFFCURVE\",\n			\"%.3f %.3f OFFCURVE\",\n		"
				  "	\"%.3f %.3f CURVE\",\n",
			p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
	// cur = q3;
	lastop = 'c';
}

/* ---------------------------------------------------------------------- */
/* functions for converting a path to an SVG path element */

/* Explicit encoding. If abs is set, move to first coordinate
absolutely. */
static int Glyphs_path(FILE *fout, potrace_curve_t *curve, int abs) {
	int i;
	dpoint_t *c;
	int m = curve->n;

	c = curve->c[m - 1];
	if (abs) {
		Glyphs_moveto(fout, c[2]);
	} else {
		Glyphs_rmoveto(fout, c[2]);
	}

	for (i = 0; i < m; i++) {
		c = curve->c[i];
		switch (curve->tag[i]) {
		case POTRACE_CORNER:
			Glyphs_lineto(fout, c[1]);
			Glyphs_lineto(fout, c[2]);
			break;
		case POTRACE_CURVETO:
			Glyphs_curveto(fout, c[0], c[1], c[2]);
			break;
		}
	}
	newline = 1;
	// shiptoken(fout, "z");
	return 0;
}

static void write_paths(FILE *fout, potrace_path_t *tree) {
	potrace_path_t *p, *q;

	for (p = tree; p; p = p->sibling) {
		//		column = print( "<path fill=\"#%06x\" stroke=\"none\" d=\"", info.color);
		//		newline = 1;
		//		lastop = 0;
		Glyphs_path(fout, &p->curve, 1);
		//		print( "\"/>\n");
		for (q = p->childlist; q; q = q->sibling) {
			Glyphs_path(fout, &q->curve, 1);
			//			print( "\"/>\n");
		}
		if (info.grouping == 2) {
			//			print( "</g>\n");
		}
		for (q = p->childlist; q; q = q->sibling) {
			write_paths(fout, q->childlist);
		}
		// if (info.grouping == 2) {
		// 	print( "</g>\n");
		// }
	}
}

/* ---------------------------------------------------------------------- */
/* Backend. */

/* public interface for SVG */
int page_Glyphs(FILE *fout, potrace_path_t *plist, imginfo_t *imginfo) {

	// double bboxx = imginfo->trans.bb[0]+imginfo->lmar+imginfo->rmar;
	// double bboxy = imginfo->trans.bb[1]+imginfo->tmar+imginfo->bmar;
	// double origx = imginfo->trans.orig[0] + imginfo->lmar;
	// double origy = bboxy - imginfo->trans.orig[1] - imginfo->bmar;
	// double scalex = imginfo->trans.scalex / info.unit;
	// double scaley = -imginfo->trans.scaley / info.unit;
	fprintf(fout, "(\n");
	lastop = '0';
	write_paths(fout, plist);
	/* header */

	/*
(
	{
		closed = 1;
		nodes =         (
			"509 0 OFFCURVE",
			"614 102 OFFCURVE",
			"614 318 CURVE SMOOTH",
			"614 522 OFFCURVE",
			"513 619 OFFCURVE",
			"301 619 CURVE SMOOTH",
			"78 619 LINE",
			"78 0 LINE",
			"288 0 LINE SMOOTH"
		);
	},
	{
		closed = 1;
		nodes =         (
			"411 505 OFFCURVE",
			"468 443 OFFCURVE",
			"468 312 CURVE SMOOTH",
			"468 177 OFFCURVE",
			"413 114 OFFCURVE",
			"296 114 CURVE SMOOTH",
			"218 114 LINE",
			"218 505 LINE",
			"292 505 LINE SMOOTH"
		);
	}
)
	*/
	fprintf(fout, "		);\n	}\n)\n");
	return 0;
}
