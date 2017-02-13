#' Main entry point of the package
#'
#' @export
#' @importFrom aws.sqs create_queue receive_msg delete_msg
#' @importFrom jsonlite fromJSON toJSON prettify
main <- function() {

  Sys.setenv(AWS_ACCESS_KEY_ID = "AKIAJVTIJ7AIE5TMHOBQ",
             AWS_SECRET_ACCESS_KEY = "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",
             AWS_DEFAULT_REGION = "us-west-1")

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
        message <- as.list(messages[i, ])
        body <- fromJSON(message$Body)
        repo_type <- body$repoType
        if (is.null(repo_type)) {
          repo_type <- 'cran'
        }

        result <- tryCatch({
          res <- process_package(body$path, body$name, repo_type)
          post_job(to_queue, res$description, "version")
          post_job(to_queue, unlist(res$topics), "topic")
          # dump_jsons_on_s3(topics_json, description_json)
        },
        error = function(e) {
          error_json <- toJSON(list(error = e$message,
                                    package = body$name,
                                    version = body$version))
          cat(prettify(error_json))
          post_job(error_queue, error_json, "error")
        }, finally = {
          message("Deleting job from SQS ...")
          delete_msg(from_queue, message$ReceiptHandle)
          message("Garbage collection ...")
          gc()
        })
      }
    }
  }
}

