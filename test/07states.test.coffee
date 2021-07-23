# states.test.coffee

import test from 'ava'
import {say, undef} from '../coffee_utils.js'
import {test_states, show_only} from './test_utils.js'

# ---------------------------------------------------------------------------

test_states 9, """
		#if x==3
		#elsif x==4
		#else
		""", """
		{#if x==3}
		{:else if x==4}
		{:else}
		{/if}
		"""

# ---------------------------------------------------------------------------
# NOTE: When no expected string is supplied, we expect an error

test_states 23, """
		#if x==3
		#elsif x==4
		#else
		#else
		"""

# ---------------------------------------------------------------------------

test_states 32, """
		#if x==3
			h1
		#elsif x==4
			h2
		#else
			p
		""", """
		{#if x==3}
			h1
		{:else if x==4}
			h2
		{:else}
			p
		{/if}
		"""

# ---------------------------------------------------------------------------

test_states 51, """
		#if x==3
		#elsif x==4
		#else
		#if x==33
		#elsif x==44
		#else
		""", """
		{#if x==3}
		{:else if x==4}
		{:else}
		{/if}
		{#if x==33}
		{:else if x==44}
		{:else}
		{/if}
		"""

# ---------------------------------------------------------------------------

test_states 71, """
		#if x==3
			#if x==33
			#elsif x==44
		#elsif x==4
			#if x==33
			#else
		#else
			#if x==33
			#else
		""", """
		{#if x==3}
			{#if x==33}
			{:else if x==44}
			{/if}
		{:else if x==4}
			{#if x==33}
			{:else}
			{/if}
		{:else}
			{#if x==33}
			{:else}
			{/if}
		{/if}
		"""

# ---------------------------------------------------------------------------

test_states 99, """
		#for x in lItems
			p paragraph
		""", """
		{#each lItems as x}
			p paragraph
		{/each}
		"""

# ---------------------------------------------------------------------------

test_states 110, """
		#for x,i in lItems
			p paragraph
		""", """
		{#each lItems as x,i}
			p paragraph
		{/each}
		"""

# ---------------------------------------------------------------------------

test_states 121, """
		#for x in lItems (key=id)
			p paragraph
		""", """
		{#each lItems as x (id)}
			p paragraph
		{/each}
		"""

# ---------------------------------------------------------------------------

test_states 132, """
		#await promise = sql('select name from users')
			p please wait
		#then result
			p result
		#catch err
			p err
		""", """
		{#await promise = sql('select name from users')}
			p please wait
		{:then result}
			p result
		{:catch err}
			p err
		{/await}
		"""

# ---------------------------------------------------------------------------
