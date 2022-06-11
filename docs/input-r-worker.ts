// name and version taken from the package <name>_<version>.tar.gz file
// path is 'cran.r-project.org/pub/R/src/contrib/' + name
export type InputRWorker = {
  name: string;
  version: string;
  path: string;
  repoType?: 'github' | 'bioconductor' | 'part_of_r';
};