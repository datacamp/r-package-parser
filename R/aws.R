#' @importFrom jsonlite write_json
dump_jsons_on_s3 <- function(description, topics) {
  pkg_name <- description$Package
  pkg_version <- description$Version
  local <- file.path(getwd(), pkg_name, pkg_version)
  remote <- file.path("s3://assets.rdocumentation.org/rpackages/unarchived", pkg_name, pkg_version)

  dir.create(local, recursive = TRUE)

  # copy everything from man/figures to local/figures
  pkg_folder <- file.path("packages", pkg_name)
  figures_path <- file.path(pkg_folder, "man", "figures")
  copy_local(local, figures_path, "figures")

  # copy everything from _vignettes to local/vignettes
  vignettes_path <- file.path(pkg_folder, "_vignettes")
  copy_local(local, vignettes_path, "vignettes")

  # copy everything from R to local/R
  r_path <- file.path(pkg_folder, "R")
  copy_local(local, r_path, "R")

  # write files to disk
  write_json(description, auto_unbox = TRUE, path = file.path(local, "DESCRIPTION.json"))
  lapply(topics, function(x) write_json(x, auto_unbox = TRUE, path = file.path(local, paste0(x$name, ".json"))))
  # do the sync
  system(sprintf("aws --region us-east-1 s3 sync %s %s", local, remote))
  # clean up again
  unlink(file.path(getwd(), pkg_name), recursive = TRUE)
}

copy_local <- function(local, path, dirname){
  if (file.exists(path) && !is.null(path)) {
    out_path <- file.path(local, dirname)
    dir.create(out_path)
    pkgdown:::copy_dir(path, out_path)
  }
}

send_msg_wrap <- function(queue, msg, type) {
  info(paste(sprintf("Sending %s message to %s", type, queue), prettify(msg), sep="\n"))

  send_msg(queue = queue,
           msg = msg,
           query = list(MessageAttribute.1.Name = "type",
                        MessageAttribute.1.Value.DataType ="String",
                        MessageAttribute.1.Value.StringValue = type))
}

