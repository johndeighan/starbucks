# starbucks.test.coffee

import {strict as assert} from 'assert'

import {AvaTester} from '@jdeighan/ava-tester'
import {loadEnvFrom} from '@jdeighan/env'
import {say, undef, setUnitTesting} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {setDebugging} from '@jdeighan/coffee-utils/debug'
import {stdImportStr} from '@jdeighan/svelte-output'
import {starbucks} from '@jdeighan/starbucks'

# --- loadEnvFrom() searches upward in the directory tree
loadEnvFrom(mydir(`import.meta.url`))
componentsDir = process.env.DIR_COMPONENTS

# --- NOTE: This must be set AFTER loadEnvFrom()
setUnitTesting(true)

# ---------------------------------------------------------------------------

class StarbucksTester extends AvaTester

	transformValue: (content) ->
		assert (content.length > 0), "StarbucksTester: empty content"
		return starbucks({content, 'unit test'}).code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------
# --- Simple parser tests

tester.equal 33, """
		#starbucks component
		nav
		""", """
		<nav>
		</nav>
		"""

tester.equal 41, """
		#starbucks component
		svelte:head
			title Page Title
		""", """
		<svelte:head>
			<title>
				Page Title
			</title>
		</svelte:head>
		"""

tester.equal 53, """
		#starbucks component
		h1 a title
		p a paragraph
		""", """
		<h1>
			a title
		</h1>
		<p>
			a paragraph
		</p>
		"""

# ---------------------------------------------------------------------------
# --- Test component parameters

tester.equal 69, """
		#starbucks component (name,phone)
		nav
		""", """
		<nav>
		</nav>

		<script>
			#{stdImportStr}
			export name = undef
			export phone = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test webpage parameters

tester.equal 86, """
		#starbucks webpage (name,phone)
		nav
		""", """
		<script context="module">
			export function load({page}) {
				return { props: {name,phone}};
				}
		</script>

		<nav>
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test that load function isn't auto-generated
#     if there's a startup section

tester.equal 104, """
		#starbucks webpage (name,phone)
		script:startup
			x = 23
		nav
		""", """
		<script context="module">
			x = 23
		</script>

		<nav>
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test auto-import of components

tester.equal 121, """
		#starbucks webpage
		Nav
		""", """
		<Nav>
		</Nav>

		<script>
			#{stdImportStr}
			import Nav from '#{process.env.DIR_COMPONENTS}/Nav.starbucks'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test dup check of components

tester.equal 137, """
		#starbucks webpage
		Nav
			Nav
		""", """
		<Nav>
			<Nav>
			</Nav>
		</Nav>

		<script>
			#{stdImportStr}
			import Nav from '#{process.env.DIR_COMPONENTS}/Nav.starbucks'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test keyhandler

tester.equal 156, """
		#starbucks webpage keyhandler=handleKeyPress
		h1 title of page
		""", """
		<svelte:window on:keydown={handleKeyPress}/>
		<h1>
			title of page
		</h1>
		"""

# ---------------------------------------------------------------------------
# --- Test stores from standard file stores.coffee

tester.equal 169, """
		#starbucks webpage store=PersonStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			#{stdImportStr}
			import {PersonStore} from '#{process.env.DIR_STORES}/stores.js'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test stores from non-standard stores file

tester.equal 186, """
		#starbucks webpage store=mystores.PersonStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			#{stdImportStr}
			import {PersonStore} from '#{process.env.DIR_STORES}/mystores.js'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test multiple stores

tester.equal 203, """
		#starbucks webpage store=PersonStore,MyStore.MyStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			#{stdImportStr}
			import {PersonStore} from '#{process.env.DIR_STORES}/stores.js'
			import {MyStore} from '#{process.env.DIR_STORES}/MyStore.js'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test style

tester.equal 221, """
		#starbucks webpage
		main
			slot
		style
			main
				overflow: auto

			nav
				overflow: auto
		""", """
		<main>
			<slot>
			</slot>
		</main>

		<style>
		main
			overflow: auto

		nav
			overflow: auto
		</style>
		"""

# ---------------------------------------------------------------------------
# --- Test attributes

tester.equal 249, """
		#starbucks webpage
		nav.menu
		""", """
		<nav class="menu">
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test event handlers

tester.equal 260, """
		#starbucks webpage

		button on:click={doCount} Click Me
		p The button was clicked {count} times
		""", """
		<button on:click={doCount}>
			Click Me
		</button>
		<p>
			The button was clicked {count} times
		</p>
		"""

# ---------------------------------------------------------------------------
# --- Test auto-declare of bind variables

tester.equal 277, """
		#starbucks webpage

		input bind:value={name}
		h1 Hello, {name}!
		""", """
		<input bind:value={name}>
		<h1>
			Hello, {name}!
		</h1>
		<script>
			#{stdImportStr}
			name = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test markdown
