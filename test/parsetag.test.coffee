# parsetag.test.coffee

import {UnitTester} from '@jdeighan/unit-tester'
import {undef} from '@jdeighan/coffee-utils'
import {parsetag, tag2str} from '@jdeighan/starbucks/parser'

# ---------------------------------------------------------------------------

(() ->

	class TagTester extends UnitTester

		transformValue: (input) ->
			return parsetag(input)

	tester = new TagTester()

	tester.test 18, 'p', {
		type: 'tag',
		tag: 'p',
		}

	tester.test 23, 'p.class1', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: {value: 'class1', quote: '"'},
			}
		}

	tester.test 31, 'p.class1.class2', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: {value: 'class1 class2', quote: '"' },
			}
		}

	tester.test 39, 'p border=yes', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: {value: 'yes', quote: '' },
			}
		}

	tester.test 47, 'p bind:border={var}', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			'bind:border': {value: 'var', quote: '{' },
			}
		}

	tester.test 55, 'myCanvas = canvas width=32 height=32', {
		type: 'tag',
		tag: 'canvas',
		hAttr: {
			width:  {value: '32', quote: '' },
			height: {value: '32', quote: '' },
			'bind:this': {value: 'myCanvas', quote: '{'},
			}
		}

	tester.test 65, 'p border="yes"', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		}

	tester.test 73, "p border='yes'", {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: {value: 'yes', quote: "'" },
			}
		}

	tester.test 81, 'p border="yes" this is a paragraph', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		containedText: 'this is a paragraph',
		}

	tester.test 90, 'p border="yes" "this is a paragraph"', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		containedText: 'this is a paragraph',
		}

	tester.test 99, 'p.nice.x border=yes class="abc def" "a paragraph"', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '' },
			class:  { value: 'nice x abc def', quote: '"' },
			}
		containedText: 'a paragraph',
		}

	tester.test 109, 'img href="file.ext" alt="a description"  ', {
		type: 'tag',
		tag: 'img',
		hAttr: {
			href: { value: 'file.ext', quote: '"' },
			alt:  { value: 'a description', quote: '"' },
			}
		}

	tester.test 118, 'h1 class="desc" The syntax is nice', {
		type: 'tag',
		tag: 'h1',
		hAttr: {
			class: { value: 'desc', quote: '"' },
			},
		containedText: 'The syntax is nice',
		}

	tester.test 127, 'h1.desc The syntax is nice', {
		type: 'tag',
		tag: 'h1',
		hAttr: {
			class: { value: 'desc', quote: '"' },
			},
		containedText: 'The syntax is nice',
		}

	tester.test 136, 'div:markdown', {
		type: 'tag',
		tag: 'div',
		subtype: 'markdown',
		hAttr: {
			class: { value: 'markdown', quote: '"' },
			},
		}

	tester.test 145, 'div:markdown.desc # Title', {
		type: 'tag',
		tag: 'div',
		subtype: 'markdown',
		hAttr: {
			class: { value: 'markdown desc', quote: '"' },
			},
		containedText: '# Title',
		}

	tester.test 155, 'svelte:head', {
		type: 'tag',
		tag: 'svelte:head',
		}

	)()

# ---------------------------------------------------------------------------

(() ->

	class TagTester2 extends UnitTester

		transformValue: (input) ->
			return tag2str(input)

	tester = new TagTester2()

	tester.test 173, {
		type: 'tag',
		tag: 'p',
		}, "<p>"

	tester.test 178, {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: { value: 'error', quote: '"' },
			},
		}, '<p class="error">'

	tester.test 186, {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: { value: 'myclass', quote: '{' },
			},
		}, '<p class={myclass}>'

	tester.test 194, {
		type: 'tag',
		tag: 'svelte:head',
		}, '<svelte:head>'

	)()

# ---------------------------------------------------------------------------
