FROM dockerhub.datacamp.com:443/r-base-prod:18
# r-base-prod already contains python and awscli

# clean up credentials - install libxml2-dev and pandoc
RUN rm -rf /home/repl/.aws \
  && apt-get update && apt-get install -y libxml2-dev \
  && wget https://github.com/jgm/pandoc/releases/download/1.19.1/pandoc-1.19.1-1-amd64.deb && dpkg -i pandoc-1.19.1-1-amd64.deb

RUN R -e 'devtools::install_github("filipsch/pkgdown", ref = "v0.0.1")' \
  && R -e 'devtools::install_github("datacamp/r-package-parser", ref = "v0.0.1")'

CMD ["R", "-e", "RPackageParser::main()"]
