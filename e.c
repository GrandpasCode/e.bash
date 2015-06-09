/*
 * a tiny expression evaluator
 * Copyright (C) 2014-2015  Yu-Jie Lin
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

#include <float.h>
#ifndef BASH_LOADABLE
#include <getopt.h>
#endif
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#ifdef BASH_LOADABLE
#include <builtins.h>
#include <shell.h>
#include <variables.h>
#include <bashgetopt.h>
#endif

#include "version.h"

bool DEBUG = false;
#define DPRINT(...)                     \
        if (DEBUG) {                    \
          fprintf(stderr, "DEBUG: ");   \
          fprintf(stderr, __VA_ARGS__); \
          fprintf(stderr, "\n");        \
        }
#define DPRINT_(...)   if (DEBUG) fprintf(stderr, __VA_ARGS__);

#define NAME    "e"
#define USAGE   NAME " [OPTIONS] [--] [expression]"

char *e_doc[] = {
  "Tiny expression evaluator.",
  "",
  "Options:",
  "",
  "  -h        display this help message",
  "  -V        display version string",
  "  -d        display debugging messages",
#ifdef BASH_LOADABLE
  "  -v VAR    store the result to VAR variable",
#endif
  (char *) NULL
};

#define COPYRIGHT \
        "Copyright (C) 2014 Authors of e.bash\n"\
        "License GPLv2+: GNU GPL version 2 or later <https://www.gnu.org/licenses/gpl-2.0.html>\n"\
        "This is free software: you are free to change and redistribute it.\n"\
        "There is NO WARRANTY, to the extent permitted by law."

#define URL_HOMEPAGE  "https://bitbucket.org/livibetter/e.bash"
#define URL_ISSUES    URL_HOMEPAGE "/issues"

#ifndef BASH_LOADABLE
#define GETOPT()    getopt(argc, argv, "hVd")
#define OPTARG      optarg
#define FMTPNT(...) printf(__VA_ARGS__)
#define FORMAT(s)   format(s)
#define SUCCESS     EXIT_SUCCESS
#define FAILURE     EXIT_FAILURE
#define EXIT_USAGE  EXIT_FAILURE
#else
#define GETOPT()    internal_getopt(list, "hVdv:")
#define OPTARG      list_optarg
#define FMTPNT(...) sprintf(result + strlen(result), __VA_ARGS__)
#define FORMAT(s)   format(s, varname)
#define SUCCESS     EXECUTION_SUCCESS
#define FAILURE     EXECUTION_FAILURE
#define EXIT_USAGE  EX_USAGE
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


/**
 * mark the character for debugging messages
 */
void
debug_syntax (char *p)
{
  int tc = p - e;

  fprintf(stderr, "DEBUG: %s\n", e);
  fprintf(stderr, "DEBUG: %*s%s ", tc, "^", "---");
}
#define DEBUG_SYNTAX(p)  if (DEBUG) debug_syntax(p);

void
unknown (char *s)
{
  printf("'%s': unknown function\n", s);
  exit(FAILURE);
}


