# StarbucksMapper.test.coffee

import {test_mapper} from './test_utils.js'

# ---------------------------------------------------------------------------
# --- Test basic mapping

# --- Expected should be result of mapping 1st line in the string
#     which may result in additional lines being consumed

test_mapper 11, """
		nav
		h1
		p
		""", {
			tag: 'nav',
			type: 'tag',
			level: 0, lineNum: 1, line: 'nav',
			}

test_mapper 21, """
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

test_mapper 35, """
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

test_mapper 50, """
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

test_mapper 69, """
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

test_mapper 85, """
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

test_mapper 101, """
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
