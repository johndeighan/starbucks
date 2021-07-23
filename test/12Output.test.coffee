# Output.test.coffee

import {StarbucksOutput, stdImportStr} from '../Output.js'
import {config} from '../starbucks.config.js'
import {test_output, show_only} from './test_utils.js'

# ---------------------------------------------------------------------------
# --- Test simple output

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.put "<p>"

	test_output 14, oOutput, """
	<p>
	"""

	)()

# ---------------------------------------------------------------------------
# --- Test simple output

(()->
	oOutput = new StarbucksOutput 'unit test'
	oOutput.put "<p>"
	oOutput.put "</p>"

	test_output 28, oOutput, """
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

	test_output 44, oOutput, """
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

	test_output 62, oOutput, """
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

	test_output 77, oOutput, """
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

	test_output 95, oOutput, """
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

	test_output 120, oOutput, """
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

	test_output 143, oOutput, """
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

	test_output 166, oOutput, """
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

	test_output 189, oOutput, """
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

	test_output 216, oOutput, """
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

	test_output 240, oOutput, """
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

	test_output 274, oOutput, """
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

	test_output 307, oOutput, """
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
