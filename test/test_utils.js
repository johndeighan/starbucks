// Generated by CoffeeScript 2.5.1
  // test_utils.coffee
import {
  strict as assert
} from 'assert';

import test from 'ava';

import {
  say,
  normalize,
  undef,
  isString,
  error,
  setUnitTesting
} from '../coffee_utils.js';

import {
  disableMarkdown
} from '../markdownify.js';

import {
  disableBrewing
} from '../brewCoffee.js';

import {
  disableSassify
} from '../sassify.js';

// ---------------------------------------------------------------------------
export var AvaTester = class AvaTester {
  // --- Use package globals: testing
  constructor(whichTest = 'deepEqual') {
    this.hFound = {};
    this.setWhichTest(whichTest);
    this.justshow = false;
    this.testing = true;
  }

  // ........................................................................
  setWhichTest(testName) {
    this.whichTest = testName;
  }

  // ........................................................................
  transformValue(input) {
    return input;
  }

  // ........................................................................
  truthy(lineNum, input, expected, just_show = false) {
    this.setWhichTest('truthy');
    return this.test(lineNum, input, expected, just_show);
  }

  // ........................................................................
  falsy(lineNum, input, expected, just_show = false) {
    this.setWhichTest('falsy');
    return this.test(lineNum, input, expected, just_show);
  }

  // ........................................................................
  equal(lineNum, input, expected, just_show = false) {
    this.setWhichTest('deepEqual');
    return this.test(lineNum, input, expected, just_show);
  }

  // ........................................................................
  notequal(lineNum, input, expected, just_show = false) {
    this.setWhichTest('notDeepEqual');
    return this.test(lineNum, input, expected, just_show);
  }

  // ........................................................................
  fails(lineNum, input, expected, just_show = false) {
    if (expected !== undef) {
      error("AvaTester.fails(): expected value not allowed");
    }
    this.setWhichTest('throws');
    return this.test(lineNum, input, expected, just_show);
  }

  // ........................................................................
  normalize(input) {
    if (isString(input)) {
      return normalize(input);
    } else {
      return input;
    }
  }

  // ........................................................................
  test(lineNum, input, expected, just_show = false) {
    var err, got, whichTest;
    setUnitTesting(true);
    disableBrewing(); // disable converting CoffeeScript to JavaScript
    disableSassify(); // disable converting SASS to CSS
    disableMarkdown(); // disable converting markdown to HTML
    if (!this.testing) {
      return;
    }
    this.justshow = just_show;
    lineNum = this.getLineNum(lineNum);
    expected = this.normalize(expected);
    // --- We need to save this here because in the tests themselves,
    //     'this' won't be correct
    whichTest = this.whichTest;
    if (whichTest === 'throws') {
      if (this.justshow) {
        say(`line ${lineNum}`);
        try {
          got = this.transformValue(input);
          say(result, "GOT:\n");
        } catch (error1) {
          err = error1;
          say("GOT ERROR");
        }
        say("EXPECTED ERROR\n");
      }
    } else {
      got = this.normalize(this.transformValue(input));
      if (lineNum < 0) {
        if (this.justshow) {
          say(`line ${lineNum}`);
          say(got, "GOT:\n");
          say(expected, "EXPECTED:\n");
        } else {
          test.only(`line ${lineNum}`, function(t) {
            return t[whichTest](got, expected);
          });
        }
        this.testing = false;
      } else {
        test(`line ${lineNum}`, function(t) {
          return t[whichTest](got, expected);
        });
      }
    }
  }

  // ........................................................................
  getLineNum(lineNum) {
    // --- patch lineNum to avoid duplicates
    while (this.hFound[lineNum]) {
      if (lineNum < 0) {
        lineNum -= 1000;
      } else {
        lineNum += 1000;
      }
    }
    this.hFound[lineNum] = true;
    return lineNum;
  }

};
