node() {
  stage ('Checkout Source') {
    deleteDir();
    checkout scm
    // Get commit id
    GIT_COMMIT = sh script: 'git rev-parse HEAD', returnStdout: true
    GIT_COMMIT = GIT_COMMIT.replaceAll("\\s","")
  }

  stage ('Install Gems') {
    sh '''#!/bin/bash -l
          rvm use 2.3.0@echo-client-ios-swift --create
          gem install cocoapods --pre
          gem install xcpretty
          pod install --repo-update
       '''
  }

  stage ('Build & Test Library') {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "XTerm"]) {
      try {
          sh '''#!/bin/bash -l
                xcodebuild -workspace Echo.xcworkspace -scheme Echo -destination "platform=iOS Simulator,name=iPhone 7 Plus" clean test | tee build.log | xcpretty --color --report junit && exit "${PIPESTATUS[0]}"
             '''
          UNIT_TESTS = 'success'
      } catch (Exception error) {
          UNIT_TESTS = 'failure'
      }
      // Report UNit tests result to github
      sh """curl "https://api.github.com/repos/bbc/echo-client-ios-swift/statuses/${GIT_COMMIT}"\\
            -H "Authorization: token ${env.GITHUB_API_TOKEN}"\\
            -X POST\\
            -d "{\\"state\\": \\"${UNIT_TESTS}\\", \\"description\\": \\"Unit Tests\\", \\"target_url\\": \\"${env.BUILD_URL}\\", \\"context\\": \\"Jenkins Unit Tests\\"}" """
    }
    step([$class: 'JUnitResultArchiver', testResults: '**/build/reports/*.xml'])
  }



  stage ('Lint Podspec') {
    try {
      sh '''#!/bin/bash -l
            pod lib lint --sources=\"git@github.com:bbc/map-ios-podspecs.git,https://github.com/CocoaPods/Specs\" --allow-warnings --verbose
         '''
      PODSPEC_LINT_STATUS = 'success'
    } catch (Exception error) {
      PODSPEC_LINT_STATUS = 'failure'
    }
    // Report Linting result to github
    sh """curl "https://api.github.com/repos/bbc/echo-client-ios-swift/statuses/${GIT_COMMIT}"\\
          -H "Authorization: token ${env.GITHUB_API_TOKEN}"\\
          -X POST\\
          -d "{\\"state\\": \\"${PODSPEC_LINT_STATUS}\\", \\"description\\": \\"Podspec Linting\\", \\"target_url\\": \\"${env.BUILD_URL}\\", \\"context\\": \\"Jenkins Podspec Linting\\"}" """
  }
  // Set Build Status
  if (UNIT_TESTS == 'success' && PODSPEC_LINT_STATUS == 'success' ) {
    currentBuild.result = 'SUCCESS'
  } else {
    currentBuild.result = 'FAILURE'
  }

  // Send Slack Notification
  if(currentBuild.result == "SUCCESS") {
     slackSend color: "#2A9B3A", message: "Successful Build: ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
   } else {
     slackSend color: "#C50000", message: "Failed Build: ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
   }

} // end node
