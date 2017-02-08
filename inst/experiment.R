library(RPackageParser)
p <- list(path = "https://s3.amazonaws.com/assets.rdocumentation.org/rpackages/archived/base/base_3.3.1.tar.gz",
          name = "base",
          version = "3.3.1",
          repoType = "part_of_r")
process_package(p$path, p$name, p$repoType)
