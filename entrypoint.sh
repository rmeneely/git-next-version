#!/bin/bash 
# Description: Utility to get the last version tag and calculate the next version
program=`basename $0`
Syntax='$program [-t <tag pattern>] [-i <increment>] [-p <new prefix> | -P] [-s <new suffix> | -S] [-l <last version>] [-n <next version>] [-T]'
set -e

# Defaults
export TAG_PATTERN="${INPUT_TAG_PATTERN:-'v[0-9]*.[0-9]*.[0-9]*'}"
export INCREMENT="${INPUT_INCREMENT:-'patch'}"
export AUTO_INCREMENT="${INPUT_AUTO_INCREMENT:-'false'}"
export AUTO_INCREMENT_MAJOR_VERSION_PATTERN="${INPUT_AUTO_INCREMENT_MAJOR_VERSION_PATTERN:-'*major*'}"
export AUTO_INCREMENT_MINOR_VERSION_PATTERN="${INPUT_AUTO_INCREMENT_MINOR_VERSION_PATTERN:-'*minor*'}"
export AUTO_INCREMENT_LIMIT="${INPUT_AUTO_INCREMENT_LIMIT:-'minor'}"
export NEW_PREFIX="${INPUT_NEW_PREFIX:-''}"
export REMOVE_PREFIX="${INPUT_REMOVE_PREFIX:-'false'}"
export NEW_SUFFIX="${INPUT_NEW_SUFFIX:-''}"
export REMOVE_SUFFIX="${INPUT_REMOVE_SUFFIX:-'false'}"
export LAST_VERSION="${INPUT_LAST_VERSION:-''}"
export NEXT_VERSION="${INPUT_NEXT_VERSION:-''}"
export SET_NEXT_VERSION="${INPUT_SET_NEXT_VERSION:-'true'}"

# Add this git workspace as a safe directory
# Required by GitHub Actions to enable this action to execute git commands
if [ "${GITHUB_WORKSPACE}" !=  '' ]; then
   git config --global --add safe.directory "$GITHUB_WORKSPACE"
fi

# Get command line arguments
while getopts "t:i:p:s:l:n:PSTh" option; do
  case $option in
    t) # Tag pattern
       TAG_PATTERN=$OPTARG ;;
    i) # Version increment
       INCREMENT=$OPTARG
       if [ "${INCREMENT}" = "1.0.0" ]; then
          INCREMENT="major"
       elif [ "${INCREMENT}" = "0.1.0" ]; then
          INCREMENT="minor"
       elif [ "${INCREMENT}" = "0.0.1" ]; then
          INCREMENT="patch"
       fi
       ;;
    p) # prefix
       NEW_PREFIX=$OPTARG 
       if [ "${NEW_PREFIX}" = '' ]; then
          REMOVE_PREFIX='true'
       fi
       ;;
    P) # Remove prefix
       REMOVE_PREFIX='true' ;;
    s) # suffix
       NEW_SUFFIX=$OPTARG 
       if [ "${NEW_SUFFIX}" = '' ]; then
          REMOVE_SUFFIX='true'
       fi
       ;;
    S) # Remove suffix
       REMOVE_SUFFIX='true' ;;
    l) # Last version
       LAST_VERSION=$OPTARG ;;
    n) # Next version
       NEXT_VERSION=$OPTARG ;;
    T) # Don't set next version
       SET_NEXT_VERSION='false' ;;
    h) # Help
       echo "Syntax: ${Syntax}"
       echo "Defaults:"
       echo "Tag Pattern: ${TAG_PATTERN}"
       echo "Version increment: ${INCREMENT}"
       if [ ! -z "${NEW_SUFFIX}" ]; then
          echo "New Suffix: ${NEW_SUFFIX}"
       fi
       exit 0
       ;;
    \?) # Invalid option
       echo "Error: Invalid option" >&2
       echo "Syntax: ${Syntax}" >&2
       exit 1
       ;;
  esac
done

function get_last_version() { # Get last version tag
  default_pattern='v[0-9]*'
  pattern="${1:-${default_pattern}}"
  git tag --sort=committerdate --list "${pattern}" | tail -1
}

