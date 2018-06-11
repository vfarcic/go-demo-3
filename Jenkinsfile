import java.text.SimpleDateFormat

env.GH_USER = "tigran10" // Replace me
env.DH_USER = "digitalinside" // Replace me
env.PROJECT = "go-demo-3"

def label = "mypod-${UUID.randomUUID().toString()}"
podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: some-label-value
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.8.2
    command:
    - cat
    tty: true
  - name: go
    image: golang:1.10
    command:
    - cat
    tty: true
  - name: git
    image: alpine/git
    command:
    - cat
    tty: true
  - name: docker
    image: docker
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock-volume
  volumes:
  - name: docker-sock-volume
    hostPath:
      path: /var/run/docker.sock
      type: File
"""
) {
  currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
  node(label) {
    stage('build docker') {
      container('git') {
            sh """git clone https://github.com/${env.GH_USER}/${env.PROJECT}.git ."""
      }
            
      container('docker') {
          withCredentials([usernamePassword(credentialsId: "docker", usernameVariable: "USER", passwordVariable: "PASS")]) {
              sh """docker login -u $USER -p $PASS"""
          }
          sh """docker image build -t ${env.DH_USER}/${env.PROJECT}:${currentBuild.displayName}-beta ."""
          sh """docker image push ${env.DH_USER}/${env.PROJECT}:${currentBuild.displayName}-beta"""
          sh "docker logout"
      }
    }      
  }
}
