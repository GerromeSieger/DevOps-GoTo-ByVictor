import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.DockerCommandStep
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.sshExec
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

        sshExec {
            name = "deploy"
            id = "deploy"
            commands = """
                # Stop and remove existing container if it exists
                docker stop reactapp || true
                docker rm reactapp || true
                
                # Pull the new image
                docker pull %env.DOCKER_IMAGE%:%DOCKER_TAG%
                
                # Run the new container
                docker run -d \
                    --name reactapp \
                    -p 80:80 \
                    --restart unless-stopped \
                    %env.DOCKER_IMAGE%:%DOCKER_TAG%
                
                # Clean up old images
                docker system prune -f
            """.trimIndent()
            targetUrl = "%env.HOST%"
            authMethod = uploadedKey {
                username = "%env.USER%"
                key = "gcp_key"
            }
        }
    }

    triggers {
        vcs { }
    }

    features {
        perfmon { }
    }
})