# 12Output.test.coffee

import {StarbucksOutput, stdImportStr} from '../src/Output.js'
import {config} from '../starbucks.config.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class OutputTester extends AvaTester

	transformValue: (oOutput) ->
		return oOutput.get()

tester = new OutputTester()

# ---------------------------------------------------------------------------
# --- Test simple output

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.put "<p>"

	tester.equal 24, oOutput, """
		<p>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test simple output

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.put "<p>"
	oOutput.put "</p>"

	tester.equal 38, oOutput, """
		<p>
		</p>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test simple output

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.put "<p>"
	oOutput.put "this is a paragraph", 1
	oOutput.put "</p>"

	tester.equal 54, oOutput, """
		<p>
			this is a paragraph
		</p>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test interpolation

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.setConst 'LINE', 2
	oOutput.put "<p>"
	oOutput.put "this is line {{LINE}}", 1
	oOutput.put "</p>"

	tester.equal 72, oOutput, """
		<p>
			this is line 2
		</p>
		"""

	)()

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.setConst 'name', 'John'
	oOutput.put "<p>"
	oOutput.put "my name is {{name}}", 1
	oOutput.put "</p>"

	tester.equal 87, oOutput, """
		<p>
			my name is John
		</p>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test auto-import of components

(()->
	oOutput = new StarbucksOutput
	oOutput.addComponent 'Para'
	oOutput.put "<Para>"
	oOutput.put "this is a para", 1
	oOutput.put "</Para>"

	tester.equal 107, oOutput, """
		<Para>
			this is a para
		</Para>

		<script>
			#{stdImportStr}
			```
			import Para from '#{config.componentsDir}/Para.starbucks';
			```
		</script>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test script section

(()->
	oOutput = new StarbucksOutput
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"
	oOutput.putScript "x = 23;"

	tester.equal 131, oOutput, """
		<p>
			this is text
		</p>

		<script>
			#{stdImportStr}
			x = 23;
		</script>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test script section

(()->
	oOutput = new StarbucksOutput
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"
	oOutput.putScript "x = 23;", 1

	tester.equal 153, oOutput, """
		<p>
			this is text
		</p>

		<script>
			#{stdImportStr}
			x = 23;
		</script>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test startup section

(()->
	oOutput = new StarbucksOutput
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"
	oOutput.putStartup "x = 23;", 1

	tester.equal 176, oOutput, """
		<script context="module">
			x = 23;
		</script>

		<p>
			this is text
		</p>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test startup AND script sections

(()->
	oOutput = new StarbucksOutput
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"
	oOutput.putStartup "x = 23;", 1
	oOutput.putScript "x = 42;", 1

	tester.equal 199, oOutput, """
		<script context="module">
			x = 23;
		</script>

		<p>
			this is text
		</p>

		<script>
			#{stdImportStr}
			x = 42;
		</script>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test style section

(()->
	oOutput = new StarbucksOutput
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"
	oOutput.putStyle "p { color: red; }", 1

	tester.equal 226, oOutput, """
		<p>
			this is text
		</p>

		<style>
			p { color: red; }
		</style>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test startup, script AND style sections

(()->
	oOutput = new StarbucksOutput
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"
	oOutput.putStartup "x = 23;", 1
	oOutput.putScript "x = 42;", 1
	oOutput.putStyle "p { color: red; }", 1

	tester.equal 250, oOutput, """
		<script context="module">
			x = 23;
		</script>

		<p>
			this is text
		</p>

		<script>
			#{stdImportStr}
			x = 42;
		</script>

		<style>
			p { color: red; }
		</style>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test startup, script AND style sections
#        - order of sections doesn't matter

(()->
	oOutput = new StarbucksOutput
	oOutput.putStartup "x = 23;", 1
	oOutput.putScript "x = 42;", 1
	oOutput.putStyle "p { color: red; }", 1
	oOutput.put "<p>"
	oOutput.put "this is text", 1
	oOutput.put "</p>"

	tester.equal 284, oOutput, """
		<script context="module">
			x = 23;
		</script>

		<p>
			this is text
		</p>

		<script>
			#{stdImportStr}
			x = 42;
		</script>

		<style>
			p { color: red; }
		</style>
		"""

	)()

# ---------------------------------------------------------------------------
# --- Test included markdown files

(()->
	filename = 'test.md'
	html = "<h1>Contents of #{filename}</h1>"

	oOutput = new StarbucksOutput()
	oOutput.put "<div class=\"markdown\">", 0
	oOutput.putJSVar('myhtml', html)
	oOutput.put "{@html myhtml}", 1
	oOutput.put "</div>"

	tester.equal 318, oOutput, """
		<div class="markdown">
			{@html myhtml}
		</div>
		<script>
			#{stdImportStr}
			myhtml = \"\"\"
				<h1>Contents of #{filename}</h1>
				\"\"\"
		</script>
		"""

	)()

# ---------------------------------------------------------------------------
