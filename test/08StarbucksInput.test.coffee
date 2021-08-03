# 13StarbucksInput.test.coffee

import {say, undef, setUnitTesting} from '@jdeighan/coffee-utils'
import {StarbucksInput, getFileContents} from '../src/StarbucksInput.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# --- Test the real starbucks mapper, with:
#        - skips blank lines and comments
#        - handles continuation lines
#        - handles HEREDOCs
#        - returns one of:
#           { type: 'cmd',
#             cmd: <cmd>,
#             argstr: <argstr>,
#             level: <n>,
#             line: <text>,
#             lineNum: <n>,
#             }
#           { type: 'text',
#             text: <text>,
#             level: <n>,
#             line: <text>,
#             lineNum: <n>,
#             }
#           { type: 'tag',
#             tag: <tag>
#             attrstr: <string>,        # only if non-empty
#             containedText: <text>,    # only if non-empty
#             level: <n>,
#             line: <text>,
#             lineNum: <n>,
#             }
# --- The following tags should include all following, indented text
#     in containedText:
#
#        script
#        style
#        pre
#        div:markdown
#        div:sourcecode

setUnitTesting(true)
simple = new AvaTester()

# ---------------------------------------------------------------------------

class GatherTester extends AvaTester

	transformValue: (input) ->
		if input not instanceof StarbucksInput
			throw new Error("input should be a StarbucksInput object")
		lLines = []
		line = input.get()
		while line?
			lLines.push(line)
			line = input.get()
		return lLines

tester = new GatherTester()

# ---------------------------------------------------------------------------

# --- Test basic reading till EOF

tester.equal 66, new StarbucksInput("""
		nav
		h1
		p
		"""), [
		{
			type: 'tag',
			tag: 'nav',
			level: 0,
			lineNum: 1,
			line: 'nav',
			},
		{
			type: 'tag',
			tag: 'h1',
			level: 0,
			lineNum: 2,
			line: 'h1',
			}
		{
			type: 'tag',
			tag: 'p',
			level: 0,
			lineNum: 3,
			line: 'p',
			}
		]

# ---------------------------------------------------------------------------

# --- Test line number handling

(()->
	tester.equal 99, new StarbucksInput("""
			nav

			h1
			"""), [
			{
				type: 'tag',
				tag: 'nav',
				level: 0,
				lineNum: 1,
				line: 'nav',
				},
			{
				type: 'tag',
				tag: 'h1',
				level: 0,
				lineNum: 3,
				line: 'h1',
				}
			]

	)()

# ---------------------------------------------------------------------------

(()->

	tester.equal 126, new StarbucksInput("""
			Nav

			# --- decide whether to display an h1 or a p

			#if x==y
				h1 lower(<<<)
					this is
					a title

			#else
				p
						a long
						paragraph

			footer Done

			"""), [
			{
				type: 'tag',
				tag: 'Nav',
				level: 0,
				lineNum: 1,
				line: 'Nav',
				},
			{
				type: 'cmd',
				cmd: 'if',
				argstr: 'x==y',
				level: 0,
				lineNum: 5,
				line: '#if x==y',
				},
			{
				type: 'tag',
				tag: 'h1',
				containedText: 'lower("this is\\na title\\n")',
				level: 1,
				lineNum: 6,
				line: 'h1 lower("this is\\na title\\n")',
				},
			{
				type: 'cmd',
				cmd: 'else',
				level: 0,
				lineNum: 10,
				line: '#else',
				},
			{
				type: 'tag',
				tag: 'p',
				containedText: 'a long paragraph',
				level: 1,
				lineNum: 11,
				line: 'p a long paragraph',
				},
			{
				type: 'tag',
				tag: 'footer',
				containedText: 'Done',
				level: 0,
				lineNum: 15,
				line: 'footer Done',
				},
			]
	)()

# ---------------------------------------------------------------------------

