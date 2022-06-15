# RPackageParser

R Package that uses `pkgdown` package, to parse R package documentation and pass it on to the next Lambda worker to upload the documentation to the RDocumentation database.

## How it works

1. Read messages from [rdocs-r-worker](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker) SQS queue. This will contain the packages that need to be processed. The message types are documented in the [/docs](/docs) folder.
2. Process the messages into a JSON files that we dump in S3 for logging.
3. If the message is successfully processed, add the JSON to the [rdocs-app-worker](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-app-worker) SQS queue (that will then be handled in the [rdocs app API](https://github.com/datacamp/RDocumentation-app/tree/master/api)).
4. If the processing fails, add an error job to the [rdoc-r-worker-deadletter](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker-deadletter) queue.

## Local development

### Installing the package

- Ensure you have `devtools` installed to ease local development
- Install the package's dependencies:
  ```R
  remotes::install_github("datacamp/pkgdown", ref = "fs/pkgdown-updates")
  install.packages("aws.sqs", repos = c(getOption("repos"), "http://cloudyr.github.io/drat"))
  ```
- Open up `RPackageParser.RProj` in RStudio.
- Select Build > Load All; this will make all exported and unexported functions of the package available.
- To verify that it works, try to following command in your R console:
  ```R
  res <- process_package("https://cran.r-project.org/src/contrib/Archive/R6/R6_2.5.0.tar.gz", "R6", "cran")
  ```

### Polling and posting to SQS queues

First, add a file `.env.R` in the package root folder with info that AWS needs:

```R
Sys.setenv(AWS_ACCESS_KEY_ID = "ACCESS_KEY_ID",
           AWS_SECRET_ACCESS_KEY = "SECRET_ACCESS_KEY",
           AWS_DEFAULT_REGION = "us-west-1")

```

After that, you can run `main()`; this will poll the SQS queues and do all the processing:

```R
RPackageParser::main()
```

## Deployment

TODO ADD INFO

