library(RPackageParser)
library(purrr)
library(magrittr)
library(jsonlite)
p <- list(path = "https://s3.amazonaws.com/assets.rdocumentation.org/rpackages/archived/base/base_3.3.1.tar.gz",
          name = "base",
          repoType = "part_of_r")
res <- process_package(p$path, p$name, p$repoType)
topics <- res$topics %>% purrr::map(jsonlite::fromJSON, simplifyDataFrame = FALSE)
