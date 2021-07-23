# parsetag.test.coffee

import test from 'ava'
import {parsetag, tag2str} from '../parsetag.js'
import {Tester} from './test_utils.js'

# ---------------------------------------------------------------------------

class TagTester extends Tester

	getValue: (input) ->
		return parsetag(input)

tester = new TagTester()

# ---------------------------------------------------------------------------

tester.test 15, 'p', {
	tag: 'p',
	}

# ---------------------------------------------------------------------------

tester.test 21, 'p.class1', {
	tag: 'p',
	hAttr: {
		class: {value: 'class1', quote: '"'},
		}
	}

# ---------------------------------------------------------------------------

tester.test 28, 'p.class1.class2', {
	tag: 'p',
	hAttr: {
		class: {value: 'class1 class2', quote: '"' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 35, 'p border=yes', {
	tag: 'p',
	hAttr: {
		border: {value: 'yes', quote: '' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 44, 'p border="yes"', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '"' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 53, "p border='yes'", {
	tag: 'p',
	hAttr: {
		border: {value: 'yes', quote: "'" },
		}
	}

# ---------------------------------------------------------------------------

tester.test 62, 'p border="yes" this is a paragraph', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '"' },
		}
	containedText: 'this is a paragraph',
	}

# ---------------------------------------------------------------------------

tester.test 72, 'p border="yes" "this is a paragraph"', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '"' },
		}
	containedText: 'this is a paragraph',
	}

# ---------------------------------------------------------------------------

tester.test 82, 'p.nice.x border=yes class="abc def" "a paragraph"', {
	tag: 'p',
	hAttr: {
		border: { value: 'yes', quote: '' },
		class:  { value: 'nice x abc def', quote: '"' },
		}
	containedText: 'a paragraph',
	}

# ---------------------------------------------------------------------------

tester.test 93, 'img href="file.ext" alt="a description"  ', {
	tag: 'img',
	hAttr: {
		href: { value: 'file.ext', quote: '"' },
		alt:  { value: 'a description', quote: '"' },
		}
	}

# ---------------------------------------------------------------------------

tester.test 103, 'h1 class="desc" The syntax is nice', {
	tag: 'h1',
	hAttr: {
		class: { value: 'desc', quote: '"' },
		},
	containedText: 'The syntax is nice',
	}

# ---------------------------------------------------------------------------

tester.test 113, 'h1.desc The syntax is nice', {
	tag: 'h1',
	hAttr: {
		class: { value: 'desc', quote: '"' },
		},
	containedText: 'The syntax is nice',
	}

# ---------------------------------------------------------------------------

tester.test 127, 'div:markdown', {
	tag: 'div',
	subtype: 'markdown',
	hAttr: {
		class: { value: 'markdown', quote: '"' },
		},
	}

# ---------------------------------------------------------------------------

tester.test 137, 'div:markdown.desc # Title', {
	tag: 'div',
	subtype: 'markdown',
	hAttr: {
		class: { value: 'markdown desc', quote: '"' },
		},
	containedText: '# Title',
	}

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

class TagTester2 extends Tester

	getValue: (input) ->
		return tag2str(input)

tester = new TagTester2()

# ---------------------------------------------------------------------------

tester.test 134, {
		tag: 'p',
		}, "<p>"

# ---------------------------------------------------------------------------

tester.test 140, {
		tag: 'p',
		hAttr: {
			class: { value: 'error', quote: '"' },
			},
		}, '<p class="error">'

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

