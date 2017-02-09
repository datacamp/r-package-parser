library(RPackageParser)
p <- list(path = "http://bioconductor.org/packages/release/bioc/src/contrib/destiny_2.0.3.tar.gz",
          name = "destiny",
          repoType = "bioconductor")
res <- process_package(p$path, p$name, p$repoType)