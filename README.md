# ecs-tools

A package of tools written in the Ruby programming language, used to handle Amazon Elastic Container Service.
With these tools you can easily define your container deployment, build and push containers and connect to your containers hosted on AWS.

Its current state is in development.

## Prerequisites

The most comfortable on a secure machine is to have `aws cli` configured and to have your access key and secret key in your environment variables.
You can use tools like [`direnv`](https://github.com/direnv/direnv)) to keep these narrowed down by project/directory.

You need to have:

* A valid AWS access key and secret key, the tools respect `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
* An Amazon region you can use, the tools respect the `AWS_REGION` environment variable as default
* If you configured `aws-cli` to use profiles, make sure `AWS_DEFAULT_PROFILE` is set.

## ecr-build

Build docker images and push it to your private repository hosted on Amazon ECR.
Beware, ecr-build assumes you are using `docker login` and the machine you are operating from is safe to use that way of logging into a docker registry.

**Example:**

Build the current directory, assumes a `Dockerfile` to be present, login docker to ECR, pushes to `0123456789.dkr.ecr.us-east-1.amazonaws.com/my-repository`

```
ecr-build --tag mytag --repository-url 0123456789.dkr.ecr.us-east-1.amazonaws.com/myrepository
```

## ecs-deploy

Uses a configuration file to deploy one or more services and tasks onto your ECS cluster.
This tool heavily relies on the configuration file you provide.

It allows for multiple different container definitions, one off commands and services to be described.

```yaml
# container_definitions hold generic container descriptions that can be stored as a YAML reference.
container_definitions:
  # use a YAML reference &railsapp as a template for task definitions
  # Everything that should serve as a base for this container goes here.
  railsapp: &railsapp
    image: 0123456789.dkr.ecr.us-east-1.amazonaws.com/myrepository:mytag
    port_mappings: []
    # docker cpu units (lowest 2, 1 core = 1024 units)
    cpu: 2
    # Max RAM in MiB
    memory: 750
    essential: true
    user: app
    working_directory: /home/app/current
    entry_point:
      - "/bin/bash"
      - "-c"
    log_configuration:
      log_driver: "syslog"
      options:
        "syslog-address": "tcp+tls://logs123.papertrailapp.com:12345"
        tag: "railsapp-web"
    environment:
      - name: RAILS_ENV
        value: "production"

# task_definitions describe an ECS task, using container_definitions to overwrite docker container settings of the image
# So it is possible to have the same container running different tasks. Hence the YAML references for generic container configuration.
# One app container might be used to serve a Rails app server and a sidekiq background process.
task_definitions:
  # the name of the task family, should be uniq across your AWS account. All tasks share the same namespace.
  "railsapp-staging-web":
    # a task can have its own container definitions
    # generic definitions for this container are taken from the YAML reference
    container_definitions:
      - <<: *railsapp
        cpu: 2
        # you must give a name to this container definition
        name: "railsapp-web"
        command:
          - "bundle exec puma -C config/puma.rb"
        port_mappings:
          - container_port: 3000
            # use dynamic host port mapping in order to allow for multiple tasks on the same container instance
            host_port: 0
            protocol: "tcp"

# one_off_commands describes just a list of commands that should be issued before updating services to a newer task version
# the service update will not be performed if one of these commands fail
# each one off command must be based on a task definition above. Make sure to create or use a task definition with sufficient cpu, ram setting.
one_off_commands:
  - command: "bundle exec rake db:migrate"
    task_family: "railsapp-staging-web"
  - command: "bundle exec rake assets:sync"
    task_family: "railsapp-staging-web"

# services describes all services on your ECS cluster
# A service makes sure your task is run across a cluster with the specified number.
# Also it does a parameterized deployment specified by deployment_configuration.
services:
  # specify a unique name for your service (must be uniq across your ECS cluster)
  - name: "railsapp-staging-web"
    # use a task definition to execute
    task_family: "wdn-staging-web"
    # the desired number of tasks to schedule across the cluster
    desired_count: 2
    # describe the deployment process
    deployment_configuration:
      # the maximum number of tasks in percent that are allowed to run within your cluster
      maximum_percent: 200
      # the minimum number of tasks that should be kept running during a deployment
      minimum_healthy_percent: 50
```

Executing a deployment:

```
ecs-deploy --cluster my-ecs-cluster
```

## ecs-console

Launch an interative session on a new container using the first available EC2-container instance registered to your cluster.
The image you are using to start the command must be pullable by that EC2-container instance, (e.g. hosted on your private ECR registry, or publicly on docker hub).

Uses the ecs-deploy configuration (default `config/ecs_deploy.yml`).

```
ecs-console --container-name your_container_definition \
  --private-key ~/.ssh/amazon-ec2.pem \
  --image 0123456789.dkr.ecr.us-east-1.amazonaws.com/my-repository:mytag \
  --cluster my-ecs-cluster \
  'bundle exec rails c'
```

