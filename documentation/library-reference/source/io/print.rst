****************************
The print and pprint Modules
****************************

.. current-library:: io
.. current-module:: print

The IO library's printing modules provide an interface that outputs an object
in Dylan literal syntax if the object can be represented as a Dylan literal,
and otherwise, outputs the object in an implementation-dependent manner.

There are two functions, :func:`print` and :gf:`print-object`. The
:func:`print` function accepts keyword arguments that form a print request,
controlling features such as circular printing, how deep within a data
structure to print, how many elements in long sequences to print before using
an ellipsis notation, whether pretty printing is desired, and so on. Users
extend :func:`print`'s ability to print various objects by adding methods to
the :gf:`print-object` generic function.

The :func:`print` function handles most of the overhead to satisfy special
print requests, outputting any special notations required, and it only calls
:gf:`print-object` when it is necessary to print objects. Users should always
call the :func:`print` function to output objects, especially recursively from
within :gf:`print-object` methods, to output an object's components.  Users
should never call :gf:`print-object` directly.

The IO library exports two modules for use with printing, *print* and
*pprint*. Reference entries for the interfaces exported from the *print* module
can be found in `The print Module`_, and reference entries for interfaces
exported from the *pprint* module are in `The pprint Module`_.

These modules use the Streams module. See :doc:`streams` for
full details of the Streams module.

Print functions
---------------

The Print module offers functions for users to call to print objects,
:func:`print` and :func:`print-to-string`, along with interfaces that allow you
to modify the way your own objects are printed: :gf:`print-object` and
:macro:`printing-object`.

The Print module exports the following variables which provide default
values for calls to the print function. Their values are
implementation-dependent.

- :var:`*print-level*`
- :var:`*print-length*`
- :var:`*print-circle?*`
- :var:`*print-pretty?*`
- :var:`*print-escape?*`

Pretty printing
---------------

When writing :gf:`print-object` methods, you can ignore whether pretty
printing is in effect. If you write your :gf:`print-object` method using
pretty printing functions, then when pretty printing is in effect, the
output is pretty printed. When pretty printing is not in effect, your
method produces output as though you had not written it to use pretty
printing. All :gf:`print-object` methods that are written to do pretty
printing must call the pretty printing functions within the dynamic
scope of a call to *pprint-logical-block*; otherwise, the pretty
printing functions are no-ops.

The following interfaces are exported from the *pprint* module:

- :var:`*default-line-length*`
- :var:`*print-miser-width*`
- :func:`pprint-logical-block`
- :func:`pprint-newline`
- :func:`pprint-indent`
- :func:`pprint-tab`

The print Module
----------------

This section contains a reference entry for each item exported from the
IO library's *print* module.

