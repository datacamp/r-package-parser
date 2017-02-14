#' @importFrom jsonlite write_json
dump_jsons_on_s3 <- function(description, topics) {
  pkg_name <- description$Package
  pkg_version <- description$Version
  local <- file.path(getwd(), pkg_name, pkg_version)
  remote <- file.path("s3://assets.rdocumentation.org/rpackages/unarchived", pkg_name, pkg_version)
  # write files to disk
  dir.create(local, recursive = TRUE)
  write_json(description, auto_unbox = TRUE, path = file.path(local, "DESCRIPTION.json"))
  lapply(topics, function(x) write_json(x, auto_unbox = TRUE, path = file.path(local, paste0(x$name, ".json"))))
  # do the sync
  system(sprintf("aws s3 sync %s %s", local, remote))
  # clean up again
  unlink(file.path(getwd(), pkg_name), recursive = TRUE)
}

send_msg <- function(queue, msg, query = list(), attributes = NULL, delay = NULL, ...) {
  queue <- aws.sqs:::.urlFromName(queue)
  if(length(msg) > 1) {
    # batch mode
    batchs <- split(msg, ceiling(seq_along(msg)/10))

    for (batch in batchs) {
      l <- length(batch)
      n <- 1:l
      id <- paste0("msg", n)
      a <- as.list(c(id, batch))
      names(a) <- c(paste0("SendMessageBatchRequestEntry.",n,".Id"),
                    paste0("SendMessageBatchRequestEntry.",n,".MessageBody"))
      query_args <-  list(Action = "SendMessageBatch")
      query_mult <- rep(query, each = l)
      front <- c(paste0("SendMessageBatchRequestEntry.",n, "."))
      back <- rep(names(query), each = l)
      names(query_mult) <- paste0(front, back)

      body <- c(a, query_mult, query_args)

      out <- aws.sqs:::sqsHTTP(url = queue, query = body, ...)
      if (inherits(out, "aws-error") || inherits(out, "unknown")) {
        return(out)
      }
      structure(out$SendMessageBatchResponse$SendMessageBatchResult,
                RequestId = out$SendMessageBatchResponse$ResponseMetadata$RequestId)
    }

  } else {
    # single mode
    query_args <- append(query, list(Action = "SendMessage"))
    query_args$MessageBody = msg
    out <- aws.sqs:::sqsHTTP(url = queue, query = query_args, ...)
    if (inherits(out, "aws-error") || inherits(out, "unknown")) {
      return(out)
    }
    structure(list(out$SendMessageResponse$SendMessageResult),
              RequestId = out$SendMessageResponse$ResponseMetadata$RequestId)
  }
}

post_job <- function(queue, json, value) {
  message(sprintf("Posting %s job...", value))
  send_msg(queue,
           msg = json,
           query = list(MessageAttribute.1.Name = "type",
                        MessageAttribute.1.Value.DataType ="String",
                        MessageAttribute.1.Value.StringValue = value))
}
