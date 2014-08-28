/*
 * a tiny expression evaluator
 * Copyright (C) 2014  Yu-Jie Lin
 * Copyright (C) 2001  Dimitromanolakis Apostolos
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef BASH_LOADABLE
#include <builtins.h>
#include <shell.h>
#include <variables.h>
#include <bashgetopt.h>
#endif

#include "version.h"

#define NAME    "e"
#define USAGE   NAME " [-v VARNAME] [expression]"


#ifndef BASH_LOADABLE
#define FMTPNT(...) printf(__VA_ARGS__)
#define FORMAT(s)   format(s)
#define SUCCESS     EXIT_SUCCESS
#define FAILURE     EXIT_FAILURE
#else
#define FMTPNT(...) sprintf(result + strlen(result), __VA_ARGS__)
#define FORMAT(s)   format(s, varname)
#define SUCCESS     EXECUTION_SUCCESS
#define FAILURE     EXECUTION_FAILURE
#endif


// copied from math.h
# define M_PI           3.14159265358979323846  /* pi */
# define M_E            2.7182818284590452354   /* e */


typedef double type;

// concatenated expression from argv or WORD_LIST
char *e;
char  c;
char *p;


type E();
/* For unknown reason, in Bash loadable with -O > 0:
 *
 * Running: e -- -1
 * Returns: -nan
 *
 * Even disabling all these optizmizers:
 *
 *   diff -y <(gcc -c -Q -O0 --help=optimizers) <(gcc -c -Q -O1 --help=optimizers) | grep '|'
 *
 * It doesn't help, only the following would get the correct answer.
 */
#ifdef BASH_LOADABLE
#pragma GCC push_options
#pragma GCC optimize ("O0")
#endif
type term();
#ifdef BASH_LOADABLE
#pragma GCC pop_options
#endif


void
next ()
{
  while ((c = *p++) == ' ');
}


void
syntax ()
{
  int tc = p - e - 1;
  int c;
  char *t = e;

  puts(e);

  if (tc >= 16) {
    for (c = 0; c < tc - 16; c++)
      putchar(' ');
    printf("syntax error ---^\n");
  } else {
    for (c = 0; c < tc; c++)
      putchar(' ');
    printf("^--- syntax error\n");
  }

  exit(FAILURE);
}


void
unknown (char *s)
{
  printf("'%s': unknown function\n", s);
  exit(FAILURE);
}


type
constant ()
{
  type r = 0;

  while (c >= '0' && c <= '9') {
    r = 10 * r + (c - '0');
    next();
  }

  if (c == '.') {
    type p = 0.1;
    next();

    while (c >= '0' && c <= '9') {
      r += p * (c-'0');
      p /= 10;
      next();
    }
  }

  if (c == 'e' || c == 'E') {
    type m = 1;

    next();
    if (c == '-') {
      m = -m;
      next();
    } else {
      if (c == '+')
        next();
    }

    r *= pow(10, m * term());
  }

  return r;
}


type
function ()
{
  char f[20];
  char *p;
  type v;

  p = f;
  while (p - f < 19 && c >= 'a' && c <= 'z') {
    *p++ = c;
    next();
  }

  *p = 0;

  if (!strcmp(f,"pi"))
    return M_PI;
  if (!strcmp(f,"e" ))
    return M_E;

  if (!strcmp(f,"randmax"))
    return RAND_MAX;

  v = term();

  #define mathfunc(a,b) if(!strcmp(f,a)) return b;

  mathfunc("abs"   , fabs(v));
  mathfunc("fabs"  , fabs(v));
  mathfunc("floor" , floor(v));
  mathfunc("ceil"  , ceil(v));
  mathfunc("sqrt"  , sqrt(v));
  mathfunc("exp"   , exp(v));

  mathfunc("sin"   , sin(v));
  mathfunc("cos"   , cos(v));
  mathfunc("tan"   , tan(v));
  mathfunc("asin"  , asin(v));
  mathfunc("acos"  , acos(v));
  mathfunc("atan"  , atan(v));

  mathfunc("sinh"  , sinh(v));
  mathfunc("cosh"  , cosh(v));
  mathfunc("tanh"  , tanh(v));
  mathfunc("asinh" , asinh(v));
  mathfunc("acosh" , acosh(v));
  mathfunc("atanh" , atanh(v));

  mathfunc("ln"    , log(v));
  mathfunc("log"   , log(v) / log(2));

  mathfunc("rand"  , rand());
  mathfunc("randf" , (type) rand() / (type) RAND_MAX);

  unknown(f);
  return 0;
}


