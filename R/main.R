#' Main entry point of the package
#'
#' @export
#' @importFrom aws.sqs create_queue receive_msg delete_msg
#' @importFrom jsonlite fromJSON toJSON prettify
main <- function() {

  if(file.exists(".env.R")) {
    source(".env.R")
  }

  # names for the queues
  from_queue <- "RdocRWorkerQueue"
  to_queue <- "RdocWorkerQueue"
  error_queue <- "RdocRWorkerDeadQueue"

  # initialize the queues
  create_queue(from_queue)
  create_queue(to_queue)
  create_queue(error_queue)

  while(1) {
    message("Polling for messages...")
    messages <- receive_msg(from_queue, wait = 20)
    if(nrow(messages) > 0) {

      for (i in 1:nrow(messages)) {
        delete_files()
        message <- as.list(messages[i, ])
        body <- fromJSON(message$Body)
        repo_type <- body$repoType
        if (is.null(repo_type)) {
          repo_type <- 'cran'
        }

        result <- tryCatch({
          res <- process_package(body$path, body$name, repo_type)
          dump_jsons_on_s3(res$description, res$topics)
          post_job(to_queue, toJSON(res$description, auto_unbox = TRUE), "version")
          post_job(to_queue, sapply(res$topics, toJSON, auto_unbox = TRUE), "topic")
        },
        error = function(e) {
          error_json <- toJSON(list(error = e$message,
                                    package = body$name,
                                    version = body$version))
          cat(prettify(error_json))
          post_job(error_queue, error_json, "error")
        }, finally = {
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

