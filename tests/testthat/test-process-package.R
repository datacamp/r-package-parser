context("process_package")

test_that("works for cran package", {
  p <- list(path = "https://cran.r-project.org/src/contrib/Archive/R6/R6_2.1.3.tar.gz",
            name = "R6",
            repoType = "cran")
  res <- process_package(p$path, p$name, p$repoType)
  desc <- jsonlite::fromJSON(res$description, simplifyDataFrame = FALSE)
  expect_equal(desc$Package, "R6")
  expect_equal(desc$Version, "2.1.3")
  expect_true(grepl("R6 classes", desc$readme, fixed = TRUE))
  expect_equal(desc$repoType, "cran")
  topics <- purrr:::map(res$topics, jsonlite::fromJSON, simplifyDataFrame = FALSE)
  expect_equal(length(topics), 2)
  expect_equal(topics[[1]]$name, "as.list.R6")
  expect_equal(topics[[2]]$name, "R6Class")
  expect_equal(topics[[1]]$title, "Create a list from an R6 object")
  expect_equal(topics[[2]]$title, "Create an R6 reference object generator")
  expect_equal(length(topics[[2]]$sections), 4)
})

test_that("works for bioconductor package", {
  p <- list(path = "http://bioconductor.org/packages/release/bioc/src/contrib/destiny_2.0.3.tar.gz",
            name = "destiny",
            repoType = "bioconductor")
  res <- process_package(p$path, p$name, p$repoType)
  # TODO
})

test_that("works for github package", {
  p <- list(path = "https://github.com/datacamp/testwhat/archive/v4.2.6.tar.gz",
            name = "testwhat",
            repoType = "github")
  res <- process_package(p$path, p$name, p$repoType)
  # TODO
})

test_that("works for baked-in R package", {
  p <- list(path = "https://s3.amazonaws.com/assets.rdocumentation.org/rpackages/archived/base/base_3.3.1.tar.gz",
            name = "base",
            repoType = "part_of_r")
  res <- process_package(p$path, p$name, p$repoType)
  # TODO
})
