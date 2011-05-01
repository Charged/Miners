// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.ints;

static final int imin(int a, int b) { return a < b ? a : b; }
static final int imax(int a, int b) { return a > b ? a : b; }
static final int imin4(int a, int b, int c, int d) { return imin(imin(a, b), imin(c, d)); }
static final int imax4(int a, int b, int c, int d) { return imax(imax(a, b), imax(c, d)); }
static final int iclamp(int min, int v, int max) { return imax(min, imin(v, max)); }
