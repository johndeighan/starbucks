# 01utils.test.coffee

import {AvaTester} from '@jdeighan/ava-tester'
import {say, normalize, setUnitTesting} from '@jdeighan/coffee-utils'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {
	svelteSourceCodeEsc,
	svelteHtmlEsc,
	} from '@jdeighan/coffee-utils/svelte'

setUnitTesting(true)
tester = new AvaTester()

# ---------------------------------------------------------------------------

tester.equal 13, svelteSourceCodeEsc("{key: value}"), "&lbrace;key: value&rbrace;"
tester.equal 14, svelteSourceCodeEsc("<p>yes</p>"), "&lt;p&gt;yes&lt;/p&gt;"
tester.equal 15, svelteSourceCodeEsc("$100"), "&dollar;100"

# ---------------------------------------------------------------------------

tester.equal 19, svelteHtmlEsc("{key: value}"), "&lbrace;key: value&rbrace;"
tester.equal 20, svelteHtmlEsc("<p>yes</p>"), "<p>yes</p>"
tester.equal 21, svelteHtmlEsc("$100"), "&dollar;100"

# ---------------------------------------------------------------------------
