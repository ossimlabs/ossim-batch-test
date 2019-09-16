// Expected env vars from Jenkins:

properties([
    parameters ([
      string(name: 'BUILD_NODE', defaultValue: 'ossim-test-build', description: 'The build node to run on'),
      booleanParam(name: 'ACCEPT_TESTS', defaultValue: false, description: 'Check this box to accept all tests as "expected results". The results from the tests will then be uploaded to s3 and replace the current expected results.'),
      booleanParam(name: 'CLEAN_WORKSPACE', defaultValue: true, description: 'Clean the workspace at the end of the run')
    ]),
    pipelineTriggers([
            [$class: "GitHubPushTrigger"]
    ]),
    [$class: 'GithubProjectProperty', displayName: '', projectUrlStr: 'https://github.com/ossimlabs/ossim-sandbox'],
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '3', daysToKeepStr: '', numToKeepStr: '20')),
    disableConcurrentBuilds()
])

node("${BUILD_NODE}")
{
  //  echo "WORKSPACE        = ${env.WORKSPACE}"
  //  echo "LD_LIBRARY_PATH  = ${env.LD_LIBRARY_PATH}"
  //  echo "PATH             = ${env.PATH}"
  //  echo "S3_DATA_BUCKET   = ${env.S3_DATA_BUCKET}"
  //  echo "ACCEPT_TESTS     = ${ACCEPT_TESTS}"
  //  echo "OSSIM_PIPELINE   = ${OSSIM_PIPELINE}"
  //  echo "OSSIM_GIT_BRANCH = ${OSSIM_GIT_BRANCH}"
  //  echo "CLEAN_WORKSPACE  = ${CLEAN_WORKSPACE}"

   env.S3_DATA_BUCKET="s3://o2-test-data"

   try
   {
      stage("Checkout")
      {
        checkout(scm)
     }
      stage("Download Artifacts")
      {
        withCredentials([string(credentialsId: 'o2-artifact-project', variable: 'o2ArtifactProject')]) {
            step ([$class: "CopyArtifact",
              projectName: "ossim-sandbox-ossimbuild-multibranch/${BRANCH_NAME}",
              filter: "ossim-sandbox-centos-7-*.tgz",
              flatten: true])            
            step([$class     : 'CopyArtifact',
                  projectName: o2ArtifactProject,
                  filter     : "common-variables.groovy",
                  flatten    : true,
                  target     : "${env.WORKSPACE}"])
          }

         sh """
           mkdir ${env.WORKSPACE}/ossim-install
           pushd ${env.WORKSPACE}/ossim-install
           tar xvfz ossim-sandbox-centos-7-*.tgz
           popd
         """
        }

      stage("Load Variables")
      {
         load "common-variables.groovy"
      }

     stage("Run Tests")
     {
        env.OSSIM_INSTALL_PREFIX="${env.WORKSPACE}/ossim-install"
        env.OSSIM_PREFS_PREFIX="${env.OSSIM_INSTALL_PREFIX}/share/ossim/ossim-site-preferences"
        if (ACCEPT_TESTS.toBoolean())
        {  
          echo "**************ACCEPTING ALL TESTS*************"
          sh """
          pushd ${env.WORKSPACE}/ossim-batch-test/scripts/linux
          ./ossim-test.sh accept
          popd
          """
        }
        else
        {
          sh """
          pushd ${env.WORKSPACE}/ossim-batch-test/scripts/linux
          ./ossim-test.sh
          popd
          """
        }
     }
  }
  catch(e)
  {
    currentBuild.result = 'FAILED'

  }

  stage("Clean Workspace")
  {
      if ("${CLEAN_WORKSPACE}" == "true")
        step([$class: 'WsCleanup'])
  }
}
