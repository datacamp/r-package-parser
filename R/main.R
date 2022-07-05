#' Main entry point of the package
#'
#' @export
#' @importFrom jsonlite fromJSON toJSON prettify
main <- function() {
  parser_version <- 2

  if(file.exists(".env.R")) {
    source(".env.R")
  }

  # names for the queues
  from_queue <- Sys.getenv("SOURCE_QUEUE")
  to_queue <- Sys.getenv("DEST_QUEUE") # rdoc-app-worker
  error_queue <- Sys.getenv("DEADLETTER_QUEUE") # rdoc-r-worker-deadletter

  # # initialize the queues
  # create_queue(from_queue)
  # create_queue(to_queue)
  # create_queue(error_queue)

  while(1) {
    info("Polling for messages on", from_queue, "...")
    messages <- receive_msg(from_queue, wait = 20)
    print(messages)
    if(nrow(messages) > 0) {

      for (i in 1:nrow(messages)) {
        delete_files()
        message <- as.list(messages[i, ])
        info(paste("Received message:", prettify(message$Body), sep="\n"))
        body <- fromJSON(message$Body)
        repo_type <- body$repoType
        if (is.null(repo_type)) {
          repo_type <- 'cran'
        }

        tm <- as.POSIXlt(Sys.time(), Sys.timezone(), "%Y-%m-%dT%H:%M:%S")
        datetime <- format(tm , "%Y-%m-%dT%H:%M:%S%z")
        result <- tryCatch({
          res <- process_package(body$path, body$name, repo_type)
          res$description$jobInfo <- list(package = body$name,
                                          version = body$version,
                                          parsingStatus = "success",
                                          parserVersion = parser_version,
                                          parsedAt = datetime)
          info("Putting description and topics on S3 ...")
          dump_jsons_on_s3(res$description, res$topics)
          post_job(to_queue, toJSON(res$description, auto_unbox = TRUE), "version")
          post_job(to_queue, sapply(res$topics, toJSON, auto_unbox = TRUE), "topic")
        },
        error = function(e) {
          errorObject <- character(0)
          errorObject$jobInfo <-  list(message_body = body,
                                       error = e$message,
                                       parsingStatus = "failed",
                                       parserVersion = parser_version,
                                       parsedAt = datetime)

          error_json <- toJSON(errorObject, auto_unbox = TRUE)
          message(prettify(error_json))
          info("Putting job in deadletter queue ...")
          post_job(error_queue, error_json, "error")
        }, finally = {
          delete_files()
          info("Deleting job from SQS ...")
          delete_msg(from_queue, message$ReceiptHandle)
          info("Garbage collection ...")
          gc()
        })
      }
    }
  }
}

