Module: common-dylan-test-utilities
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define open generic test-collection-class
    (class :: subclass(<collection>), #key, #all-keys) => ();

define method test-collection-class
    (class :: subclass(<collection>), #key instantiable?, #all-keys)
 => ()
  if (instantiable?)
    test-collection-of-size(format-to-string("Empty %s", class), class, 0);
    test-collection-of-size(format-to-string("One item %s", class), class, 1);
    test-collection-of-size(format-to-string("Even size %s", class), class, 4);
    test-collection-of-size(format-to-string("Odd size %s", class), class, 5);
  end
end method test-collection-class;

//--- An extra method to test special features of arrays
define method test-collection-class
    (class == <array>, #key instantiable?, #all-keys) => ()
  next-method();
  if (instantiable?)
    test-collection("2x2 <array>",   make-array(#(2, 2)));
    test-collection("5x5 <array>",   make-array(#(5, 5)));
    test-collection("2x3x4 <array>", make-array(#(2, 3, 4)));
  end
end method test-collection-class;

//--- An extra method to test unbounded ranges
define method test-collection-class
    (class == <range>, #key instantiable?, #all-keys) => ()
  next-method();
  if (instantiable?)
    //---*** Test reverse ranges...
/*---*** Switch this on when the image is up to it!
  test-collection("unbounded forwards <range>",  range(from: 10));
  test-collection("unbounded backwards <range>", range(from: 10, by: -1));
*/
  end
end method test-collection-class;

//--- Pairs don't really behave like collections in that you can't
//--- make a pair of size n. So we'll test this differently.
define method test-collection-class
    (class == <pair>, #key instantiable?, #all-keys) => ()
/*---*** switch this on when we make a decision about the status of <pair>
  if (instantiable?)
    test-collection("pair(1, #())", pair(1, #()));
    test-collection("pair(1, pair(2, #()))", pair(1, pair(2, #())));
    //--- These are likely to crash so make them a unit
    with-test-unit ("Non-list <pair> tests")
      test-collection("pair(1, 2)", pair(1, 2));
      test-collection("pair(1, pair(2, 3))", pair(1, pair(2, 3)));
    end
  end
*/
end method test-collection-class;

define method test-collection-of-size
    (name :: <string>, class :: <class>, collection-size :: <integer>) => ()
  let collections = #[];
  let element-type = collection-type-element-type(class);
  check(format-to-string("%s creation", name),
        always(#t),
        collections := make-collections-of-size(class, collection-size));
  for (collection in collections)
    let individual-name
      = if (collection-size = 0)
          name
        else
          format-to-string("%s of %s", name, element-type)
        end;
    check-equal(format-to-string("%s empty?", individual-name),
                empty?(collection), collection-size == 0);
    check-equal(format-to-string("%s size", individual-name),
                size(collection), collection-size);
    check-equal(format-to-string("%s = shallow-copy", individual-name),
                shallow-copy(collection), collection);
    test-collection(individual-name, collection)
  end;
  test-limited-collection-of-size(name, class, collection-size)
end method test-collection-of-size;

define method test-limited-collection-of-size
    (name :: <string>, class :: <class>, collection-size :: <integer>) => ()
  let collections = #[];
  let name = format-to-string("Limited %s", name);
  check(format-to-string("%s creation", name),
        always(#t),
        collections := make-limited-collections-of-size(class, collection-size));
  for (collection in collections)
    let individual-name
      = format-to-string("%s of %s", name, element-type(collection));
    check-equal(format-to-string("%s empty?", individual-name),
                empty?(collection), collection-size == 0);
    check-equal(format-to-string("%s size", individual-name),
                size(collection), collection-size);
    check-equal(format-to-string("%s = shallow-copy", individual-name),
                shallow-copy(collection), collection);
    test-collection(individual-name, collection)
  end
end method test-limited-collection-of-size;


/// Test collection creation

define constant $default-string  = "abcdefghijklmnopqrstuvwxyz";
define constant $default-vectors = map-as(<vector>, vector, $default-string);

// This list was originally retrieved at runtime from dylan-test-suite's
// dylan-collections-specification-suite. It is reproduced here to break the
// dependency on that test suite.
define constant $instantiable-collection-classes
  = list(<array>,
         <byte-string>,
         <deque>,
         <empty-list>,
         <list>,
         <object-table>,
         <pair>,
         <range>,
         <simple-object-vector>,
         <simple-vector>,
         <stretchy-vector>,
         <string>,
         <table>,
         <vector>);

define function collection-class-instantiable?
    (class :: <class>) => (_ :: <boolean>)
  member?(class, $instantiable-collection-classes)
end function;

define function instantiable-subclasses
    (superclass :: <class>) => (subclasses :: <sequence>)
  let subclasses = make(<stretchy-vector>);
  for (class in $instantiable-collection-classes)
    if (subtype?(class, superclass))
      add!(subclasses, class);
    end;
  end;
  subclasses
end function;

define sideways method make-test-instance
    (class :: subclass(<collection>)) => (object)
  if (collection-class-instantiable?(class))
    make-collections-of-size(class, 2)[0]
  else
    next-method()
  end
end method make-test-instance;

define sideways method make-test-instance
    (class == <pair>) => (object)
  pair(1, 2)
end method make-test-instance;

define sideways method make-test-instance
    (class == <empty-list>) => (object)
  #()
end method make-test-instance;

define method make-collections-of-size
    (class :: <class>, collection-size :: <integer>)
 => (collections :: <sequence>)
  let sequences = make(<stretchy-vector>);
  let element-type = collection-type-element-type(class);
  if (subtype?(<integer>, element-type))
    add!(sequences, as(class, range(from: 1, to: collection-size)))
  end;
  if (subtype?(<character>, element-type))
    add!(sequences,
         if (collection-size < size($default-string))
           as(class, copy-sequence($default-string, end: collection-size));
         else
           as(class, make(<vector>, size: collection-size, fill: 'a'));
         end)
  end;
  // Only return one for size 0, because they are all the same
  if (collection-size = 0)
    vector(sequences[0])
  else
    sequences
  end
end method make-collections-of-size;

define method make-collections-of-size
    (class :: subclass(<table>), collection-size :: <integer>)
 => (tables :: <sequence>)
  let table-1 = make(<table>);
  let table-2 = make(<table>);
  for (i from 0 below collection-size,
       char in $default-string)
    table-1[i] := i + 1;
    table-2[i] := char;
  end;
  vector(table-1, table-2)
end method make-collections-of-size;

define method make-collections-of-size
    (class == <pair>, collection-size :: <integer>)
 => (pairs :: <sequence>)
  #[]
end method make-collections-of-size;

define method make-collections-of-size
    (class == <empty-list>, collection-size :: <integer>)
 => (lists :: <sequence>)
  if (collection-size = 0)
    vector(#())
  else
    #[]
  end
end method make-collections-of-size;

define method make-limited-collections-of-size
    (class :: <class>, collection-size :: <integer>)
 => (collections :: <sequence>)
  let sequences = make(<stretchy-vector>);
  let element-types = limited-collection-element-types(class);
  for (element-type :: <type> in element-types)
    let type = limited(class, of: element-type);
    if (subtype?(<integer>, element-type))
      add!(sequences, as(type, range(from: 1, to: collection-size)))
    end;
    if (subtype?(<character>, element-type))
      add!(sequences,
           if (collection-size < size($default-string))
             as(type, copy-sequence($default-string, end: collection-size));
           else
             make(type, size: collection-size, fill: 'a');
           end)
    end;
    if (subtype?(<vector>, element-type))
      add!(sequences,
           if (collection-size < size($default-vectors))
             as(type, copy-sequence($default-vectors, end: collection-size));
           else
             make(type, size: collection-size, fill: #[]);
           end)
    end
  end;
  // Only return one for size 0, because they are all the same
  if (collection-size = 0)
    if (size(sequences) > 0)
      vector(sequences[0])
    else
      #[]
    end if
  else
    sequences
  end
end method make-limited-collections-of-size;

define method make-limited-collections-of-size
    (class :: subclass(<table>), collection-size :: <integer>)
 => (tables :: <sequence>)
  let table-1 = make(limited(<table>, of: <integer>));
  let table-2 = make(limited(<table>, of: <character>));
  for (i from 0 below collection-size,
       char in $default-string)
    table-1[i] := i + 1;
    table-2[i] := char;
  end;
  vector(table-1, table-2)
end method make-limited-collections-of-size;

define method make-limited-collections-of-size
    (class :: subclass(<list>), collection-size :: <integer>)
 => (pairs :: <sequence>)
  #[]
end method make-limited-collections-of-size;

define method expected-element
    (collection :: <collection>, index) => (element)
  let element-type = collection-element-type(collection);
  if (element-type = <object>)
    element-type :=
      select (collection[0] by instance?)
        <character> => <character>;
        <integer>   => <integer>;
        <vector>    => <vector>;
      end;
  end;
  select (element-type by subtype?)
    <character> =>
      if (size(collection) < size($default-string))
        $default-string[index]
      else
        'a'
      end;
    <integer>, <real> =>
      index + 1;
    <vector> =>
      if (size(collection) < size($default-vectors))
        $default-vectors[index];
      else
        #[]
      end if;
  end
end method expected-element;

define method expected-key-sequence
    (collection :: <collection>) => (key-sequence :: <sequence>)
  range(from: 0, below: size(collection))
end method expected-key-sequence;


/// Some collection information
define method collection-type-element-type
    (class :: subclass(<collection>)) => (element-type :: <class>)
  <object>
end method collection-type-element-type;

define method collection-type-element-type
    (class :: subclass(<range>)) => (element-type :: <class>)
  <integer>
end method collection-type-element-type;

define method collection-type-element-type
    (class :: subclass(<string>)) => (element-type :: <class>)
  <character>
end method collection-type-element-type;


define method collection-element-type
    (collection :: <collection>) => (element-type :: <type>)
  element-type(collection)
end method collection-element-type;


define method limited-collection-element-types
    (class :: subclass(<collection>)) => (element-types :: <sequence>)
  vector(<integer>, <character>, <vector>)
end method limited-collection-element-types;

define method limited-collection-element-types
    (class :: subclass(<range>)) => (element-types :: <sequence>)
  #[]
end method limited-collection-element-types;

define method limited-collection-element-types
    (class :: subclass(<string>)) => (element-types :: <sequence>)
  #[]
end method limited-collection-element-types;

define generic collection-default (type :: <type>) => (res);

define method collection-default (type :: <class>) => (res)
  #"bad-default"
end method collection-default;

define method collection-default (type :: subclass(<number>)) => (res)
  as(type, -1)
end method collection-default;

define method collection-default (type :: subclass(<character>)) => (res)
  as(type, 0)
end method collection-default;

define method collection-default (type :: subclass(<sequence>)) => (res)
  as(type, #[#"bad-default"])
end method collection-default;


/// Collection test functions
define method test-collection
    (name :: <string>, collection :: <collection>) => ()
  do(method (function) function(name, collection) end,
     vector(// Functions on <collection>
            do-test-as,
            do-test-do,
            do-test-map,
            do-test-map-as,
            do-test-map-into,
            do-test-any?,
            do-test-every?,

            // Generic functions on <collection>
            do-test-element,
            do-test-key-sequence,
            do-test-reduce,
            do-test-reduce1,
            do-test-member?,
            do-test-find-key,
            do-test-key-test,
            do-test-forward-iteration-protocol,
            do-test-backward-iteration-protocol,

            // Methods on <collection>
            do-test-=,
            do-test-empty?,
            do-test-size,
            do-test-shallow-copy
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <sequence>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Functions on <sequence>
            do-test-concatenate,
            do-test-concatenate-as,
            do-test-first,
            do-test-second,
            do-test-third,
            do-test-add,
            do-test-add!,
            do-test-add-new,
            do-test-add-new!,
            do-test-remove,
            do-test-remove!,
            do-test-choose,
            do-test-choose-by,
            do-test-intersection,
            do-test-union,
            do-test-remove-duplicates,
            do-test-remove-duplicates!,
            do-test-copy-sequence,
            do-test-replace-subsequence!,
            do-test-reverse,
            do-test-reverse!,
            do-test-sort,
            do-test-sort!,
            do-test-last,
            do-test-subsequence-position
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <mutable-collection>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Functions on <mutable-collection>
            do-test-map-into,

            // Generic functions on <mutable-collection>
            do-test-element-setter,
            do-test-fill!,         // missing from the DRM.

            // Methods on <mutable-collection>
            do-test-type-for-copy
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <stretchy-collection>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Methods on <stretchy-collection>
            do-test-size-setter
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <mutable-sequence>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Functions on <mutable-sequence>
            do-test-first-setter,
            do-test-second-setter,
            do-test-third-setter,

            // Generic functions on <mutable-sequence>
            do-test-last-setter
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <array>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Functions on <array>
            do-test-rank,
            do-test-row-major-index,
            do-test-aref,
            do-test-aref-setter,
            do-test-dimensions,
            do-test-dimension
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <vector>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Constructors for <vector>
            do-test-vector
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <deque>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Functions on <deque>
            do-test-push,
            do-test-pop,
            do-test-push-last,
            do-test-pop-last
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <list>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Constructors for <list>
            do-test-list,
            do-test-pair,

            // Functions on <list>
            do-test-head,
            do-test-tail
            ))
end method test-collection;

/*---*** Comment this out for the moment because it causes the compiler
  ---*** problems
  ---*** Seems fine now.  Andy said this used to cause hard runtime
         crashes, but it runs fine now.  -carlg 98-08-26 1.1c4
 */
define method test-collection
    (name :: <string>, collection :: <pair>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Functions on <pair>
            do-test-head-setter,
            do-test-tail-setter
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <string>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Methods on <string>
            do-test-<,
            do-test-as-lowercase,
            do-test-as-lowercase!,
            do-test-as-uppercase,
            do-test-as-uppercase!
            ))
end method test-collection;

define method test-collection
    (name :: <string>, collection :: <table>) => ()
  next-method();
  do(method (function) function(name, collection) end,
     vector(// Generic Functions on <table>
            do-test-table-protocol
            ))
end method test-collection;

define method make-array
    (dimensions :: <sequence>) => (array :: <array>)
  let array = make(<array>, dimensions: dimensions);
  for (i from 0 below size(array))
    array[i] := i + 1
  end;
  array
end method make-array;


/// Iteration testing

define constant $iteration-results = make(<stretchy-vector>);

define method iteration-recording-procedure (#rest args) => ()
  add!($iteration-results, args)
end method iteration-recording-procedure;

define method run-iteration-test
    (function :: <function>) => (sequence :: <sequence>)
  $iteration-results.size := 0;
  function(iteration-recording-procedure);
  $iteration-results;
end method run-iteration-test;

define method iteration-test-equal?
    (results :: <sequence>, #rest arguments) => (equal? :: <boolean>)
  block (return)
    for (argument in arguments,
         index from 0)
      for (value in argument,
           result in results)
        unless (value = result[index])
          return(#f)
        end
      end
    end;
    #t
  end
end method iteration-test-equal?;

define method iteration-test-equal?
    (results :: <collection>, #rest arguments) => (equal? :: <boolean>)
  //---*** Need to implement this!
  #f
end method iteration-test-equal?;


/// Utilities for collection testing

// Is the collection 'proper' meaning that it isn't an error to call size?

define method proper-collection?
    (collection :: <collection>) => (proper? :: <boolean>)
  #t
end method proper-collection?;

define method proper-collection?
    (pair :: <pair>) => (proper? :: <boolean>)
  block (return)
    while (#t)
      let tail-element = tail(pair);
      select (tail-element by instance?)
        <empty-list> => return(#t);
        <pair>       => pair := tail-element;
        otherwise    => return(#f);
      end
    end
  end
end method proper-collection?;


/// collection-valid-as-class?
///
/// Can the collection be converted to this class?
///
/// Also, we should probably do some check to make sure that an
/// invalid coercion generates a reasonable error.

define generic collection-valid-as-class?
    (class :: subclass(<collection>), collection :: <collection>)
 => (valid? :: <boolean>);

// In general, you cannot convert an arbitrary collection to any other.
define method collection-valid-as-class?
    (class :: subclass(<collection>), collection :: <collection>)
 => (valid? :: <boolean>)
  #f
end method collection-valid-as-class?;

// Sequences can be coerced if their element types match
define method collection-valid-as-class?
    (class :: subclass(<sequence>), collection :: <sequence>)
 => (valid? :: <boolean>)
  select (collection by instance?)
    class   => #t;
    <range> => #f;
    <array> => #f;
    otherwise =>
      proper-collection?(collection)
        & begin
            let element-type = collection-type-element-type(class);
            select (element-type)
              <object> => #t;
              otherwise =>
                every?(method (item)
                         instance?(item, element-type)
                       end,
                       collection)
            end
          end;
  end
end method collection-valid-as-class?;

// Only ranges can be converted to ranges
define method collection-valid-as-class?
    (class :: subclass(<range>), collection :: <sequence>)
 => (valid? :: <boolean>)
  instance?(collection, <range>)
end method collection-valid-as-class?;

// Only pairs can be converted to pairs
define method collection-valid-as-class?
    (class == <list>, collection :: <sequence>)
 => (valid? :: <boolean>)
  instance?(collection, <pair>)
end method collection-valid-as-class?;

// Pair can never be the class to map into
define method collection-valid-as-class?
    (class == <pair>, collection :: <sequence>)
 => (valid? :: <boolean>)
  #f
end method collection-valid-as-class?;

define method collection-valid-as-class?
    (class == <empty-list>, collection :: <sequence>)
 => (valid? :: <boolean>)
  empty?(collection)
end method collection-valid-as-class?;

// Explicit key collections can always be converted amongst each other
define method collection-valid-as-class?
    (class :: subclass(<explicit-key-collection>),
     collection :: <explicit-key-collection>)
 => (valid? :: <boolean>)
  #t
end method collection-valid-as-class?;


/// Collection testing

define method do-test-as
    (name :: <string>, collection :: <collection>) => ()
  for (class in instantiable-subclasses(<collection>))
    if (collection-valid-as-class?(class, collection))
      let collection-size = size(collection);
      check-true(format-to-string("%s as %s", name, class),
                 begin
                   let new-collection = as(class, collection);
                   instance?(new-collection, class)
                     & size(new-collection) = collection-size
                 end);
    end
  end;
end method;

define method do-test-do
    (name :: <string>, collection :: <collection>) => ()
  if (proper-collection?(collection))
    let do-results
      = run-iteration-test(method (f)
                             do(f, collection)
                           end);
    check-true(format-to-string("%s 'do' using collection once", name),
               iteration-test-equal?(do-results, collection));
    let do-results
      = run-iteration-test(method (f)
                             do(f, collection, collection)
                           end);
    check-true(format-to-string("%s 'do' using collection twice", name),
               iteration-test-equal?(do-results, collection, collection));
  else
    check-condition(format-to-string("%s 'do' errors because improper",
                                     name),
                    <error>,
                    do(identity, collection))
  end
end method;

define method do-test-map
    (name :: <string>, collection :: <collection>) => ()
  if (proper-collection?(collection))
    let new-collection = #f;
    check-equal(format-to-string("%s 'map' with identity", name),
                new-collection := map(identity, collection), collection);
    check-true(format-to-string("%s 'map' creates new collection", name),
               empty?(collection) | new-collection ~== collection);
    check-instance?(format-to-string("%s 'map' uses type-for-copy", name),
                    type-for-copy(collection),
                    new-collection);
  else
    check-condition(format-to-string("%s 'map' errors because improper",
                                     name),
                    <error>,
                    map(identity, collection))
  end
end method;

define method do-test-map-as
    (name :: <string>, collection :: <collection>) => ()
  if (proper-collection?(collection))
    let collection-size = size(collection);
    for (class in instantiable-subclasses(<mutable-collection>))
      //--- Arrays don't take size: as an argument
      if (collection-valid-as-class?(class, collection))
        check-true(format-to-string("%s 'map-as' %s with identity", name, class),
                   begin
                     let new-collection
                       = map-as(class, identity, collection);
                     instance?(new-collection, class)
                       & size(new-collection) = collection-size
                   end);
      end;
    end;
  else
    check-condition(format-to-string("%s 'map-as' errors because improper", name),
                    <error>,
                    map(identity, collection));
  end
end method;

define method do-test-map-into
    (name :: <string>, collection :: <collection>) => ()
  if (proper-collection?(collection))
    let new-collection = make(<vector>, size: size(collection));
    check-equal(format-to-string("%s 'map-into' with identity", name),
                map-into(new-collection, identity, collection),
                collection)
  else
    check-condition(format-to-string("%s 'map-into' errors because improper",
                                     name),
                    <error>,
                    map-into(make(<vector>, size: 100), identity, collection))
  end
end method;

define method do-test-any?
    (name :: <string>, collection :: <collection>) => ()
  if (proper-collection?(collection))
    check-equal(format-to-string("%s any? always matching", name),
                any?(always(#t), collection),
                ~empty?(collection));
    check-false(format-to-string("%s any? never matching", name),
                any?(always(#f), collection));
  else
    check-condition(format-to-string("%s any? errors because improper", name),
                    <error>,
                    any?(always(#t), collection))
  end
end method;

define method do-test-every?
    (name :: <string>, collection :: <collection>) => ()
  if (proper-collection?(collection))
    check-true(format-to-string("%s every? always matching", name),
               every?(always(#t), collection));
    check-true(format-to-string("%s every? never matching", name),
               empty?(collection) | ~every?(always(#f), collection))
  else
    check-condition(format-to-string("%s every? errors because improper", name),
                    <error>,
                    every?(always(#t), collection))
  end
end method;

define method do-test-element
    (name :: <string>, collection :: <collection>) => ()
  check-condition(format-to-string("%s element of -1 errors", name),
                  <error>,
                  element(collection, -1));
  check-condition(format-to-string("%s element of size errors", name),
                  <error>,
                  element(collection, size(collection)));
  let type    = collection-element-type(collection);
  let default = collection-default(type);
  check-equal(format-to-string("%s element default", name),
              element(collection, -1, default: default),
              default);
  unless (type == <object>)
    check-condition(format-to-string("%s element wrong default type errors", name),
                    <error>,
                    element(collection, -1, default: #"wrong-default-type"));
  end unless;
  for (key in key-sequence(collection))
    check-equal(format-to-string("%s element %=", name, key),
                element(collection, key), expected-element(collection, key))
  end
end method;

define method do-test-key-sequence
    (name :: <string>, collection :: <collection>) => ()
  check-equal(format-to-string("%s key-sequence", name),
              sort(key-sequence(collection)),
              expected-key-sequence(collection))
end method;

define method do-test-reduce
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-reduce1
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-member?
    (name :: <string>, collection :: <collection>) => ()
  check-false(format-to-string("%s member? of non-member", name),
              member?(#"non-member", collection));
  for (key in key-sequence(collection))
    check-true(format-to-string("%s key %= is member?", name, key),
               member?(collection[key], collection));
    check-false(format-to-string("%s key %= is member? with failing test",
                                 name, key),
                member?(collection[key], collection, test: always(#f)))
  end
end method;

define method do-test-find-key
    (name :: <string>, collection :: <collection>) => ()
  check-equal(format-to-string("%s find-key failure", name),
              #f, find-key(collection, curry(\=, #"no-such-key")));
  check-equal(format-to-string("%s find-key failure value", name),
              #"failure",
              find-key(collection, curry(\=, #"no-such-key"),
                       failure: #"failure"));
  for (item in collection)
    check-equal(format-to-string("%s find-key %=", name, item),
                item,
                element(collection, find-key(collection, curry(\=, item))))
  end
end method;

define method do-test-key-test
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-forward-iteration-protocol
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-backward-iteration-protocol
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-=
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-empty?
    (name :: <string>, collection :: <collection>) => ()
  check-equal(format-to-string("%s empty?", name),
              empty?(collection),
              size(collection) = 0)
end method;

define method do-test-size
    (name :: <string>, collection :: <collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-shallow-copy
    (name :: <string>, collection :: <collection>) => ()
  let copy = #f;
  check-instance?(format-to-string("%s shallow-copy uses type-for-copy", name),
                  type-for-copy(collection),
                  copy := shallow-copy(collection));
  if (copy)
    let new-copy-needed?
      = instance?(collection, <mutable-collection>) & ~empty?(collection);
    if (new-copy-needed?)
      check-true(format-to-string("%s shallow-copy creates new object", name),
                 copy ~== collection);
      check-true(format-to-string("%s shallow-copy creates correct elements", name),
                 copy = collection)
    end
  end
end method;


/// Mutable collection testing

define method do-test-map-into
    (name :: <string>, collection :: <mutable-collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-element-setter
    (name :: <string>, collection :: <mutable-collection>) => ()
  //---*** Fill this in...
end method;

define method do-test-fill!
    (name :: <string>, collection :: <mutable-collection>) => ()
  //---*** Fill this in...
end method;

define method valid-type-for-copy?
    (type :: <type>, collection :: <collection>)
 => (valid-type? :: <boolean>)
  subtype?(type, <mutable-collection>)
    & instance?(type, <class>)
end method valid-type-for-copy?;

define method valid-type-for-copy?
    (type :: <type>, collection :: <sequence>)
 => (valid-type? :: <boolean>)
  subtype?(type, <sequence>)
    & next-method()
end method valid-type-for-copy?;

define method valid-type-for-copy?
    (type :: <type>, collection :: <explicit-key-collection>)
 => (valid-type? :: <boolean>)
  subtype?(type, <explicit-key-collection>)
    & next-method()
end method valid-type-for-copy?;

define method valid-type-for-copy?
    (type :: <type>, collection :: <mutable-collection>)
 => (valid-type? :: <boolean>)
  //--- The DRM pg. 293 says that this should be == object-class(collection)
  //--- but that doesn't work in the emulator. Which should it be?
  if (instance?(collection, <limited-collection>))
    instance?(collection, type)
  else
    subtype?(object-class(collection), type)
  end if
end method valid-type-for-copy?;

define method valid-type-for-copy?
    (type :: <type>, collection :: <range>)
 => (valid-type? :: <boolean>)
  type == <list>
end method valid-type-for-copy?;

define method do-test-type-for-copy
    (name :: <string>, collection :: <mutable-collection>) => ()
  check-true(format-to-string("%s type-for-copy", name),
             begin
               let type = type-for-copy(collection);
               valid-type-for-copy?(type, collection)
             end)
end method;

// Note that size-setter is only on both <stretchy-collection>
// and <sequence>! Why is there no <stretchy-sequence>?
define method do-test-size-setter
    (name :: <string>, collection :: <stretchy-collection>) => ()
  if (instance?(collection, <sequence>))
    let new-size = size(collection) + 5;
    if (instance?(#f, collection-element-type(collection)))
      check-equal(format-to-string("%s resizes", name),
                  begin
                    size(collection) := new-size;
                    size(collection)
                  end,
                  new-size)
    end;
    check-equal(format-to-string("%s emptied", name),
                begin
                  size(collection) := 0;
                  size(collection)
                end,
                0);
  end
end method;



/// Sequence testing

define method do-test-concatenate
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-concatenate-as
    (name :: <string>, sequence :: <sequence>) => ()
  for (class in instantiable-subclasses(<mutable-sequence>))
    if (collection-valid-as-class?(class, sequence)
          //---*** Currently pairs crash concatenate-as
          & class ~== <pair>)
      let sequence-size = size(sequence);
      let sequence-empty? = empty?(sequence);
      check-true(format-to-string("%s concatenate-as %s identity", name, class),
                 begin
                   let collection = concatenate-as(class, sequence);
                   instance?(collection, class)
                     & (collection = sequence)
                 end);
      check-true(format-to-string("%s concatenate-as %s", name, class),
                 begin
                   let collection = concatenate-as(class, sequence, sequence);
                   instance?(collection, class)
                     & (size(collection) = sequence-size * 2)
                     & (sequence-empty?
                          | (collection[0] = sequence[0]
                               & collection[sequence-size] = sequence[0]))
                 end);
      check-true(format-to-string("%s concatenate-as %s three times", name, class),
                 begin
                   let collection
                     = concatenate-as(class, sequence, sequence, sequence);
                   instance?(collection, class)
                     & (size(collection) = sequence-size * 3)
                     & (sequence-empty?
                          | (collection[0] = sequence[0]
                               & collection[sequence-size] = sequence[0]
                               & collection[sequence-size * 2] = sequence[0]))
                 end);
    end
  end;
end method;

define method do-test-nth-getter
    (name :: <string>, sequence :: <sequence>,
     nth-getter :: <function>, n :: <integer>)
 => ()
  let nth-item = size(sequence) > n & sequence[n];
  if (nth-item)
    check-equal(name, nth-getter(sequence), nth-item)
  else
    check-condition(format-to-string("%s generates an error", name),
                    <error>,
                    nth-getter(sequence))
  end;
end method;

define method do-test-first
    (name :: <string>, sequence :: <sequence>) => ()
  let name = format-to-string("%s first", name);
  do-test-nth-getter(name, sequence, first, 0)
end method;

define method do-test-second
    (name :: <string>, sequence :: <sequence>) => ()
  let name = format-to-string("%s second", name);
  do-test-nth-getter(name, sequence, second, 1)
end method;

define method do-test-third
    (name :: <string>, sequence :: <sequence>) => ()
  let name = format-to-string("%s third", name);
  do-test-nth-getter(name, sequence, third, 2)
end method;

define method do-test-add
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-add!
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-add-new
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-add-new!
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-remove
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-remove!
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-choose
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-choose-by
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-intersection
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-union
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-remove-duplicates
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-remove-duplicates!
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method valid-copy-of-sequence?
    (new-sequence :: <sequence>, old-sequence :: <sequence>)
 => (valid-copy? :: <boolean>)
 instance?(new-sequence, type-for-copy(old-sequence))
   & old-sequence = new-sequence
end method valid-copy-of-sequence?;

define method valid-copy-of-sequence?
    (new-sequence :: <sequence>, old-sequence :: <range>)
 => (valid-copy? :: <boolean>)
 // DRM says copy-sequence ignores type-for-copy for ranges!
 instance?(new-sequence, <range>)
   & old-sequence = new-sequence
end method valid-copy-of-sequence?;

define method do-test-copy-sequence
    (name :: <string>, sequence :: <sequence>) => ()
  check-true(format-to-string("%s copy-sequence", name),
             begin
               let new-sequence = copy-sequence(sequence);
               valid-copy-of-sequence?(new-sequence, sequence)
             end)
end method;

define method do-test-replace-subsequence!
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method valid-reversed-sequence?
    (new-sequence :: <sequence>, old-sequence :: <sequence>)
 => (valid? :: <boolean>)
  let old-size = size(old-sequence);
  instance?(new-sequence, <sequence>)
    & size(new-sequence) = old-size
    & every?(method (i)
               old-sequence[i] = new-sequence[old-size - i - 1]
             end,
             range(from: 0, below: old-size))
end method valid-reversed-sequence?;

define method do-test-reverse
    (name :: <string>, sequence :: <sequence>) => ()
  let sequence-size = size(sequence);
  if (sequence-size)
    check-true(format-to-string("%s reverse", name),
               begin
                 let reversed-sequence = reverse(sequence);
                 let new-copy-needed? = ~empty?(sequence);
                 if (new-copy-needed?)
                   check-true(format-to-string("%s reverse didn't mutate original", name),
                              reversed-sequence ~== sequence)
                 end;
                 valid-reversed-sequence?(reversed-sequence, sequence)
               end)
  else
    check-condition(format-to-string("%s reverse errors because unbounded", name),
                    <error>,
                    reverse(sequence))
  end
end method;

define method do-test-reverse!
    (name :: <string>, sequence :: <sequence>) => ()
  let sequence-size = size(sequence);
  if (sequence-size)
    check-true(format-to-string("%s reverse!", name),
               begin
                 let old-sequence = copy-sequence(sequence);
                 let reversed-sequence = reverse!(old-sequence);
                 valid-reversed-sequence?(reversed-sequence, sequence)
               end)
  else
    check-condition(format-to-string("%s reverse! errors", name),
                    <error>,
                    reverse!(sequence))
  end
end method;

define function do-test-equal? (x, y) => (well? :: <boolean>)
  x = y
end function;

define method do-test-less?
    (x, y) => (well? :: <boolean>)
  x < y
end method;

define method do-test-less?
    (x :: <vector>, y :: <vector>) => (well? :: <boolean>)
  x[0] < y[0]
end method;

define function do-test-less-or-equal? (x, y) => (well? :: <boolean>)
  do-test-less?(x, y) | do-test-equal?(x, y)
end function;

define function do-test-greater? (x, y) => (well? :: <boolean>)
  ~do-test-less?(x, y)
end function;

define method sequence-sorted?
    (sequence :: <sequence>, #key test = do-test-less-or-equal?)
 => (sorted? :: <boolean>)
  every?(method (i)
           test(sequence[i], sequence[i + 1])
         end,
         range(from: 0, below: size(sequence) - 1))
end method sequence-sorted?;

define method do-test-sorted-sequence
    (name :: <string>, new-sequence, old-sequence :: <sequence>,
     #key test = do-test-less-or-equal?)
 => ()
  let old-size = size(old-sequence);
  check-instance?(format-to-string("%s returns a sequence", name),
                  <sequence>,
                  new-sequence);
  check-true(format-to-string("%s all elements in order", name),
             size(new-sequence) = old-size
               & sequence-sorted?(new-sequence, test: test)
               & every?(method (x)
                          member?(x, old-sequence)
                        end,
                        new-sequence))
end method;

define method do-test-sort-options
    (name :: <string>, sequence :: <sequence>,
     #key test = do-test-less-or-equal?,
          copy-function = copy-sequence,
          sort-function = sort)
 => ()
  let copy = #f;
  let sorted-sequence = #f;
  check-true(format-to-string("%s copies if necessary", name),
             begin
               copy := copy-function(sequence);
               let new-copy-needed?
                 = sort-function == sort
                     & ~sequence-sorted?(sequence, test: test);
               sorted-sequence := sort-function(copy, test: test);
               ~new-copy-needed? | sorted-sequence ~== copy
             end);
  if (copy & sorted-sequence)
    do-test-sorted-sequence(name, sorted-sequence, copy, test: test)
  end
end method;

define method do-test-sort
    (name :: <string>, sequence :: <sequence>, #key sort-function = sort)
 => ()
  let sort-name
    = format-to-string("%s sort%s",
                       name, if (sort-function == sort!) "!" else "" end);
  do-test-sort-options(sort-name,
                       sequence,
                       sort-function: sort-function);
  do-test-sort-options(format-to-string("reversed %s", sort-name),
                       sequence,
                       sort-function: sort-function, copy-function: reverse);
  do-test-sort-options(format-to-string("%s with > test", sort-name),
                       sequence,
                       sort-function: sort-function, test: do-test-greater?);
end method;

define method do-test-sort!
    (name :: <string>, sequence :: <sequence>) => ()
  do-test-sort(name, sequence, sort-function: sort!)
end method;

define method do-test-last
    (name :: <string>, sequence :: <sequence>) => ()
  let sequence-size = size(sequence);
  let last-item = sequence-size & sequence-size > 0 & sequence[sequence-size - 1];
  case
    last-item =>
      check-equal(format-to-string("%s 'last' returns last item", name),
                  last(sequence), last-item);
    otherwise =>
      check-condition(format-to-string("%s 'last' generates an error", name),
                      <error>,
                      last(sequence))
  end;
end method;

define method do-test-subsequence-position
    (name :: <string>, sequence :: <sequence>) => ()
  //---*** Fill this in...
end method;

define method do-test-nth-setter
    (name :: <string>, sequence :: <mutable-sequence>,
     nth-setter :: <function>, n :: <integer>)
 => ()
  let item
    = select (collection-element-type(sequence) by subtype?)
        <character> => 'z';
        <number>    => 100;
        <vector>    => #['z'];
        <object>    => 100;
      end;
  case
    n < size(sequence) =>
      check-true(name,
                 begin
                   let copy = shallow-copy(sequence);
                   nth-setter(item, copy);
                   copy[n] = item
                 end);
    instance?(sequence, <stretchy-collection>)
      & (n = size(sequence) |
           instance?(#f, collection-element-type(sequence))) =>
      check-true(name,
                 begin
                   let copy = shallow-copy(sequence);
                   nth-setter(item, copy);
                   size(copy) = n + 1
                     & copy[n] = item
                 end);
    otherwise =>
      check-condition(format-to-string("%s generates an error", name),
                      <error>,
                      begin
                        let copy = shallow-copy(sequence);
                        nth-setter(item, copy)
                      end);
  end;
end method;

define method do-test-first-setter
    (name :: <string>, sequence :: <mutable-sequence>) => ()
  let name = format-to-string("%s first-setter", name);
  do-test-nth-setter(name, sequence, first-setter, 0)
end method;

define method do-test-second-setter
    (name :: <string>, sequence :: <mutable-sequence>) => ()
  let name = format-to-string("%s second-setter", name);
  do-test-nth-setter(name, sequence, second-setter, 1)
end method;

define method do-test-third-setter
    (name :: <string>, sequence :: <mutable-sequence>) => ()
  let name = format-to-string("%s third-setter", name);
  do-test-nth-setter(name, sequence, third-setter, 2)
end method;

define method do-test-last-setter
    (name :: <string>, sequence :: <mutable-sequence>) => ()
  let sequence-size = size(sequence);
  let last-key = sequence-size & sequence-size > 0 & sequence-size - 1;
  let item
    = select (collection-element-type(sequence) by subtype?)
        <character> => 'z';
        <number>    => 100;
        <vector>    => #['z'];
        <object>    => 100;
      end;
  case
    last-key =>
      check-true(format-to-string("%s last", name),
                 begin
                   let old-item = sequence[last-key];
                   last(sequence) := item;
                   let new-item = sequence[last-key];
                   sequence[last-key] := old-item;
                   new-item = item
                 end);
    otherwise =>
      check-condition(format-to-string("%s last-setter generates an error", name),
                      <error>,
                      last(sequence) := item)
  end;
end method;


/// Stretchy sequence testing

define method do-test-rank
    (name :: <string>, array :: <array>) => ()
  //---*** Fill this in...
end method;

define method do-test-row-major-index
    (name :: <string>, array :: <array>) => ()
  //---*** Fill this in...
end method;

define method do-test-aref
    (name :: <string>, array :: <array>) => ()
  //---*** Fill this in...
end method;

define method do-test-aref-setter
    (name :: <string>, array :: <array>) => ()
  //---*** Fill this in...
end method;

define method do-test-dimensions
    (name :: <string>, array :: <array>) => ()
  //---*** Fill this in...
end method;

define method do-test-dimension
    (name :: <string>, array :: <array>) => ()
  //---*** Fill this in...
end method;


/// Vector tests

define method do-test-vector
    (name :: <string>, array :: <vector>) => ()
  //---*** Fill this in...
end method;


/// Deque tests

define method do-test-push
    (name :: <string>, deque :: <deque>) => ()
  //---*** Fill this in...
end method;

define method do-test-pop
    (name :: <string>, deque :: <deque>) => ()
  //---*** Fill this in...
end method;

define method do-test-push-last
    (name :: <string>, deque :: <deque>) => ()
  //---*** Fill this in...
end method;

define method do-test-pop-last
    (name :: <string>, deque :: <deque>) => ()
  //---*** Fill this in...
end method;


/// List tests

define method do-test-list
    (name :: <string>, list :: <list>) => ()
  //---*** Fill this in...
end method;

define method do-test-pair
    (name :: <string>, list :: <list>) => ()
  //---*** Fill this in...
end method;

define method do-test-head
    (name :: <string>, list :: <list>) => ()
  //---*** Fill this in...
end method;

define method do-test-tail
    (name :: <string>, list :: <list>) => ()
  //---*** Fill this in...
end method;


/// Pair tests

define method do-test-head-setter
    (name :: <string>, pair :: <pair>) => ()
  //---*** Fill this in...
end method;

define method do-test-tail-setter
    (name :: <string>, pair :: <pair>) => ()
  //---*** Fill this in...
end method;


/// String tests

define method do-test-<
    (name :: <string>, string :: <string>) => ()
  //---*** Fill this in...
end method;

define method valid-as-new-case?
    (new-string, old-string :: <sequence>, test :: <function>)
 => (valid? :: <boolean>)
  let old-size = size(old-string);
  instance?(new-string, <string>)
    & size(new-string) = old-size
    & every?(method (i)
               new-string[i] = test(old-string[i])
             end,
             range(from: 0, below: old-size))
end method valid-as-new-case?;

define method do-test-as-lowercase
    (name :: <string>, string :: <string>) => ()
  check-true(format-to-string("%s as-lowercase", name),
             begin
               let new-string = as-lowercase(string);
               unless (empty?(string))
                 check-true(format-to-string("%s as-lowercase not destructive", name),
                            new-string ~== string)
               end;
               valid-as-new-case?(new-string, string, as-lowercase)
             end)
end method;

define method do-test-as-lowercase!
    (name :: <string>, string :: <string>) => ()
  check-true(format-to-string("%s as-lowercase!", name),
             begin
               let old-string = copy-sequence(string);
               let new-string = as-lowercase(old-string);
               valid-as-new-case?(new-string, string, as-lowercase)
             end)
end method;

define method do-test-as-uppercase
    (name :: <string>, string :: <string>) => ()
  check-true(format-to-string("%s as-uppercase", name),
             begin
               let new-string = as-uppercase(string);
               unless (empty?(string))
                 check-true(format-to-string("%s as-uppercase not destructive", name),
                            new-string ~== string)
               end;
               valid-as-new-case?(new-string, string, as-uppercase)
             end)
end method;

define method do-test-as-uppercase!
    (name :: <string>, string :: <string>) => ()
  check-true(format-to-string("%s as-uppercase!", name),
             begin
               let old-string = copy-sequence(string);
               let new-string = as-uppercase(old-string);
               valid-as-new-case?(new-string, string, as-uppercase)
             end)
end method;


/// Table tests

define method do-test-table-protocol
    (name :: <string>, table :: <table>) => ()
  //---*** Fill this in...
end method;


