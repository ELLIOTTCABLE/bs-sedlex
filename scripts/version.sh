puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}

jq_bin="$(npm prefix)/node_modules/node-jq/bin/jq"
pj() {
   "$jq_bin" -e "$@" package.json
}
jqinplace() {
   file="$2"
   "$jq_bin" -e "$@" | sponge "$file"
}


new_version="$(pj -r .version)"
puts 'New version (from `bs-sedlex/package.json`):  '"v$new_version"

old_version="$(cd ./ppx-sedlex; pj -r .version)"
puts 'Old version (from `ppx-sedlex/package.json`): '"v$old_version"
puts '' >&2

if [ "$new_version" = "$old_version" ]; then
   pute 'The version in `bs-sedlex` doesn'\''t appear to have been bumped!'
   puts '' >&2

   pute 'You may have called this directly by accident; this script is intended to be'
   pute 'called from the `version` lifecycle. Try the following, instead:'
   puts '' >&2
   puts '      npm version patch --no-git-tag-version' >&2
   puts '' >&2
   exit 2
fi



printf %s 'Update bsconfig.json to match? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   jqinplace ".version = \"$new_version\"" bsconfig.json
else
   exit 4
fi


printf %s 'Kick off the publishing process by committing this new version? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   git add package.json bsconfig.json
   git checkout master
   git commit -m "(- rel NF) Prep for v$new_version"
else
   exit 4
fi


printf %s 'Push these changes to GitHub? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   git push master
else
   exit 4
fi


printf %s 'Bump ppx-sedlex version to match? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex && \
      npm version --no-git-tag-version "$new_version" )
else
   exit 4
fi


printf %s 'Start checking for build artifacts on GitHub? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   until (
      cd ./ppx-sedlex && \
      make SHASUM256.txt
   ); do sleep 5; done
else
   exit 4
fi


