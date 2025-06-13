# Setting Up Bamboo CI/CD Server and Agent

This guide explains how to set up a Bamboo Server and Agent configuration using Docker.

1. Create a working directory:

```bash
mkdir bamboo
cd bamboo
```
2. Create a the agent's Dockerfile:

```bash
nano Dockerfile
```

3. Create the bamboo-capabilities.properties file:

```bash
nano bamboo-capabilities.properties
```

2. Create a docker-compose file:

```bash
nano docker-compose.yml
```

Add the necessary configuration for the Bamboo server and agent(s).

3. Start the Bamboo server and postgres database:

```bash
    docker-compose up -d bamboo-server postgres
```

Access the Bamboo UI at http://ipaddress:8085 and complete the setup wizard:

4. Set up your license at https://my.atlassian.com/license/evaluation:

5. Add this line as the broker Url: failover:(tcp://bamboo-server:54663?wireFormat.maxInactivityDuration=300000)?initialReconnectDelay=15000&maxReconnectAttempts=10

6. Connect to the postgres database with credentials created:

7. Create an admin user:

8. Configure your instance name and base URL:

9. Start the Bamboo agent(s):

```bash
docker-compose up -d --build bamboo-agent
```

10. Check the agent logs to ensure successful startup:

```bash
docker-compose logs -f bamboo-agent
```

11. Approve the agent in the UI:
    - Go to Settings > Agents > Online remote agents
    - Click "Approve agent" for the new agent


12. Create a project:
    - Projects > Create project   
    - Fill in the project name and key


13. Create a plan:
    - In your project, click "Create plan"
    - Choose a name and key for your plan
    - Select your Version Control System (VCS) and provide the repository details
    - Configure job tasks (e.g., compile, test, package)
    - Set up triggers (e.g., repository polling for automatic builds on commits)


14. Run your first build:
    - Click "Run plan" on your plan's page
    - Monitor the build progress and review results


15. Setup a Repository and authenticate to it with:
    - Username & Password (Bitbucket and Gitlab)
    - Access Token (Github)
    - Ensure the repository has Project Access.

16. Set up Bamboo Specs (equivalent to TeamCity's Versioned Settings):
    - In your project, go to Spec > Set up specs repository
    - Choose the repository where you'll store your Bamboo Specs
    - Configure the Specs settings (e.g., file location, branch)

17. Create and commit the initial Bamboo Specs in bamboo-specs/bamboo.yaml.

18. Setup a webhook for in the repository and ensure the content-type is application json. Copy the webhook url from bamboo to the repository webhook settings. 

19. Use the Bamboo Java Specs API to define your project and plan configuration
Commit these files to your repository (OPTIONAL)

20. Test the Bamboo Specs:

21. Make a change to your plan configuration in the Specs file
Commit and push the changes
Verify that the changes are reflected in the Bamboo UI


Set up additional build agents (if using multiple):

Configure additional agent containers in your docker-compose file
Start the new agents: docker-compose up -d
Approve the new agents in the Bamboo UI


Configure build agent capabilities:

In the Bamboo UI, go to Settings > Agents > Capabilities
Add or modify capabilities as needed (e.g., environment variables, executable locations)


Set up agent assignments (optional):

Go to your plan configuration
In the "Requirements" tab, specify the capabilities required for this plan
Bamboo will automatically assign builds to agents with matching capabilities


Set up Deployments (Bamboo's equivalent to TeamCity's build configurations for deployments):

Go to Deployments > Create deployment project
Link it to your build plan
Configure environments (e.g., Development, Staging, Production)
Set up deployment tasks for each environment


Configure Bamboo variables:

Go to Settings > Global variables to set global variables
In your plan or deployment configuration, add plan or environment-specific variables


Set up notifications:

Go to your plan or deployment project
Configure notifications for build or deployment events


Enable artifacts sharing:

In your build plan, configure which files should be saved as artifacts
In your deployment project, use these artifacts for deployment tasks



This guide provides a similar structure to your TeamCity setup, adapted for Bamboo CI/CD. Remember that while there are many similarities, some concepts and terminologies differ between TeamCity and Bamboo.
