#' Process a package:
#' @export
process_package <- function(pkg_url, pkg_name, repo_type) {
  message(sprintf("Processing package at %s ...", pkg_url))
  pkg_folder <- download_and_unpack(pkg_url, pkg_name)
  description <- parse_description(pkg_folder, pkg_url, repo_type)
  topics <- parse_topics(pkg_folder)
  return(list(description = description,
              topics = topics))
}

get_description <- function(pkg_folder) {
  desc_path <- file.path(pkg_folder, "DESCRIPTION")
  as.list(read.dcf(desc_path)[1, ])
}

#' @importFrom jsonlite toJSON
#' @importFrom purrr map
#' @export
parse_description <- function(pkg_folder, pkg_url, repo_type) {
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
parse_topics <- function(pkg_folder) {
  message("Parsing topics ...")
  file.rename(file.path(pkg_folder, "vignettes"), file.path(pkg_folder, "_vignettes"))
  pkg <- pkgdown:::as_pkgdown(pkg_folder)
  pkg$topics %>%
    transpose() %>%
    map(pkgdown:::data_reference_topic, pkg, examples = FALSE) %>%
    map(clean_up) %>%
    map(add_pkg_info, pkg_folder)
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

  return(data)
}

add_pkg_info <- function(topic_data, pkg_folder) {
  description <- get_description(pkg_folder)
  topic_data$package <- list(package = description$Package, version = description$Version)
  return(topic_data)
}
formatAuthor <- function(author) {
  return(list(name = paste(author$given, author$family),
              email = if (is.null(author$email)) NA else author$email,
              maintainer = ("cre" %in% author$role)))
}

