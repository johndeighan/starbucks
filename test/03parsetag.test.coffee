# 03parsetag.test.coffee

import {parsetag, tag2str} from '../src/parsetag.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class TagTester extends AvaTester

	transformValue: (input) ->
		return parsetag(input)

tester = new TagTester()

# ---------------------------------------------------------------------------

tester.test 18, 'p', {
	tag: 'p',
	}

# ---------------------------------------------------------------------------

tester.test 24, 'p.class1', {
	tag: 'p',
	hAttr: {
		class: {value: 'class1', quote: '"'},
		}
	}

# ---------------------------------------------------------------------------

tester.test 33, 'p.class1.class2', {
	tag: 'p',
	hAttr: {
		class: {value: 'class1 class2', quote: '"' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 42, 'p border=yes', {
	tag: 'p',
	hAttr: {
		border: {value: 'yes', quote: '' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 51, 'p border="yes"', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '"' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 60, "p border='yes'", {
	tag: 'p',
	hAttr: {
		border: {value: 'yes', quote: "'" },
		}
	}

# ---------------------------------------------------------------------------

tester.test 69, 'p border="yes" this is a paragraph', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '"' },
		}
	containedText: 'this is a paragraph',
	}

# ---------------------------------------------------------------------------

tester.test 79, 'p border="yes" "this is a paragraph"', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '"' },
		}
	containedText: 'this is a paragraph',
	}

# ---------------------------------------------------------------------------

tester.test 89, 'p.nice.x border=yes class="abc def" "a paragraph"', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '' },
		class:  { value: 'nice x abc def', quote: '"' },
		}
	containedText: 'a paragraph',
	}

# ---------------------------------------------------------------------------

tester.test 100, 'img href="file.ext" alt="a description"  ', {
	tag: 'img',
	hAttr: {
		href: { value: 'file.ext', quote: '"' },
		alt:  { value: 'a description', quote: '"' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 110, 'h1 class="desc" The syntax is nice', {
	tag: 'h1',
	hAttr: {
		class: { value: 'desc', quote: '"' },
		},
	containedText: 'The syntax is nice',
	}

# ---------------------------------------------------------------------------

tester.test 120, 'h1.desc The syntax is nice', {
	tag: 'h1',
	hAttr: {
		class: { value: 'desc', quote: '"' },
		},
	containedText: 'The syntax is nice',
	}

# ---------------------------------------------------------------------------

tester.test 130, 'div:markdown', {
	tag: 'div',
	subtype: 'markdown',
	hAttr: {
		class: { value: 'markdown', quote: '"' },
		},
	}

# ---------------------------------------------------------------------------

tester.test 140, 'div:markdown.desc # Title', {
	tag: 'div',
	subtype: 'markdown',
	hAttr: {
		class: { value: 'markdown desc', quote: '"' },
		},
	containedText: '# Title',
	}

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

class TagTester2 extends AvaTester

	transformValue: (input) ->
		return tag2str(input)

tester = new TagTester2()

# ---------------------------------------------------------------------------

tester.test 161, {
		tag: 'p',
		}, "<p>"

# ---------------------------------------------------------------------------

tester.test 167, {
		tag: 'p',
		hAttr: {
			class: { value: 'error', quote: '"' },
			},
		}, '<p class="error">'

# ---------------------------------------------------------------------------
