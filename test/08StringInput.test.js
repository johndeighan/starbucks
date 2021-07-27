// Generated by CoffeeScript 2.5.1
// 08StringInput.test.coffee
var GatherTester, tester;

import {
  say,
  undef
} from '@jdeighan/coffee-utils';

import {
  indentLevel,
  undentedStr
} from '@jdeighan/coffee-utils/indent';

import {
  numHereDocs,
  patch
} from '../src/heredoc_utils.js';

import {
  StringInput
} from '../src/StringInput.js';

import {
  AvaTester
} from '@jdeighan/ava-tester';

import {
  init
} from './test_init.js';

// ---------------------------------------------------------------------------
GatherTester = class GatherTester extends AvaTester {
  transformValue(input) {
    var lLines, line;
    if (!(input instanceof StringInput)) {
      throw new Error("input should be a StringInput object");
    }
    lLines = [];
    line = input.get();
    while (line != null) {
      lLines.push(line);
      line = input.get();
    }
    return lLines;
  }

};

tester = new GatherTester();

// ---------------------------------------------------------------------------

// --- Test basic reading till EOF
tester.equal(30, new StringInput(`abc
def`), ['abc', 'def']);

tester.equal(38, new StringInput(`abc

def`), ['abc', '', 'def']);

tester.equal(48, new StringInput(`abc

def`, {
  mapper: function(line) {
    if (line === '') {
      return undef;
    } else {
      return line;
    }
  }
}), ['abc', 'def']);

// ---------------------------------------------------------------------------

  // --- Test basic use of mapping function
(function() {
  var mapper;
  mapper = function(line) {
    if (line === '') {
      return undef;
    } else {
      return 'x';
    }
  };
  return tester.equal(74, new StringInput(`abc

def`, {mapper}), ['x', 'x']);
})();

// ---------------------------------------------------------------------------

  // --- Test ability to access 'this' object from a mapper
//     Goal: remove not only blank lines, but also the line following
(function() {
  var mapper;
  mapper = function(line, oInput) {
    if (line === '') {
      oInput.get();
      return undef;
    } else {
      return line;
    }
  };
  return tester.equal(98, new StringInput(`abc

def
ghi`, {mapper}), ['abc', 'ghi']);
})();

// ---------------------------------------------------------------------------

  // --- Test handling HEREDOC
(function() {
  var mapper;
  mapper = function(line, oInput) {
    var lLines, lSections, n, next;
    if (line === '' || line.match(/^\s*#\s/)) {
      return undef; // skip comments and blank lines
    }
    n = numHereDocs(line);
    if (n === 0) {
      return line;
    }
    lSections = []; // --- will have one subarray for each HEREDOC
    while (n > 0) {
      lLines = [];
      while ((oInput.lBuffer.length > 0) && (oInput.lBuffer[0] !== '')) {
        next = oInput.lBuffer.shift();
        lLines.push(next);
      }
      if (oInput.lBuffer.length === 0) {
        throw new Error(`EOF while processing HEREDOC
at line ${oInput.lineNum}
n = ${n}`);
      }
      oInput.lBuffer.shift(); // empty line
      lSections.push(lLines);
      n -= 1;
    }
    return patch(line, lSections);
  };
  tester.equal(138, new StringInput(`x = 3

str = <<<
ghi

jkl`, {mapper}), ['x = 3', 'str = "ghi\\n"', 'jkl']);
  tester.fails(151, new StringInput(`x = 3

str = <<<
ghi
jkl`, {mapper}));
  // --- test multiple HEREDOCs
  return tester.equal(162, new StringInput(`x = 3

str = compare(<<<, <<<)
ghi

jkl
xyz

say "OK"`, {mapper}), ['x = 3', 'str = compare("ghi\\n", "jkl\\nxyz\\n")', 'say "OK"']);
})();

// ---------------------------------------------------------------------------

  // --- Test mapping to objects
(function() {
  var cmdRE, mapper;
  cmdRE = /^\s*\#([a-z][a-z_]*)\s*(.*)$/; // skip leading whitespace
  // command name
  // skipwhitespace following command
  // command arguments
  mapper = function(line, oInput) {
    var lMatches;
    lMatches = line.match(cmdRE);
    if (lMatches != null) {
      return {
        cmd: lMatches[1],
        argstr: lMatches[2]
      };
    } else {
      return line;
    }
  };
  return tester.equal(199, new StringInput(`abc
#if x==y
	def
#else
	ghi`, {mapper}), [
    'abc',
    {
      cmd: 'if',
      argstr: 'x==y'
    },
    '\tdef',
    {
      cmd: 'else',
      argstr: ''
    },
    '\tghi'
  ]);
})();

// ---------------------------------------------------------------------------

  // --- Test handling TAML HEREDOC
(function() {
  var mapper;
  mapper = function(line, oInput) {
    var lLines, lSections, n, next;
    if (line === '' || line.match(/^\s*#\s/)) {
      return undef; // skip comments and blank lines
    }
    n = numHereDocs(line);
    if (n === 0) {
      return line;
    }
    lSections = []; // --- will have one subarray for each HEREDOC
    while (n > 0) {
      lLines = [];
      while ((oInput.lBuffer.length > 0) && (oInput.lBuffer[0] !== '')) {
        next = oInput.lBuffer.shift();
        lLines.push(next);
      }
      if (oInput.lBuffer.length === 0) {
        throw new Error(`EOF while processing HEREDOC
at line ${oInput.lineNum}
n = ${n}`);
      }
      oInput.lBuffer.shift(); // empty line
      lSections.push(lLines);
      n -= 1;
    }
    return patch(line, lSections);
  };
  return tester.equal(243, new StringInput(`x = 3

str = compare(<<<, <<<, <<<)
	a multi
	line string

	---
		- first
		- second

	---
		name: John
		address: Blacksburg

jkl`, {mapper}), ['x = 3', 'str = compare("a multi\\nline string\\n", ["first","second"], {"name":"John","address":"Blacksburg"})', 'jkl']);
})();

// ---------------------------------------------------------------------------

  // --- Test continuation lines
(function() {
  var mapper;
  mapper = function(line, oInput) {
    var n, next;
    if (line === '' || line.match(/^\s*#\s/)) {
      return undef; // skip comments and blank lines
    }
    n = indentLevel(line); // current line indent
    while ((oInput.lBuffer.length > 0) && (indentLevel(oInput.lBuffer[0]) >= n + 2)) {
      next = oInput.lBuffer.shift();
      line += ' ' + undentedStr(next);
    }
    return line;
  };
  return tester.equal(283, new StringInput(`str = compare(
		"abcde",
		expected
		)

call func
		with multiple
		long parameters

# --- DONE ---`, {mapper}), ['str = compare( "abcde", expected )', 'call func with multiple long parameters']);
})();

// ---------------------------------------------------------------------------

  // --- Test continuation lines AND HEREDOCs
(function() {
  var mapper;
  mapper = function(line, oInput) {
    var n, next;
    if (line === '' || line.match(/^\s*#\s/)) {
      return undef; // skip comments and blank lines
    }
    n = indentLevel(line); // current line indent
    while ((oInput.lBuffer.length > 0) && (indentLevel(oInput.lBuffer[0]) >= n + 2)) {
      next = oInput.lBuffer.shift();
      line += ' ' + undentedStr(next);
    }
    return line;
  };
  return tester.equal(317, new StringInput(`str = compare(
		"abcde",
		expected
		)

call func
		with multiple
		long parameters

# --- DONE ---`, {mapper}), ['str = compare( "abcde", expected )', 'call func with multiple long parameters']);
})();