function get_next_version() { # Return the next increment from the last version
  last_version=$1
  default_increment=patch
  increment="${2:-${INCREMENT}}"
  increment=`echo "${increment}" | tr '[:upper:]' '[:lower:]'`

  # Major and Prefix
  major=`echo ${last_version} | cut -d '.' -f 1`
  prefix=`echo ${major}|sed 's/[0-9][0-9]*$//'`
  major=`echo $major | sed -e "s/$prefix//"`
  if [ "${NEW_PREFIX}" != '' ]; then
     prefix=${NEW_PREFIX}
  fi
  if [ "${REMOVE_PREFIX}" = 'true' ]; then
     prefix=''
  fi

  # Minor
  minor=`echo ${last_version} | cut -d '.' -f 2`

  # Patch and Suffix
  patch=`echo ${last_version} | cut -d '.' -f 3`
  suffix=`echo ${patch}|sed 's/^[0-9][0-9]*//'`
  patch=`echo $patch | sed -e "s/${suffix}$//"`
  if [ "${NEW_SUFFIX}" != '' ]; then
     suffix=${NEW_SUFFIX}
  fi
  if [ "${REMOVE_SUFFIX}" = 'true' ]; then
     suffix=''
  fi

  # Increment
  case "${increment}" in
    'major') let major+=1
           minor=0
           patch=0
           ;;
    'minor') let minor+=1 
           patch=0
           ;;
    'patch') let patch+=1 ;;
    'none') ;; # No increment
    *) echo "Error: invalid increment ${increment}" >&2
       exit 1
       ;;
  esac
  echo "${prefix}${major}.${minor}.${patch}${suffix}"
}

# Auto increment count
function commit_pattern_count() {
   last_version=$1
   pattern=$2
   count=`git log --pretty=oneline "${last_version}..HEAD" |  | sed 's/[a-zA-Z0-9]* //' | egrep -i "${pattern}" | wc -l`
   return $count
}

# Auto increment version
function auto_increment_version() {
   last_version="${1:-${LAST_VERSION}}"
   major_version_pattern="${2:-${AUTO_INCREMENT_MAJOR_VERSION_PATTERN}}"
   minor_version_pattern="${3:-${AUTO_INCREMENT_MINOR_VERSION_PATTERN}}"
   
   # Get count of matching commits
   major_count=`commit_pattern_count "${last_version}" "${major_version_pattern}"`
   minor_count=`commit_pattern_count "${last_version}" "${minor_version_pattern}"`

   # Major
   if [ $major_count -gt 0  && "${auto_increment_limit}" = 'major' ]; then
      next_version=`get_next_version "${last_version}" 'major'`
      return "${next_version}"
   fi

   # Minor
   count=$((${major_count} + ${minor_count}))
   if [ $count -gt 0 ]; then
      if [ "${auto_increment_limit}" = "major" || "${auto_increment_limit}" = "minor" ]; then
         next_version=`get_next_version "${last_version}" 'minor'`
         return "${next_version}"
      fi
   fi

   # Patch
   next_version=`get_next_version "${last_version}" 'patch'`
   return "${next_version}"
}

function set_next_version() {
   next_version=${1:-''}

   if [ "${next_version}" != '' ]; then
      git tag "${next_version}"
      git push --tags
   fi
}

function output_versions() {
  if [ "${GITHUB_ENV}" !=  '' ]; then
     echo "LAST_VERSION=${LAST_VERSION}" >> $GITHUB_ENV
     echo "NEXT_VERSION=${NEXT_VERSION}" >> $GITHUB_ENV
  else
     echo "LAST_VERSION=${LAST_VERSION}"
     echo "NEXT_VERSION=${NEXT_VERSION}"
  fi
}

function main() { # main function
  # Get the last version 
  if [ "${LAST_VERSION}" = '' ]; then
     export LAST_VERSION=`get_last_version "${TAG_PATTERN}"`
  fi
  if [ "${LAST_VERSION}" = '' ]; then
     echo "Error: last version not found" >&2
     exit 1
  fi

  # Get the next version
  if [ "${SET_NEXT_VERSION}" = 'true' ]; then
     set_next_version "${NEXT_VERSION}"
  else
    if [ "${AUTO_INCREMENT}" = 'true' ]; then
       export NEXT_VERSION=`auto_increment_version "${LAST_VERSION}" "${AUTO_INCREMENT_MAJOR_VERSION_PATTERN}" "${AUTO_INCREMENT_MINOR_VERSION_PATTERN}"`
    else 
       export NEXT_VERSION=`get_next_version "${LAST_VERSION}" "${INCREMENT}"`
    fi
  fi
  
  # Output the versions
  output_versions
}

# Main
main

exit $?

# EOF: entrypoint.sh
