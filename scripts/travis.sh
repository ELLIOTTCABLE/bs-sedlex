set -e

puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}

# An alternative to `set +o xtrace` that doesn't print the unset line.
x () { puts '`` '"$*" >&2 ; "$@" || exit $? ;}

if [ -z "$STAGE" ] || [ -z "$COMPONENT" ]; then
   pute 'This script is intended to be called in a CI environment with a current $STAGE,'
   pute 'and a $COMPONENT to build. e.g.'

   puts '' >&2
   puts '      STAGE=install COMPONENT=runtime npm run travis' >&2
   puts '' >&2
   exit 2
fi

# Helpers
# -------
install_matching_ocaml() {
   x wget https://raw.githubusercontent.com/ocaml/ocaml-ci-scripts/master/.travis-ocaml.sh

   BSC_VERSION="$(bsc -vnum)"

   case "$BSC_VERSION" in
      *OCaml*4.02.3*) export OCAML_VERSION=4.02 OPAM_SWITCH=ocaml-base-compiler.4.02.3;;
      *OCaml*4.06.1*) export OCAML_VERSION=4.06 OPAM_SWITCH=ocaml-base-compiler.4.06.1;;
      *)
         pute 'Unrecognized `bsc` version: '"$BSC_VERSION"
         exit 10
      ;;
   esac

   puts 'export OPAM_SWITCH='"$OPAM_SWITCH"
   x bash -ex .travis-ocaml.sh
   x opam pin -y -n add sedlex .
   x opam install -y --deps-only sedlex
   eval `opam config env`

   if [ -n "$VERBOSE" ]; then
      x opam config env
      x opam list
   fi
}

# Stages
# ------
stage_install() {
   # Enable configurable debugging without adding new commits. (If something goes wrong,
   # you can set $VERBOSE to some value inside Travis's configuration, and then hit
   # "rebuild".)
   if [ -n "$VERBOSE" ]; then
      x npm config set loglevel verbose
   fi

   x git fetch --tags --no-recurse-submodules

   # Install npm dependencies, but avoid invoking our own `prepare` script
   x npm ci --ignore-scripts

   # A horrible hack is necessary here, with which we *manually* apply any `postinstall`
   # scripts of transitive dependencies. Yuck.
   #
   # Remember to add any new dependencies! No, I don't know an easy way to remember to do
   # this, and I'm probably going to forget. Sorry, future-me, when you figure out that
   # this is what's screwing up the build.
   #
   # See: <https://npm.community/t/ignore-scripts-ignores-all-scripts/1403/10>
   x npm rebuild node-jq

   # Now we either select a particular `bs-platform` to install, or manually process the
   # `postinstall` script of the one we installed above.
   if [ -n "$NPM_TAG" ]; then
      x npm install "bs-platform@$NPM_TAG"
   else
      x npm rebuild bs-platform
   fi

   # ‘Install’ our own local `ppx-sedlex` version.
   x npm link ./ppx-sedlex

   # Finally, for everything except the `runtime`, we need a working OCaml installation of
   # the same version as the BuckleScript we just built.
   if [ "$COMPONENT" != "runtime" ]; then install_matching_ocaml; fi
}

stage_test() {
   case "$COMPONENT" in
      runtime)
         x npm run --silent build:runtime
      ;;
      ppx-examples-test)
         eval `opam config env`

         x npm run --silent build:ppx
         (cd examples && x bsb -make-world)
         x npm run --silent test
      ;;
   esac
}

stage_deploy() {
   eval `opam config env`

   x npm run --silent clean:ppx
   x npm run --silent build:ppx
}

# Invocation
# ----------
case "$STAGE" in
   install) stage_install ;;
   test) stage_test ;;
   deploy) stage_deploy ;;
esac
