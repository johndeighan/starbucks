# 03parsetag.test.coffee

import {parsetag, tag2str} from '../src/parsetag.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {setUnitTesting} from '@jdeighan/coffee-utils'

setUnitTesting(true)

# ---------------------------------------------------------------------------

(() ->

	class TagTester extends AvaTester

		transformValue: (input) ->
			return parsetag(input)

	tester = new TagTester()

	tester.test 20, 'p', {
		tag: 'p',
		}

	tester.test 24, 'p.class1', {
		tag: 'p',
		hAttr: {
			class: {value: 'class1', quote: '"'},
			}
		}

	tester.test 31, 'p.class1.class2', {
		tag: 'p',
		hAttr: {
			class: {value: 'class1 class2', quote: '"' },
			}
		}

	tester.test 38, 'p border=yes', {
		tag: 'p',
		hAttr: {
			border: {value: 'yes', quote: '' },
			}
		}

	tester.test 45, 'p border="yes"', {
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		}

	tester.test 52, "p border='yes'", {
		tag: 'p',
		hAttr: {
			border: {value: 'yes', quote: "'" },
			}
		}

	tester.test 59, 'p border="yes" this is a paragraph', {
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		containedText: 'this is a paragraph',
		}

	tester.test 67, 'p border="yes" "this is a paragraph"', {
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		containedText: 'this is a paragraph',
		}

	tester.test 75, 'p.nice.x border=yes class="abc def" "a paragraph"', {
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '' },
			class:  { value: 'nice x abc def', quote: '"' },
			}
		containedText: 'a paragraph',
		}

	tester.test 84, 'img href="file.ext" alt="a description"  ', {
		tag: 'img',
		hAttr: {
			href: { value: 'file.ext', quote: '"' },
			alt:  { value: 'a description', quote: '"' },
			}
		}

	tester.test 92, 'h1 class="desc" The syntax is nice', {
		tag: 'h1',
		hAttr: {
			class: { value: 'desc', quote: '"' },
			},
		containedText: 'The syntax is nice',
		}

	tester.test 100, 'h1.desc The syntax is nice', {
		tag: 'h1',
		hAttr: {
			class: { value: 'desc', quote: '"' },
			},
		containedText: 'The syntax is nice',
		}

	tester.test 108, 'div:markdown', {
		tag: 'div',
		subtype: 'markdown',
		hAttr: {
			class: { value: 'markdown', quote: '"' },
			},
		}

	tester.test 116, 'div:markdown.desc # Title', {
		tag: 'div',
		subtype: 'markdown',
		hAttr: {
			class: { value: 'markdown desc', quote: '"' },
			},
		containedText: '# Title',
		}
	)()

# ---------------------------------------------------------------------------

(() ->

	class TagTester2 extends AvaTester

		transformValue: (input) ->
			return tag2str(input)

	tester = new TagTester2()

	tester.test 137, {
			tag: 'p',
			}, "<p>"

	tester.test 141, {
			tag: 'p',
			hAttr: {
				class: { value: 'error', quote: '"' },
				},
			}, '<p class="error">'

	)()

# ---------------------------------------------------------------------------
