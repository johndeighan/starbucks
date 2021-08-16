# 09StarbucksMapper.test.coffee

import {StarbucksInput} from '../src/StarbucksInput.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {setUnitTesting} from '@jdeighan/coffee-utils'

setUnitTesting(true)

# ---------------------------------------------------------------------------

class MapperTester extends AvaTester

	transformValue: (text) ->
		oInput = new StarbucksInput(text)
		return oInput.get()

tester = new MapperTester()

# ---------------------------------------------------------------------------
# --- Test basic mapping

# --- Expected should be result of mapping 1st line in the string
#     which may result in additional lines being consumed

tester.equal 25, """
		nav
		h1
		p
		""", {
			tag: 'nav',
			type: 'tag',
			level: 0, lineNum: 1, line: 'nav',
			}

tester.equal 35, """
		#if x==5
			h1
				p
		""", {
			type:  'cmd',
			cmd:   'if',
			argstr: 'x==5'
			level: 0, lineNum: 1, line: '#if x==5',
			}

# ---------------------------------------------------------------------------
# --- Test script handling

tester.equal 49, """
		script
			x = 23
			parse(this)
		footer the end
		""", {
			type:  'tag',
			tag:   'script',
			blockText: 'x = 23\nparse(this)\n',
			level: 0, lineNum: 1, line: 'script',
			}

# ---------------------------------------------------------------------------
# --- Test startup handling

tester.equal 64, """
		script:startup
			x = 23
			parse(this)
		footer the end
		""", {
			type:    'tag',
			tag:     'script',
			subtype: 'startup',
			hAttr: {
				context: { value: 'module', quote: '"' },
				},
			blockText: 'x = 23\nparse(this)\n',
			level: 0, lineNum: 1, line: 'script:startup',
			}

# ---------------------------------------------------------------------------
# --- Test onmount handling

tester.equal 83, """
		script:onmount
			x = 23
			parse(this)
		footer the end
		""", {
			type:    'tag',
			tag:     'script',
			subtype: 'onmount',
			blockText: 'x = 23\nparse(this)\n',
			level: 0, lineNum: 1, line: 'script:onmount',
			}

# ---------------------------------------------------------------------------
# --- Test ondestroy handling

tester.equal 99, """
		script:ondestroy
			x = 23
			parse(this)
		footer the end
		""", {
			type:    'tag',
			tag:     'script',
			subtype: 'ondestroy',
			blockText: 'x = 23\nparse(this)\n',
			level: 0, lineNum: 1, line: 'script:ondestroy',
			}

# ---------------------------------------------------------------------------
# --- Test style handling

tester.equal 115, """
		style
			p
				color:red
		footer the end
		""", {
			type:  'tag',
			tag:   'style',
			blockText: 'p\n\tcolor:red\n',
			level: 0, lineNum: 1, line: 'style',
			}
