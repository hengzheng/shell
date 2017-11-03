#! /bin/bash
###########################################
# @doc release code/exe from svn to server
# @author hengzheng
# @date 2017/10/23
###########################################
# base svn url
BASE_SVN_URL="svn://127.0.0.1/server"
# version
VERSION=
# release tar name
RELEASE_TAR=
# release svn url
RELEASE_SVN_URL=
# server ip
SERVER_IP=
# server dir
SERVER_DIR=
# work dir
WORK_DIR=`mktemp -d`
# date
NOW_DATE=`date +%Y%m%d`
# compile flag
COMPILE_FLAG=false

# error
error() {
    echo -e "\033[31m[Error]\033[0m"$1
    exit 1
}

# process
process() {
    echo -e "\033[31m[Doing]\033[0m"$1
}

# help
help() {
    echo "*******release from svn to server********"
    echo "Usage: $0 -t Version -s ServerIp -d ServerDir"
    echo "Options:"
    echo "  -t Version      : release Version to server (default:trunk)"
    echo "  -s ServerIp     : Server Ip"
    echo "  -d ServerDir    : Server directory"
    echo "  -c              : set compile flag"
    exit 0
}

# check svn url
check_version() {
    process "check svn url: ${RELEASE_SVN_URL}"
    if !( svn info ${RELEASE_SVN_URL} > /dev/null 2>&1 ); then
        error "${RELEASE_SVN_URL} not exist"
    fi
}

# check out svn
check_out() {
    process "check out from svn: ${RELEASE_SVN_URL}"
    if !( cd ${WORK_DIR} && svn co ${RELEASE_SVN_URL} . > /dev/null 2>&1 ); then
        error "checkout ${RELEASE_SVN_URL} failed"
    fi
}

# check server
check_server() {
    process "check server ip: ${SERVER_IP}"
    local SER_IP=`echo ${SERVER_IP} | grep '^\(\(25[0-5]\|2[0-4][0-9]\|[01]\?[0-9]\?[0-9]\)\.\)\{3\}\(25[0-5]\|2[0-4][0-9]\|[01]\?[0-9]\?[0-9]\)$'`
    if  [ -z ${SER_IP} ]; then
        error "server ip ${SERVER_IP} format error"
    fi
}

# compile 
compile_code() {
    process "compile code"
    if  !( cd ${WORK_DIR} && make clean && make ); then
        error "compile failed"
    fi
}

# tar
tar_code() {
    process "tar code: ${RELEASE_TAR}"
    if !( cd ${WORK_DIR} && tar czf ${RELEASE_TAR} ./* > /dev/null 2>&1 );then
        error "tar ${RELEASE_TAR} failed"
    fi
}

# confirm
confirm() {
    echo "Do you want to release ${VERSION:-trunk} to server ${SERVER_IP}:${SERVER_DIR}?(Yes/No)"
    read CONFIRM
    if  [ "$CONFIRM" != "Yes" ]; then
        exit 0
    fi
}

# upload_by_ssh
upload_by_ssh() {
    process "upload ${RELEASE_TAR} to server ${SERVER_IP}:${SERVER_DIR}"
    if  !( eval ssh -p 22 root@${SERVER_IP} "\"mkdir -p ${SERVER_DIR}\"" && \
        scp ${WORK_DIR}/${RELEASE_TAR} root@${SERVER_IP}:${SERVER_DIR} ); then
        error "upload failed"
    fi
    process "UnZip ${RELEASE_TAR} to ${SERVER_IP}:${SERVER_DIR}"
    if !( eval ssh -p 22 root@${SERVER_IP} "\"cd ${SERVER_DIR} &&\
        tar zxf ${RELEASE_TAR} &&\
        rm -rf ${RELEASE_TAR} \""); then
        error "unzip failed"
    fi
}

# options
while [ $# -ne 0 ];do
    ARG=$1
    shift
    case "${ARG}" in
        -t )
            VERSION=$1;shift;;
        -s )
            SERVER_IP=$1;shift;;
        -d )
            SERVER_DIR=$1;shift;;
        -c )
            COMPILE_FLAG=true;;
        * )
            help
    esac
done

# release svn url
if  [ -z "${VERSION}" ];then
    RELEASE_SVN_URL=${BASE_SVN_URL}/trunk
    RELEASE_TAR=release_trunk_${NOW_DATE}.tar.gz
else
    RELEASE_SVN_URL=${BASE_SVN_URL}/tags/$VERSION
    RELEASE_TAR=release_${VERSION}_${NOW_DATE}.tar.gz
fi

# server dir 
if  [ -z "${SERVER_DIR}" ];then
    SERVER_DIR=~
fi

# check svn
check_version

# check server
check_server

# check out
check_out

# compile
if  [ ${COMPILE_FLAG} = true ]; then
    compile_code
fi

# tar
tar_code

# confirm
confirm

# upload
upload_by_ssh
