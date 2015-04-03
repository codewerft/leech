#!/bin/bash -l

# Copyright (C) 2015 Codewerft Flensburg (http://www.codewerft.net)
# Licensed under the MIT License
#
# Leech is a simple bash script that periodically updates a locally
# cloned Git repository.

# -----------------------------------------------------------------------------
# Global variables
#
SCRIPTNAME=`basename $0`
SCRIPTVERSION=0.1
UPDATE_INTERVAL=300 # default interval - 5 minutes
CHECKOUT_DIR=
REPOSITORY_URL=
BRANCH=master # default branch is master
OAUTHTOKEN=0

# -----------------------------------------------------------------------------
# Some ANSI color definitions
#
CLR_ERROR='\033[0;31m'
CLR_WARNING='\033[0;33m'
CLR_OK='\033[0;32m'
CLR_CHANGE='\033[0;35m'
CLR_RESET='\033[0m'

# -----------------------------------------------------------------------------
# Print version of this tool
#
version()
{
    echo -e "\n$SCRIPTNAME $SCRIPTVERSION\n"
    echo -e "Copyright (C) 2015 Codewerft Flensburg (http://www.codewerft.net)"
    echo -e "Licensed under the MIT License\n"
    echo -e "This is free software: you are free to change and redistribute it."
    echo -e "There is NO WARRANTY, to the extent permitted by law.\n"
}

# -----------------------------------------------------------------------------
# Print the log prefix consisting of timestamp and scriptname
#
log_prefix()
{
    echo "[$(date +"%d/%b/%Y:%H:%M:%S %z")] $SCRIPTNAME:"
}

# -----------------------------------------------------------------------------
# Print script usage help
#
usage()
{

cat << EOF
usage: $SCRIPTNAME options

$SCRIPTNAME is a simple bash script that periodically updates a locally
cloned Git repository.

OPTIONS:

   -d DIR      Local direcotry to check out the repository to
   -r URL      Git repository URL
   -b BRANCH   Branch to check out (default: master)
   -t TOKEN    OAuth token (optional for private repositories)
   -i INTERVAL Update interval (default: 5m)
   -v          Print the version of $SCRIPTNAME and exit.
   -h          Show this message


EXAMPLES:

  Clone and periodially update the 'release' branch of the 'leech' repository
on GitHub to /var/repos/leech:

$SCRIPTNAME.sh -d /tmp/leech -r git@github.com:codewerft/leech.git -b release

EOF
}

# -----------------------------------------------------------------------------
# MAIN - Script entry point
#

# make sure fswatch is installed, exit with error if not
fswatch --version >/dev/null 2>&1 || {
    echo >&2 -e "$CLR_ERROR$SCRIPTNAME requires fswatch but it's not installed. Aborting.$CLR_RESET";
    echo >&2 -e "\nOn OS X install fswatch with 'brew install fswatch'.";
    echo >&2 -e "On Linux install fswatch with 'xyz'.\n";
    exit 1;
}

while getopts hvd:r:b:t:i: OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        v)
            version
            exit 0
            ;;
        r)
            REPOSITORY_URL=$OPTARG
            ;;
        d)
            CHECKOUT_DIR=$OPTARG
            ;;
        b)
            BRANCH=$OPTARG
            ;;
        t)
            OAUTHTOKEN=$OPTARG
            ;;
        i)
            UPDATE_INTERVAL=$OPTARG
            ;;
        ?)
            usage
            exit
            ;;
     esac
done

# Make sure at least -d and -r were set.
if [[ -z $CHECKOUT_DIR ]] || [[ -z $REPOSITORY_URL ]]
then
    usage
    exit 1
fi

# Make sure the checkout dir exists and we have write permission.
if ! [[ -d "$CHECKOUT_DIR" ]] ; then
    echo -e "$CLR_OK$(log_prefix) creating checkout directory $CHECKOUT_DIR $CLR_RESET" >&2
    mkdir -p $CHECKOUT_DIR
fi

# Check if $CHECKOUT_DIR is a valid git repository.
cd $CHECKOUT_DIR
git status
if [[ $? != 0 ]] ; then
    # It is not. Clone the repository.
    echo -e "$CLR_WARNING$(log_prefix) no git reposiory found in $CHECKOUT_DIR. Cloning into $REPOSITORY_URL $CLR_RESET" >&2

    git clone -b $BRANCH $REPOSITORY_URL $CHECKOUT_DIR
    if [[ $? != 0 ]] ; then
        echo -e "$CLR_ERROR$(log_prefix) cloning failed. Aborting $CLR_RESET" >&2
        exit 1
    else:
        echo -e "$CLR_ERROR$(log_prefix) successfully cloned $REPOSITORY_URL into $CHECKOUT_DIR $CLR_RESET" >&2
    fi
fi

while true
do
    # Update the repository
    git pull
    if [[ $? != 0 ]] ; then
        # Git command failed.
        echo -e "$CLR_ERROR$(log_prefix) updating repository FAILED $CLR_RESET" >&2
    else
        echo -e "$CLR_OK$(log_prefix) successfully updated repository $CLR_RESET" >&2
    fi

    # sleep until the next interval
    sleep $UPDATE_INTERVAL
done
