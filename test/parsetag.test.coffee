# parsetag.test.coffee

import {AvaTester} from '@jdeighan/ava-tester'
import {setUnitTesting} from '@jdeighan/coffee-utils'
import {parsetag, tag2str} from '@jdeighan/starbucks/parser'

setUnitTesting(true)

# ---------------------------------------------------------------------------

(() ->

	class TagTester extends AvaTester

		transformValue: (input) ->
			return parsetag(input)

	tester = new TagTester()

	tester.test 20, 'p', {
		type: 'tag',
		tag: 'p',
		}

	tester.test 25, 'p.class1', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: {value: 'class1', quote: '"'},
			}
		}

	tester.test 33, 'p.class1.class2', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: {value: 'class1 class2', quote: '"' },
			}
		}

	tester.test 41, 'p border=yes', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: {value: 'yes', quote: '' },
			}
		}

	tester.test 49, 'p bind:border={var}', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			'bind:border': {value: 'var', quote: '{' },
			}
		}

	tester.test 57, 'myCanvas = canvas width=32 height=32', {
		type: 'tag',
		tag: 'canvas',
		hAttr: {
			width:  {value: '32', quote: '' },
			height: {value: '32', quote: '' },
			'bind:this': {value: 'myCanvas', quote: '{'},
			}
		}

	tester.test 67, 'p border="yes"', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		}

	tester.test 75, "p border='yes'", {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: {value: 'yes', quote: "'" },
			}
		}

	tester.test 83, 'p border="yes" this is a paragraph', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		containedText: 'this is a paragraph',
		}

	tester.test 92, 'p border="yes" "this is a paragraph"', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '"' },
			}
		containedText: 'this is a paragraph',
		}

	tester.test 101, 'p.nice.x border=yes class="abc def" "a paragraph"', {
		type: 'tag',
		tag: 'p',
		hAttr: {
			border: { value: 'yes', quote: '' },
			class:  { value: 'nice x abc def', quote: '"' },
			}
		containedText: 'a paragraph',
		}

	tester.test 111, 'img href="file.ext" alt="a description"  ', {
		type: 'tag',
		tag: 'img',
		hAttr: {
			href: { value: 'file.ext', quote: '"' },
			alt:  { value: 'a description', quote: '"' },
			}
		}

	tester.test 120, 'h1 class="desc" The syntax is nice', {
		type: 'tag',
		tag: 'h1',
		hAttr: {
			class: { value: 'desc', quote: '"' },
			},
		containedText: 'The syntax is nice',
		}

	tester.test 129, 'h1.desc The syntax is nice', {
		type: 'tag',
		tag: 'h1',
		hAttr: {
			class: { value: 'desc', quote: '"' },
			},
		containedText: 'The syntax is nice',
		}

	tester.test 138, 'div:markdown', {
		type: 'tag',
		tag: 'div',
		subtype: 'markdown',
		hAttr: {
			class: { value: 'markdown', quote: '"' },
			},
		}

	tester.test 147, 'div:markdown.desc # Title', {
		type: 'tag',
		tag: 'div',
		subtype: 'markdown',
		hAttr: {
			class: { value: 'markdown desc', quote: '"' },
			},
		containedText: '# Title',
		}

	tester.test 157, 'svelte:head', {
		type: 'tag',
		tag: 'svelte:head',
		}

	)()

# ---------------------------------------------------------------------------

(() ->

	class TagTester2 extends AvaTester

		transformValue: (input) ->
			return tag2str(input)

	tester = new TagTester2()

	tester.test 175, {
		type: 'tag',
		tag: 'p',
		}, "<p>"

	tester.test 180, {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: { value: 'error', quote: '"' },
			},
		}, '<p class="error">'

	tester.test 188, {
		type: 'tag',
		tag: 'p',
		hAttr: {
			class: { value: 'myclass', quote: '{' },
			},
		}, '<p class={myclass}>'

	tester.test 196, {
		type: 'tag',
		tag: 'svelte:head',
		}, '<svelte:head>'

	)()

# ---------------------------------------------------------------------------
