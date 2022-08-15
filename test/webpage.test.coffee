# webpage.test.coffee

import {assert} from '@jdeighan/unit-tester/utils'

import {UnitTester, simple} from '@jdeighan/unit-tester'
import {undef, OL} from '@jdeighan/coffee-utils'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {setDebugging, debug} from '@jdeighan/coffee-utils/debug'
import {mkpath, mydir} from '@jdeighan/coffee-utils/fs'

import {starbucks} from '@jdeighan/starbucks'

my_dir = mydir(import.meta.url)
my_file = mkpath(my_dir, 'temp.webpage.star')

# --- NOTE: Some unit tests may only work with these versions:
#           coffeescript 2.7.0
#           sass 1.53.0
#           js-yaml 4.1.0
#           marked 4.0.17

# ---------------------------------------------------------------------------

class StarbucksTester extends UnitTester

	transformValue: (content) ->

		hResult = starbucks({content, filename: my_file})
		code = hResult.code
		return code

tester = new StarbucksTester()

# ---------------------------------------------------------------------------
#                 WEBPAGEs
# ---------------------------------------------------------------------------
# --- Simple parser tests

# --- These fail due to the missing #starbucks header

simple.fails 41, () -> starbucks({'', filename: my_file})
simple.fails 42, () -> starbucks({'p a paragraph', filename: my_file})

tester.equal 44, """
		#starbucks webpage
		""", ''

tester.equal 48, """
		#starbucks webpage
		nav
		""", """
		<nav>
		</nav>
		"""

tester.equal 56, """
		#starbucks webpage
		nav.menu
		""", """
		<nav class="menu">
		</nav>
		"""

tester.equal 64, """
		#starbucks webpage
		nav.menu.dropdown
		""", """
		<nav class="menu dropdown">
		</nav>
		"""

tester.equal 72, """
		#starbucks webpage
		plot = canvas.pic height=42
		""", """
		<canvas bind:this={plot} height=42 class="pic">
		</canvas>
		"""

tester.equal 80, """
		#starbucks
		h1 Hello world!
		""", """
		<h1>
			Hello world!
		</h1>
		"""

tester.equal 89, """
		#starbucks webpage
		svelte:head
			title Page Title
		""", """
		<svelte:head>
			<title>
				Page Title
			</title>
		</svelte:head>
		"""

