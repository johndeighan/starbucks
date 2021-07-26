// Generated by CoffeeScript 2.5.1
// starbucks.config.coffee
var rootDir, srcDir;

import process from 'process';

import dotenv from 'dotenv';

dotenv.config();

// --- Directories are relative to /src/routes or /src/components
rootDir = process.env.ROOT;

srcDir = `${rootDir}/src`;

export var config = {
  rootDir,
  componentsDir: `${srcDir}/components`,
  markdownDir: `${srcDir}/markdown`,
  storesDir: `${srcDir}/stores`,
  libDir: `${srcDir}/lib`,
  dumpDir: `${rootDir}/dump`,
  hConstants: {
    companyName: "WayForward Technologies, Inc."
  }
};
