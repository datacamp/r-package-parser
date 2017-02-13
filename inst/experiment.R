library(RPackageParser)
library(purrr)
library(magrittr)
library(jsonlite)
p <- list(path = "https://cran.r-project.org/src/contrib/openintro_1.4.tar.gz",
          name = "openintro",
          repoType = "cran")
res <- process_package(p$path, p$name, p$repoType)
topics <- res$topics %>% purrr::map(jsonlite::fromJSON, simplifyDataFrame = FALSE)