tester.equal 101, """
		#starbucks webpage
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

tester.equal 114, """
		#starbucks
		h1 a title
			p a paragraph
		""", """
		<h1>
			a title
			<p>
				a paragraph
			</p>
		</h1>
		"""

tester.equal 127, """
		#starbucks
		h1 a title
		div:sourcecode
		""", """
		<h1>
			a title
		</h1>
		<div class="sourcecode">
			<pre>
				#starbucks
				h1 a title
				div:sourcecode
			</pre>
		</div>
		"""

tester.equal 144, """
		#starbucks
		h1 a title
		pre
			title
			=====

			some text
		""", """
		<h1>
			a title
		</h1>
		<pre>
			title
			=====

			some text
		</pre>
		"""

tester.equal 164, """
		#starbucks
		h1 a title
		div:markdown
			title
			=====

			some text
		""", """
		<h1>
			a title
		</h1>
		<div class="markdown">
			<h1>title</h1>
			<p>some text</p>
		</div>
		"""

tester.equal 182, """
		#starbucks
		h1 a title
		pre
			anything?
			< here >
		""", """
		<h1>
			a title
		</h1>
		<pre>
			anything?
			< here >
		</pre>
		"""

tester.equal 198, """
		#starbucks script=cielo
		h1 Hello {name}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name}!
		</h1>
		<script>
			# |||| =
			name = 'John'
		</script>
		"""

tester.equal 213, """
		#starbucks
		h1 Hello {name}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name}!
		</h1>
		<script>
			var name;
			name = 'John';
		</script>
		"""

tester.equal 228, """
		#starbucks script=cielo
		h1 Hello {name.toUpperCase()}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name.toUpperCase()}!
		</h1>
		<script>
			# |||| =
			name = 'John'
		</script>
		"""

tester.equal 243, """
		#starbucks script=cielo
		h1 Hello {name.toUpperCase()}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name.toUpperCase()}!
		</h1>
		<script>
			# |||| =
			name = 'John'
		</script>
		"""

tester.equal 258, """
		#starbucks
		h1 Hello {name.toUpperCase()}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name.toUpperCase()}!
		</h1>
		<script>
			var name;
			name = 'John';
		</script>
		"""

tester.equal 273, """
		#starbucks script=cielo
		img src={src} alt="{name} dances"
		script
			src = '/tutorial/image.gif'
			name = 'a man'
		""", """
		<img src={src} alt="{name} dances">
		<script>
			# |||| =
			src = '/tutorial/image.gif'
			name = 'a man'
		</script>
		"""

tester.equal 288, """
		#starbucks
		img src={src} alt="{name} dances"
		script
			src = '/tutorial/image.gif'
			name = 'a man'
		""", """
		<img src={src} alt="{name} dances">
		<script>
			var name, src;
			src = '/tutorial/image.gif';
			name = 'a man';
		</script>
		"""

# --- Make sure that shorthand attributes work OK
tester.equal 304, """
		#starbucks script=cielo
		img {src} alt="dance"
		script
			src = '/tutorial/image.gif'
			name = 'a man'
		""", """
		<img {src} alt="dance">
		<script>
			# |||| =
			src = '/tutorial/image.gif'
			name = 'a man'
		</script>
		"""

tester.equal 319, """
		#starbucks
		img {src} alt="dance"
		script
			src = '/tutorial/image.gif'
			name = 'a man'
		""", """
		<img {src} alt="dance">
		<script>
			var name, src;
			src = '/tutorial/image.gif';
			name = 'a man';
		</script>
		"""

# --- NOTE: ugly indentation is from SASS

tester.equal 336, """
		#starbucks
		p This is a paragraph
		style
			p
				color: purple
		""", """
		<p>
			This is a paragraph
		</p>
		<style>
			p {
					color: purple;
			}
		</style>
		"""

tester.equal 353, """
		#starbucks
		p This is a paragraph
		style
			div
				p
					color: purple
				ul
					color: gray
		""", """
		<p>
			This is a paragraph
		</p>
		<style>
			div p {
					color: purple;
			}
			div ul {
					color: gray;
			}
		</style>
		"""

# --- Nested components

tester.equal 378, """
		#starbucks
		p This is a paragraph
		Nested This is a nested component
		TopMenu
		""", """
		<p>
			This is a paragraph
		</p>
		<Nested>
			This is a nested component
		</Nested>
		<TopMenu>
		</TopMenu>
		<script>
			import {
			  Nested
			} from './Nested.svelte';
			import {
			  TopMenu
			} from './components/TopMenu.svelte';
		</script>
		"""

# --- HTML in variables (eventually, we should automatically sanitize)

tester.equal 404, """
		#starbucks
		p This is a paragraph with {@html htmlVar}
		""", """
		<p>
			This is a paragraph with {@html htmlVar}
		</p>
		"""

tester.equal 413, """
		#starbucks
		button on:click={<<<} Click Me
			(e) ->
				alert 'clicked'

		""", """
		<button on:click={$_0}>
			Click Me
		</button>
		<script>
			var $_0;
			$_0 = function(e) {
			  return alert('clicked');
			};
		</script>
		"""

tester.equal 431, """
		#starbucks script=cielo
		button on:click={<<<} Clicked {count} times
			(e) ->
				count += 1

		script
			count = 0
		""", """
		<button on:click={$_0}>
			Clicked {count} times
		</button>
		<script>
			# |||| =
			$_0 = (e) ->
				count += 1
			count = 0
		</script>
		"""

tester.equal 451, """
		#starbucks
		button on:click={<<<} Clicked {count} times
			(e) ->
				count += 1

		script
			count = 0
		""", """
		<button on:click={$_0}>
			Clicked {count} times
		</button>
		<script>
			var $_0, count;
			$_0 = function(e) {
			  return count += 1;
			};
			count = 0;
		</script>
		"""

tester.equal 472, """
		#starbucks
		TopMenu lItems={<<<}
			---
			- File
			- Edit
			- Help

		""", """
		<TopMenu lItems={$_0}>
		</TopMenu>
		<script>
			var $_0;
			import {
			  TopMenu
			} from './components/TopMenu.svelte';
			$_0 = ["File", "Edit", "Help"];
		</script>
		"""

tester.equal 492, """
		#starbucks
		p {<<<}
			...this is
				an error message

		""", """
		<p>
			{$_0}
		</p>
		<script>
			var $_0;
			$_0 = "this is an error message";
		</script>
		"""

# ---------------------------------------------------------------------------
# --- test reactive statements

tester.equal 511, """
		#starbucks script=cielo
		p "{count} doubled is {doubled}"
		button on:click={<<<} Clicked {count} {count==1 ? 'time' : 'times'}
			() ->
				count += 1

		script
			count = 0
			#reactive doubled = 2 * count
		""", """
		<p>
			{count} doubled is {doubled}
		</p>
		<button on:click={$_0}>
			Clicked {count} {count==1 ? 'time' : 'times'}
		</button>
		<script>
			# |||| =
			$_0 = () ->
				count += 1
			count = 0
			#reactive doubled = 2 * count
		</script>
		"""

tester.equal 538, """
		#starbucks script=coffee
		p "{count} doubled is {doubled}"
		button on:click={<<<} Clicked {count} {count==1 ? 'time' : 'times'}
			() ->
				count += 1

		script
			count = 0
			#reactive doubled = 2 * count
		""", """
		<p>
			{count} doubled is {doubled}
		</p>
		<button on:click={$_0}>
			Clicked {count} {count==1 ? 'time' : 'times'}
		</button>
		<script>
			# |||| =
			$_0 = () ->
				count += 1
			count = 0
			# |||| $:
			doubled = 2 * count
		</script>
		"""

tester.equal 565, """
		#starbucks
		p "{count} doubled is {doubled}"
		button on:click={<<<} Clicked {count} {count==1 ? 'time' : 'times'}
			() ->
				count += 1

		script
			count = 0
			#reactive doubled = 2 * count
		""", """
		<p>
			{count} doubled is {doubled}
		</p>
		<button on:click={$_0}>
			Clicked {count} {count==1 ? 'time' : 'times'}
		</button>
		<script>
			var $_0, count, doubled;
			$_0 = function() {
			  return count += 1;
			};
			count = 0;
			$:
			doubled = 2 * count;
		</script>
		"""

# ---------------------------------------------------------------------------
