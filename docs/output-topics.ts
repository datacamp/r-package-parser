export type Topics = {
  "name": string;
  "title": string;
  "pagetitle": string;
  "source": string;
  "filename": string;
  "author": [],
  "aliases": string | string[];
  "keywords": [],
  "description": string;
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
  }[],
  "package": {
    "package": string;
    "version":string;
  }
}