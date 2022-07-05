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
