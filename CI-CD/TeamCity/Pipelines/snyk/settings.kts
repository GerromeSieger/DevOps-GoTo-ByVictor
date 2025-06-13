import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.buildFeatures.swabra

version = "2025.03"

project {
    buildType(SnykScan)
}

object SnykScan : BuildType({
    name = "Snyk Security Scan"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Code Scan"
            id = "snyk_code_scan"
            scriptContent = """
                #!/bin/bash
                echo "Running Snyk Code Scan"
                
                apt-get update && apt-get install -y ca-certificates && \
                npm install -g snyk@latest --cache .npm --prefer-offline && \
                snyk auth %env.SNYK_TOKEN% && \
                snyk code test --severity-threshold=high --sarif-file-output=./snyk-code-results.sarif || true && \
                test -f ./snyk-code-results.sarif || echo '{}' > ./snyk-code-results.sarif
            """.trimIndent()
            dockerImage = "node:18-slim"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerPull = true
            dockerRunParameters = """
                -v "%system.teamcity.build.checkoutDir%:/scan-target"
                -w /scan-target
            """.trimIndent()
        }

        script {
            name = "Build and Scan Container Image"
            id = "snyk_image_scan"
            scriptContent = """
                #!/bin/sh
                echo "Building and scanning container image"
                
                # Build the image
                docker build -t my-app:%build.vcs.number% .
                
                # Run Snyk container scan
                apk add --no-cache nodejs npm && \
                npm install -g snyk@latest && \
                snyk auth %env.SNYK_TOKEN% && \
                snyk container test my-app:%build.vcs.number% --severity-threshold=high \
                    --json-file-output=./snyk-image-results.json || true
            """.trimIndent()
            dockerImage = "docker:latest"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerPull = true
            dockerRunParameters = """
                -v "%system.teamcity.build.checkoutDir%:/scan-target"
                -v /var/run/docker.sock:/var/run/docker.sock
                -w /scan-target
            """.trimIndent()
        }
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
        swabra {
            forceCleanCheckout = true
            verbose = true
        }
    }
    
    artifactRules = """
        snyk-code-results.sarif
        snyk-image-results.json
    """.trimIndent()
})