#     NOTE: markdown is not translated in a unit test
#           it will be translated in the real starbucks processor

tester.equal 298, """
		#starbucks webpage
		div:markdown
			title
			=====
		""", """
		<div class="markdown">
			title
			=====
		</div>
		"""

# ---------------------------------------------------------------------------
# --- Test live assignments
#     NOTE: coffeescript is not translated in a unit test
#           it will be translated in the real starbucks processor

tester.equal 315, """
		#starbucks webpage
		script
			count = 0
			doubled <== 2 * count
		""", """
		<script>
			#{stdImportStr}
			count = 0
			doubled <== 2 * count
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test automatic declaration of variables

tester.equal 331, """
		#starbucks webpage

		canvas bind:this={canvas} width=100 height=100
		input bind:value={color}
		button on:click={changeColor} Change Color
		""", """
		<canvas bind:this={canvas} width=100 height=100>
		</canvas>
		<input bind:value={color}>
		<button on:click={changeColor}>
			Change Color
		</button>

		<script>
			#{stdImportStr}
			canvas = undef
			color = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test automatic declaration of variables

tester.equal 355, """
		#starbucks webpage

		canvas = canvas width=100 height=100
		input bind:value={color}
		button on:click={changeColor} Change Color
		""", """
		<canvas bind:this={canvas} width=100 height=100>
		</canvas>
		<input bind:value={color}>
		<button on:click={changeColor}>
			Change Color
		</button>

		<script>
			#{stdImportStr}
			canvas = undef
			color = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test reactive code

tester.equal 379, """
		#starbucks webpage

		script:onmount
			ctx = canvas.getContext('2d')
			<==
				ctx.fillStyle = $prefs.color
				ctx.fillRect(10, 10, 80, 80)
		""", """
		<script>
			#{stdImportStr}
			import {onMount, onDestroy} from 'svelte'

			onMount () =>
				ctx = canvas.getContext('2d')
				<==
					ctx.fillStyle = $prefs.color
					ctx.fillRect(10, 10, 80, 80)
		</script>
"""

# ---------------------------------------------------------------------------
# --- Test coffeescript expressions in #if, #for

tester.equal 403, """
		#starbucks webpage

		#if loggedIn?
			p You are logged in
		#else
			p Login failed

		script
			loggedIn = true
		""", """
		{#if loggedIn? }
			<p>
				You are logged in
			</p>
		{:else}
			<p>
				Login failed
			</p>
		{/if}

		<script>
			#{stdImportStr}
			loggedIn = true
		</script>
"""

# ---------------------------------------------------------------------------
# --- Test coffeescript expressions in #if, #for when not unit testing

setUnitTesting(false)
tester.equal 434, """
		#starbucks webpage

		#if loggedIn?
			p You are logged in
		#else
			p Login failed

		script
			loggedIn = true
		""", """
		{#if typeof loggedIn !== "undefined" && loggedIn !== null }
			<p>
				You are logged in
			</p>
		{:else}
			<p>
				Login failed
			</p>
		{/if}

		<script>
			#{stdImportStr}
			var loggedIn;
			loggedIn = true;
		</script>
		"""
setUnitTesting(true)

# ---------------------------------------------------------------------------
# --- Test <<< in html section

tester.equal 466, """
		#starbucks webpage

		TopMenu lItems={<<<}
			---
			-
				label: Help
				url: /help
			-
				label: Books
				url: /books

		p Select a source
		""", """
		<TopMenu lItems={__anonVar0}>
		</TopMenu>
		<p>
			Select a source
		</p>
		<script>
			#{stdImportStr}
			__anonVar0 = [{"label":"Help","url":"/help"},{"label":"Books","url":"/books"}]
			import TopMenu from '#{componentsDir}/TopMenu.starbucks'
		</script>
"""

# ---------------------------------------------------------------------------
# --- Test TopMenu (corrected)

tester.equal 495, """
		#starbucks component (lItems, bgColor)

		#if item.lItems?
			div.dropdown
				a {item.label}
				div.submenu
					#for subitem in item.lItems
						a href="{subitem.url}" {subitem.label}
		""", """
		{#if item.lItems? }
			<div class="dropdown">
				<a>
					{item.label}
				</a>
				<div class="submenu">
					{#each item.lItems as subitem}
						<a href="{subitem.url}">
							{subitem.label}
						</a>
					{/each}
				</div>
			</div>
		{/if}
		<script>
			import {undef,say,ask,isEmpty,nonEmpty} from '@jdeighan/coffee-utils'
			export lItems = undef
			export bgColor = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test comments (was a bug)

tester.equal 529, """
		#starbucks webpage dump

		# --- this is a comment

		p hi there
		""", """
		<p>
			hi there
		</p>
"""
