# RPackageParser

_Note:_ Please read this [confluence page](https://datacamp.atlassian.net/wiki/spaces/PRODENG/pages/2314469377/RDocumentation) which explains the complete architecture of how RDocumentation works.

R Package that uses `pkgdown` package, to parse R package documentation and pass it on to the next Lambda worker to upload the documentation to the RDocumentation database.

We have forked our own version of `pkgdown` which we use here: https://github.com/datacamp/pkgdown

## How it works

1. Read messages from [rdocs-r-worker](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker) SQS queue. This will contain the packages that need to be processed. The message types are documented in the [/docs](/docs) folder.
2. Process the messages into a JSON files that we dump in S3 for logging.
3. If the message is successfully processed, add the JSON to the [rdocs-app-worker](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-app-worker) SQS queue (that will then be handled in the [rdocs app API](https://github.com/datacamp/RDocumentation-app/tree/master/api)).
4. If the processing fails, add an error job to the [rdoc-r-worker-deadletter](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker-deadletter) queue.

## Local development

### Installing the package

- Ensure you have `devtools` installed to ease local development
- Set an environment variable `GITHUB_PAT`
- Install the package's dependencies:
  ```R
  devtools::install_github("datacamp/pkgdown", ref = "master")
  ```
- Open up `RPackageParser.RProj` in RStudio.
- Select Build > Load All; this will make all exported and unexported functions of the package available.
- To verify that it works, try to following command in your R console:
  ```R
  res <- process_package("https://cran.r-project.org/src/contrib/Archive/R6/R6_2.5.0.tar.gz", "R6", "cran")
  ```
  
### Test the parsing logic

If you just want to test the downloading, unpacking and parsing of a package and its topics:

1. `devtools::load_all(".")`
2. `library("RPackageParser")`
3. `res <- process_package("https://cran.r-project.org/src/contrib/REdaS_0.9.4.tar.gz", "REdaS", "cran")`: replace these arguments with the ones of the package you want to test.
4. `write(jsonlite::toJSON(res$topics[[1]],auto_unbox = TRUE), file = 'topic.json')`: this will create a `topic.json` file in the root of the project that contains the JSON that will be added to the queue. This is what the API will process before adding the topic to the mysql database.

### Setting up local SQS queues

First, install LocalStack to locally set up SQS queues

```
pip3 install --user localstack
pip3 install --user awscli-local
# Start the container
localstack start -d
# Create the local queues
awslocal sqs create-queue --queue-name rdoc-r-worker-local
awslocal sqs create-queue --queue-name rdoc-r-deadletter-local
awslocal sqs create-queue --queue-name rdoc-app-worker-local
```

add a file `.env.R` in the package root folder with dummy AWS credentials and the right queue names:

```R
Sys.setenv(
  AWS_ACCESS_KEY_ID ="AKI",
  AWS_SECRET_ACCESS_KEY = "SAK",
  AWS_DEFAULT_REGION = "us-east-1",
  SOURCE_QUEUE = "http://localhost:4566/000000000000/rdoc-r-worker-local",
  DEADLETTER_QUEUE = "http://localhost:4566/000000000000/rdoc-r-worker-deadletter-local",
  DEST_QUEUE = "http://localhost:4566/000000000000/rdoc-app-worker-local"
)
```

Now you can run the `main()` function:

```R
RPackageParser::main()
```

Finally, you can add messages to the queue, e.g.:

```
awslocal sqs send-message --queue-url http://localhost:4566/000000000000/rdoc-r-worker-local--message-body '{"name":"sm","version":"2.2-5.7","path":"ftp://cran.r-project.org/pub/R/src/contrib/sm_2.2-5.7.tar.gz"}'
```

The `main()` function will ingest new messages, run `process_packages()`, and posts the parsed JSONs on the destination queue.

## Connecting to staging/production AWS queues

Although this is not advised, you can also have a locally running `main()` function connect to staging and production queues on AWS.

To do so, you need to add AWS keys that have write access to the SQS queues so that you can post messages to the queue. Ask Filip, Zaurbek or the infrastructure team for valid `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` credentials and update your `.env.R` file:

```R
Sys.setenv(
  AWS_ACCESS_KEY_ID ="SECRET",
  AWS_SECRET_ACCESS_KEY = "SECRET",
  AWS_DEFAULT_REGION = "us-east-1",
  SOURCE_QUEUE = "rdoc-r-worker",
  DEST_QUEUE = "rdoc-app-worker",
  DEADLETTER_QUEUE = "rdoc-r-worker-deadletter"
)
```

To add a message to e.g. the production queue:

```
aws sqs send-message --queue-url https://queue.amazonaws.com/301258414863/rdoc-r-worker --message-body '{"name":"ReorderCluster","version":"1.0","path":"ftp://cran.r-project.org/pub/R/src/contrib/ReorderCluster_1.0.tar.gz"}'
```

Note that this is the production queue, which means that the queue will be processed both by your local parser and the production parser, and whoever pics the message first will be the one to process it. That's why you might need to send a few requests until your local parser can pick the message.

After you added your message to the [rdoc-r-worker queue](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-r-worker/send-receive), you should see it for a brief moment in AWS while its being processed. After the processing is done, you should be able to see new messages in [rdoc-app-worker queue](https://us-east-1.console.aws.amazon.com/sqs/v2/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F301258414863%2Frdoc-app-worker/send-receive#/) (click on the "Poll for messages" button in the aws console).


## Deployment

- Commits to master are deployed to staging
- Tags that use `vx.y.z` are deployed to production
