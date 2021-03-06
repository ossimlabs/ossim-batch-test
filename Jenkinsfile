// Expected env vars from Jenkins:

properties([
    parameters ([
      string(name: 'BUILD_NODE', defaultValue: 'ossim-test-build', description: 'The build node to run on'),
      booleanParam(name: 'ACCEPT_TESTS', defaultValue: false, description: 'Check this box to accept all tests as "expected results". The results from the tests will then be uploaded to s3 and replace the current expected results.'),
      booleanParam(name: 'CLEAN_WORKSPACE', defaultValue: true, description: 'Clean the workspace at the end of the run')
    ]),
    pipelineTriggers([
            [$class: "GitHubPushTrigger"],
            [
                $class: 'jenkins.triggers.ReverseBuildTrigger',
                upstreamProjects: "ossim-sandbox-ossimbuild-multibranch/${BRANCH_NAME}", threshold: hudson.model.Result.SUCCESS
            ]
    ]),
    [$class: 'GithubProjectProperty', displayName: '', projectUrlStr: 'https://github.com/ossimlabs/ossim-sandbox'],
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '3', daysToKeepStr: '', numToKeepStr: '20')),
    disableConcurrentBuilds()
])

node("${BUILD_NODE}")
{
   env.S3_DATA_BUCKET="s3://o2-test-data"

   try
   {
      stage("Download Artifacts")
      {
        withCredentials([string(credentialsId: 'o2-artifact-project', variable: 'o2ArtifactProject')]) {
            step ([$class: "CopyArtifact",
              projectName: "ossim-sandbox-ossimbuild-multibranch/${BRANCH_NAME}",
              filter: "ossim-sandbox-centos-7-runtime.tgz",
              flatten: true])            
            step ([$class: "CopyArtifact",
              projectName: "ossim-sandbox-ossimbuild-multibranch/${BRANCH_NAME}",
              filter: "ossim-centos-7-runtime.tgz",
              flatten: true])            
            step([$class     : 'CopyArtifact',
                  projectName: o2ArtifactProject,
                  filter     : "common-variables.groovy",
                  flatten    : true,
                  target     : "${env.WORKSPACE}"])
          }

         load "common-variables.groovy"
        }

     stage("Checkout")
     {
         dir("ossim-batch-test"){
            git branch: "${BRANCH_NAME}",
            url: "${GIT_PUBLIC_SERVER_URL}/ossim-batch-test.git",
            credentialsId: "${CREDENTIALS_ID}"
         }
     }

     stage("Run Tests")
     {
        env.OSSIM_INSTALL_PREFIX="${env.WORKSPACE}/ossim-install"
        env.OSSIM_PREFS_PREFIX="${env.OSSIM_INSTALL_PREFIX}/share/ossim/ossim-site-preferences"
        env.OSSIM_GIT_BRANCH = "${BRANCH_NAME}"
         sh """
           mkdir ${env.WORKSPACE}/ossim-install
           pushd ${env.WORKSPACE}/ossim-install
           tar xvfz ${env.WORKSPACE}/ossim-sandbox-centos-7-runtime.tgz
           tar xvfz ${env.WORKSPACE}/ossim-centos-7-runtime.tgz
           popd
         """
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
