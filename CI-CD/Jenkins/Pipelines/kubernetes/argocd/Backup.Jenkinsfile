pipeline {
    agent any
    environment {
        DOCKER_IMAGE = credentials('docker-image')
        DOCKER_TAG = sh(script: "echo ${GIT_COMMIT.take(7)}", returnStdout: true).trim()
    }     
    stages {
        stage('Test') {
            environment {
                SONAR_TOKEN = credentials('SONAR_TOKEN')
                SONAR_HOST_URL = credentials('SONAR_HOST_URL')
                PROJECT_KEY = credentials('PROJECT_KEY')
            } 
            agent {
                docker { 
                    image 'sonarsource/sonar-scanner-cli:latest'
                    args '-u root'
                    reuseNode true  
                }
              }
            steps {
                script {
                    sh """
                        sonar-scanner \
                            -Dsonar.projectKey=${PROJECT_KEY} \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }

            post {
                always {
                    sh 'docker rmi sonarsource/sonar-scanner-cli:latest || true'
                }
            }            
        }

        stage('Build') {
            environment {
                DOCKERHUB_CREDENTIALS = credentials('dockerhub-cred')
            }            
            agent {
                docker { 
                    image 'docker:dind'
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root:root'
                    reuseNode true
                }
            }
            
            steps {
                script {
                    sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                    def customImage = docker.build("${DOCKER_IMAGE}")
                    customImage.push()
                    customImage.push("${DOCKER_TAG}")
                    sh 'docker logout'
                }
            }
            
            post {
                always {
                    sh 'docker rmi docker:dind || true'
                }
            }
        }
        
        stage('Deploy') {
            agent {
                docker { 
                    image 'cimg/base:stable'
                    reuseNode true
                }
            }
            
            steps {
                withCredentials([
                    string(credentialsId: 'manifest-repo', variable: 'K8S_MANIFEST_REPO'),
                    string(credentialsId: 'access-token', variable: 'MANIFEST_REPO_PAT')
                ]) {
                    sh '''
                        git clone https://x-access-token:${MANIFEST_REPO_PAT}@${K8S_MANIFEST_REPO} k8s-manifests
                        cd k8s-manifests
                        git config user.name "Jenkins"
                        git config user.email "jenkins@example.com"
                        git pull origin main
                        
                        awk -v image="${DOCKER_IMAGE}:${DOCKER_TAG}" '
                        /image:/ {$0 = "        image: " image}
                        {print}
                        ' app.yml > temp.yml && mv temp.yml app.yml
                        
                        if [ -n "$(git status --porcelain)" ]; then
                            echo "Changes detected. Committing and pushing..."
                            git add .
                            git commit -m "Update image tag to ${DOCKER_TAG}"
                            git push origin main
                        else
                            echo "No changes detected in Kubernetes manifests."
                        fi
                    '''
                }
            }
            
            post {
                always {
                    sh 'docker rmi cimg/base:stable || true'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
            sh 'docker system prune -af || true'
        }
    }
}