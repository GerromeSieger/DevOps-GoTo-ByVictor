import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.NodeJSBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.SSHUpload
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.nodeJS
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.buildSteps.sshExec
import jetbrains.buildServer.configs.kotlin.buildSteps.sshUpload
import jetbrains.buildServer.configs.kotlin.triggers.vcs

version = "2024.03"

project {

    buildType(Build)

}

object Build : BuildType({
    name = "Build"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        nodeJS {
            name = "build"
            id = "nodejs_runner"
            shellScript = """
                npm install
                npm run build
            """.trimIndent()
            dockerImage = "node:18-alpine"
            dockerImagePlatform = NodeJSBuildStep.ImagePlatform.Any
        }
        script {
            name = "test"
            id = "simpleRunner"
            scriptContent = "sh test.sh"
            dockerImage = "ubuntu:22.04"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerPull = true
        }
        sshUpload {
            name = "deploy_copy"
            id = "deploy_copy"
            transportProtocol = SSHUpload.TransportProtocol.SCP
            sourcePath = "build => ."
            targetUrl = "%env.HOST%:/root/build"
            authMethod = uploadedKey {
                username = "%env.USER%"
                key = "id_rsa"
            }
        }
        sshExec {
            name = "deploy_run"
            id = "deploy_run"
            commands = "cp -r build/* /var/www/html && systemctl restart nginx"
            targetUrl = "%env.HOST%"
            authMethod = uploadedKey {
                username = "%env.USER%"
                key = "id_rsa"
            }
        }
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