type
constant ()
{
  char *dp = p;
  type r = 0;

  while (c >= '0' && c <= '9') {
    r = 10 * r + (c - '0');
    next();
  }

  if (c == '.') {
    type p = 0.1;
    next();

    while (c >= '0' && c <= '9') {
      r += p * (c - '0');
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

  DEBUG_SYNTAX(dp);
  DPRINT_("%f\n", r);
  return r;
}


type
function ()
{
  char f[20];
  char *dp = p;
  char *q;
  type v;

  q = f;
  while (q - f < 19 && c >= 'a' && c <= 'z') {
    *q++ = c;
    next();
  }

  *q = 0;

  #define RETURN(r)                       \
          do {                            \
            DEBUG_SYNTAX(dp);             \
            DPRINT_("%s = %f\n", f, r);   \
            return r;                     \
          } while (false);                \

  if (!strcmp(f, "pi"))
    RETURN(M_PI);
  if (!strcmp(f, "e" ))
    RETURN(M_E);

  if (!strcmp(f, "dblmax"))
    RETURN((type) DBL_MAX);
  if (!strcmp(f, "dblmin"))
    RETURN((type) DBL_MIN);
  if (!strcmp(f, "randmax"))
    RETURN((type) RAND_MAX);

  v = term();

  #define mathfunc(a,b)                         \
          if (!strcmp(f, a)) {                  \
            DEBUG_SYNTAX(dp);                   \
            DPRINT_("%s(%f) = %f\n", f, v, b);  \
            return b;                           \
          }
  #define mathfret(a,b,r)                             \
          if (!strcmp(f, a)) {                        \
            DEBUG_SYNTAX(dp);                         \
            DPRINT_("void %s(%f) = %f\n", f, v, r);   \
            b;                                        \
            return r;                                 \
          }

  mathfunc("sign"  , (v == 0) ? 0.0 : (v > 0) ? 1.0 : -1.0);

  mathfunc("abs"   , fabs(v));
  mathfunc("fabs"  , fabs(v));
  mathfunc("floor" , floor(v));
  mathfunc("ceil"  , ceil(v));
  mathfunc("round" , round(v));
  mathfunc("trunc" , trunc(v));
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

  mathfunc("time"  , (type) time((time_t *) &v));
  mathfret("srand" , srand((unsigned int) v), (type) 0);
  mathfunc("rand"  , (type) rand());
  mathfunc("randf" , (type) rand() / (type) RAND_MAX);

  unknown(f);
  return 0;
}


type
term ()
{
  if (c == '(' || c == '[') {
    type r;

    next();
    r = E();
    if (c != ')' && c !=']')
      syntax();

    next();
    return r;
  } else if ((c >= '0' && c <= '9') || c == '.')
    return constant();
  else if (c >= 'a' && c <= 'z')
    return function();

  return 0;
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
  char *dp = p;
  type q = term();
  type r = q;

  if (c == '!') {
    next();
    r = factorial(q);
    DEBUG_SYNTAX(dp);
    DPRINT_("%f! = %f\n", q, r);
  }

  return r;
}


type
G ()
{
  char *dp = p;
  type q;
  type r = H();

  while (c == '^') {
    next();
    q = G();
    r = pow(r, q);
    DEBUG_SYNTAX(dp);
    DPRINT_("^ %f = %f\n", q, r);
  }

  return r;
}


type
F ()
{
  char *dp;
  char  dc;
  type q;
  type r = G();

  while (true) {
    dp = p;
    dc = c;
    if (c == '*') {
      next();
      q = r;
      r *= G();
    } else if (c == '/') {
      next();
      q = r;
      r /= G();
    } else if (c == '%') {
      next();
      q = r;
      r = fmod(r, G());
    } else
      break;
    DEBUG_SYNTAX(dp);
    DPRINT_("%c %f = %f\n", dc, q, r);
  }

  return r;
}


type
E ()
{
  char *dp;
  char  dc;
  type q;
  type r = F();

  while (true) {
    dp = p;
    dc = c;
    if (c == '+') {
      next();
      q = r;
      r += F();
    } else if (c == '-') {
      next();
      q = r;
      r -= F();
    } else
      break;
    DEBUG_SYNTAX(dp);
    DPRINT_("%c %f = %f\n", dc, q, r);
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

#ifndef BASH_LOADABLE
  printf("\n");
#else
out:
  DPRINT("result is %s", result);
  if (varname) {
    bind_variable(varname, result, 0);
    DPRINT("Bound result to %s", varname);
  } else {
    printf("%s\n", result);
  }
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


void
print_help () {
  unsigned int i;

  puts("Usage: " USAGE);
  for (i = 0; i < sizeof(e_doc) / sizeof(char *); i++)
    if (e_doc[i])
      puts(e_doc[i]);

  printf("\n"\
         "Report bugs to <" URL_ISSUES ">\n"\
         "Home page: <" URL_HOMEPAGE ">\n");
}


int
#ifndef BASH_LOADABLE
main (int argc, char **argv)
#else
e_builtin (WORD_LIST *list)
#endif
{
  int opt;
#ifndef BASH_LOADABLE
  int i;
#else
  char *varname = NULL;

  /**
   * reset variables
   */
  DEBUG = false;
  e = NULL;
  p = NULL;
  c = 0;
#endif

#ifdef BASH_LOADABLE
  reset_internal_getopt();
#endif
  while ((opt = GETOPT()) != -1) {
    DPRINT("option = %c", opt);
    switch (opt) {
    case 'h':
      print_help();
      goto out;
    case 'V':
      puts(NAME " " VERSION);
      puts(COPYRIGHT);
      goto out;
    case 'd':
      DEBUG = true;
      DPRINT("debug is on");
      break;
#ifdef BASH_LOADABLE
    case 'v':
      varname = strauto(varname, OPTARG);
      DPRINT("varname = %s", varname);
      break;
#endif
    default:
#ifndef BASH_LOADABLE
      fprintf(stderr, "Usage: " USAGE "\n");
#endif
      return EXIT_USAGE;
    }
  }

  e = strauto(e, "");

#ifndef BASH_LOADABLE
  for (i = optind; i < argc; i++) {
    e = strauto(e, argv[i]);
    e = strauto(e, " ");
  }
#else
  list = loptend;
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

out:
#ifdef BASH_LOADABLE
  free(varname);
#endif

  return SUCCESS;
}


#ifdef BASH_LOADABLE
struct builtin e_struct = {
  "e",
  e_builtin,
  BUILTIN_ENABLED,
  e_doc,
  USAGE,
  0
};
#endif
