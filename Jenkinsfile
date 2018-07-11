import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.BUILDER_POD = "builder-pod-${UUID.randomUUID().toString()}"

env.DH_USER="digitalinside"
env.USERNAME="tigran10"

env.REPO = "https://github.com/${env.USERNAME}/go-demo-3.git" // Replace me
env.IMAGE = "${DH_USER}/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.TAG_BETA = "${currentBuild.displayName}-${env.BRANCH_NAME}"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"
env.shortGitCommit = "${env.GIT_COMMIT[0..10]}"

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
"""
) {

    node("docker") {
        stage("build") {
            git "${env.REPO}"
            sh """./build_docker.sh -n ${env.IMAGE} -l -t ${env.TAG_BETA} -t ${env.shortGitCommit} -i . """
            withCredentials([usernamePassword(
                    credentialsId: "docker",
                    usernameVariable: "USER",
                    passwordVariable: "PASS"
            )]) {
                sh """sudo docker login -u $USER -p $PASS"""
            }
            sh """sudo docker image push ${env.IMAGE}:${env.TAG_BETA}"""
        }
    }

    node(env.BUILDER_POD) {


        stage("func-test") {
            try {

                git "${env.REPO}"
                container("helm") {


                    sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
                }
                container("kubectl") {
                    sh """kubectl -n go-demo-3-build \
            rollout status deployment \
            ${env.CHART_NAME}"""
                }
                container("golang") { // Uses env ADDRESS
                    sh "go get -d -v -t"
                    sh """go test ./... -v \
            --run FunctionalTest"""
                }
            } catch(e) {
                error "Failed functional tests"
            } finally {
                container("helm") {
                    sh """helm delete ${env.CHART_NAME} \
            --tiller-namespace go-demo-3-build \
            --purge"""
                }
            }
        }
    }
}