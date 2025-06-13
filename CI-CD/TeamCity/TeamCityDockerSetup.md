# Setting Up TeamCity Server and Agent

This guide explains how to set up a TeamCity Server and Agent configuration with docker-compose.


1. Create a working directory and a docker-compose file:

```bash
mkdir teamcity
cd teamcity/
nano docker-compose.yml
```
Add the necessary configuration for the TeamCity server and agent(s).

2. Start the TeamCity server:

```bash
docker-compose up -d server
```

3. Access the TeamCity UI at http://ipaddress:8111 and create an admin user.

4. Start the TeamCity agent(s):

```bash
docker-compose up -d agent
```

5. Check the agent logs to ensure successful startup:

```bash
docker-compose logs -f agent
```

6. Authorize the agent in the UI: Agents > Unauthorized > Select Agent > Authorize

7. Create a project:
    - Projects > Create Project > From a repository URL
    - Fill in the required information and create the project


8. Create a build configuration:
    - In your project, click "Create build configuration"
    - Choose a name and ID for your build configuration
    - Select your Version Control System (VCS) and provide the repository URL
    - Configure build steps (e.g., compile, test, package)
    - Set up triggers (e.g., VCS trigger for automatic builds on commits)

9. Run your first build:
    - Click "Run" on your build configuration
    - Monitor the build progress and review results

10. Set up Versioned Settings:
    - Go to Project Settings > Versioned Settings
    - Enable "Synchronization enabled"
    - Choose "Use settings from VCS"
    - Select the VCS root containing your TeamCity settings
    - Configure the settings format (Kotlin or XML)
    - Apply the changes

11. Commit the initial versioned settings:
    - TeamCity will generate the initial settings files
    - Commit these files to your repository

12. Test the versioned settings:
    - Make a change to your build configuration in the UI
    - Observe that TeamCity automatically commits the change to your repository
    - Verify that changes made directly in the repository are reflected in the TeamCity UI

13. Set up build agents (if using multiple):
    - Configure additional agent containers in your docker-compose file
    - Start the new agents: docker-compose up -d
    - Authorize the new agents in the TeamCity UI

14. Configure build agent properties:
    - In the TeamCity UI, go to Agents > Select an agent > Agent Parameters
    - Add or modify properties as needed (e.g., environment variables, system properties)

15. Set up agent pools (optional):
    - Go to Agents > Agent Pools > Create new pool
    - Add agents to the pool
    - Assign build configurations to specific agent pools