type
term ()
{
  const int m = 1;

  if (c == '(' || c == '[') {
    type r;

    next();
    r = E();
    if (c != ')' && c !=']')
      syntax();

    next();
    return m * r;
  } else if ((c >= '0' && c <= '9') || c == '.')
    return m * constant();
  else if (c >= 'a' && c <= 'z')
    return m * function();
}


static inline type
factorial (type v)
{
  type i;
  type r = 1;

  for (i = 2; i <= v; i++)
    r *= i;

  return r;
}


type
H ()
{
  type r = term();

  if (c == '!') {
    next();
    r = factorial(r);
  }

  return r;
}


type
G ()
{
  type q;
  type r = H();

  while (c == '^') {
    next();
    q = G();
    r = pow(r, q);
  }

  return r;
}


type
F ()
{
  type r = G();

  while (true) {
    if (c == '*') {
      next(); r *= G();
    } else if (c == '/') {
      next();
      r /= G();
    } else if (c == '%') {
      next();
      r = fmod(r, G());
    } else
      break;
  }

  return r;
}


type
E ()
{
  type r = F();

  while (true) {
    if (c == '+') {
      next();
      r += F();
    } else if (c == '-') {
      next();
      r -= F();
    } else
      break;
  }

  return r;
}


type
S ()
{
  type r = E();

  if (c != 0)
    syntax();

  return r;
}


void
#ifndef BASH_LOADABLE
format (type X)
#else
format (type X, char *varname)
#endif
{
  type i;
  type f;
  int d;
#ifdef BASH_LOADABLE
  char result[2000] = "";
#endif

  if (!isfinite(X)) {
    FMTPNT("%f", X);
#ifdef BASH_LOADABLE
    goto out;
#endif
  }

  f = fabs(modf(X, &i));
  d = floor(log10(fabs(X))) + 1;

  if (isfinite(f) && f != 0) {
    char *p;
    char s[2000];
    char t[2000];

    sprintf(t, "%%.%df", 15 - d);
    sprintf(s, t, f);

    // remove all zeros from s
    p = s;
    while (*p)
      p++;
    p--;
    while (p > s && *p == '0')
      *p-- = 0;

    // decimal part has been rounded
    if (s[0] == '1')
      FMTPNT("%.0f", i + (X >= 0 ? 1 : -1));
    else {
      FMTPNT("%.0f", i);
      if (s[2] != 0)
        FMTPNT("%s", s + 1);
    }
  } else
    FMTPNT("%.0f", i);

#ifdef BASH_LOADABLE
out:
  if (varname)
    bind_variable(varname, result, 0);
  else
    printf("%s\n", result);
#endif
}


/*
 * automatic memmory allocation for strcpy or re-allocation for strcat
 */
char *
strauto (char *dest, char *src) {
  if (dest == NULL) {
    if ((dest = malloc(strlen(src) + 1)))
      return strcpy(dest, src);

    fprintf(stderr, "error: malloc failed\n");
    exit(FAILURE);
  }

  if ((dest = realloc(dest, strlen(dest) + strlen(src) + 1)))
    return strcat(dest, src);

  fprintf(stderr, "error: realloc failed\n");
  exit(FAILURE);
}


int
#ifndef BASH_LOADABLE
main (int argc, char **argv)
#else
e_builtin (WORD_LIST *list)
#endif
{
#ifndef BASH_LOADABLE
  int i;
#else
  int opt;
  char *varname = NULL;

  reset_internal_getopt();
  while ((opt = internal_getopt(list, "Vv:")) != -1) {
    switch (opt) {
    case 'V':
      printf(NAME " " VERSION "\n");
      goto out;  
    case 'v':
      varname = malloc(strlen(list_optarg) + 1);
      strcpy(varname, list_optarg);
      break;
    default:
      return EX_USAGE;
    }
  }
  list = loptend;
#endif

  e = strauto(e, "");

#ifndef BASH_LOADABLE
  for (i = 1; i < argc; i++) {
    e = strauto(e, argv[i]);
    e = strauto(e, " ");
  }
#else
  while (list) {
    e = strauto(e, list->word->word);
    list = list->next;
    e = strauto(e, " ");
  }
#endif
  e[strlen(e) - 1] = '\0';
  p = e;

  srand(time(NULL));

  next();
  FORMAT(S());

  free(e);

#ifndef BASH_LOADABLE
  printf("\n");

  return SUCCESS;
#else
out:
  free(varname);

  return SUCCESS;
#endif
}


#ifdef BASH_LOADABLE
char *e_doc[] = {
  "Tiny expression evaluator.",
  (char *) NULL
};


struct builtin e_struct = {
  "e",
  e_builtin,
  BUILTIN_ENABLED,
  e_doc,
  USAGE,
  0
};
#endif
