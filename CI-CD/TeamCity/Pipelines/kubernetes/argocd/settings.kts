import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.DockerCommandStep
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.buildSteps.sshExec
import jetbrains.buildServer.configs.kotlin.triggers.vcs

version = "2024.12"

project {

    buildType(Build)
}

object Build : BuildType({
    name = "Build"

    params {
        param("DOCKER_TAG", "%build.number%")
    }

    steps {
        dockerCommand {
            name = "Run SonarQube Analysis"
            commandType = other {
                subCommand = "run"
                commandArgs = """
                    --rm 
                    -v %system.teamcity.build.checkoutDir%:/usr/src
                    -e SONAR_HOST_URL=%env.SONAR_HOST_URL% 
                    -e SONAR_TOKEN=%env.SONAR_TOKEN% 
                    sonarsource/sonar-scanner-cli:latest 
                    sonar-scanner 
                    -Dsonar.projectKey=%env.SONAR_PROJECT_KEY% 
                    -Dsonar.projectName=%env.SONAR_PROJECT_NAME% 
                    -Dsonar.sources=/usr/src
                    -Dsonar.scm.disabled=true
                """.trimIndent()
            }
        }

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
                namesAndTags = "%env.DOCKER_IMAGE%:%DOCKER_TAG% %env.DOCKER_IMAGE%:latest"
                commandArgs = "--pull"
            }
        }

        dockerCommand {
            name = "push_tagged"
            id = "push_tagged"
            commandType = push {
                namesAndTags = "%env.DOCKER_IMAGE%:%DOCKER_TAG%"
            }
        }

        dockerCommand {
            name = "push_latest"
            id = "push_latest"
            commandType = push {
                namesAndTags = "%env.DOCKER_IMAGE%:latest"
            }
        }

        script {
            name = "deploy_argo"
            id = "deploy_argo"
            scriptContent = """
                #!/bin/bash
                
                apt-get update
                apt-get install -y git
                git clone %env.K8S_MANIFEST_REPO% k8s-manifests
                cd k8s-manifests
                git config user.name "TeamCity"
                git config user.email "teamcity@example.com"
                git pull origin main
                awk -v image="%env.DOCKER_IMAGE%:%DOCKER_TAG%" '
                    /image:/ {$0 = "        image: " image}
                    {print}
                ' app.yml > temp.yml && mv temp.yml app.yml
                
                if [[ -n $(git status -s) ]]; then
                    git add .
                    git commit -m "Update image tag"
                    git push
                else
                    echo "No changes detected in Kubernetes manifests."
                fi
            """.trimIndent()
        }    
    }

    vcs {
        root(DslContext.settingsRoot)
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
    }
})
