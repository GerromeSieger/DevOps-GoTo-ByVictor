import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.DockerCommandStep
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

version = "2025.03"

project {
    buildType(Build)
}

object Build : BuildType({
    name = "Build and Deploy"
    
    params {
        param("DOCKER_TAG", "%build.number%")
    }

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        dockerCommand {
            name = "docker_login"
            id = "docker_login"
            commandType = other {
                subCommand = "login"
                commandArgs = "-u %env.DOCKERHUB_USERNAME% -p %env.DOCKERHUB_PASSWORD%"
            }
        }

        dockerCommand {
            name = "build"
            id = "build"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                platform = DockerCommandStep.ImagePlatform.Linux
                namesAndTags = "%env.DOCKER_IMAGE%:%DOCKER_TAG%"
                commandArgs = "--pull"
            }
        }

        dockerCommand {
            name = "push"
            id = "push"
            commandType = push {
                namesAndTags = "%env.DOCKER_IMAGE%:%DOCKER_TAG%"
            }
        }
        
        script {
            name = "Install Google Cloud SDK and deploy to GKE"
            id = "deploy_to_gke"
            scriptContent = """
                #!/bin/bash
                
                apt-get update
                apt-get install -y apt-transport-https ca-certificates gnupg curl
                
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
                
                apt-get update
                apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin kubectl
                
                gcloud auth activate-refresh-token "%env.GCP_CLIENT_ID%" "%env.GCP_REFRESH_TOKEN%"
                gcloud config set project "%env.GCP_PROJECT_ID%"
                gcloud container clusters get-credentials "%env.GKE_CLUSTER_NAME%" --zone "%env.GKE_CLUSTER_ZONE%"
                
                kubectl get nodes
                
                awk -v image="%env.DOCKER_IMAGE%:%DOCKER_TAG%" '
                    /image:/ {$0 = "        image: " image}
                    {print}
                ' k8s/app.yml > temp.yml && mv temp.yml k8s/app.yml
                
                if [[ -n $(git status -s) ]]; then
                    kubectl apply -f k8s/
                else
                    echo "No changes detected in Kubernetes manifests."
                fi
            """.trimIndent()  
        }
    }

    triggers {
        vcs { }
    }

    features {
        perfmon { }
    }
})