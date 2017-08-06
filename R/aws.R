#' @importFrom jsonlite write_json
dump_jsons_on_s3 <- function(description, topics) {
  pkg_name <- description$Package
  pkg_version <- description$Version
  local <- file.path(getwd(), pkg_name, pkg_version)
  remote <- file.path("s3://assets.rdocumentation.org/rpackages/unarchived", pkg_name, pkg_version)

  dir.create(local, recursive = TRUE)

  # copy everything from man/figures to local/figures
  pkg_folder <- file.path("packages", pkg_name)
  figures_path <- file.path(pkg_folder, "man", "figures")
  copy_local(figures_path, "figures")

  # copy everything from _vignettes to local/vignettes
  vignettes_path <- file.path(pkg_folder, "_vignettes")
  copy_local(vignettes_path, "vignettes")

  # copy everything from R to local/R
  r_path <- file.path(pkg_folder, "R")
  copy_local(r_path, "R")

  # write files to disk
  write_json(description, auto_unbox = TRUE, path = file.path(local, "DESCRIPTION.json"))
  lapply(topics, function(x) write_json(x, auto_unbox = TRUE, path = file.path(local, paste0(x$name, ".json"))))
  # do the sync
  system(sprintf("aws --region us-east-1 s3 sync %s %s", local, remote))
  # clean up again
  unlink(file.path(getwd(), pkg_name), recursive = TRUE)
}

copy_local <- function(path, dirname){
  if (file.exists(path) && !is.null(path)) {
    out_path <- file.path(local, dirname)
    dir.create(out_path)
    pkgdown:::copy_dir(path, out_path)
  }
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
