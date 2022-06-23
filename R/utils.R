delete_files <- function() {
  message("Cleaning up ...")
  unlink("packages", recursive = TRUE)
}

unpack_pkg_tar <- function(path) {

  if(file.exists(path)) {
    local_path <- path
  } else {
    message("Downloading tarball ", path, " ...")
    local_path <- basename(path)
    options(timeout = 30)
    tryCatch(download.file(path, local_path, quiet = TRUE),
             error = function(e) simpleError('archive not found'))
  }

  message("Unpacking tarball ...")
  untar(local_path)
  pkg_folder <- list.dirs(recursive = FALSE)
  return(pkg_folder)
}
