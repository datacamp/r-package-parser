context("process_package")

test_that("works for cran package", {
  res <- process_package("https://cran.r-project.org/src/contrib/Archive/R6/R6_2.5.0.tar.gz", "R6", "cran")
  # desc <- jsonlite::fromJSON(res$description, simplifyDataFrame = FALSE)
  desc <- res$description
  expect_equal(desc$Package, "R6")
  expect_equal(desc$Version, "2.5.0")
  expect_true(grepl("R6 classes", desc$readme, fixed = TRUE))
  expect_equal(desc$repoType, "cran")
  # topics <- purrr:::map(res$topics, jsonlite::fromJSON, simplifyDataFrame = FALSE)
  # expect_equal(length(topics), 2)
  # expect_equal(topics[[1]]$name, "as.list.R6")
  # expect_equal(topics[[2]]$name, "R6Class")
  # expect_equal(topics[[1]]$title, "Create a list from an R6 object")
  # expect_equal(topics[[2]]$title, "Create an R6 reference object generator")
  # expect_equal(length(topics[[2]]$sections), 4)
})

test_that("works for bioconductor package", {
  res <-
    process_package(
      "https://bioconductor.org/packages/release/bioc/src/contrib/destiny_3.10.0.tar.gz",
      "destiny",
      "bioconductor"
    )
  # desc <- jsonlite::fromJSON(res$description, simplifyDataFrame = FALSE)
  desc <- res$description
  expect_equal(desc$Package, "destiny")
  expect_equal(desc$Version, "2.0.3")
  expect_equal(desc$readme, "")
  expect_equal(desc$repoType, "bioconductor")
  # topics <- purrr:::map(res$topics, jsonlite::fromJSON, simplifyDataFrame = FALSE)
  # expect_equal(length(topics), 27)
})

test_that("works for github package", {
  res <-
    process_package(
      "https://github.com/datacamp/testwhat/archive/v4.2.6.tar.gz",
      "testwhat",
      "github"
    )
  # desc <- jsonlite::fromJSON(res$description, simplifyDataFrame = FALSE)
  desc <- res$description
  expect_equal(desc$Package, "testwhat")
  expect_equal(desc$Version, "4.2.6")
  expect_true(grepl("Submission Correctness Tests", desc$readme, fixed = TRUE))
  expect_equal(desc$repoType, "github")
  # topics <- purrr:::map(res$topics, jsonlite::fromJSON, simplifyDataFrame = FALSE)
  # expect_equal(length(topics), 41)
})

test_that("works for baked-in R package", {
  res <-
    process_package(
      "https://s3.amazonaws.com/assets.rdocumentation.org/rpackages/archived/base/base_3.3.1.tar.gz",
      "base",
      "part_of_r"
    )
  # desc <- jsonlite::fromJSON(res$description, simplifyDataFrame = FALSE)
  desc <- res$description
  expect_equal(desc$Package, "base")
  expect_equal(desc$Version, "3.3.1")
  expect_equal(desc$readme, "")
  expect_equal(desc$repoType, "part_of_r")
  # topics <- purrr:::map(res$topics, jsonlite::fromJSON, simplifyDataFrame = FALSE)
  # expect_equal(length(topics), 427 + 2 + 1)
})
