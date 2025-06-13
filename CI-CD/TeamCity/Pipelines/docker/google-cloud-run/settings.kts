import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.DockerCommandStep
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.buildFeatures.swabra

version = "2025.03"

project {
    buildType(BuildAndDeploy)
}

object BuildAndDeploy : BuildType({
    name = "Build and Deploy to Cloud Run"
    
    // Parameters
    params {
        param("DOCKER_TAG", "%build.number%-%build.vcs.number.1%")
        param("GCP_REGION", "us-central1")
        param("SERVICE_NAME", "my-application")
        param("GCP_REPOSITORY", "container-images")
        param("TAGGED_IMAGE", "%GCP_REGION%-docker.pkg.dev/%env.GCP_PROJECT_ID%/%GCP_REPOSITORY%/%SERVICE_NAME%:%DOCKER_TAG%")
        param("LATEST_IMAGE", "%GCP_REGION%-docker.pkg.dev/%env.GCP_PROJECT_ID%/%GCP_REPOSITORY%/%SERVICE_NAME%:latest")    
    }

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {

        script {
            name = "Push to Registry"
            id = "build_push"
            scriptContent = """
                set -e
                # Authenticate with Google Cloud
                echo "Authenticating with Google Cloud..."
                gcloud auth activate-refresh-token "%env.GCP_CLIENT_ID%" "%env.GCP_REFRESH_TOKEN%"
                gcloud config set project "%env.GCP_PROJECT_ID%"
                
                echo "Configuring Docker authentication..."
                gcloud auth configure-docker %GCP_REGION%-docker.pkg.dev --quiet
                
                # Push Docker images
                echo "Pushing images to Artifact Registry..."
                docker push %TAGGED_IMAGE%
                docker push %LATEST_IMAGE%
                
            """.trimIndent()
            dockerImage = "google/cloud-sdk:latest"
            dockerPull = true
            dockerRunParameters = """
                --privileged
                -v /var/run/docker.sock:/var/run/docker.sock
            """
        }

        script {
            name = "Deploy to Cloud Run"
            id = "deploy"
            scriptContent = """
                set -e
                # Authenticate with Google Cloud
                echo "Authenticating with Google Cloud..."
                gcloud auth activate-refresh-token "%env.GCP_CLIENT_ID%" "%env.GCP_REFRESH_TOKEN%"
                gcloud config set project "%env.GCP_PROJECT_ID%"
                
                # Deploy to Cloud Run
                echo "Deploying to Cloud Run..."
                gcloud run deploy %SERVICE_NAME% \
                    --image=%TAGGED_IMAGE% \
                    --region=%GCP_REGION% \
                    --platform=managed \
                    --memory=512Mi \
                    --cpu=1 \
                    --min-instances=0 \
                    --max-instances=10 \
                    --concurrency=80 \
                    --timeout=300s \
                    --port=80 \
                    --quiet
                
                # Get and display the service URL
                gcloud run services describe %SERVICE_NAME% --region=%GCP_REGION% --format='value(status.url)' > service_url.txt
                echo "Deployed to: $(cat service_url.txt)"
            """.trimIndent()
            dockerImage = "google/cloud-sdk:latest"
            dockerPull = true
            dockerRunParameters = """
                --privileged
                -v /var/run/docker.sock:/var/run/docker.sock
            """
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
})