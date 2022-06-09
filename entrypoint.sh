#!/bin/bash
# Description: Utility to get the last version tag and calculate the next version
program=`basename $0`
Syntax='$program [-t <tag pattern>] [-i <increment>] [-p <new prefix> | -P] [-s <new suffix> | -S] [-l <last version>] [-n <next version>] [-T] [-V]'
set -e

# Defaults
export TAG_PATTERN="${INPUT_TAG_PATTERN:-'v[0-9]*.[0-9]*.[0-9]*'}"
export INCREMENT="${INPUT_INCREMENT:-patch}"
export AUTO_INCREMENT="${INPUT_AUTO_INCREMENT:-false}"
export AUTO_INCREMENT_MAJOR_VERSION_PATTERN="${INPUT_AUTO_INCREMENT_MAJOR_VERSION_PATTERN:-major:|breaking:|incompatible:}"
export AUTO_INCREMENT_MINOR_VERSION_PATTERN="${INPUT_AUTO_INCREMENT_MINOR_VERSION_PATTERN:-minor:|feature:}"
export AUTO_INCREMENT_LIMIT="${INPUT_AUTO_INCREMENT_LIMIT:-minor}"
export NEW_PREFIX="${INPUT_NEW_PREFIX:-}"
export REMOVE_PREFIX="${INPUT_REMOVE_PREFIX:-false}"
export NEW_SUFFIX="${INPUT_NEW_SUFFIX:-}"
export REMOVE_SUFFIX="${INPUT_REMOVE_SUFFIX:-false}"
export LAST_VERSION="${INPUT_LAST_VERSION:-}"
export NEXT_VERSION="${INPUT_NEXT_VERSION:-}"
export SET_NEXT_VERSION="${INPUT_SET_NEXT_VERSION_TAG:-true}"
export VERBOSE="${INPUT_VERBOSE:-true}"

# Add this git workspace as a safe directory
# Required by GitHub Actions to enable this action to execute git commands
if [ "${GITHUB_WORKSPACE}" !=  '' ]; then
   git config --global --add safe.directory "$GITHUB_WORKSPACE"
fi

# Get command line arguments
while getopts "t:i:p:s:l:n:PSTVh" option; do
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
       SET_NEXT_VERSION_TAG='false' ;;
    V) # Verbose
       VERBOSE='true' ;;
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

display_options() {
  echo "TAG_PATTERN=$TAG_PATTERN"
  echo "INCREMENT=$INCREMENT"
  echo "AUTO_INCREMENT=$AUTO_INCREMENT"
  echo "AUTO_INCREMENT_MAJOR_VERSION_PATTERN=$AUTO_INCREMENT_MAJOR_VERSION_PATTERN"
  echo "AUTO_INCREMENT_MINOR_VERSION_PATTERN=$AUTO_INCREMENT_MINOR_VERSION_PATTERN"
  echo "AUTO_INCREMENT_LIMIT=$AUTO_INCREMENT_LIMIT"
  echo "REMOVE_PREFIX=INPUT_NEW_PREFIX=$NEW_PREFIX"
  echo "REMOVE_PREFIX=$REMOVE_PREFIX"
  echo "NEW_SUFFIX=$NEW_SUFFIX"
  echo "REMOVE_SUFFIX=$REMOVE_SUFFIX"
  echo "LAST_VERSION=$LAST_VERSION"
  echo "NEXT_VERSION=$NEXT_VERSION"
  echo "SET_NEXT_VERSION_TAG=$SET_NEXT_VERSION_TAG"
  echo ""
}

function get_last_version() { # Get last version tag
  pattern="${1:-${TAG_PATTERN}}"
  #pattern="'${pattern}'"
  #pattern=`echo $pattern | sed -e 's/^\'\'/'/' -e 's/\'\'$/'/'` # Ensure there are only single quotes
  git fetch -tag
  cmd="git tag --sort=committerdate --list ${pattern} | tail -1"
  if [ "${VERBOSE}" = 'true' ]; then 
     echo "get_last_version($pattern)" >&2
     echo "  $cmd" >&2 
  fi
  eval $cmd
}

function get_next_suffix() {
  last_version="${1:-${LAST_VERSION}}"
  if [ "${VERBOSE}" = 'true' ]; then echo "get_next_suffix($last_version)" >&2 ; fi

  # Split into prefix and suffix
  prefix=`echo "${last_version}" | cut -d '-' -f 1`
  suffix=`echo "${last_version}" | cut -d '-' -f 2`

  # Split and increment the suffix
  suffix1=`echo "${suffix}" | cut -d '.' -f 1`
  suffix2=`echo "${suffix}" | cut -d '.' -f 2`
  let suffix2+=1

  echo "${prefix}-${suffix1}.${suffix2}"
}

