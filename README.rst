=================================
e.bash: tiny expression evaluator
=================================

**e.bash** is a Bash loadable extension, just like ``printf`` or ``read``, it
runs fast. It's a fork of |ee|__, which was made for calculation with float
numbers in 2001.

.. |ee| replace:: *e*
__ History_

.. contents:: **Contents**
   :local:


Who should use e.bash?
======================

No one, and no one should use ``bc``, too, if you are doing mass calculations
with float numbers in shell scripting. If you are doing that, then you are
doing it wrong. Use another shell that supports float natively, or the better,
use another programming language for that kind of task.

How is it wrong? Have you seen the numbers in Benchmark_? How much processing
power have you wasted? Bash isn't meant for mass float calculation, in fact, it
can't. That's why many people use external ``bc``, and most of them ain't aware
of how costly to invoke external command.

Nevertheless, if you just want to say "Because I can," well, go ahead.

Or just want to get ``1 + 1 = ?``, then either programs are fine to use.


Installation
============

By default, it's installed to ``/usr/local`` and you will need to provide the
path to Bash header files using ``BASH_INC``:

.. code:: sh

  $ make [prefix=PREFIX] BASH_INC=/path/to/bash/include [install|install-strip]

You can change the installed location using ``prefix``. If everything compiles
successfully, you should have two binary files:

* ``e``: the command
* ``e.bash``: the loadable

Both are installed to ``prefix/bin``, although you can't directly execute
``e.bash``, which is meant to be loaded by Bash, see Loadable_.

If you need to strip, use ``install-strip`` target to install. To uninstall,
with same ``prefix``, use ``uninstall`` target.


Usage
=====

Loadable
--------

.. code:: sh

  $ enable -f /path/to/e.bash e
  $ e -v VARNAME [expression]

The result will be stored (Variable Binding) to ``$VARNAME``, of course, you
can use with Command Substitution:

.. code:: sh

  $ echo $(e [expression])

Command
-------

.. code:: sh

  $ ./e [expression]


Expression
==========

Operators
---------

+-------------------+--------------------------+---------------+------------+
| operators         | explanation              | evaluation    | precedence |
+===================+==========================+===============+============+
| ``+`` ``-``       | add,subtract             | left to right | lower      |
+-------------------+--------------------------+---------------+------------+
| ``*`` ``/`` ``%`` | multiply, divide, modulo | left to right |            |
+-------------------+--------------------------+---------------+------------+
| ``^``             | exponentiate             | right to left |            |
+-------------------+--------------------------+---------------+------------+
| ``!``             | factorial                | obvious       | higher     |
+-------------------+--------------------------+---------------+------------+

Constants
---------

mathematical
............

+-------------+------------------------+--------------+
| constants   | value                  | in C         |
+=============+========================+==============+
| ``e``       | 2.7182818284590452354  | ``M_E``      |
+-------------+------------------------+--------------+
| ``pi``      | 3.14159265358979323846 | ``M_PI``     |
+-------------+------------------------+--------------+

limitations
...........

+-------------+------------------------+--------------+
| constants   | value                  | in C         |
+=============+========================+==============+
| ``dblmin``  | *too long to display*  | ``DBL_MIN``  |
+-------------+------------------------+--------------+
| ``dblmax``  | *too long to display*  | ``DBL_MAX``  |
+-------------+------------------------+--------------+
| ``randmax`` | 2147483647             | ``RAND_MAX`` |
+-------------+------------------------+--------------+

Functions
---------

absolute
........

+---------------+-----------------------------------------------------------+
| functions     | explanation                                               |
+===============+===========================================================+
| ``abs``       | absolute value of integer number                          |
+---------------+-----------------------------------------------------------+
| ``fabs``      | absolute value of floating point number                   |
+---------------+-----------------------------------------------------------+

exponents and logarithms
........................

+---------------+-----------------------------------------------------------+
| functions     | explanation                                               |
+===============+===========================================================+
| ``exp``       | base e exponential                                        |
+---------------+-----------------------------------------------------------+
| ``ln``        | natural logarithm (base e)                                |
+---------------+-----------------------------------------------------------+
| ``log``       | base 2 logarithm (log256 = 8)                             |
+---------------+-----------------------------------------------------------+
| ``sqrt``      | sqrt                                                      |
+---------------+-----------------------------------------------------------+

rounding
........

