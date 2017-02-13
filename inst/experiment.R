library(RPackageParser)
library(purrr)
library(magrittr)
library(jsonlite)
p <- list(path = "ftp://cran.r-project.org/pub/R/src/contrib/sequoia_0.7.2.tar.gz",
          name = "sequoia",
          repoType = "cran")
res <- process_package(p$path, p$name, p$repoType)
topics <- res$topics %>% purrr::map(jsonlite::fromJSON, simplifyDataFrame = FALSE)
