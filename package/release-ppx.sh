puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}

alias jq="$(npm prefix)/node_modules/node-jq/bin/jq"
pj() { jq -er "$1" package.json ;}


# for EXTDEP in jq; do
#    if ! command -v $EXTDEP >/dev/null; then
#       pute 'You need `'"$EXTDEP"'` to use this script!'
#       pute 'Try: `brew install '"$EXTDEP"'`'
#       printf \\n >&2
#       missing_dep=true
#    fi
# done

if ! command -v sponge >/dev/null; then
   pute 'You need `sponge` to use this script!'
   pute 'Try: `brew install moreutils`'
   puts '' >&2
   missing_dep=true
fi

if [ -n "$missing_dep" ]; then exit 3; fi


new_version="$(pj .version)"
puts 'New version (from `bs-sedlex/package.json`):  '"v$new_version"

old_version="$(cd ./ppx-sedlex; pj .version)"
puts 'Old version (from `ppx-sedlex/package.json`): '"v$old_version"
puts '' >&2

if [ "$new_version" = "$old_version" ]; then
   pute 'The version in `bs-sedlex` doesn'\''t appear to have been bumped!'
   puts '' >&2

   pute 'This script is intended to be used *after* Travis builds and packages binary'
   pute 'artifacts; try something like the following:'
   puts '' >&2

   puts '      git stash save' >&2
   puts '      git checkout master' >&2
   puts '      npm version patch --no-git-tag-version' >&2
   puts '      git add --all' >&2
   puts '      git commit "(rel) Bump to v`jq -r .version package.json`"' >&2
   puts '      git push' >&2
   puts '' >&2
   exit 2
fi

puts 'yay!'
