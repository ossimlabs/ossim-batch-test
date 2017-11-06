def notifyObj
node("BATCH_TEST"){
   env.WORKSPACE=pwd()
//   env.LD_LIBRARY_PATH="${env.WORKSPACE}/install/lib64:${env.WORKSPACE}/install/lib64/ossim/plugins:${env.LD_LIBRARY_PATH}"
//   env.PATH="${env.WORKSPACE}/install/bin:${env.PATH}"
   env.S3_DATA_BUCKET="s3://o2-test-data"
   
   echo "WORKSPACE        = ${env.WORKSPACE}"
   echo "LD_LIBRARY_PATH  = ${env.LD_LIBRARY_PATH}"   
   echo "PATH             = ${env.PATH}"
   echo "S3_DATA_BUCKET   = ${env.S3_DATA_BUCKET}"
   echo "ACCEPT_TESTS     = ${ACCEPT_TESTS}"
   echo "OSSIM_GIT_BRANCH = ${OSSIM_GIT_BRANCH}"
   try{
     stage("Checkout") {
         dir("ossim-ci") {
            git branch: "${OSSIM_GIT_BRANCH}", url: 'https://github.com/ossimlabs/ossim-ci.git'
         }
         notifyObj = load "${env.WORKSPACE}/ossim-ci/jenkins/pipeline/notify.groovy"
     }

     stage("Download Artifacts") {
        step ([$class: 'CopyArtifact',
              projectName: "ossim-${OSSIM_GIT_BRANCH}",
              filter: "artifacts/install.tgz",
              flatten: true,
              target: "${env.WORKSPACE}"])
        sh """
          pushd ${env.WORKSPACE}
          tar xvfz install.tgz
          popd
        """
     }
     if (ACCEPT_TESTS.toBoolean()) {
       stage("Accept Results")
       {
          sh """
          pushd ${env.WORKSPACE}/ossim-ci/scripts/linux
          ./ossim-test.sh accept
          popd
          """
      }
    }
    else {
       stage("Run Tests")
       {
          sh """
          pushd ${env.WORKSPACE}/ossim-ci/scripts/linux
          ./ossim-test.sh
          popd
          """
       }
    }
   
  }
  catch(e)
  {
    currentBuild.result = "FAILED"
    notifyObj?.notifyFailed()
  }
  stage("Clean Workspace"){
     step([$class: 'WsCleanup'])
  }
}
