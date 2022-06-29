delete_files <- function() {
  unlink("packages", recursive = TRUE)
}

unpack_pkg_tar <- function(path) {

  if(file.exists(path)) {
    local_path <- path
  } else {
    info("Downloading tarball", path, "...")
    local_path <- basename(path)
    options(timeout = 30)
    tryCatch(download.file(path, local_path, quiet = TRUE),
             error = function(e) simpleError('archive not found'))
  }

  info("Unpacking tarball ...")
  untar(local_path)
  pkg_folder <- list.dirs(recursive = FALSE)
  return(pkg_folder)
}

info <- function(...) {
  cat("[INFO]", ..., "\n", sep = " ")
}