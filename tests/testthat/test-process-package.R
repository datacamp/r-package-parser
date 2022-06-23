context("process_package")

test_that("works for cran package", {
  tar_url <- "https://cran.r-project.org/src/contrib/Archive/R6/R6_2.5.0.tar.gz"
  res <- process_package(tar_url, "R6", "cran")
  desc <- res$description
  expect_equal(desc$Package, "R6")
  expect_equal(desc$Version, "2.5.0")
  expect_true(grepl("R6 classes", desc$readme, fixed = TRUE))
  expect_equal(desc$repoType, "cran")

  topics <- res$topics
  expect_equal(length(topics), 3)
  expect_equal(topics[[1]]$name, "R6Class")
  expect_equal(topics[[2]]$name, "as.list.R6")
  expect_equal(topics[[1]]$title, "Create an R6 reference object generator")
  expect_equal(topics[[2]]$title, "Create a list from an R6 object")
  expect_equal(length(topics[[1]]$sections), 6)
})

test_that("works for bioconductor package", {
  tar_url <- "https://bioconductor.org/packages/release/bioc/src/contrib/destiny_3.10.0.tar.gz"
  res <- process_package(tar_url, "destiny", "bioconductor")
  desc <- res$description
  expect_equal(desc$Package, "destiny")
  expect_equal(desc$Version, "3.10.0")
  expect_equal(desc$readme, "")
  expect_equal(desc$repoType, "bioconductor")

  expect_equal(length(res$topics), 31)
})

test_that("works for github package", {
  tar_url <- "https://github.com/r-lib/pkgdown/archive/refs/tags/v2.0.4.tar.gz"
  res <- process_package(tar_url, "pkgdown", "github")
  desc <- res$description
  expect_equal(desc$Package, "pkgdown")
  expect_equal(desc$Version, "2.0.4")
  expect_true(grepl(
    "pkgdown is designed to make it quick and easy",
    desc$readme,
    fixed = TRUE
  ))
  expect_equal(desc$repoType, "github")
  expect_equal(length(res$topics), 36)
})

test_that("works for baked-in R package", {
  res <-
    process_package(
      "https://s3.amazonaws.com/assets.rdocumentation.org/rpackages/archived/base/base_3.3.1.tar.gz",
      "base",
      "part_of_r"
    )
  desc <- res$description
  expect_equal(desc$Package, "base")
  expect_equal(desc$Version, "3.3.1")
  expect_equal(desc$readme, "")
  expect_equal(desc$repoType, "part_of_r")
  expect_equal(length(res$topics), 427)
})
