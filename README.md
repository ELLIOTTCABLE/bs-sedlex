<h1><img alt='Maintenance status: maintained' src="https://img.shields.io/maintenance/yes/2019.svg?style=popout-square&logo=verizon&logoColor=000000" align=right><a href="https://github.com/ELLIOTTCABLE/bs-sedlex/releases" align=right><img alt='Latest npm release' src="https://img.shields.io/npm/v/bs-sedlex.svg?style=popout-square&logo=npm&label=bs%20version" align=right></a><a target="_blank" href="https://travis-ci.com/ELLIOTTCABLE/bs-sedlex" align=right><img alt='Build status on Travis-CI' src="https://img.shields.io/travis/com/ELLIOTTCABLE/bs-sedlex.svg?style=popout-square&logo=travis&label=bs%20build" align=right></a><a target="_blank" href="https://twitter.com/intent/follow?screen_name=ELLIOTTCABLE" align=right><img alt='Follow my work on Twitter' src="https://img.shields.io/twitter/follow/ELLIOTTCABLE.svg?style=popout-square&logo=twitter&label=%40ELLIOTTCABLE&color=blue" align=right></a>
<code>bs-sedlex</code></h1>

> **For details on purpose, usage, and API of sedlex, [scroll down](#sedlex).** These sections added
> at the top is specific to ways that installation and usage of the `bs-sedlex` distribution
> **differ** from using the upstream release.

This repository contains a fork of the [sedlex][] lexer-generator tooling for OCaml-family
languages, packaged for use in projects utilizing [BuckleScript][] (an OCaml-to-JavaScript compiler)
and [ReasonML][] (an alternative OCaml syntax targeting that compiler.)

Care is taken in this project to publish pre-compiled binaries of the [ppx
syntax-extension](#lexer-specifications) component necessary to use sedlex in practice. These are
published to npm as the separate package [`ppx-sedlex`][ppx-sedlex], versioned in lockstep with the
parent `bs-sedlex` package. Instructions for *enabling* this extension in your BuckleScript
configuration-file, `bsconfig.json`, are included below. Don't miss them!

   [sedlex]: <https://github.com/ocaml-community/sedlex>
      "The upstream distribution of sedlex, maintained by the OCaml community"
   [BuckleScript]: <https://bucklescript.github.io/>
   [ReasonML]: <https://reasonml.github.io/>
   [ppx-sedlex]: <https://www.npmjs.com/package/ppx-sedlex>
      "The native syntax-extension component of bs-sedlex, published separately to npm"

## Installation in BuckleScript projects

You can safely ignore the installation instructions in the upstream README reproduced below, when
compiling to JS using BuckleScript. Instead:

1. If you're writing an app or a similar end-consumer project, install BuckleScript compiler (a
   peerDependency of this project) via [npm][].

   ```sh
   $ npm install --save bs-platform
   ```

   Worh repeating: *do not add this dependencies to a library.* The final application-developer
   should generally select the version of the BuckleScript compiler; you don't want users having
   duplicated versions of the compiler in their `node_modules`. Instead, library developers should
   add `bs-platform` to both `"peerDependencies"` (with a permissive version), and
   `"devDependencies"` (with a restrictive version):

   ```sh
   $ npm install --save-dev bs-platform
   ```

   ```diff
    "devDependencies": {
      ...
      "bs-platform": "^5.0.0"
    },
    "peerDependencies": {
   +  "bs-platform": "4.x || 5.x" // example. express the versions of BuckleScript you support here.
    },
   ```

2. Add the ppx transformer to your `"devDependencies"`:

   ```sh
   $ npm install --save-dev ppx-sedlex
   ```

3. Add the runtime package (this one!) to your direct `"dependencies"`, for both libraries and apps:

   ```sh
   $ npm install --save bs-sedlex
   ```

4. Manually add the the runtime package (`bs-sedlex`) to your `bsconfig.json`'s `bs-dependencies`
   field:

   ```diff
    "bs-dependencies": [
      ...
   +  "bs-sedlex"
    ],
   ```

5. Additionally tell BuckleScript to apply the `ppx-sedlex` syntax-transformer over your source-code
   by adding a `ppx-flags` field at the root level of the same `bsconfig.json`. (Note that,
   unintuitively, this is *not* a relative path; it follows the format `package-name/file-path`.)

   ```diff
    "bs-dependencies": [
      ...
      "bs-sedlex"
    ],
   +"ppx-flags": [
   +   "ppx-sedlex/ppx.js"
   +],
   ```

6. Write blazing-fast, type-safe, and Unicode-aware / multilingual lexers and parsers galore!

   [npm]: <https://www.npmjs.com/>
      "npm, the package-manager for the JavaScript ecosystem"

## Versioning of this package
Thanks to [SemVer not including a ‘generation’ number][semver-213], there's really no way I can
reasonably tie this project's version on npm to the upstream version of Sedlex as released by the
community maintainers. As ugly as it is, I've opted to pin the *major version* of `bs-sedlex`, to
the *flattened* major and minor versions of the upstream project.

I started doing this with Sedlex 2.0; thus, the mapping looks like this:

| Sedlex    | `bs-sedlex` |
| --------- | ----------- |
| `v1.99.4` | `v1.99.4`   |
| `v2.0`    | `v20.0.x`   |

Correspondingly, this project can't really strictly adhere to SemVer. Tentatively, I intend to use
the ‘minor’ field for breaking changes to the port, and the ‘patch’ field for everything else.

   [semver-213]: <https://github.com/semver/semver/issues/213#issuecomment-266914818>
      "A discussion around extending SemVer with an additional, human-focused major component"

## Parser-writing tips from a fellow JavaScripter

I'm dogfooding this port on a parsing-project in JavaScript & ML (Excmd.js, <https://excmd.js.org>).
Feel free to refer to that for a real-world example of compiling industrial-strength OCaml parsing
tooling down to JavaScript for the web. Some takeaways follow:

 - Use [Menhir][] for parser-generation. Seriously. It's got [spectacularly clear
   docs][menhir-docs], an [entire chapter in Real World OCaml][menhir-rwo] dedicated to it, and a
   laundry-list of advanced features — everything from automated tooling that *explains* reported
   parsing-conflicts to you, neophyte language-developer; to [an incremental-parsing
   API][menhir-incremental] allowing you to implement extremely advanced error-recovery and
   introspection/reporting tools.

 - If you want to take that advice, unfortunately, there's no cool, easy port to JavaScript for you,
   like this one for Sedlex. 😉 (Maybe I'll publish one someday!) Until one exists, you'll have to
   maintain a dualistic build-system that uses the standard OCaml tooling and build-system (i.e.
   [opam][] and <https://dune.build>) to produce the `.ml` parsing-automaton, and then feed that
   into the BuckleScript build. Maybe you can [glean][excmd-bsconf-generators] some
   [ideas][excmd-bsconf-sources] from [my experiences][excmd-dune-libraries] here.

 - A major selling-point of sedlex is the deep and thorough Unicode compatibility. Use it! [I
   suggest][uax-notes] reading through the Unicode Consortium's documentation on the topics, known
   as Unicode Standard Annex №. 31, or [UAX#31][uax31]. It goes into more detail than you could ever
   want to know about a vast number of topics. Get this stuff right!

 - I (ELLIOTTCABLE) am also very happy to help with any of these topics — I spent a lot of time and
   effort figuring this out; and although it'll hopefully improve as the BuckleScript community
   grows, until then, there's a lot of minutae to get just right. I'm active on both the
   [OCaml][ocaml-discord] and [ReasonML][reasonml-discord] Discord servers (why there are *two*, I
   cannot fathom); as well as on the Freenode IRC server, in both `#ocaml` and
   [`#ELLIOTTCABLE`](http://ell.io/irc). Feel free to reach out if you just want to chat about these
   topics, or to get more formal support!

   [Menhir]: <http://gallium.inria.fr/~fpottier/menhir/> "The Menhir parser-generator for OCaml"
   [menhir-docs]: <http://gallium.inria.fr/~fpottier/menhir/manual.html>
      "HTML version of Menhir's in-depth documentation"
   [menhir-rwo]: <https://dev.realworldocaml.org/parsing-with-ocamllex-and-menhir.html>
      "Real World OCaml - Chapter 16: Parsing with OCamllex and Menhir"
   [menhir-incremental]: <http://gallium.inria.fr/~fpottier/menhir/manual.html#sec57>
      "Menhir manual: the Incremental API"
   [opam]: <https://opam.ocaml.org/> "opam, the OCaml package-manager"
   [excmd-bsconf-generators]: <https://github.com/ELLIOTTCABLE/excmd.js/blob/63ac20b5/bsconfig.json#L21-L42>
      "Setting up the undocumented 'generators' configuration in bsb to invoke Menhir"
   [excmd-bsconf-sources]: <https://github.com/ELLIOTTCABLE/excmd.js/blob/63ac20b5/bsconfig.json#L5-L13>
      "Using the undocumented 'generators' configuration in bsb to produce a parser-automaton"
   [excmd-dune-libraries]: <https://github.com/ELLIOTTCABLE/excmd.js/blob/63ac20b5/src/dune#L4>
      "Ensuring menhirLib is reachable from the OCaml side"
   [uax-notes]: <https://github.com/ELLIOTTCABLE/excmd.js#internationalization-concerns-wrt-lexing>
      "My own notes on UAX#31 adherence with regards to lexing and sedlex"
   [uax31]: <http://unicode.org/reports/tr31/>
      "Unicode® Standard Annex #31: Unicode Identifier and Pattern Syntax"
   [ocaml-discord]: <https://discord.gg/cCYQbqN>
      "Official OCaml Discord server"
   [reasonml-discord]: <https://discordapp.com/invite/reasonml>
      "Official ReasonML Discord server"

# sedlex

[![Build Status](https://travis-ci.com/ocaml-community/sedlex.svg?branch=master)](https://travis-ci.com/ocaml-community/sedlex)

Unicode-friendly lexer generator for OCaml.

This package is licensed by LexiFi under the terms of the MIT license.

sedlex was originally written by Alain Frisch
<alain.frisch@lexifi.com> and is now maintained as part of the
ocaml-community repositories on github.

## API
The API is documented [here](https://ocaml-community.github.io/sedlex).

## Overview

sedlex is a lexer generator for OCaml, similar to ocamllex, but
supporting Unicode.  Contrary to ocamllex, lexer specifications for
sedlex are embedded in regular OCaml source files.

The lexers work with a new kind of "lexbuf", similar to ocamllex
Lexing lexbufs, but designed to support Unicode, and abstracting from
a specific encoding.  A single lexer can work with arbitrary encodings
of the input stream.

sedlex is the successor of the ulex project. Contrary to ulex which
was implemented as a Camlp4 syntax extension, sedlex is based on the
new "-ppx" technology of OCaml, which allow rewriting OCaml parse
trees through external rewriters. (And what a better name than "sed"
for a rewriter?)

As any -ppx rewriter, sedlex does not touch the concrete syntax of the
language: lexer specifications are written in source file which comply
with the standard grammar of OCaml programs. sedlex reuse the syntax
for pattern matching in order to describe lexers (regular expressions
are encoded within OCaml patterns). A nice consequence is that your
editor (vi, emacs, ...) won't get confused (indentation, coloring) and
you don't need to learn new priority rules. Moreover, sedlex is
compatible with any front-end parsing technology: it works fine even
if you use camlp4 or camlp5, with the standard or revised syntax.


## Lexer specifications


sedlex adds a new kind of expression to OCaml: lexer definitions.
The syntax for the new construction is:

```ocaml
  match%sedlex lexbuf with
  | R1 -> e1
  ...
  | Rn -> en
  | _  -> def
```

or:

```ocaml
  [%sedlex match lexbuf with 
  | R1 -> e1
  ...
  | Rn -> en
  | _  -> def
  ]
```

(The first vertical bar is optional as in any OCaml pattern matching.
Guard expressions are not allowed.)

where:
- lexbuf is an arbitrary lowercase identifier, which must refer to
  an existing value of type `Sedlexing.lexbuf`.
- the Ri are regular expressions (see below);
- the ei and def are OCaml expressions (called actions) of the same type
  (the type for the whole lexer definition).

Unlike ocamllex, lexers work on stream of Unicode codepoints, not
bytes.

The actions can call functions from the Sedlexing module to extract
(parts of) the matched lexeme, in the desired encoding.

Regular expressions are syntactically OCaml patterns:

- `"...."` (string constant): recognize the specified string
- `'....'` (character constant) : recognize the specified character
- `i` (integer constant) : recognize the specified codepoint
- `'...' .. '...'`: character range
- `i1 .. i2`: range between two codepoints
- `R1 | R2` : alternation
- `R, R2, ..., Rn` : concatenation
- `Star R` : Kleene star (0 or more repetition)
- `Plus R` : equivalent to `R, R*`
- `Opt R` : equivalent to `("" | R)`
- `Rep (R, n)` : equivalent to `R{n}`
- `Rep (R, n .. m)` : equivalent to `R{n, m}`
- `Chars "..."` : recognize any character in the string
- `Compl R` : assume that R is a single-character length regexp (see below)
  and recognize the complement set
- `Sub (R1,R2)` : assume that R is a single-character length regexp (see below)
  and recognize the set of items in `R1` but not in `R2` ("subtract")
- `Intersect (R1,R2)` : assume that `R` is a single-character length regexp (see
  below) and recognize the set of items which are in both `R1` and `R2`
- `lid` (lowercase identifier) : reference a named regexp (see below)

A single-character length regexp is a regexp which does not contain (after
expansion of references) concatenation, Star, Plus, Opt or string constants
with a length different from one.



Note:
 - The OCaml source is assumed to be encoded in Latin1 (for string
   and character literals).


It is possible to define named regular expressions with the following
construction, that can appear in place of a structure item:

```ocaml
  let lid = [%sedlex.regexp? R]
```

where lid is the regexp name to be defined and R its definition.  The
scope of the "lid" regular expression is the rest of the structure,
after the definition.

The same syntax can be used for local binding:

```ocaml
  let lid = [%sedlex.regexp? R] in
  body
```

The scope of "lid" is the body expression.


## Predefined regexps

sedlex provides a set of predefined regexps:
- any: any character
- eof: the virtual end-of-file character
- xml_letter, xml_digit, xml_extender, xml_base_char, xml_ideographic,
  xml_combining_char, xml_blank: as defined by the XML recommandation
- tr8876_ident_char: characters names in identifiers from ISO TR8876
- cc, cf, cn, co, cs, ll, lm, lo, lt, lu, mc, me, mn, nd, nl, no, pc, pd,
  pe, pf, pi, po, ps, sc, sk, sm, so, zl, zp, zs: as defined by the
  Unicode standard (categories)
- alphabetic, ascii_hex_digit, hex_digit, id_continue, id_start,
  lowercase, math, other_alphabetic, other_lowercase, other_math,
  other_uppercase, uppercase, white_space, xid_continue, xid_start: as
  defined by the Unicode standard (properties)


## Running a lexer

See the interface of the Sedlexing module for a description of how to
create lexbuf values (from strings, stream or channels encoded in
Latin1, utf8 or utf16, or from integer arrays or streams representing
Unicode code points).

It is possible to work with a custom implementation for lex buffers.
To do this, you just have to ensure that a module called Sedlexing is
in scope of your lexer specifications, and that it defines at least
the following functions: start, next, mark, backtrack.  See the interface
of the Sedlexing module for more information.



## Using sedlex

The quick way:

```
   opam install sedlex
```


Otherwise, the first thing to do is to compile and install sedlex.
You need a recent version of OCaml and [dune](https://dune.build/).

```
  make
```

### With findlib

If you have findlib, you can use it to install and use sedlex.
The name of the findlib package is "sedlex".

Installation (after "make"):

```
  make install
```

Compilation of OCaml files with lexer specifications:

```
  ocamlfind ocamlc -c -package sedlex my_file.ml
```

When linking, you must also include the sedlex package:

```
  ocamlfind ocamlc -o my_prog -linkpkg -package sedlex my_file.cmo
```


There is also a sedlex.ppx subpackage containing the code of the ppx
filter.  This can be used to build custom drivers (combining several ppx
transformations in a single process).


### Without findlib

You can use sedlex without findlib. To compile, you need to run the
source file through -ppx rewriter ppx_sedlex. Moreover, you need to
link the application with the runtime support library for sedlex
(sedlexing.cma / sedlexing.cmxa).

## Examples

The `examples/` subdirectory contains several samples of sedlex in use.

## Contributors

- Benus Becker: implementation of Utf16
- sghost: for Unicode 6.3 categories and properties
- Peter Zotov:
  - improvements to the build system
  - switched parts of ppx_sedlex to using concrete syntax (with ppx_metaquot)
- Steffen Smolka: port to dune
- Elliott Cable: publish this BuckleScript-compatible fork on npm
