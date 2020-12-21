git tag -d $1
git push --delete origin $1
git tag -a $1 -m "version ${1} release"
git push origin --tags
