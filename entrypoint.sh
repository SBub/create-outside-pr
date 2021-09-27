#!/bin/sh

set -e
set -x

get_value_from_package()
{
  PROP=$1
  cat package.json \
  | grep $PROP \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]'
}

CLONE_DIR=$(mktemp -d)
PACKAGE_VERSION="$(get_value_from_package version)"
PACAKGE_NAME="$(get_value_from_package name)"
DESTINATION_BRANCH="chore/bump-$PACAKGE_NAME-$PACKAGE_VERSION-$(date +%s)"

echo "Setting git variables"
export GITHUB_TOKEN=$API_TOKEN_GITHUB
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"

echo "Cloning destination git repository"
git clone "https://$API_TOKEN_GITHUB@github.com/$INPUT_DESTINATION_REPO.git" "$CLONE_DIR"

echo "Copying contents to git repo"
mkdir -p $CLONE_DIR
cd "$CLONE_DIR"
git checkout -b $DESTINATION_BRANCH

echo "Adding git commit"
git commit -m "Update from https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA" --allow-empty
git push -u origin HEAD:$DESTINATION_BRANCH
echo "Creating a pull request"
gh pr create -t "$PACAKGE_NAME was updated to v$PACKAGE_VERSION" \
              -b "You should bump the version of $PACAKGE_NAME to $PACKAGE_VERSION to use latest updates" \
              -B $INPUT_DESTINATION_BASE_BRANCH \
              -H $DESTINATION_BRANCH \
