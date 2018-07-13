import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.BUILDER_POD = "builder-pod-${UUID.randomUUID().toString()}"

env.DH_USER = "digitalinside"
env.USERNAME = "tigran10"

env.REPO = "https://github.com/${env.USERNAME}/go-demo-3.git" // Replace me
env.IMAGE = "${DH_USER}/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.10.217.44.206.nip.io" // Replace `acme.com` with the $ADDR retrieved earlier
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${currentBuild.displayName}-${env.BRANCH_NAME}"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"


podTemplate(
        label: env.BUILDER_POD,
        namespace: "go-demo-3-build",
        yaml: """         
apiVersion: v1
kind: Pod
spec:
  containers:    
  - name: helm
    image: vfarcic/helm:2.8.2    
    command: ["sleep"]
    args: ["100000"]
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: git
    image: alpine/git:latest
    command: ["sleep"]
    args: ["100000"]    
"""
) {

    node("docker") {
        def scmVars = checkout scm
        def commitHash = scmVars.GIT_COMMIT
        env.shortGitCommit = "${commitHash[0..10]}"

        stash name: 'source', useDefaultExcludes: false
//        stash name: 'source'

        sh "git fetch origin 'refs/tags/*:refs/tags/*'"
        def version = sh(script: 'git tag -l | tail -n1', returnStdout: true).trim() ?: 'v1.0.0'
        def parser = /(?<major>v\d+).(?<minor>\d+).(?<revision>\d+)/
        def match = version =~ parser
        match.matches()
        def (major, minor, revision) = ['major', 'minor', 'revision'].collect { match.group(it) }
        env.newVersion = "${major + "." + minor + "." + (revision.toInteger() + 1)}"

        try {
            timeout(time: 15, unit: 'SECONDS') { // change to a convenient timeout for you
                env.newVersion = input(
                        id: 'ProceedRelease', message: 'Was this successful?', parameters: [
                        [$class: 'StringParameterDefinition', defaultValue: env.newVersion, description: '', name: 'Confirm release version ']
                ])
            }
        } catch(err) { }
    }

    node("docker") {
        stage("build") {
            withCredentials([usernamePassword(
                    credentialsId: "docker",
                    usernameVariable: "USER",
                    passwordVariable: "PASS"
            )]) {
                sh """ sudo docker login -u $USER -p $PASS """
                sh """ ./build_docker.sh -n ${env.IMAGE} -t ${env.TAG_BETA} -t ${env.shortGitCommit} -p -i . """
            }
        }
    }

    node(env.BUILDER_POD) {
        unstash name: 'source'

        stage("func-test") {
            try {
                container("helm") {
                    sh """helm upgrade ${env.CHART_NAME} \
                        helm/go-demo-3 -i \
                        --tiller-namespace go-demo-3-build \
                        --set image.tag=${env.TAG_BETA} \
                        --set ingress.host=${env.ADDRESS}"""
                }
                container("kubectl") {
                    sh """kubectl -n go-demo-3-build rollout status deployment ${env.CHART_NAME}"""
                }
                container("golang") {
                    echo "--------this is NOT DONE--------"
                    sh "go get -d -v -t"
                    echo "--------this is done--------"
                    sh "ls -al"
                    sh """ADDRESS=${env.ADDRESS} go test ./... -v --run FunctionalTest"""
                }
            } catch (e) {
                error "Failed functional tests"
            } finally {
                container("helm") {
                    sh """helm delete ${env.CHART_NAME} --tiller-namespace go-demo-3-build --purge"""
                }
            }
        }

        node("docker") {
            if (env.BRANCH_NAME == 'master') {
                stage("release") {
                    sh """sudo docker pull ${env.IMAGE}:${env.TAG_BETA}"""
                    sh """sudo docker image tag ${env.IMAGE}:${env.TAG_BETA} ${env.IMAGE}:${env.newVersion}"""
                    sh """sudo docker image tag ${env.IMAGE}:${env.TAG_BETA} ${env.IMAGE}:latest"""
                    withCredentials([usernamePassword(
                            credentialsId: "docker",
                            usernameVariable: "USER",
                            passwordVariable: "PASS"
                    )]) {
                        sh """sudo docker login -u $USER -p $PASS"""
                    }
                    sh """sudo docker image push ${env.IMAGE}:${env.newVersion}"""
                    sh """sudo docker image push ${env.IMAGE}:latest"""

                    sh """ git tag $env.newVersion master  """
                    sh """ git push origin $env.newVersion """
                }

            }

        }


        stage("deploy") {
            if (env.BRANCH_NAME == 'master') {
                try {
                    container("helm") {
                        sh """helm upgrade \
                                go-demo-3 \
                                helm/go-demo-3 -i \
                                --tiller-namespace go-demo-3-build \
                                --namespace go-demo-3 \
                                --set image.tag=${env.TAG} \
                                --set ingress.host=${env.PROD_ADDRESS}"""
                    }
                    container("kubectl") {
                        sh """kubectl -n go-demo-3 rollout status deployment go-demo-3"""
                    }
                    container("golang") {
                        sh "go get -d -v -t"
                        sh """DURATION=1 ADDRESS=${env.PROD_ADDRESS} go test ./... -v --run ProductionTest"""
                    }
                } catch (e) {
                    container("helm") {
                        sh """helm rollback go-demo-3 0 --tiller-namespace go-demo-3-build"""
                        error "Failed production tests"
                    }
                }
            }

        }
    }
}