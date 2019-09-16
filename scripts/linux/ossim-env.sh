#!/bin/bash

#set -x; trap read debug
pushd `dirname ${BASH_SOURCE[0]}` >/dev/null
SCRIPT_DIR=`pwd -P`
popd

if [ -z $WORKSPACE ] ; then
   if [ -z $OSSIM_DEV_HOME ] ; then
      pushd $SCRIPT_DIR/../../.. >/dev/null
      export OSSIM_DEV_HOME=$PWD
      popd > /dev/null
   fi
else
   export OSSIM_DEV_HOME=$WORKSPACE
fi

if [  "$OSSIM_INSTALL_PREFIX" == "" ]; then
  export OSSIM_INSTALL_PREFIX=$OSSIM_DEV_HOME/install
fi

# For OSSIM run-time environment:
if [ "$OSSIM_DATA" == "" ] ; then
   export OSSIM_DATA="/data"
fi
if [  "$OSSIM_BATCH_TEST_DATA" == "" ] ; then
   export OSSIM_BATCH_TEST_DATA="$OSSIM_DATA/ossim-data/${OSSIM_GIT_BRANCH}"
fi
if [ "$OSSIM_BATCH_TEST_EXPECTED" == "" ] ; then
   export OSSIM_BATCH_TEST_EXPECTED="$OSSIM_DATA/ossim-expected/${OSSIM_GIT_BRANCH}"
fi
if [ "$OSSIM_BATCH_TEST_RESULTS" == "" ] ; then
   export OSSIM_BATCH_TEST_RESULTS="$OSSIM_DATA/ossim-results/${OSSIM_GIT_BRANCH}"
fi

# Always use the prefs file provided in this repo:
if [ "$OSSIM_PREFS_FILE" == "" ] ;  then
  export OSSIM_PREFS_FILE=$OSSIM_INSTALL_PREFIX/share/ossim/ossim-site-preferences
fi

# For S3 storage/syncing of test data
if [ "$S3_DATA_BUCKET" == "" ] ; then
   export S3_DATA_BUCKET="s3://o2_test_data"
fi


echo "S3_DATA_BUCKET = ${S3_DATA_BUCKET}"
echo "OSSIM_DATA = ${OSSIM_DATA}"
echo "OSSIM_BATCH_TEST_DATA = ${OSSIM_BATCH_TEST_DATA}"
echo "OSSIM_INSTALL_PREFIX = ${OSSIM_INSTALL_PREFIX}"
echo "OSSIM_PREFS_FILE = ${OSSIM_PREFS_FILE}"

export LD_LIBRARY_PATH="${OSSIM_INSTALL_PREFIX}/lib64:${OSSIM_INSTALL_PREFIX}/lib:${OSSIM_INSTALL_PREFIX}/lib64/ossim/plugins:${LD_LIBRARY_PATH}"
export PATH="${OSSIM_INSTALL_PREFIX}/bin:${PATH}"