(()->

	content = """
			header
				h1 this is a title
			main
				p this is a paragraph
			"""

	tester.equal 204, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'header',
			level: 0,
			lineNum: 1,
			line: 'header',
			}
		{
			type: 'tag',
			tag: 'h1',
			containedText: 'this is a title',
			level: 1,
			lineNum: 2,
			line: 'h1 this is a title',
			}
		{
			type: 'tag',
			tag: 'main',
			level: 0,
			lineNum: 3,
			line: 'main',
			}
		{
			type: 'tag',
			tag: 'p',
			containedText: 'this is a paragraph',
			level: 1,
			lineNum: 4,
			line: 'p this is a paragraph',
			}
		]

	)()

# ---------------------------------------------------------------------------

(()->

	content = """
			main
				slot
			style
				nav
					overflow: auto
			"""
	tester.equal 250, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'main',
			level: 0,
			line: 'main',
			lineNum: 1,
			},
		{
			type: 'tag',
			tag: 'slot',
			level: 1,
			line: 'slot',
			lineNum: 2,
			},
		{
			type: 'tag',
			tag: 'style',
			level: 0,
			line: 'style',
			lineNum: 3,
			blockText: 'nav\n\toverflow: auto\n'
			}
		]

	)()

# ---------------------------------------------------------------------------
# test onmount handler

(()->

	content = """
			main
				slot
			script:onmount
				x = 23
			"""
	tester.equal 288, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'main',
			level: 0,
			line: 'main',
			lineNum: 1,
			},
		{
			type: 'tag',
			tag: 'slot',
			level: 1,
			line: 'slot',
			lineNum: 2,
			},
		{
			type: 'tag',
			tag: 'script',
			subtype: 'onmount',
			level: 0,
			line: 'script:onmount',
			lineNum: 3,
			blockText: 'x = 23\n'
			}
		]

	)()

# ---------------------------------------------------------------------------
# test ondestroy handler

(()->

	content = """
			main
				slot
			script:ondestroy
				x = 23
			"""
	tester.equal 327, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'main',
			level: 0,
			line: 'main',
			lineNum: 1,
			},
		{
			type: 'tag',
			tag: 'slot',
			level: 1,
			line: 'slot',
			lineNum: 2,
			},
		{
			type: 'tag',
			tag: 'script',
			subtype: 'ondestroy',
			level: 0,
			line: 'script:ondestroy',
			lineNum: 3,
			blockText: 'x = 23\n'
			}
		]

	)()

# ---------------------------------------------------------------------------
# test pre

(()->

	content = """
			pre
				line1
				line2
			"""
	tester.equal 365, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'pre',
			level: 0,
			line: 'pre',
			lineNum: 1,
			blockText: 'line1\nline2\n'
			}
		]

	)()

# ---------------------------------------------------------------------------
# test div:markdown

(()->

	content = """
			div:markdown
				line1
				line2
			"""
	tester.equal 388, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'div',
			subtype: 'markdown',
			hAttr: {
				class: {value: 'markdown', quote: '"' }
				}
			level: 0,
			line: 'div:markdown',
			lineNum: 1,
			blockText: 'line1\nline2\n'
			}
		]

	)()

# ---------------------------------------------------------------------------
# test div:sourcecode

(()->

	content = """
			div:sourcecode
				line1
				line2
			"""
	tester.equal 415, new StarbucksInput(content), [
		{
			type: 'tag',
			tag: 'div',
			subtype: 'sourcecode'
			level: 0,
			line: 'div:sourcecode',
			lineNum: 1,
			blockText: 'line1\nline2\n'
			}
		]

	)()

# ---------------------------------------------------------------------------
# test getFileContents

simple.equal 432, getFileContents('title.md'), "Contents of title.md"
simple.fails 433, () -> getFileContents('title.txt')

setUnitTesting(false)
simple.equal 436, getFileContents('title.md'), "title\n=====\n"
setUnitTesting(true)