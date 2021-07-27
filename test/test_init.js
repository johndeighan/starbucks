// Generated by CoffeeScript 2.5.1
  // test_init.coffee
import {
  strict as assert
} from 'assert';

import {
  setUnitTesting
} from '@jdeighan/coffee-utils';

import {
  disableMarkdown
} from '../src/markdownify.js';

import {
  disableBrewing
} from '../src/brewCoffee.js';

import {
  disableSassify
} from '../src/sassify.js';

export var init = function() {
  setUnitTesting(true);
  disableMarkdown();
  disableBrewing();
  return disableSassify();
};

init();
