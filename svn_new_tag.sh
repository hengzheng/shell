#! /bin/bash
#####################################
# @doc create svn new tag
# @author hengzheng
# @ date 2017/10/14
#####################################
# svn base url
BASE_SVN_URL="svn://127.0.0.1"
# repositorys in svn
REPOS_LIST="server client"
# repos of new tag
REPOS=
# new tag version
TAG_VERSION=
# is force
IS_FORCE=false

# usage
function usage {
    echo "******************************************************************"
    echo "              New SVN TAG"
    echo "Tag version like vMajoy:Minor:Modify."
    echo "Options:"
    echo "-r Repos|Repos:Ver :specify the repos and version(default HEAD)" 
    echo "                     which want to new tag."
    echo "                     (server|client, default all)"
    echo "-f                 :force create even the tag existes"
    echo "-v                 :tag version"
    echo "Usage: $0 -r server -v v1.0.0"
    echo "******************************************************************"
}

# error
function error {
    echo -e "\033[31m[Error]\033[0m"$1
    exit 1
}

# check if the repos exist
function check_repos {
    local REPOS_URL=$1
    if ! ( svn info $REPOS_URL > /dev/null 2>&1 ); then
        error "Repos $REPOS_URL not exist!"
    fi
}

# check the tag version
function check_version {
    local VERSION=$1
    CHECK=`echo ${VERSION} | grep '^v\([0-9]\+\.\)\{2\}[0-9]\+$'`
    if [ -z "$CHECK" ]; then
        error "version $VERSION format err, must vMajoy.Minor.Change like v1.0.1"
    fi
}

# get version
function get_ver {
    local REPOS=$1
    VER=${REPOS##*:}
    if [ $VER -gt 0 > /dev/null 2>&1 ];then
        echo "$VER"
    else
        echo "HEAD"
    fi
}

# confirm
function confirm {
    echo "Do you want to new tag $1 from $2?(Yes/No)"
    read CONFIRM
    if  [ "$CONFIRM" != "Yes" ]; then
        exit 0
    fi
}

# new tag
function new_tag {
    local REPOS=$1
    REPOS=${REPOS%%:*}
    local VER=$2
    FROM_URL=$BASE_SVN_URL/$REPOS/trunk
    TAG_URL=$BASE_SVN_URL/$REPOS/tags/$TAG_VERSION

    # check from
    check_repos $FROM_URL -r $VER

    # if base tag url exist
    BASE_TAG_URL=${TAG_URL%/*}
    if ! ( svn info $BASE_TAG_URL > /dev/null 2>&1 ); then
        if ! ( svn mkdir -p "$BASE_TAG_URL" > /dev/null 2>&1 ); then
            error "tag $BASE_TAG_URL not exist"
        fi
    fi

    # confirm
    confirm $TAG_URL $FROM_URL:$VER

    # if tag exist
    if ( svn info $TAG_URL > /dev/null 2>&1 ); then
        if ( "$IS_FORCE" = true ); then
            if ! ( svn rm --force $TAG_URL -m "del tag when tag exist" > /dev/null 2>&1 ); then
                error "del exist tag err"
            fi
        else
            error "tag $TAG_VERSION already exist"
        fi
    fi

    COMMIT_LOG="new tag by tool"
    # new tag
    if ! ( svn copy $FROM_URL -r $VER $TAG_URL -m "$COMMIT_LOG" > /dev/null 2>&1 ); then
        error "new tag $TAG_URL failed"
    fi

    echo "repos $REPOS new tag $TAG_VERSION success"
}

# Option
while [ $# -ne 0 ]; do
    PARAM=$1
    shift
    case "$PARAM" in
        -r )
            REPOS=$1;shift;;
        -f )
            IS_FORCE=true;;
        -v )
            TAG_VERSION=$1;shift;;
        -h|--help )
            usage;exit 0;;
        * ) # other arg ignore
            shift;;
    esac
done

#
check_version $TAG_VERSION

# new tag
if  [ -z "$REPOS" ]; then
    for REPOS in $REPOS_LIST;
    do
        VER=`get_ver $REPOS`
        new_tag $REPOS $VER
    done
else
    VER=`get_ver $REPOS`
    new_tag $REPOS $VER
fi
