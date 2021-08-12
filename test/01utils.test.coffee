# 01utils.test.coffee

import {say,
	normalize,
	debug,
	setDebugging,
	setUnitTesting,
	} from '@jdeighan/coffee-utils'
import {svelteSourceCodeEsc, svelteHtmlEsc} from '../src/svelte_utils.js'
import {AvaTester} from '@jdeighan/ava-tester'

setUnitTesting(true)
tester = new AvaTester()

# ---------------------------------------------------------------------------

tester.equal 17, svelteSourceCodeEsc("{key: value}"), "&lbrace;key: value&rbrace;"
tester.equal 18, svelteSourceCodeEsc("<p>yes</p>"), "&lt;p&gt;yes&lt;/p&gt;"
tester.equal 19, svelteSourceCodeEsc("$100"), "&dollar;100"

# ---------------------------------------------------------------------------

tester.equal 23, svelteHtmlEsc("{key: value}"), "&lbrace;key: value&rbrace;"
tester.equal 24, svelteHtmlEsc("<p>yes</p>"), "<p>yes</p>"
tester.equal 25, svelteHtmlEsc("$100"), "&dollar;100"

# ---------------------------------------------------------------------------
