# callbacks.test.coffee

import {
	say, undef, pass, error,
	escapeStr, setUnitTesting,
	} from '@jdeighan/coffee-utils'
import {setDebugging, debugging} from '@jdeighan/coffee-utils/debug'
import {AvaTester} from '@jdeighan/ava-tester'
import {getHooks, clearTrace, getTrace} from './CallbackHooks.js'
import {StarbucksParser, attrStr} from '@jdeighan/starbucks/parser'
import {StarbucksTreeWalker} from '@jdeighan/starbucks/walker'
import {SvelteOutput} from '@jdeighan/svelte-output'

# ---------------------------------------------------------------------------

class WalkerTester extends AvaTester

	# --- If debugging is set, we only want it on for parse()

	transformValue: (text) ->

		clearTrace()
		parser = new StarbucksParser(text, new SvelteOutput())
		tree = parser.getTree()
		walker = new StarbucksTreeWalker(getHooks())
		walker.walk(tree)
		return getTrace()

tester = new WalkerTester()

# ---------------------------------------------------------------------------

tester.equal 33, """
		#starbucks webpage
		nav
		""", """
		[0] STARBUCKS webpage
		[0] TAG <nav>
		[0] END_TAG </nav>
		"""

# ---------------------------------------------------------------------------

tester.equal 44, """
		#starbucks webpage
		div
		nav
		""", """
		[0] STARBUCKS webpage
		[0] TAG <div>
		[0] END_TAG </div>
		[0] TAG <nav>
		[0] END_TAG </nav>
		"""

# ---------------------------------------------------------------------------

tester.equal 58, """
		#starbucks webpage
		div
			nav
		""", """
		[0] STARBUCKS webpage
		[0] TAG <div>
		[1] TAG <nav>
		[1] END_TAG </nav>
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------

tester.equal 72, """
		#starbucks webpage
		div
			nav
			h1 page title
		""", """
		[0] STARBUCKS webpage
		[0] TAG <div>
		[1] TAG <nav>
		[1] END_TAG </nav>
		[1] TAG <h1>
		[2] CHARS 'page title'
		[1] END_TAG </h1>
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
# test startup section

tester.equal 91, """
		#starbucks webpage
		div
		script:startup
			meaning = 42
		""", """
		[0] STARBUCKS webpage
		[0] TAG <div>
		[0] END_TAG </div>
		[0] STARTUP 'meaning = 42'
		"""

# ---------------------------------------------------------------------------
# test skipping blank lines

tester.equal 106, """
		#starbucks webpage

		div
			nav

			h1 page title

		""", """
		[0] STARBUCKS webpage
		[0] TAG <div>
		[1] TAG <nav>
		[1] END_TAG </nav>
		[1] TAG <h1>
		[2] CHARS 'page title'
		[1] END_TAG </h1>
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
# Test '#envvar'

tester.equal 128, """
		#starbucks webpage
		#envvar name = 'John'
		""", """
		[0] STARBUCKS webpage
		[0] CMD #envvar name = 'John'
		"""

# ---------------------------------------------------------------------------
# Test '#if'

tester.equal 139, """
		#starbucks webpage
		#if n==0
			p nothing
		#elsif n==1
			p one
		#else
			div
		""", """
		[0] STARBUCKS webpage
		[0] CMD #if n==0
		[1] TAG <p>
		[2] CHARS 'nothing'
		[1] END_TAG </p>
		[0] CMD #elsif n==1
		[1] TAG <p>
		[2] CHARS 'one'
		[1] END_TAG </p>
		[0] CMD #else
		[1] TAG <div>
		[1] END_TAG </div>
		[0] END_CMD #if
		"""

# ---------------------------------------------------------------------------
# Test '#for'

tester.equal 166, """
		#starbucks webpage
		#for name,i in lNames (key=id)
			p {name}
		""", """
		[0] STARBUCKS webpage
		[0] CMD #for name,i in lNames (key=id)
		[1] TAG <p>
		[2] CHARS '{name}'
		[1] END_TAG </p>
		[0] END_CMD #for
		"""

# ---------------------------------------------------------------------------
# Test '#await'

tester.equal 182, """
		#starbucks webpage
		#await fetch('http://virus.stats.com/')
			p ...please wait
		#then data
			Graph data={data}
		#catch err
			#log err
		p Done
		""", """
		[0] STARBUCKS webpage
		[0] CMD #await fetch('http://virus.stats.com/')
		[1] TAG <p>
		[2] CHARS '...please wait'
		[1] END_TAG </p>
		[0] CMD #then data
		[1] TAG <Graph data={data}>
		[1] END_TAG </Graph>
		[0] CMD #catch err
		[1] CMD #log err
		[0] END_CMD #await
		[0] TAG <p>
		[1] CHARS 'Done'
		[0] END_TAG </p>
		"""

# ---------------------------------------------------------------------------
