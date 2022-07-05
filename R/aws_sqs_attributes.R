#' @title Get a queue URL
#' @aliases get_queue_url
#' @description Retrieves the URL for an SQS queue by its name.
#' @param name A character string containing the name of the queue.
#' @param owner A character string containing the AWS Account ID that created the queue.
#' @param query A list specifying additional query arguments to be passed to the \code{query} argument of \code{\link{sqsHTTP}}.
#' @param ... Additional arguments passed to \code{\link{sqsHTTP}}.
#' @return If successful, a character string containing an SQS Queue URL. Otherwise, a data structure of class \dQuote{aws_error} containing any error message(s) from AWS and information about the request attempt.
#' @author Thomas J. Leeper
#' @seealso \code{link{create_queue}} \code{link{delete_queue}} \code{\link{get_queue_attrs}} \code{\link{set_queue_attrs}}
#' @references
#' \href{http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_GetQueueUrl.html}{GetQueueURL}
#' @export
get_queue_url <- function(name, owner = NULL, query = NULL, ...) {
  query_args <- c(query, list(Action = "GetQueueUrl", QueueName = name))
  if (!is.null(owner)) {
    query_args$QueueOwnerAWSAccountId <- owner
  }
  out <- sqsHTTP(query = query_args, ...)
  if (inherits(out, "aws-error") || inherits(out, "unknown")) {
    return(out)
  }
  structure(out$GetQueueUrlResponse$GetQueueUrlResult$QueueUrl,
            RequestId = out$GetQueueUrlResponse$ResponseMetadata$RequestId)
}

.urlFromName <- function(queue) {
  p <- httr::parse_url(queue)
  if (is.null(p$scheme)) {
    out <- get_queue_url(queue)
    if(!length(out))
      stop("Queue URL not found")
  } else {
    out <- queue
  }
  return(out)
}