.. function:: print

   Prints *object* to the specified stream.

   :signature: print *object* *stream* #key *circle? escape? length level pretty?* => ()

   :parameter object: An instance of :drm:`<object>`.
   :parameter stream: An instance of :class:`<stream>`.
   :parameter #key circle?: An instance of :drm:`<boolean>`. Default value:
     :var:`*print-circle?*`.
   :parameter #key escape?: An instance of :drm:`<boolean>`. Default value:
     :var:`*print-escape?*`.
   :parameter #key level: :drm:`#f` or an instance of :drm:`<integer>`.
     Default value: :var:`*print-level*`.
   :parameter #key length: :drm:`#f` or an instance of :drm:`<integer>`.
     Default value: :var:`*print-length*`.
   :parameter #key pretty?: An instance of :drm:`<boolean>`. Default value:
     :var:`*print-pretty?*`.

   :description:

     Prints *object* to *stream* according to the print request formed
     by the keyword arguments. A first call to *print* creates a
     printing stream to represent the print request, and recursive calls
     to *print* on this printing stream process the keyword arguments
     differently (see below). There are inspection functions for
     querying the print request. When :func:`print` actually prints an
     object, it calls :gf:`print-object`. Though the inspection
     functions for querying the print request allow you to inspect any
     parameter of the print request, :gf:`print-object` methods should
     only need to call :gf:`print-length`. All other aspects of the
     print request are handled by :func:`print`. There is one exception,
     which is described in `Pretty printing`_.

     The *level* keyword controls how deep into a nested data structure
     to print. The value :drm:`#f` indicates that there is no limit. The
     default, :var:`*print-level*`, has no effect on recursive calls to
     :func:`print`. Recursive calls to :func:`print` may change the value of
     *print-level* explicitly, but :func:`print` always uses a value to
     ensure the print request formed by the first call to :func:`print` is
     never exceeded. For example, if a first call to :func:`print` set the
     level to 5, and while at a depth of 3, a recursive call specified a
     level of 4, the recursive call would only descend 2 more levels,
     not 4.

     The *length* keyword controls how many elements of a sequence to
     print before printing ellipsis notation (*...*). The value :drm:`#f`
     indicates that there is no limit. The *print-length* control can be
     interpreted loosely by some :gf:`print-object` methods to control
     how many *elements* of any kind of object to print; for example,
     the default :drm:`<object>` method might regard *print-length* to
     determine how many slot-name/value pairs to print. The default,
     :var:`*print-length*`, has no effect on recursive calls to
     :func:`print`. Recursive calls to :func:`print` may change the value of
     *print-length* explicitly, but they may only decrease the value,
     never increase it.

     The *circle?* keyword indicates whether printing should check all
     subcomponent references to make sure the printing process does not
     infinitely recurse through a data structure. Circular printing also
     tags objects that occur more than once when they are first printed,
     and later occurrences are printed as a reference to the previously
     emitted tag. The default, :var:`*print-circle?*`, has no effect on
     recursive calls to :func:`print`. If *print-circle?* is already :drm:`#t`,
     then it remains :drm:`#t` throughout all recursive calls. If
     *print-circle?* is :drm:`#f`, then recursive calls to :func:`print` can
     change the value to :drm:`#t` ; however, when printing exits the
     dynamic scope of the call that changed the value to :drm:`#t`, the
     value reverts back to :drm:`#f`. If the original call to :func:`print`
     specifies *circle?* as :drm:`#f`, and dynamically distinct recursive
     calls turn circular printing on and off, all output generated while
     circular printing was on shares the same tagging space; that is, if
     ``#1#`` is printed twice, once from each of two distinct recursive
     calls to print, then each ``#1#`` is guaranteed to signify the same
     :drm:`==` object.

     The *pretty?* keyword indicates whether printing should attempt to
     insert line breaks and indentation to format objects according to
     how programmers tend to find it easier to read data. The default,
     :var:`*print-pretty?*`, has no effect on recursive calls to
     :func:`print`. If *print-pretty?* is already :drm:`#t`, then it remains
     :drm:`#t` throughout all recursive calls. If *print-pretty?* is
     :drm:`#f`, then recursive calls to :func:`print` can change the value to
     :drm:`#t` ; however, when printing exits the dynamic scope of the call
     that changed the value to :drm:`#t`, the value reverts back to :drm:`#f`.

     The *escape?* keyword indicates whether printing should show escape
     codes in strings and, by extension, whether other objects should be
     printed with additional identifying information.

.. variable:: *print-circle?*
   :thread:

   Controls whether or not to detect circular structures when printing.

   :type: <boolean>

   :value: :drm:`#f`

   :description:

     :var:`*print-circle?*` holds the default value for whether or not to
     detect circular structures when printing. When :drm:`#t`, circularity
     detection is enabled. The default is :drm:`#f`.

     When calling :func:`print` directly, :var:`*print-circle?*` may be
     overridden by specifying a value for the ``circle?`` argument. It is
     dynamically bound by :func:`print` so that its value is inherited by
     recursive calls.

     Note that when :var:`*print-circle?*` is :drm:`#t` attempts to print circular
     structures may result in failure to terminate.

   :seealso:

    - :func:`print` for more detail on how circular structures are handled.

.. variable:: *print-escape?*
   :thread:

     Whether to print objects for debugging or for display to the end user.

   :type: <boolean>

   :value: :drm:`#t`

   :description:

     Controls whether or not :func:`print` displays extra identifying
     information for the object being printed, making it easier to distinguish
     from other objects of the same type for debugging purposes. For those who
     know Python, this is much like the difference between ``__repr__`` and
     ``__str__``.

     For example, when :var:`*print-escape?*` is true strings print exactly the
     way Dylan string literals look, for example ``"abc\\n"``. When
     :var:`*print-escape?*` is false the same string prints as ``abc`` with a
     trailing newline.

   :seealso:

    - :func:`print`

.. variable:: *print-length*
   :thread:

   Controls the number of elements of an expression to print.

   :type: false-or(<integer>)

   :value: :drm:`#f`

   :description:

     Controls how many elements to print at a given level of a nested
     expression. The default is unlimited (:drm:`#f`).

   :seealso:

    - :func:`print`

