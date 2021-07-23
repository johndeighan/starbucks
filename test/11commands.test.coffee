# commands.test.coffee

import {say, undef} from '../coffee_utils.js'
import {test_parser, show_only} from './test_utils.js'

# ---------------------------------------------------------------------------

test_parser 9, """
		#starbucks component

		#const company = WayForward Technologies

		p by {{company}}
		""", """
		<p>
			by WayForward Technologies
		</p>
		"""

# ---------------------------------------------------------------------------

test_parser 23, """
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

