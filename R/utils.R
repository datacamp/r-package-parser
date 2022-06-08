delete_files <- function() {
  message("Cleaning up ...")
  unlink("packages", recursive = TRUE)
}

download_and_unpack <- function(pkg_url, pkg_name) {
  message("Downloading and unpacking tarball ...")


  tmp_dir <- tempfile(pattern = "package_")
  dir.create(tmp_dir)
  tar_path <- file.path(tmp_dir, paste0(pkg_name, ".tar.gz"))
  options(timeout = 30)
  tryCatch(download.file(pkg_url, tar_path),
           error = function(e) simpleError('archive not found'))

  untar_dir <- file.path(tmp_dir, pkg_name)
  untar(tar_path, exdir = untar_dir)
  # file.remove(tar_path)

  pkg_folder <- list.dirs(untar_dir, recursive = FALSE)

  return(pkg_folder)
}
