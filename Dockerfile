FROM rocker/hadleyverse:latest

RUN apt-get update && apt-get install -y python-pip groff-base libmagick++-dev \
  && pip install awscli \
  && R -e 'devtools::install_github("datacamp/r-package-parser")'

RUN mkdir packages
VOLUME /ecs-worker/packages

RUN mkdir jsons
VOLUME /ecs-worker/jsons

CMD ["R", "-e", "RPackageParser::main()"]
