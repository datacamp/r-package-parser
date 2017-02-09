library(RPackageParser)
p <- list(path = "ftp://cran.r-project.org/pub/R/src/contrib/00Archive/tutorial/tutorial_0.4.0.tar.gz",
          name = "tutorial",
          repoType = "cran")
process_package(p$path, p$name, p$repoType)