.. variable:: *print-level*
   :thread:

   Controls how deeply into a nested expression to print.

   :type: false-or(<integer>)

   :value: :drm:`#f`

   :description:

     Controls how many levels of a nested expression to print.

   :seealso:

    - :func:`print`

.. variable:: *print-pretty?*
   :thread:

   Controls whether or not pretty printing is used.

   :type: <boolean>

   :value: :drm:`#f`

   :description:

     Controls whether or not :func:`print` does pretty printing by default.
     May be overridden via the ``pretty?`` keyword argument to :func:`print`.

   :seealso:

    - :func:`print`

.. generic-function:: print-object
   :open:

   Prints an object to a stream.

   :signature: print-object *object stream* => ()

   :parameter object: An instance of :drm:`<object>`.
   :parameter stream: An instance of :class:`<stream>`.

   :description:

     Prints an object to a stream. Extend the ability of :func:`print` to print
     objects by adding methods to this generic function. When :func:`print`
     actually prints an object, it calls :gf:`print-object`.

     The most common use of this functionality is to change the way objects in
     your own library display in the debugger, to make individual instances
     more easily identifiable. See the example under :macro:`printing-object`.

     Never call :gf:`print-object` directly.

   :seealso:

      - :macro:`printing-object`, which simplifies writing :gf:`print-object`
        methods.

.. function:: print-to-string

   Calls :func:`print` on *object* and returns the result as a string.

   :signature: print-to-string *object* #key *circle? escape? level length pretty?* => *result*

   :parameter object: An instance of :drm:`<object>`.
   :parameter #key level: :drm:`#f` or an instance of :drm:`<integer>`.
     Default value: :var:`*print-level*`.
   :parameter #key length: :drm:`#f` or an instance of :drm:`<integer>`.
     Default value: :var:`*print-length*`.
   :parameter #key circle?: An instance of :drm:`<boolean>`. Default value:
     :var:`*print-circle?*`.
   :parameter #key pretty?: An instance of :drm:`<boolean>`. Default value:
     :var:`*print-pretty?*`.
   :parameter #key escape?: An instance of :drm:`<boolean>`. Default value:
     :var:`*print-escape?*`.
   :value result: An instance of :drm:`<byte-string>`.

   :description:

     Calls :func:`print` to produce output according to the print
     request formed by the keyword arguments and returns the result as a
     string.

