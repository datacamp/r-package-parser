// name and version taken from the package <name>_<version>.tar.gz file
// path is a url to download the package file
export type RWorkerJobType = {
  name: string;
  version: string;
  path: string;
  repoType?: 'github' | 'bioconductor' | 'part_of_r';
};