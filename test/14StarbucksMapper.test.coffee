# 14StarbucksMapper.test.coffee

import {StarbucksMapper, StarbucksInput} from '../src/StarbucksInput.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class MapperTester extends AvaTester

	transformValue: (input) ->
		oInput = new StarbucksInput(input)
		line = oInput.fetch()
		return StarbucksMapper(line, oInput)

tester = new MapperTester()

# ---------------------------------------------------------------------------
# --- Test basic mapping

# --- Expected should be result of mapping 1st line in the string
#     which may result in additional lines being consumed

tester.equal 23, """
		nav
		h1
		p
		""", {
			tag: 'nav',
			type: 'tag',
			level: 0, lineNum: 1, line: 'nav',
			}

tester.equal 33, """
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

tester.equal 47, """
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

tester.equal 62, """
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

tester.equal 81, """
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

tester.equal 97, """
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

tester.equal 113, """
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