function get_next_version() { # Return the next increment from the last version
  last_version="${1:-${LAST_VERSION}}"
  increment="${2:-${INCREMENT}}"
  increment=`echo "${increment}" | tr '[:upper:]' '[:lower:]'`
  if [ "${VERBOSE}" = 'true' ]; then echo "get_next_version($last_version, $increment)" >&2 ; fi

  if [ "${INCREMENT}" = 'suffix' ]; then
     next_version=`get_next_suffix "${last_version}"`
     echo "${next_version}"
     return
  fi

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

# Commit pattern count
function commit_pattern_count() {
  from_version=$1
  pattern=$2
  to_version="${3:-HEAD}"
  if [ "${VERBOSE}" = 'true' ]; then echo "commit_pattern_count($from_version, $pattern, $to_version)" >&2 ; fi

  # Determine the number of matching commits
  count=`git log --pretty=oneline "${from_version}..${to_version}" | sed 's/[a-zA-Z0-9]* //' | egrep -iwe "${pattern}" | wc -l`
  count=`echo $count | sed 's/ //g'`
  if [ "${VERBOSE}" = 'true' ]; then echo "  $count=git log --pretty=oneline ${from_version}..${to_version} | sed 's/[a-zA-Z0-9]* //' | egrep -iwe ${pattern} | wc -l" >&2 ; fi
  echo $count
}

# Auto increment version
function auto_increment_version() {
   last_version="${1:-${LAST_VERSION}}"
   major_version_pattern="${2:-${AUTO_INCREMENT_MAJOR_VERSION_PATTERN}}"
   minor_version_pattern="${3:-${AUTO_INCREMENT_MINOR_VERSION_PATTERN}}"
   auto_increment_limit="${4:-${AUTO_INCREMENT_LIMIT}}"
   if [ "${VERBOSE}" = 'true' ]; then echo "auto_increment_version($last_version, $major_version_pattern, $minor_version_pattern, $auto_increment_limit)" >&2 ; fi
   
   # Get count of matching commit types
   major_count=`commit_pattern_count "${last_version}" "${major_version_pattern}"`
   minor_count=`commit_pattern_count "${last_version}" "${minor_version_pattern}"`

   # Major
   if [ $major_count -gt 0 ]; then
      if [ "${auto_increment_limit}" = 'major' ]; then
         next_version=`get_next_version "${last_version}" 'major'`
         echo "${next_version}"
         return
      fi
   fi

   # Minor
   count=$(($major_count + $minor_count))
   if [ $count -gt 0 ]; then
      case "${auto_increment_limit}" in # Check increment limit
        'major'|'minor')
           next_version=`get_next_version "${last_version}" 'minor'`
           echo "${next_version}"
           return
         ;;
      esac
   fi

   # Patch
   next_version=`get_next_version "${last_version}" 'patch'`
   echo "${next_version}"
   return
}

function set_next_version_tag() {
  next_version="${1:-${NEXT_VERSION}}"
  if [ "${VERBOSE}" = 'true' ]; then echo "set_next_version_tag($next_version)" >&2 ; fi

  # Valid tag
  valid=`echo ${next_version} | egrep -ice '^[a-zA-Z0-9]'`
  if [ $valid -eq 0 ]; then
     echo "Error: Invalid version tag: ${next_version}" >&2
     exit 1
  fi

  if [ "${next_version}" != '' ]; then
     git tag "${next_version}"
     git push --tags
  fi
}

function output_versions() {
  if [ "${VERBOSE}" = 'true' ]; then echo "output_versions()" >&2 ; fi
  if [ "${GITHUB_ENV}" !=  '' ]; then
     echo "LAST_VERSION=${LAST_VERSION}" >> $GITHUB_ENV
     echo "NEXT_VERSION=${NEXT_VERSION}" >> $GITHUB_ENV
  else
     echo "LAST_VERSION=${LAST_VERSION}"
     echo "NEXT_VERSION=${NEXT_VERSION}"
  fi
}

function main() { # main function
  if [ "${VERBOSE}" = 'true' ]; then 
     echo "main()" >&2
     display_options >&2  
  fi

  # Get the last version 
  if [ "${LAST_VERSION}" = '' ]; then
     export LAST_VERSION=`get_last_version "${TAG_PATTERN}"`
  fi
  if [ "${LAST_VERSION}" = '' ]; then
     echo "Error: last version matching pattern ${TAG_PATTERN} not found" >&2
     exit 1
  fi
  if [ "${VERBOSE}" = 'true' ]; then echo "main: LAST_VERSION: $LAST_VERSION" >&2 ; fi

  # Get the next version
  if [ "${NEXT_VERSION}" = '' ]; then
     if [ "${INCREMENT}" != 'suffix' ]; then
        if [ "${AUTO_INCREMENT}" = 'true' ]; then # Determine next version based on commit messages
           export NEXT_VERSION=`auto_increment_version "${LAST_VERSION}" "${AUTO_INCREMENT_MAJOR_VERSION_PATTERN}" "${AUTO_INCREMENT_MINOR_VERSION_PATTERN}" "${AUTO_INCREMENT_LIMIT}"`
        else # Determine next version from increment value
           export NEXT_VERSION=`get_next_version "${LAST_VERSION}" "${INCREMENT}"`
        fi
     else # Increment suffix
        #prefix=`echo "${LAST_VERSION}" | cut -d '-' -f 1`
        #suffix=`echo "${LAST_VERSION}" | cut -d '-' -f 2`
        #suffix1=`echo "${suffix}" | cut -d '.' -f 1`
        #suffix2=`echo "${suffix}" | cut -d '.' -f 2`
        #let suffix2+=1
        #export NEXT_VERSION="${prefix}-${suffix1}.${suffix2}"
        export NEXT_VERSION=`get_next_suffix "${LAST_VERSION}"`
     fi
  fi
  if [ "${VERBOSE}" = 'true' ]; then echo "main: NEXT_VERSION: $NEXT_VERSION" >&2 ; fi
  if [ "${SET_NEXT_VERSION_TAG}" = 'true' ]; then
     set_next_version_tag "${NEXT_VERSION}"
  fi
  
  # Output the versions
  output_versions
}

# Main
main

exit $?

# EOF: entrypoint.sh