.. macro:: printing-object

   Wrapper around :macro:`printing-logical-block`.

   :macrocall:
      .. parsed-literal:: 
         printing-object(`object`, `stream`, #key type? = #t)
           `body`
         end

   *printing-object* may be used within :gf:`print-object` to print Dylan
   objects in a standardized way while adding identifying information for your
   own classes. Example:

      .. code-block:: dylan

         define method print-object (acct :: <account>, stream :: <stream>) => ()
           printing-object(acct, stream)
             print(account-name(acct), stream, escape?: #t);
           end;
         end;

   With the above method, an ``<account>`` object with name "foo" will print as
   ``{<account> "foo" #xDEADBEEF}``.


The pprint Module
-----------------

.. current-module:: pprint

This section contains a reference entry for each item exported from the
IO library's *pprint* module.

.. variable:: *default-line-length*

   Controls the default line length used by the pretty printer.

   :type: <integer>
   :value: 80

   :description:

     Controls the line length used by the pretty printer to determine
     how much output will fit on a single line. The value must be an
     integer.

.. function:: pprint-indent

   Specifies the indentation to use within the current logical block.

   :signature: pprint-indent *relative-to n stream* => ()

   :parameter relative-to: One of ``#"block"`` or ``#"current"``.
   :parameter n: An instance of :drm:`<integer>`.
   :parameter stream: An instance of :class:`<stream>`.

   :description:

     Specifies the indentation to use within the current logical block.
     When *relative-to* is ``#"block"``, then :func:`pprint-indent` sets the
     indentation to the column of the first character of the logical
     block plus *n*. When *relative-to* is ``#"current"``, then
     :func:`pprint-indent` sets the indentation to the current column plus
     *n*.

.. function:: pprint-logical-block

   Groups printing into a logical block.

   :signature: pprint-logical-block *stream* #key *prefix per-line-prefix body suffix column* => ()

   :parameter stream: An instance of :class:`<stream>`.
   :parameter #key prefix: :drm:`#f` or an instance of :drm:`<byte-string>`.
   :parameter #key per-line-prefix: :drm:`#f` or an instance of :drm:`<byte-string>`.
   :parameter #key body: An instance of :drm:`<function>`.
   :parameter #key suffix: :drm:`#f` or an instance of :drm:`<byte-string>`.
   :parameter #key column: A *limited* instance of :drm:`<integer>`, minimum 0.

   :description:

     Groups printing into a logical block. The logical block provides
     boundaries for new levels of indentation, affects ``#"linear"``
     newlines, and so on. *Prefix* is a string to print at the beginning
     of the logical block. The block's indentation is automatically set
     to be one character position greater than the column in which
     *prefix* ends. Alternatively, *per-line-prefix* is a string to
     print on every line of the logical block. This function signals an
     error if it is called with both *prefix* and *per-line-prefix*
     supplied as non-:drm:`#f`. *Suffix* is a string to print at the end of
     the logical block. *Column* advises the pretty printer as to the
     current column of the output stream (the default is zero). The
     *column* argument may be ignored entirely by some methods, and it
     may be ignored in some cases by methods that can better determine
     the stream's current output column.

     The *body* keyword must be a function that can take one argument,
     and this argument is a stream. The *body* function should use the
     stream argument passed to it; the *body* function should not close
     over the stream argument to :macro:`pprint-logical-block`.
     :macro:`pprint-logical-block` wraps *stream* with a pretty printing
     stream when *stream* is any other kind of stream. If *stream* is
     already a pretty printing stream, then the *body* function is
     called on *stream*.

     All :gf:`print-object` methods that are written to do pretty
     printing must call the other pretty printing functions within the
     dynamic scope of a call to :macro:`pprint-logical-block`; otherwise, the
     pretty printing functions are no-ops.

.. function:: pprint-newline

   Announces a conditional newline to the pretty printer.

   :signature: pprint-newline *kind stream* => ()

   :parameter kind: One of ``#"fill"``, ``#"linear"``, ``#"miser"``,
     ``#"mandatory"``.
   :parameter stream: An instance of :class:`<stream>`.

   :description:

     Announces a conditional newline to the pretty printer. The pretty
     printer emits a newline depending on the *kind* and the state of
     the pretty printer's current line buffer. The *kind* argument has
     roughly the following meanings:

     - ``#"fill"`` Emit a newline if the current *section* of output
       does not fit on one line.
     - ``#"linear"`` Emit a newline if any ``#"linear"`` newline in the
       current *section* needs to be emitted. That is, if a current
       *section* of output cannot fit on one line, and any one of the
       ``#"linear"`` newlines in the section needs to be emitted, then
       emit them all.
     - ``#"miser"`` Emit a newline as if it were a ``#"linear"``
       newline, but only when *miser mode* is in effect. Miser style is
       in effect when a logical block starts past a particular column of
       output.
     - ``#"mandatory"`` Emit a newline always. Establish that any
       containing *sections* cannot be printed on a single line so that
       ``#"linear"`` and ``#"miser"`` newlines will be emitted as
       appropriate.

.. function:: pprint-tab

   Announces a tab to the pretty printer.

   :signature: pprint-tab *kind colnum colinc stream* => ()

   :parameter kind: One of ``#"line"``, ``#"line-relative"``,
     ``#"section"``, ``#"section-relative"``.
   :parameter colnum: An instance of :drm:`<integer>`.
   :parameter colinc: An instance of :drm:`<integer>`.
   :parameter stream: An instance of :class:`<stream>`.

   :description:

     Announces a tab to the pretty printer. The *colnum* and *colinc*
     arguments have meaning based on the value of *kind*:

     - ``#"line"``
       Tab to output column *colnum*. If the output is already at
       or beyond *colnum*, then add *colinc* to *colnum* until printing can
       continue at a column beyond the end of the output already on the
       line.

     - ``#"line-relative"``
       Output *colnum* spaces. Then output enough spaces to tab to a column
       that is a multiple of *colinc* from the beginning of the line.

     - ``#"section"``
       Similar to ``#"line"``, but column counting is relative
       to the beginning of the current *section* rather than the beginning
       of the line.

     - ``#"section-relative"``
       Similar to ``#"line-relative"``, but column counting is relative to
       the beginning of the current *section* rather than the beginning of
       the line.

.. variable:: *print-miser-width*

   Controls miser mode.

   :type: false-or(<integer>)
   :value: :drm:`#f`

   :description:

     Controls *miser mode*. Pretty printing is in miser mode whenever a
     logical block (see :gf:`pprint-logical-block`) begins in a column
     of output that is greater than::

       .. code-block:: dylan

          *default-line-length* - *print-miser-width*

     The value must be an integer or :drm:`#f` (the default); :drm:`#f`
     indicates that the pretty printer should never enter miser mode.
