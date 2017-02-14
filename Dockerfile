FROM dockerhub.datacamp.com:443/r-base-prod:18
# r-base-prod already contains python and awscli

# clean up credentials; we need other ones
RUN rm -rf /home/repl/.aws
RUN R -e 'devtools::install_github("filipsch/pkgdown")' \
  && R -e 'devtools::install_github("datacamp/r-package-parser")'

CMD ["R", "-e", "RPackageParser::main()"]
