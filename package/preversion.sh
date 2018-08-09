puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}


if ! command -v sponge >/dev/null; then
   pute 'You need `sponge` to use this script!'
   pute 'Try: `brew install moreutils`'
   puts '' >&2
   missing_dep=true
fi

if [ -n "$missing_dep" ]; then exit 3; fi

(
   cd ./ppx-sedlex;
   if ! git diff --exit-code >/dev/null || ! git diff --cached --exit-code >/dev/null; then
      pute 'There appear to be uncommitted changes in `ppx-sedlex`. You should ensure the'
      pute 'submodule is entirely committed and clean before attempting to version-bump'
      pute 'the superproject.'
      puts '' >&2

      pute 'Try:'
      puts '' >&2
      puts '      (cd ./ppx-sedlex && git stash save)' >&2
      puts '' >&2
      exit 2
   fi
)
