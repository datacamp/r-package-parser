
getMessages <- function(queue) {

}

dump_jsons_on_s3 <- function(package_name) {
  message("Syncing S3 (disabled for now) ...")
  #package_path <- paste(package_name, sep= "/")
  #system(sprintf("aws s3 sync jsons/%s s3://assets.rdocumentation.org/rpackages/unarchived/%s", package_path, package_path))
}

sqs_attributes <- list(MessageAttribute.1.Name = "type",
                       MessageAttribute.1.Value.DataType ="String",
                       MessageAttribute.1.Value.StringValue ="version")

# see if you can use aws.sqs::send_msg instead of manual override.
#' @importFrom aws.sqs send_msg
post_job <- function(queue, json, type) {
  message(sprintf("Posting %s job...", type))
  send_msg(queue,
           msg = json,
           query = sqs_attributes)
}
