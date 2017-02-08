#' Handles package version
#'
#' @export
process_package <- function(pkg_url, name, repoType) {

  delete_files()
  pkg_folder <- download_and_unpack(pkg_url, name)
  parse_package(pkg_folder, name, repoType)
  postDescriptionJob(to_queue, name)
  postTopicsJob(to_queue, name)

  # syncS3(name)
}
