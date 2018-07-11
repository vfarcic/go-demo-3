import java.text.SimpleDateFormat

def props
currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.9.1
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: build-config
      mountPath: /etc/config
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.9
    command: ["cat"]
    tty: true
  volumes:
  - name: build-config
    configMap:
      name: build-config
"""
) {
  node("kubernetes") {
    stage("build") {
      container("helm") {
        sh "cp /etc/config/build-config.properties ."
        props = readProperties interpolate: true, file: "build-config.properties"
      }
      node("docker") {
        checkout scm
        k8sBuildImageBeta(props.image)
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          checkout scm
          k8sUpgradeBeta(props.project, props.domain)
        }
        container("kubectl") {
          k8sRolloutBeta(props.project)
        }
        container("golang") {
          k8sFuncTestGolang(props.project, props.domain)
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          k8sDeleteBeta(props.project)
        }
      }
    }
    stage("release") {
      node("docker") {
        k8sPushImage(props.image)
      }
      container("helm") {
        k8sPushHelm(props.project, props.chartVer, props.cmAddr)
      }
    }
    stage("deploy") {
      try {
        container("helm") {
          k8sUpgrade(props.project, props.addr)
        }
        container("kubectl") {
          k8sRollout(props.project)
        }
        container("golang") {
          k8sProdTestGolang(props.addr)
        }
      } catch(e) {
        container("helm") {
          k8sRollback(props.project)
        }
      }
    }
  }
}