// Generated by CoffeeScript 2.5.1
// 04markdown.test.coffee
var MarkdownTester, tester;

import {
  markdownify,
  disableMarkdown,
  enableMarkdown
} from '../markdownify.js';

import {
  AvaTester
} from '@jdeighan/ava-tester';

import {
  init
} from './test_init.js';

// ---------------------------------------------------------------------------
MarkdownTester = class MarkdownTester extends AvaTester {
  transformValue(input) {
    var html;
    enableMarkdown();
    html = markdownify(input);
    disableMarkdown();
    return html;
  }

};

tester = new MarkdownTester();

// ---------------------------------------------------------------------------
tester.equal(27, `# title`, `<h1>title</h1>`);

// ---------------------------------------------------------------------------
tester.equal(36, `this is **bold** text`, `<p>this is <strong>bold</strong> text</p>`);

// ---------------------------------------------------------------------------
