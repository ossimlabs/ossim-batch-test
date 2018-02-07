#!/bin/bash

######################################################################################
#
# Test script for all OSSIM repositories. Required environment variables are:
#
#   OSSIM_DATA -- Local directory to contain elevation, imagery, and expected results
#
# Usage: ossim-test.sh [accept]
#
# If "accept" is specified, the results will be uploaded to the expected results on S3.
#
######################################################################################
#set -x; trap read debug

# Set run-time environment:
ACCEPT_RESULTS=$1

pushd `dirname ${BASH_SOURCE[0]}` >/dev/null
BATCH_TEST_SCRIPT_DIR=`pwd -P`
popd >/dev/null

if [ -z $WORKSPACE ] ; then
   if [ -z $OSSIM_DEV_HOME ] ; then
      pushd $BATCH_TEST_SCRIPT_DIR/../../.. >/dev/null
      export OSSIM_DEV_HOME=$PWD
      popd > /dev/null
   fi
else
   export OSSIM_DEV_HOME=$WORKSPACE
fi

if [ -z $OSSIM_INSTALL_PREFIX ]; then
  export OSSIM_INSTALL_PREFIX=$OSSIM_DEV_HOME/install
fi

# For OSSIM run-time environment:
if [ -z $OSSIM_DATA ] ; then
   export OSSIM_DATA="/data"
fi
if [ -z $OSSIM_BATCH_TEST_DATA ] ; then
   export OSSIM_BATCH_TEST_DATA="$OSSIM_DATA/ossim-data/${OSSIM_GIT_BRANCH}"
fi
if [ -z $OSSIM_BATCH_TEST_EXPECTED ] ; then
   export OSSIM_BATCH_TEST_EXPECTED="$OSSIM_DATA/ossim-expected/${OSSIM_GIT_BRANCH}"
fi
if [ -z $OSSIM_BATCH_TEST_RESULTS ] ; then
   export OSSIM_BATCH_TEST_RESULTS="$OSSIM_DATA/ossim-results/${OSSIM_GIT_BRANCH}"
fi

# Always use the prefs file provided in this repo:
export OSSIM_PREFS_FILE=$BATCH_TEST_SCRIPT_DIR/../../ossim.config

# For S3 storage/syncing of test data
if [ -z $S3_DATA_BUCKET ] ; then
   export S3_DATA_BUCKET="s3://o2_test_data"
fi


echo "S3_DATA_BUCKET = ${S3_DATA_BUCKET}"
echo "OSSIM_DATA = ${OSSIM_DATA}"
echo "OSSIM_BATCH_TEST_DATA = ${OSSIM_BATCH_TEST_DATA}"
echo "OSSIM_INSTALL_PREFIX = ${OSSIM_INSTALL_PREFIX}"
echo "OSSIM_PREFS_FILE = ${OSSIM_PREFS_FILE}"

export LD_LIBRARY_PATH="${OSSIM_INSTALL_PREFIX}/lib64:${OSSIM_INSTALL_PREFIX}/lib:${OSSIM_INSTALL_PREFIX}/lib64/ossim/plugins:${LD_LIBRARY_PATH}"
export PATH="${OSSIM_INSTALL_PREFIX}/bin:${PATH}"

function runCommand() 
{
  $1
  if [ $? != 0 ] ; then 
    echo "ERROR: Failed while executing command: <$1>."
    echo; exit 1;
  fi
}

echo; echo; 
echo "################################################################################"
echo "#  Running `basename "$0"` out of <$PWD>"
echo "################################################################################"

# Check for required environment:
if [ -z $OSSIM_DATA ] || [  -z $OSSIM_BATCH_TEST_DATA ] || [ -z $OSSIM_BATCH_TEST_RESULTS ]; then
  echo "ERROR: Environment variables not correct. Check the following paths for problems:"
  echo "   OSSIM_DATA = $OSSIM_DATA ";
  echo "   OSSIM_BATCH_TEST_DATA = $OSSIM_BATCH_TEST_DATA ";
  echo "   OSSIM_BATCH_TEST_RESULTS = $OSSIM_BATCH_TEST_RESULTS ";
  echo; exit 1;
fi

# Copy the ossim preferences file to the top install directory:
echo; echo "STATUS: Copying ossim preferences to install directory...";
runCommand "cp $OSSIM_DEV_HOME/ossim-ci/batch_tests/ossim.config $OSSIM_INSTALL_PREFIX"

# Do basic ossim config and version check first:
echo; echo "STATUS: Running ossim-info --config test...";
runCommand "ossim-info --config --plugins"
echo "STATUS: Passed ossim-info --config test.";

echo; echo "STATUS: Running ossim-info --version test...";
VERSION_OUT="$(ossim-info --version)"
echo $VERSION_OUT
COUNT="$(echo $VERSION_OUT | grep --count 'version: 1.9')"
echo "COUNT = <$COUNT>"
if [ $COUNT != "1" ]; then
  echo "FAIL: Failed ossim-info --version test"; 
  echo; exit 1;
fi
echo "STATUS: Passed ossim-info --version test.";

# Make sure the output directories are created:
if [ "$ACCEPT_RESULTS" == "accept" ]; then
  TEST_OUTPUT_DIR=$OSSIM_BATCH_TEST_EXPECTED
else
  TEST_OUTPUT_DIR=$OSSIM_BATCH_TEST_RESULTS
fi
if [ ! -d $TEST_OUTPUT_DIR ]; then
  echo "STATUS: Creating directory <$TEST_OUTPUT_DIR> to hold test output.";
  mkdir -p $TEST_OUTPUT_DIR;
fi

# Sync test data against S3:
if [ -z $S3_DATA_BUCKET ]; then
  S3_DATA_BUCKET="s3://o2-test-data"
  echo "WARNING: No URL specified for S3 bucket containing test data. Expecting S3_DATA_BUCKET environment variable. Defaulting to <$S3_DATA_BUCKET>"
  echo;
fi
echo "STATUS: Syncronizing test data from S3 to local agent." 
runCommand "aws s3 sync $S3_DATA_BUCKET/Batch_test_data $OSSIM_BATCH_TEST_DATA"
runCommand "aws s3 sync $S3_DATA_BUCKET/elevation $OSSIM_DATA/elevation"

pushd $OSSIM_DEV_HOME/ossim-batch-test;

if [ "$ACCEPT_RESULTS" == "accept" ]; then
  echo "STATUS: Running batch test and accepting results."   
  runCommand "ossim-batch-test -a all super-test.kwl"
  echo "STATUS: Uploading expected results to S3."  
  echo "aws s3 sync $OSSIM_BATCH_TEST_EXPECTED $S3_DATA_BUCKET/Batch_test_expected/${OSSIM_GIT_BRANCH}"
  runCommand "aws s3 sync $OSSIM_BATCH_TEST_EXPECTED $S3_DATA_BUCKET/Batch_test_expected/${OSSIM_GIT_BRANCH}"
  echo "STATUS: Upload successfull."   
else
  echo "STATUS: Syncronizing expected results from S3 to local agent." 
  runCommand "aws s3 sync $S3_DATA_BUCKET/Batch_test_expected/${OSSIM_GIT_BRANCH} $OSSIM_BATCH_TEST_EXPECTED"
  echo "STATUS: Running batch test and comparing to expected results."   
  runCommand "ossim-batch-test super-test.kwl"
fi
  
echo "STATUS: Passed all tests."
echo
exit 0


