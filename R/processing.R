#' Process a package:
#' @export
process_package <- function(pkg_url, pkg_name, repo_type) {
  message(sprintf("Processing package at %s ...", pkg_url))
  pkg_folder <- download_and_unpack(pkg_url, pkg_name)
  description_json <- parse_description(pkg_folder, repo_type)
  topics_json <- parse_topics(pkg_folder)
  delete_files()
  return(list(description = description_json,
              topics = topics_json))
}

get_description <- function(pkg_folder) {
  desc_path <- file.path(pkg_folder, "DESCRIPTION")
  as.list(read.dcf(desc_path)[1, ])
}

#' @importFrom jsonlite toJSON
parse_description <- function(pkg_folder, repo_type) {
  message("Parsing DESCRIPTION file ...")
  description <- get_description(pkg_folder)
  description$repoType <- repo_type

  # Add readme, if any
  readme_path <- file.path(pkg_folder, "README.md")
  if (file.exists(readme_path)) {
    description$readme <- paste(readLines(readme_path, encoding="UTF-8", warn = FALSE), collapse = "\n")
  } else {
    description$readme <- ""
  }

  return(toJSON(description, auto_unbox = TRUE))
}

#' @importFrom magrittr %>%
#' @importFrom jsonlite toJSON
#' @importFrom purrr transpose map
parse_topics <- function(pkg_folder) {
  message("Parsing topics ...")
  pkg <- pkgdown:::as_pkgdown(pkg_folder)
  pkg$topics %>%
    transpose() %>%
    map(pkgdown:::data_reference_topic, pkg) %>%
    map(clean_up) %>%
    map(add_pkg_info, pkg_folder) %>%
    toJSON()
}

clean_up <- function(data) {
  # pkgdown puts things in sections that rdocs doesn't want in sections.
  pull_out <- data.frame(pkgdown = c("Details", "References", "Source", "Format", "See also", "Value"),
                         rdocs = c("details", "references", "source", "format", "seealso", "value"),
                         stringsAsFactors = FALSE)

  cleaned_up_sections <- list()
  for(section in data$sections) {
    if(section$title %in% pull_out$pkgdown) {
      # pull it out
      keyname <- pull_out[section$title == pull_out$pkgdown, "rdocs"]
      data[[keyname]] <- section$contents
    } else {
      # clean it up - formatted 'name' and 'description'
      cleaned_up_sections <- c(cleaned_up_sections,
                               list(list(name = section$title, description = section$contents)))
    }
  }
  data$sections <- cleaned_up_sections

  # aliases should be called alias
  names(data)[names(data) == "aliases"] <- "alias"

  # unpack description
  data$description <- data$description$contents

  return(data)
}

add_pkg_info <- function(topic_data, pkg_folder) {
  description <- get_description(pkg_folder)
  topic_data$package <- list(package = description$Package, version = description$Version)
  return(topic_data)
}
