// Generated by CoffeeScript 2.5.1
  // markdownify.coffee
import {
  strict as assert
} from 'assert';

import marked from 'marked';

import {
  config
} from '../starbucks.config.js';

import {
  say,
  undef,
  unitTesting
} from '@jdeighan/coffee-utils';

import {
  slurp
} from '@jdeighan/coffee-utils/fs';

import {
  undentedBlock
} from '@jdeighan/coffee-utils/indent';

import {
  procContent
} from '@jdeighan/string-input';

// ---------------------------------------------------------------------------
export var markdownify = function(text) {
  var html;
  if (unitTesting) {
    return text;
  }
  html = marked(undentedBlock(text), {
    grm: true,
    headerIds: false
  });
  return html;
};

// ---------------------------------------------------------------------------
export var markdownifyFile = function(filename) {
  var fpath, html, text;
  fpath = `${config.markdownDir}/${filename}`;
  text = slurp(fpath);
  html = markdownify(text);
  return html;
};
