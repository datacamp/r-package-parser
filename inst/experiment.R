library(RPackageParser)
library(purrr)
library(magrittr)
library(jsonlite)
p <- list(path = "ftp://cran.r-project.org/pub/R/src/contrib/sequoia_0.7.2.tar.gz",
          name = "s",
          repoType = "part_of_r")
res <- process_package(p$path, p$name, p$repoType)
topics <- res$topics %>% purrr::map(jsonlite::fromJSON, simplifyDataFrame = FALSE)


# library(aws.sqs)
# from_queue <- "RdocRWorkerQueue"
# create_queue(from_queue, attributes = )
# messages <- receive_msg(from_queue, wait = 20)
#
#
# body <- list(path = "ftp://cran.r-project.org/pub/R/src/contrib/sequoia_0.7.2.tar.gz",
#              name = "sequoia",
#              repoType = "cran")
# jsonlite::toJSON(body, auto_unbox = TRUE)
#
# body <- list(path = "<link_to_base>",
#              name = "base",
#              repoType = "part_of_r")
# jsonlite::toJSON(body, auto_unbox = TRUE)
