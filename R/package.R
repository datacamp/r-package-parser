readme <- function(sd_pkg) {

  # First look in staticdocs path
  path <- file.path(sd_pkg$sd_path, "README.md")
  if (file.exists(path)) {
    return(paste(readLines(path, encoding="UTF-8", warn = FALSE), collapse = "\n"));
  }

  # Then look in the package root
  path <- file.path(sd_pkg$path, "README.md")
  if (file.exists(path)) {
    return(paste(readLines(path, encoding="UTF-8", warn = FALSE), collapse = "\n"));
  }

  return("");
}

parse_topic_and_write <- function(rd, topic, pkg, path, package_path) {
  message(sprintf("Parsing %s ...", topic))
  html <- staticdocs:::to_html.Rd_doc(rd,
                                      env = new.env(parent = globalenv()),
                                      topic = topic,
                                      pkg = pkg)

  html$package <- pkg[c("package", "version")]

  out <- toJSON(html, auto_unbox= TRUE, pretty=TRUE)
  graphics.off()

  cat(out, file = path)
}

parse_package <- function(package_name, repoType) {
  message("Parsing package...")
  wd = getwd()
  package_path <- file.path("packages", package_name)

  p <- devtools::as.package(package_path)

  out_dir <- file.path("jsons", package_name, "man")
  dir.create(out_dir, recursive= TRUE)

  pkg <- as.sd_package(package_path, site_path=out_dir)

  index <- pkg$rd_index
  index$file_out <- str_replace(index$file_out, "\\.html$", ".json")
  paths <- file.path(pkg$site_path, index$file_out)

  for (i in seq_along(index$name)) {
    message("Generating ", basename(paths[[i]]))

    rd <- pkg$rd[[i]]
    topic = pkg$rd_index$name[i]
    path = paste("../../", paths[[i]], sep = "")
    setwd(package_path)
    try(parse_topic_and_write(rd, topic, pkg, path, package_path))
    setwd(wd)
  }

  readme <- readme(pkg)

  desc_path = paste(package_path, "DESCRIPTION", sep="/")
  out_path = paste("jsons", package_name,"DESCRIPTION.json", sep="/")

  description <- as.list(read.dcf(desc_path)[1, ])
  description$readme <- readme;
  description$repoType <- repoType;

  desc_json = toJSON(description, pretty= TRUE, auto_unbox= TRUE)

  cat(desc_json, file = out_path)
}
