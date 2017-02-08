to_queue <- "RdocWorkerQueue"
from_queue <- "RdocRWorkerQueue"
error_queue <- "RdocRWorkerDeadQueue"

getMessages <- function(queue) {
  receive_msg(queue, wait = 20)
}

syncS3 <- function(package_name) {
  message("Syncing S3 ...")
  package_path <- paste(package_name, sep= "/")
  system(sprintf("aws s3 sync jsons/%s s3://assets.rdocumentation.org/rpackages/unarchived/%s", package_path, package_path))
}

# # Copied from https://github.com/cloudyr/aws.sqs/blob/master/R/messages.r but added support for custom query args
# send_msg <- function(queue, msg, query = list(), attributes = NULL, delay = NULL, ...) {
#   queue <- aws.sqs:::.urlFromName(queue)
#   if(length(msg) > 1) {
#     # batch mode
#     batchs <- split(msg, ceiling(seq_along(msg)/10))
#
#     for (batch in batchs) {
#
#       l <- length(batch)
#       n <- 1:l
#
#       id <- paste0("msg", n)
#       a <- as.list(c(id, batch))
#
#       names(a) <- c(paste0("SendMessageBatchRequestEntry.",n,".Id"),
#                     paste0("SendMessageBatchRequestEntry.",n,".MessageBody"))
#       query_args <-  list(Action = "SendMessageBatch")
#
#       query_mult <- rep(query, each = l)
#       front <- c(paste0("SendMessageBatchRequestEntry.",n, "."))
#       back <- rep(names(query), each = l)
#       names(query_mult) <- paste0(front, back)
#
#       body <- c(a, query_mult, query_args)
#
#       out <- aws.sqs:::sqsHTTP(url = queue, query = body, ...)
#       if (inherits(out, "aws-error") || inherits(out, "unknown")) {
#         return(out)
#       }
#       structure(out$SendMessageBatchResponse$SendMessageBatchResult,
#                 RequestId = out$SendMessageBatchResponse$ResponseMetadata$RequestId)
#     }
#
#   } else {
#     # single mode
#     query_args <- append(query, list(Action = "SendMessage"))
#     query_args$MessageBody = msg
#     out <- aws.sqs:::sqsHTTP(url = queue, query = query_args, ...)
#     if (inherits(out, "aws-error") || inherits(out, "unknown")) {
#       return(out)
#     }
#     structure(list(out$SendMessageResponse$SendMessageResult),
#               RequestId = out$SendMessageResponse$ResponseMetadata$RequestId)
#   }
# }

# SEE IF YOU CAN USE aws.sqs::send_msg instead of manual override.
#' @importFrom aws.sqs send_msg
postDescriptionJob <- function(queue, package_name) {
  message("Posting description job...")
  description_json_path <- paste("jsons", package_name, "DESCRIPTION.json", sep = "/");

  body <- paste(readLines(description_json_path ,encoding="UTF-8", warn = FALSE), collapse = "\n");

  send_msg(queue, body,
           query= list(
             MessageAttribute.1.Name= "type",
             MessageAttribute.1.Value.DataType="String",
             MessageAttribute.1.Value.StringValue="version"
           )
  );
}

postTopicsJob <- function(queue, package_name) {
  message("Posting topics job...")
  jsons <- c()
  package_path <- paste("jsons", package_name, "man", sep="/")
  files <- list.files(path=package_path, full.names = TRUE)
  for (filename in files) {
    if (endsWith(filename, ".json")) {
      body <- paste(readLines(filename, encoding="UTF-8", warn = FALSE), collapse = "\n");
      jsons <- c(jsons, body)
    }
  }

  send_msg(queue, jsons,
           query= list(
             MessageAttribute.1.Name= "type",
             MessageAttribute.1.Value.DataType="String",
             MessageAttribute.1.Value.StringValue="topic"
           )
  );
}
