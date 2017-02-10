delete_files <- function() {
  message("Cleaning up ...")
  unlink("packages", recursive = TRUE)
}

download_and_unpack <- function(pkg_url, pkg_name) {
  message("Downloading and unpacking tarball ...")

  tar_path <- paste0(pkg_name, ".tar.gz")
  options(timeout = 30)
  tryCatch(download.file(pkg_url, tar_path, quiet = TRUE),
           error = function(e) simpleError('not found'))

  untar(tar_path, exdir = "packages/")
  file.remove(tar_path)

  # possible that tar was not unpacked with package name
  pkg_folder <- file.path("packages", pkg_name)
  file.rename(list.dirs("packages", recursive = FALSE), pkg_folder)

  return(pkg_folder)
}
