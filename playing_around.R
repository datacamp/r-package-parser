# Testing out
tm <- as.POSIXlt(Sys.time(), Sys.timezone(), "%Y-%m-%dT%H:%M:%S")
datetime <- format(tm , "%Y-%m-%dT%H:%M:%S%z")
res <- process_package("https://cran.r-project.org/src/contrib/Archive/R6/R6_2.5.0.tar.gz", "R6", "cran")
res$description$jobInfo <- list(package = "R6",
                                version = "2.5.0",
                                parsingStatus = "success",
                                parserVersion = 1,
                                parsedAt = datetime)
# x <- toJSON(res$description, auto_unbox = TRUE, pretty=TRUE)
# print(x)
y <- sapply(res$topics, toJSON, auto_unbox = TRUE)
writeLines(y, 'test.json')
