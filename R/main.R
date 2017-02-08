# to_queue <- "RdocWorkerQueue";
# queue <- create_queue(to_queue);
# from_queue <- "RdocRWorkerQueue";
# queue <- create_queue(from_queue);
#
# pruneNotRdFiles <- function(package_name) {
#   system(paste("./scripts/flatten_prune.sh ", package_name));
# }
#
# handle_package_version <- function(name, path, repoType) {
#
#   delete_files();
#   print("Downloading tarball...");
#   package_file_name <- paste(name, ".tar.gz", sep="");
#   package_path <- paste("packages/", package_file_name, sep="");
#   download(package_path, path);
#
#   print("Untar tarball...");
#   untar(package_path, exdir = "packages/");
#   dir_name <- list.dirs("packages", recursive = FALSE);
#   file.rename(dir_name, paste("packages", name, sep = "/"));
#
#
#   pruneNotRdFiles(name);
#
#   print("Parsing package...");
#   process_package(name, repoType);
#
#   print("Posting SQS jobs...");
#   postDescriptionJob(to_queue, name);
#
#   postTopicsJob(to_queue, name);
#
#   print("Syncing S3 and clean...");
#   syncS3(name);
#
# }
#
# main <- function() {
#
#   while(1) {
#     print("Polling for messages...");
#     messages <- getMessages(from_queue);
#     if(nrow(messages) > 0) {
#
#       for (i in 1:nrow(messages)) {
#         message <- as.list(messages[i, ])
#
#         body <- fromJSON(message$Body)
#
#         repoType <- body$repoType
#
#         if (is.null(repoType)) {
#           repoType <- 'cran'
#         }
#
#         result <- tryCatch({
#           handle_package_version(body$name, body$path, repoType)
#         },
#         error = function(e) {
#           error_body <- toString(list(error=e, package=body$name, version=body$version));
#           error_queue <- "RdocRWorkerDeadQueue";
#           error_q <- create_queue(error_queue);
#           print("Posting error to dead letter queue");
#           send_msg(error_queue, error_body);
#
#         }, finally = {
#           print("Cleaning files...");
#           delete_files();
#
#           print("Deleting job from SQS");
#           delete_msg(from_queue, message$ReceiptHandle);
#           print("Garbage collection");
#           gc();
#         }
#         );
#
#         if(inherits(result, "error")) next #continue
#       }
#     }
#
#   }
#
#
# }
# }
#


#p <- fromJSON("{ \"path\": \"https://s3.amazonaws.com/assets.rdocumentation.org/rpackages/archived/base/base_3.3.1.tar.gz\", \"name\": \"base\", \"version\": \"3.3.1\", \"repoType\": \"part_of_r\"  }")
#handle_package_version(p$name, p$path, p$repoType);
# main()

#' The main function
#' @export
main <- function() {
  print("THIS IS WORKING!!")
}