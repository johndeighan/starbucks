# parsetag.test.coffee

import {UnitTesterNorm, simple} from '@jdeighan/unit-tester'
import {undef} from '@jdeighan/coffee-utils'

import {parsetag, tag2str} from '@jdeighan/starbucks/parsetag'

# ---------------------------------------------------------------------------

(() ->

	class TagTester extends UnitTesterNorm

		transformValue: (input) ->
			return parsetag(input)

	tester = new TagTester()

	tester.equal 19, 'p', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		}

	tester.equal 25, 'p.class1', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			class: {value: 'class1', quote: '"'},
			}
		}

	tester.equal 34, 'p.class1.class2', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			class: {value: 'class1 class2', quote: '"' }
			}
		}

	tester.equal 43, 'p border=yes', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			border: {value: 'yes', quote: '' }
			}
		}

	tester.equal 52, 'p bind:border={var}', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			'bind:border': {value: 'var', quote: '{' }
			}
		}

	tester.equal 61, 'myCanvas = canvas width=32 height=32', {
		type: 'tag'
		tagName: 'canvas'
		fulltag: 'canvas'
		hAttr: {
			width:  {value: '32', quote: '' }
			height: {value: '32', quote: '' }
			'bind:this': {value: 'myCanvas', quote: '{'}
			}
		}

	tester.equal 72, 'p border="yes"', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			border: { value: 'yes', quote: '"' }
			}
		}

	tester.equal 81, "p border='yes'", {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			border: {value: 'yes', quote: "'" }
			}
		}

	tester.equal 90, 'p border="yes" this is a paragraph', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			border: { value: 'yes', quote: '"' }
			}
		text: 'this is a paragraph'
		}

	tester.equal 100, 'p border="yes" "this is a paragraph"', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			border: { value: 'yes', quote: '"' }
			}
		text: 'this is a paragraph'
		}

	tester.equal 110, 'p.nice.x border=yes class="abc def" "a paragraph"', {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			border: { value: 'yes', quote: '' }
			class:  { value: 'nice x abc def', quote: '"' }
			}
		text: 'a paragraph'
		}

	tester.equal 121, 'img href="file.ext" alt="a description"  ', {
		type: 'tag'
		tagName: 'img'
		fulltag: 'img'
		hAttr: {
			href: { value: 'file.ext', quote: '"' }
			alt:  { value: 'a description', quote: '"' }
			}
		}

	tester.equal 131, 'h1 class="desc" The syntax is nice', {
		type: 'tag'
		tagName: 'h1'
		fulltag: 'h1'
		hAttr: {
			class: { value: 'desc', quote: '"' }
			},
		text: 'The syntax is nice'
		}

	tester.equal 141, 'h1.desc The syntax is nice', {
		type: 'tag'
		tagName: 'h1'
		fulltag: 'h1'
		hAttr: {
			class: { value: 'desc', quote: '"' }
			},
		text: 'The syntax is nice'
		}

	tester.equal 151, 'div:markdown', {
		type: 'tag'
		tagName: 'div'
		subtype: 'markdown'
		fulltag: 'div:markdown'
		hAttr: {
			class: { value: 'markdown', quote: '"' }
			},
		}

	tester.equal 161, 'div:markdown.desc # Title', {
		type: 'tag'
		tagName: 'div'
		subtype: 'markdown'
		fulltag: 'div:markdown'
		hAttr: {
			class: { value: 'markdown desc', quote: '"' }
			},
		text: '# Title'
		}

	tester.equal 172, 'svelte:head', {
		type: 'tag'
		subtype: 'head'
		tagName: 'svelte:head'
		fulltag: 'svelte:head'
		}

	tester.equal 178, 'img {src} alt="dance"', {
		type: 'tag'
		tagName: 'img'
		fulltag: 'img'
		hAttr: {
			src: {shorthand: true, value: 'src'}
			alt: {value: 'dance', quote: '"'}
			}
		}

	)()

# ---------------------------------------------------------------------------

(() ->

	class TagTester extends UnitTesterNorm

		transformValue: (input) ->
			return tag2str(input)

	tester = new TagTester()

	tester.equal 201, {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		}, "<p>"

	tester.equal 207, {
		type: 'tag',
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			class: { value: 'error', quote: '"' }
			}
		}, '<p class="error">'

	tester.equal 216, {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			class: { value: 'myclass', quote: '{' }
			}
		}, '<p class={myclass}>'

	tester.equal 225, {
		type: 'tag'
		tagName: 'svelte:head'
		fulltag: 'svelte:head'
		}, '<svelte:head>'

	tester.equal 231, {
		type: 'tag'
		tagName: 'img'
		fulltag: 'img'
		hAttr: {
			src: {shorthand: true, value: 'src'}
			alt: {value: 'dance', quote: '"'}
			}
		}, '<img {src} alt="dance">'

	)()

# ---------------------------------------------------------------------------
# --- Test end tags

(() ->

	class TagTester extends UnitTesterNorm

		transformValue: (input) ->
			return tag2str(input, 'end')

	tester = new TagTester()

	tester.equal 255, {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		}, "</p>"

	tester.equal 261, {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			class: { value: 'error', quote: '"' }
			}
		}, '</p>'

	tester.equal 270, {
		type: 'tag'
		tagName: 'p'
		fulltag: 'p'
		hAttr: {
			class: { value: 'myclass', quote: '{' }
			}
		}, '</p>'

	tester.equal 279, {
		type: 'tag'
		tagName: 'svelte:head'
		fulltag: 'svelte:head'
		}, '</svelte:head>'

	)()
