#!/bin/bash 
# Description: Utility to get the last version tag and calculate the next version
program=`basename $0`
Syntax='$program [-t <tag pattern>] [-i <increment>] [-p <new prefix> | -P] [-s <new suffix> | -S] [-l <last version>] [-n <next version>] [-T]'
set -e

# Defaults
default_tag_pattern='v[0-9]*'
default_increment='patch'
default_new_prefix=''
default_new_suffix=''
default_last_version=''
default_next_version=''
default_set_next_version='true'
export TAG_PATTERN="${INPUT_tag_pattern:-${default_tag_pattern}}"
export INCREMENT="${INPUT_increment:-${default_increment}}"
export NEW_PREFIX="${INPUT_new_prefix:-${default_new_prefix}}"
export REMOVE_PREFIX='false' # Do not remove prefix
export NEW_SUFFIX="${INPUT_new_suffix:-${default_new_suffix}}"
export REMOVE_SUFFIX='false' # Do not remove suffix
export LAST_VERSION="${INPUT_last_version:-${default_last_version}}"
export NEXT_VERSION="${INPUT_next_version:-${default_next_version}}"
export SET_NEXT_VERSION="${INPUT_set_next_version:-${default_set_next_version}}"

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
  increment="${2:-${default_increment}}"
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
    major) let major+=1
           minor=0
           patch=0
           ;;
    minor) let minor+=1 
           patch=0
           ;;
    patch) let patch+=1 ;;
    none) ;; # No increment
    *) echo "Error: invalid increment ${increment}" >&2
       exit 1
       ;;
  esac
  echo "${prefix}${major}.${minor}.${patch}${suffix}"
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
  if [ "${NEXT_VERSION}" = '' ]; then
     export NEXT_VERSION=`get_next_version ${LAST_VERSION} "${INCREMENT}"`
  fi
  
  # Set the next version
  if [ "${SET_NEXT_VERSION}" = 'true' ]; then
     set_next_version "${NEXT_VERSION}"
  fi
  
  
  # Output the versions
  output_versions
     
}

# Main
main

exit $?

