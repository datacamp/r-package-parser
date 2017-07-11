#' Process a package:
#' @export
process_package <- function(pkg_url, pkg_name, repo_type) {
  message(sprintf("Processing package at %s ...", pkg_url))
  pkg_folder <- download_and_unpack(pkg_url, pkg_name)
  rename_lowercase_rd_files(pkg_folder)

  description <- parse_description(pkg_folder, pkg_url, repo_type)
  definedTopic <- findTopicDefinitions(pkg_folder)
  topics <- parse_topics(pkg_folder)
  return(list(description = description,
              topics = topics))
}

rename_lowercase_rd_files <- function(pkg_folder){
  lowercase_files = dir(pkg_folder, pattern = "\\.rd$", full.names = TRUE, recursive = TRUE)
  sapply(lowercase_files,FUN=function(path){
      file.rename(from=path,to=sub(pattern=".rd",replacement=".Rd",path))
  })
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

#' @export
findTopicDefinitions <- function(pkg_folder) {
  message("Parsing topic definitions ...")
  files = dir(file.path(pkg_folder, "R"), pattern = "\\.(r|R)$", full.names = TRUE, recursive = TRUE)
  sapply(files, getDeclaredFunctionsInFile)
}

findDefinitionsOfTopic <- function(topicDefinitions, topic_name){
  y <- topicDefinitions[sapply(topicDefinitions, FUN=function(item){
    topic_name %in% names(item)
  })];
  lapply(y, FUN=function(item){
    item[[topic_name]]
  });
}

#' Based on NCmisc::Rfile.indexr
getDeclaredFunctionsInFile <- function(fn)
{
  grp <- function(what,ins) { grep(what,ins,fixed=T) }
  if(file.exists(fn))  {
    fl <- readLines(fn)
    fn.lines <- unique(c(grp("<- function",fl),grp("<-function",fl)))


    #fl <- rmv.spc(fl)
    nfn <- length(fn.lines)
    fn.list <- vector("list",nfn)
    if(nfn<1) { warning(sprintf("no functions found in R %s", fn)); return(NULL) }
    for (kk in 1:nfn) {
      first.ln <- fl[fn.lines[kk]]
      n <- 1; while(substr(first.ln,n,n)!="<" & substr(first.ln,n,n)!=" ") { n <- n+1 }
      fn.nm <- substr(first.ln,1,n-1);
      name <- paste("",fn.nm,"",sep="");

      if(! startsWith(name, "#")){
        if(! fn.nm %in% names(fn.list)){
          names(fn.list)[kk] <- name; descr <- c()
          fn.list[[kk]] <- c(fn.lines[kk])
        }
        else{
          # Add line number to existing function
          fn.list[[name]] <- c(fn.list[[name]], fn.lines[kk])
        }
      }
    }

    # remove extra's
    fn.list <- fn.list[!sapply(fn.list, is.null)]
  } else {
    warning("could not find function file to index")
    return(NULL)
  }
  return(fn.list)
}