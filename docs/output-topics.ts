export type AppWorkerTopicsJobType = {
  "name": string;
  "title": string;
  "pagetitle": string;
  "source": string;
  "filename": string;
  "author": string | string[];
  "aliases": string | string[];
  "keywords": [];
  "description": {
    "title": string;
    "contents": string;
  };
  "opengraph": {
    "description": string;
  },
  "usage": {
    "title": string;
    "contents": string;
  },
  "examples": string;
  "sections":{
    "title": string;
    "contents": string;
    "slug": string;
  }[],
  "package": {
    "package": string;
    "version":string;
  }
}