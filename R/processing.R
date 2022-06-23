#' Process a package:
#' @export
process_package <- function(pkg_url, pkg_name, repo_type) {
  message(sprintf("Processing package at %s ...", pkg_url))

  withr::with_tempdir(
    pattern = pkg_name,
    {
      pkg_folder <- unpack_pkg_tar(pkg_url)
      description <- parse_description(pkg_folder, pkg_url, repo_type)
      topics <- parse_topics(pkg_folder, description)
    }
  )

  return(list(description = description,
              topics = topics))
}

#' @importFrom jsonlite toJSON
#' @importFrom purrr map
#' @export
parse_description <- function(pkg_folder = ".", pkg_url, repo_type) {
  rename_lowercase_rd_files(pkg_folder)
  message("Parsing DESCRIPTION file ...")
  description <- get_description(pkg_folder)
  description$repoType <- repo_type
  description$tarballUrl <- pkg_url

  if(!is.null(description$`Authors@R`)) {
    authors <- as.person(eval(parse(text=description$`Authors@R`)))
    tryCatch({
      description$jsonAuthors <- authors %>% map(formatAuthor)
    }, error = function(e) {
      description$Author <- authors
    })
  }
  # Add readme, if any
  readme_path <- file.path(pkg_folder, "README.md")
  if (file.exists(readme_path)) {
    description$readme <- paste(readLines(readme_path, encoding="UTF-8", warn = FALSE), collapse = "\n")
  } else {
    description$readme <- ""
  }

  return(description)
}

#' @importFrom magrittr %>%
#' @importFrom jsonlite toJSON
#' @importFrom purrr transpose map
#' @export
parse_topics <- function(pkg_folder, description) {
  message("Parsing topics ...")
  withr::with_dir(pkg_folder, {

    pkg <- pkgdown:::as_pkgdown()
    topics <- purrr::transpose(pkg$topics)

    # TODO turn into sapply again after debugging is over
    processed_topics <- list()
    for(i in 1:length(topics)) {
      message("Compiling topic ", i, "/", length(topics), " ...")
      topic <- topics[[1]]
      topic_data <- pkgdown:::data_reference_topic(topics[[i]], pkg, examples_env = NULL)
      processed_topics[[i]] <- add_pkg_info(topic_data, description)
    }
  })
  processed_topics
}

get_description <- function(pkg_folder) {
  desc_path <- file.path(pkg_folder, "DESCRIPTION")
  as.list(read.dcf(desc_path)[1, ])
}

rename_lowercase_rd_files <- function(pkg_folder){
  lowercase_files = dir(pkg_folder, pattern = "\\.rd$", full.names = TRUE, recursive = TRUE)
  sapply(lowercase_files,FUN=function(path){
    file.rename(from=path,to=sub(pattern=".rd",replacement=".Rd",path))
  })
}

add_pkg_info <- function(topic_data, description) {
  topic_data$package <- list(package = description$Package, version = description$Version)
  return(topic_data)
}
formatAuthor <- function(author) {
  return(list(name = paste(author$given, author$family),
              email = if (is.null(author$email)) NA else author$email,
              maintainer = ("cre" %in% author$role)))
}

