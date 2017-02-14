FROM dockerhub.datacamp.com:443/r-base-prod:18

RUN apt-get update && apt-get install -y python-pip \
  && pip install awscli \
  && R -e 'devtools::install_github("filipsch/pkgdown")' \
  && R -e 'devtools::install_github("datacamp/r-package-parser")'

RUN mkdir packages
VOLUME /ecs-worker/packages

RUN mkdir jsons
VOLUME /ecs-worker/jsons

CMD ["R", "-e", "RPackageParser::main()"]
