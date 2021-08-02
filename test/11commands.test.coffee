# 11commands.test.coffee

import {tester} from './15starbucks.test.js'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

tester.equal 9, """
		#starbucks component

		#const company = WayForward Technologies

		p by {{company}}
		""", """
		<p>
			by WayForward Technologies
		</p>
		"""

# ---------------------------------------------------------------------------

tester.equal 23, """
		#starbucks component

		#if n==0
			p there are no items
		#else
			p there are some items
		""", """
		{#if n==0}
			<p>
				there are no items
			</p>
		{:else}
			<p>
				there are some items
			</p>
		{/if}
		"""

