puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "!! $*" >&2 ;}
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



puts ''
printf %s 'Update bsconfig.json to match? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   jqinplace ".version = \"$new_version\"" bsconfig.json || exit 127
else
   exit 4
fi


puts ''
printf %s 'Update ppx-sedlex/package.json to match? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex && \
      npm version --no-git-tag-version "$new_version" && \
      git add package.json bsconfig.json package-lock.json) || exit 127
else
   exit 4
fi


puts ''
printf %s 'Remove previous artifacts and checksums from ppx-sedlex? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex &&
      git clean -Xdf;
   git rm SHASUM256.txt )
else
   exit 4
fi


puts ''
(  cd ./ppx-sedlex && \
   git status )
printf %s 'Commit new, unpopulated version of ppx-sedlex with these changes? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex && \
      git commit -m "(- rel NF) Prep for v$new_version" ) || exit 127
   git add ./ppx-sedlex || exit 127
else
   exit 4
fi


puts ''
git add package.json package-lock.json bsconfig.json || exit 127
git status
printf %s 'Further, commit these changes to a new version of bs-sedlex as well? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   git commit -m "(rel) v$new_version" || exit 127
else
   exit 4
fi

puts ''
git --no-pager show
printf %s "Tag this changeset as 'v$new_version'? [Y/n] "; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   git tag "v$new_version" --file=- <<MSG || exit 127
Version $new_version of Sedlexing, packaged for BuckleScript.

Of note, the corresponding version of \`ppx-sedlex\` is *not* included, due to a recursively mutual dependency. These packages are, however, properly packaged on npm:

    npm install --save bs-sedlex@$new_version
    npm install --save-dev ppx-sedlex@$new_version

If you wish to acquire them via git, ensure you manually pull the matching version of my \`ppx-sedlex\` package! The submodule linkage recorded in the repository will be perpetually one release behind.
MSG
else
   exit 4
fi


puts ''
printf %s 'Push these changes to GitHub, so Travis can start building the artifacts? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex && \
      git push ) || exit 127
   git push --tags || exit 127
   git push || exit 127
else
   exit 4
fi


puts ''
printf %s 'Start checking for those build artifacts on GitHub? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   until (
      cd ./ppx-sedlex && \
      make SHASUM256.txt
   ); do puts ''; sleep 15; done
else
   exit 4
fi


puts ''
(  cd ./ppx-sedlex && \
   git add SHASUM256.txt ) || exit 127
(  cd ./ppx-sedlex && \
   git diff )
printf %s 'Success! Now, commit the updated checksum to ppx-sedlex, and tag? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex && \
      git commit -m "(rel) v$new_version" && \
      git tag "v$new_version" ) || exit 127
   git add ./ppx-sedlex || exit 127
else
   exit 4
fi


puts ''
(  cd ./ppx-sedlex && \
   npm pack && \
   rm "ppx-sedlex-$new_version.tgz" ) || exit 127
printf %s "Publish 'ppx-sedlex@$new_version' to npm? [Y/n] "; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   (  cd ./ppx-sedlex && \
      npm publish ) || exit 127
else
   exit 4
fi


puts ''
printf %s "Update superproject's dependency on ppx-sedlex? [Y/n] "; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   jqinplace '.devDependencies["ppx-sedlex"] = "=" + .version' package.json || exit 127
   mv ppx-sedlex{,.temp} && \
      npm install --package-lock-only && \
      mv ppx-sedlex{.temp,} || exit 127
   git add package.json package-lock.json || exit 127
else
   exit 4
fi


puts ''
git status
printf %s 'Commit updated dependency and checksummed ppx to superproject? [Y/n] '; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   git commit -m "(- rel up sub) Fast-forward to artifact-checksummed v$new_version of ppx" || exit 127
else
   exit 4
fi


puts ''
npm pack && \
   rm "bs-sedlex-$new_version.tgz" || exit 127
printf %s "Publish 'bs-sedlex@$new_version' to npm? [Y/n] "; read yn
if [ "$yn" != "${yn#[Yy]}" ]; then
   npm publish || exit 127
else
   exit 4
fi
