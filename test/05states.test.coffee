# 05states.test.coffee

import {say, undef, nonEmpty, setUnitTesting} from '@jdeighan/coffee-utils'
import {StarbucksInput} from '../src/StarbucksInput.js'
import {SvelteOutput} from '@jdeighan/svelte-output'
import {foundCmd, finished} from '../src/starbucks_commands.js'
import {AvaTester} from '@jdeighan/ava-tester'

setUnitTesting(true)

# ---------------------------------------------------------------------------

procLevel = (atLevel, oInput, oOutput) ->

	while hToken = oInput.peek()
		{level, line, lineNum, type, cmd, argstr} = hToken
		if (level > atLevel)
			procLevel level, oInput, oOutput
		else
			oInput.skip()
			switch type
				when 'cmd'
					foundCmd cmd, argstr, level, oOutput
				when 'text'
					oOutput.put indentedStr(line, level)
				when 'tag'
					oOutput.put line
				else
					error "procLevel(): empty type"
	return

# ---------------------------------------------------------------------------

class StatesTester extends AvaTester

	transformValue: (text) ->

		oInput = new StarbucksInput(text)
		oOutput = new SvelteOutput()
		text = procLevel(0, oInput, oOutput)
		if nonEmpty(text)
			oOutput.put(text)
		finished(oOutput)
		return oOutput.get()

tester = new StatesTester()

# ---------------------------------------------------------------------------

tester.equal 50, """
		#if x==3
		#elsif x==4
		#else
		""", """
		{#if x==3 }
		{:else if x==4 }
		{:else}
		{/if}
		"""

# ---------------------------------------------------------------------------
# NOTE: When no expected string is supplied, we expect an error

tester.fails 64, """
		#if x==3
		#elsif x==4
		#else
		#else
		"""

# ---------------------------------------------------------------------------

tester.equal 73, """
		#if x==3
			h1
		#elsif x==4
			h2
		#else
			p
		""", """
		{#if x==3 }
			h1
		{:else if x==4 }
			h2
		{:else}
			p
		{/if}
		"""

# ---------------------------------------------------------------------------

tester.equal 92, """
		#if x==3
		#elsif x==4
		#else
		#if x==33
		#elsif x==44
		#else
		""", """
		{#if x==3 }
		{:else if x==4 }
		{:else}
		{/if}
		{#if x==33 }
		{:else if x==44 }
		{:else}
		{/if}
		"""

# ---------------------------------------------------------------------------

tester.equal 112, """
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
		{#if x==3 }
			{#if x==33 }
			{:else if x==44 }
			{/if}
		{:else if x==4 }
			{#if x==33 }
			{:else}
			{/if}
		{:else}
			{#if x==33 }
			{:else}
			{/if}
		{/if}
		"""

# ---------------------------------------------------------------------------

tester.equal 140, """
		#for x in lItems
			p paragraph
		""", """
		{#each lItems as x}
			p paragraph
		{/each}
		"""

# ---------------------------------------------------------------------------

tester.equal 151, """
		#for x,i in lItems
			p paragraph
		""", """
		{#each lItems as x,i}
			p paragraph
		{/each}
		"""

# ---------------------------------------------------------------------------

tester.equal 162, """
		#for x in lItems (key=id)
			p paragraph
		""", """
		{#each lItems as x (id)}
			p paragraph
		{/each}
		"""

# ---------------------------------------------------------------------------

tester.equal 173, """
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
