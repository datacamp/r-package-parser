# pruneNotRdFiles <- function(pkg) {
#   system(sprintf("find packages/%s/man -mindepth 2 -type f -exec mv -t packages/%s/man -i '{}' +", pkg, pkg))
#   system(sprintf("rm -R -- packages/%s/man/*/", pkg))
# }

delete_files <- function() {
  message("Cleaning up ...")
  system("shopt -s dotglob && rm -rf packages/* && rm -rf jsons/*")
}

download_and_unpack <- function(pkg_url, pkg_name) {
  message("Downloading tarball and unpack...")

  tar_path <- paste0(pkg_name, ".tar.gz")
  options(timeout = 30)
  tryCatch(download.file(pkg_url, tar_path),
           error = function(e) simpleError('not found'))

  untar(tar_path, exdir = "packages/")
  file.remove(tar_path)

  # possible that tar was not unpacked with package name
  pkg_folder <- file.path("packages", pkg_name)
  file.rename(list.dirs("packages", recursive = FALSE), pkg_folder)

  # # Remove any RD files that are not man files
  # pruneNotRdFiles(pkg_name)

  return(pkg_folder)
}
