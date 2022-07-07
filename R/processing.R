#' Process a package:
#' @export
process_package <- function(pkg_url, pkg_name, repo_type) {
  info(sprintf("Processing package at %s ...", pkg_url))

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
  info("Parsing DESCRIPTION file ...")
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
  info("Parsing topics ...")
  withr::with_dir(pkg_folder, {

    pkg <- pkgdown:::as_pkgdown()
    topics <- purrr::transpose(pkg$topics)

    # TODO turn into sapply again after debugging is over
    processed_topics <- list()
    for(i in 1:length(topics)) {
      info("Compiling topic", i, "/", length(topics), "...")
      topic <- topics[[1]]
      topic_data <- pkgdown:::data_reference_topic(topics[[i]], pkg, examples_env = NULL)
      topic_data_clean <- clean_up(topic_data)
      processed_topics[[i]] <- add_pkg_info(topic_data_clean, description)
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

clean_up <- function(data) {
  # pkgdown puts things in sections that rdocs doesn't want in sections.
  pull_out <- data.frame(pkgdown = c("Details", "References", "Source", "See also", "Value", "Note"),
                         rdocs = c("details", "references", "source", "seealso", "value", "note"),
                         stringsAsFactors = FALSE)

  cleaned_up_sections <- list()
  for(section in data$sections) {
    if(section$title %in% pull_out$pkgdown) {
      # pull it out
      keyname <- pull_out[section$title == pull_out$pkgdown, "rdocs"]
      data[[keyname]] <- section$contents
    } else {
      cleaned_up_sections <- c(cleaned_up_sections,
                               list(section[c('title', 'contents')]))
    }
  }
  data$sections <- cleaned_up_sections

  # unpack description
  data$description <- data$description$contents

  # unpack usage
  if (!is.null(data$usage) && !is.null(data$usage$contents)) {
    data$usage <- data$usage$contents
  }

  return(data)
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

