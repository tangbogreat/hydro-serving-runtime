def collectTestResults() {
    step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml', allowEmptyResults: true])
}

def currentVersion() {
    return readFile("version").trim()
}

def changeVersion(version) {
    writeFile file: 'version', text: version
}

def calculateReleaseVersion(currentVersion) {
    def index=currentVersion.lastIndexOf("-SNAPSHOT")
    def releaseVersion
    if(index>-1){
        releaseVersion=currentVersion.substring(0, index)
    }else{
        releaseVersion=currentVersion
    }
    return releaseVersion
}

def calculateNextDevVersion(releaseVersion) {
    int index = releaseVersion.lastIndexOf('.')
    String minor = releaseVersion.substring(index + 1)
    int m = minor.toInteger() + 1
    return releaseVersion.substring(0, index + 1) + m + "-SNAPSHOT"
}

def checkoutSource(gitCredentialId, organization, repository) {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: gitCredentialId, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
        git url: "https://github.com/${organization}/${repository}.git", branch: env.BRANCH_NAME, credentialsId: gitCredentialId
        sh """
            git config --global push.default simple
            git config --global user.name '${GIT_USERNAME}'
            git config --global user.email '${GIT_USERNAME}'
        """
    }
}

def pushSource(gitCredentialId, organization, repository, pushCommand) {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: gitCredentialId, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
        sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${organization}/${repository}.git ${pushCommand}"
    }
}

def isReleaseJob() {
    return "release".equalsIgnoreCase(env.BRANCH_NAME)
}

def generateTagComment(releaseVersion){
    commitsList=sh(returnStdout: true, script: "git log --pretty=\"%B\n\r (%an)\" -1").trim()
    return "${commitsList}"
}

def createReleaseInGithub(gitCredentialId, organization, repository, releaseVersion, message){

   bodyMessage=message.replaceAll("\n","<br />").replace("\r", "")
   withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: gitCredentialId, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
        def request = """
            {
                "tag_name": "${releaseVersion}",
                "name": "${releaseVersion}",
                "body": "${bodyMessage}",
                "draft": false,
                "prerelease": false
            }
        """
        echo request
        def response = httpRequest consoleLogResponseBody: true, acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: request, url: "https://api.github.com/repos/${organization}/${repository}/releases?access_token=${GIT_PASSWORD}"
   }
}

node("JenkinsOnDemand") {
    def repository = 'hydro-serving-runtime'
    def organization = 'Hydrospheredata'
    def gitCredentialId = 'HydrospheredataGithubAccessKey'


    stage('Checkout') {
        deleteDir()
        checkoutSource(gitCredentialId, organization, repository)
    }

    if (isReleaseJob()) {
        stage('Set release version') {
            def curVersion = currentVersion()
            def nextVersion=calculateReleaseVersion(curVersion)
            changeVersion(nextVersion)
        }
    }

    stage('Build') {
        def curVersion = currentVersion()
        sh "${env.WORKSPACE}/build.sh ${curVersion}"
    }

    stage('Test') {
        //TODO test???
    }
    if (isReleaseJob()) {
        //if (currentBuild.result == 'UNSTABLE') {
        //    currentBuild.result = 'FAILURE'
        //    error("Errors in tests")
        //}

        stage("Publish"){
            def curVersion = currentVersion()
            tagComment=generateTagComment(curVersion)
            sh "git commit -m 'Releasing ${curVersion}' -- version"
            sh "git tag -a ${curVersion} -m '${tagComment}'"

            sh "git checkout master"

            def nextVersion=calculateNextDevVersion(curVersion)
            changeVersion(nextVersion)

            sh "git commit -m 'Development version increased: ${nextVersion}' -- version"

            pushSource(gitCredentialId, organization, repository, "")

            sh "docker push hydrosphere/serving-runtime-scikit:${curVersion}"
            sh "docker push hydrosphere/serving-runtime-customscikit:${curVersion}"
            sh "docker push hydrosphere/serving-runtime-py2databricks:${curVersion}"
            sh "docker push hydrosphere/serving-runtime-sparklocal-2.0:${curVersion}"
            sh "docker push hydrosphere/serving-runtime-sparklocal-2.1:${curVersion}"
            sh "docker push hydrosphere/serving-runtime-sparklocal-2.2:${curVersion}"
            sh "docker push hydrosphere/serving-runtime-tensorflow:${curVersion}"

            pushSource(gitCredentialId, organization, repository, "refs/tags/${curVersion}")

            createReleaseInGithub(gitCredentialId, organization, repository,curVersion,tagComment)
        }
    } else {
        stage("Publish_snapshoot"){
            def curVersion = currentVersion()
            GIT_COMMIT = sh (
                     script: 'git rev-parse --short HEAD',
                     returnStdout: true
            ).trim()
      
            ['serving-runtime-scikit', 'serving-runtime-customscikit', 'serving-runtime-py2databricks', 'serving-runtime-sparklocal-2.0', 'serving-runtime-sparklocal-2.1', 'serving-runtime-sparklocal-2.2', 'serving-runtime-tensorflow'].each {
           
              sh "docker tag hydrosphere/${it}:${curVersion} 060183668755.dkr.ecr.eu-central-1.amazonaws.com/${it}:${GIT_COMMIT}"

              IMAGE = "060183668755.dkr.ecr.eu-central-1.amazonaws.com/${it}:${GIT_COMMIT}"
              docker.withRegistry('https://060183668755.dkr.ecr.eu-central-1.amazonaws.com', 'ecr:eu-central-1:jenkins_aws') {
                docker.image(IMAGE).push()
              }
          }
        }
     }
}
