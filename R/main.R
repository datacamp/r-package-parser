#' Main entry point of the package
#'
#' @export
#' @importFrom aws.sqs create_queue
main <- function() {

  # Initialize the queues
  create_queue(to_queue)
  create_queue(from_queue)
  create_queue(error_queue)

  while(1) {
    message("Polling for messages...")
    messages <- getMessages(from_queue)
    if(nrow(messages) > 0) {

      for (i in 1:nrow(messages)) {
        message <- as.list(messages[i, ])
        body <- fromJSON(message$Body)

        repoType <- body$repoType

        if (is.null(repoType)) {
          repoType <- 'cran'
        }

        result <- tryCatch({
          process_package(body$path, body$name, repoType)
        },
        error = function(e) {
          error_body <- toString(list(error=e, package=body$name, version=body$version))
          message("Posting error to dead letter queue ...")
          send_msg(error_queue, error_body)
        }, finally = {
          message("Cleaning files ...")
          delete_files()

          message("Deleting job from SQS ...")
          delete_msg(from_queue, message$ReceiptHandle)
          message("Garbage collection ...")
          gc()
        })
      }
    }
  }
}