+---------------+-----------------------------------------------------------+
| functions     | explanation                                               |
+===============+===========================================================+
| ``floor``     | largest integral value, not greater than argument         |
+---------------+-----------------------------------------------------------+
| ``ceil``      | smallest integral, not less than argument                 |
+---------------+-----------------------------------------------------------+
| ``round``     | round to nearest integer, away from zero                  |
+---------------+-----------------------------------------------------------+
| ``trunc``     | round to integer, toward zero                             |
+---------------+-----------------------------------------------------------+

trigonometric
.............

+---------------+-----------------------------------------------------------+
| functions     | explanation                                               |
+===============+===========================================================+
| ``sin``       | sine                                                      |
+---------------+-----------------------------------------------------------+
| ``cos``       | cosine                                                    |
+---------------+-----------------------------------------------------------+
| ``tan``       | tangent                                                   |
+---------------+-----------------------------------------------------------+
| ``asin``      | arc sine                                                  |
+---------------+-----------------------------------------------------------+
| ``acos``      | arc cosine                                                |
+---------------+-----------------------------------------------------------+
| ``atan``      | arc tangent                                               |
+---------------+-----------------------------------------------------------+

hyperbolic
..........

+---------------+-----------------------------------------------------------+
| functions     | explanation                                               |
+===============+===========================================================+
| ``sinh``      | hyperbolic sine                                           |
+---------------+-----------------------------------------------------------+
| ``cosh``      | hyperbolic cosine                                         |
+---------------+-----------------------------------------------------------+
| ``tanh``      | hyperbolic tangent                                        |
+---------------+-----------------------------------------------------------+
| ``asinh``     | inverse hyperbolic sine                                   |
+---------------+-----------------------------------------------------------+
| ``acosh``     | inverse hyperbolic cosine                                 |
+---------------+-----------------------------------------------------------+
| ``atanh``     | inverse hyperbolic tangent                                |
+---------------+-----------------------------------------------------------+

random
......

+---------------+-----------------------------------------------------------+
| functions     | explanation                                               |
+===============+===========================================================+
| ``rand``      | integer random number,  in range 0 to ``RAND_MAX``,       |
|               | inclusively                                               |
+---------------+-----------------------------------------------------------+
| ``randf``     | shorthand for ``rand / randmax``                          |
+---------------+-----------------------------------------------------------+


Benchmark
=========

.. code:: sh

  $ make benchmark

Sample result:

+-----------------+--------+
| method          | runs   |
+=================+========+
| original ``e``  | 554    |
+-----------------+--------+
| ``e``           | 596    |
+-----------------+--------+
| loadable        | 1,125  |
+-----------------+--------+
| loadable ``-v`` | 12,921 |
+-----------------+--------+

Examples
--------

+----------------+----------------+
| script         | time (seconds) |
+================+================+
| ``sine.sh``    | 0.028          |
+----------------+----------------+
| ``sine.bc.sh`` | 0.407          |
+----------------+----------------+


History
=======

The original |e|_ was written by Dimitromanolakis Apostolos in 2001, the
version 0.02718_ was released on 2011-07-11. From the original website e_:

.. |e| replace:: **e**
.. _e: http://web.archive.org/web/20090924080521/http://www.softnet.tuc.gr/%7Eapdim/projects/e/
.. _0.02718: https://bitbucket.org/livibetter/e.bash/commits/tag/v0.02718

  Some time ago while I [Dimitromanolakis Apostolos] was doing some homework
  for my university class, I needed a quick way to evaluate expressions, while
  I was typing at the command prompt. I found two solutions, using bc or
  gnuplot. bc has fixed precision which defaults to 0, so to evaluate an
  expression involving decimal results you need to issue a command like
  "scale=5" beforehand. On the other hand using gnuplot (and bc if it matters)
  involves loading the executable, evaluating your expression using the "print"
  command and quitting using the "quit" command. I needed something quicker..

  ...so, I coded *e*.

  e is a command line expression evaluator. It was designed to be as small as
  possible, and quick to use. Therefore the name "e" was chosen, so that while
  you are at the command prompt you can evaluate an expression with only 2
  keystrokes overhead. e manages to be under 8k in size on most compilers that
  I tried. My current record is 7000 bytes for v0.02718.

In August, 2014, e was forked and transformed into a Bash loadable extension by
Yu-Jie Lin (@livibetter) on Bitbucket.


Copyright
=========

This project is licensed under the GNU General Public License Version 2, see
COPYING_::

    Copyright (C) 2014  Yu-Jie Lin
    Copyright (C) 2001  Dimitromanolakis Apostolos

.. _COPYING: COPYING
