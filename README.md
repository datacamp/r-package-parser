# RPackageParser

R Package that builds on Hadley Wickham's `pkgdown` package, to parse R Documentation to be used on R Documentation. This package is being used in the pipeline of lambda workers.

## Installing the package

Latest released version from CRAN

```R
devtools::install_github("datacamp/r-package-parser")
```

## How it works

First, add a file `.env.R` in the package root folder with info that AWS needs:

```R
Sys.setenv(AWS_ACCESS_KEY_ID = "ACCESS_KEY_ID",
           AWS_SECRET_ACCESS_KEY = "SECRET_ACCESS_KEY",
           AWS_DEFAULT_REGION = "us-west-1")

```

After that, you can run `main()`; this will poll the SQS queues and do all the processing:

```R
RPackageParser::main()