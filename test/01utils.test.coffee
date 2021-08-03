# 01utils.test.coffee

import {say, normalize, debug, setDebugging} from '@jdeighan/coffee-utils'
import {svelteSourceCodeEsc, svelteHtmlEsc} from '../src/svelte_utils.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

tester = new AvaTester()

# ---------------------------------------------------------------------------

tester.equal 12, svelteSourceCodeEsc("{key: value}"), "&lbrace;key: value&rbrace;"
tester.equal 13, svelteSourceCodeEsc("<p>yes</p>"), "&lt;p&gt;yes&lt;/p&gt;"
tester.equal 14, svelteSourceCodeEsc("$100"), "&dollar;100"

# ---------------------------------------------------------------------------

tester.equal 12, svelteHtmlEsc("{key: value}"), "&lbrace;key: value&rbrace;"
tester.equal 13, svelteHtmlEsc("<p>yes</p>"), "<p>yes</p>"
tester.equal 14, svelteHtmlEsc("$100"), "&dollar;100"

# ---------------------------------------------------------------------------
