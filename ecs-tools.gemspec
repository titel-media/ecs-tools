Gem::Specification.new do |s|
  s.name        = "ecs-tools"
  s.version     = "0.0.2"
  s.date        = "2016-12-15"
  s.summary     = "AWS ECS deployment"
  s.description = "Deploy your containerized application into Amazon Elastic Container Service"
  s.authors     = ["Lukas Rieder"]
  s.email       = "l.rieder@gmail.com"
  s.files       = %w[
    lib/ecs_deploy.rb
    bin/ecs-deploy
    bin/ecs-console
  ]
  s.bindir      = "bin"
  s.executables << "ecs-deploy"
  s.executables << "ecs-console"
  s.executables << "ecr-build"
  s.homepage    = "https://github.com/Overbryd/ecs-tools"
  s.license     = "MIT"

  s.add_runtime_dependency "aws-sdk", "~> 2"
  s.add_runtime_dependency "net-ssh", "~> 3.2"
  s.add_runtime_dependency "net-scp", "~> 1.2"
end

