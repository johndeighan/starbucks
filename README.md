starbucks - a sveltekit utility
===============================

Date: 8/27/2021

How starbucks() transforms *.starbucks files to *.svelte files:

A simple webpage
---------------------------------------------------------------------

```text
#starbucks webpage

h1 Hello, World!
```
becomes
```
<h1>
   Hello, World!
</h1>
```

A simple component
---------------------------------------------------------------------

```text
#starbucks component

h1 Hello, World!
```
becomes
```
<h1>
   Hello, World!
</h1>
```

**NOTE:** The above both produce the same output. However, handling of
	parameters differs between web pages and components

**NOTE:** The above resembles `pug` syntax, but it's not.
	See attributes below.

Multiple HTML elements
---------------------------------------------------------------------

```
#starbucks webpage

h1 Hello, World!
p a paragraph
```
becomes
```
<h1>
   Hello, World!
</h1>
<p>
   a paragraph
</p>
```

Nested HTML elements
---------------------------------------------------------------------
```
#starbucks webpage

div
	h1 Hello, World!
	p a paragraph
```
becomes
```
<div>
   <h1>
      Hello, World!
   </h1>
   <p>
      a paragraph
   </p>
</div>
```
Comments
---------------------------------------------------------------------
```
#starbucks webpage

# --- this is a comment
#
# --- this is another comment

p a paragraph
```
becomes
```
<p>
   a paragraph
</p>
```
i.e. both comments and empty lines are ignored. A comment is
a line where the first non-whitespace character is a '#' and
either 1) the '#' is immediately followed by a whitespace
character, or 2) there is nothing following the '#' on the line.

This is true inside script and style sections, as well as markdown.
However, in #included markdown files, '# header' will be changed
to 'header' followed by '======' and '##header' wil be changed
to 'header' followed by '------'.

HTML attributes
---------------------------------------------------------------------
```
#starbucks webpage

p class=bold a paragraph
```
becomes
```
<p class="bold">
   a paragraph
</p>
```
---------------------------------------
```
#starbucks webpage

p class='bold' a paragraph
```
becomes
```
<p class="bold">
   a paragraph
</p>
```
---------------------------------------
```
#starbucks webpage

p class="bold" a paragraph
```
becomes
```
<p class="bold">
   a paragraph
</p>
```
---------------------------------------
```
#starbucks webpage

p.bold a paragraph
```
becomes
```
<p class="bold">
   a paragraph
</p>
```
---------------------------------------
```
#starbucks webpage

p.bold class="red" a paragraph
```
becomes
```
<p class="bold red">
   a paragraph
</p>
```
---------------------------------------
```
#starbucks webpage

p.bold name="mine" a paragraph
```
becomes
```
<p name="mine" class="bold">
   a paragraph
</p>
```
---------------------------------------
```
#starbucks webpage

p.bold name="mine" 'a paragraph'
```
becomes
```
<p name="mine" class="bold">
   a paragraph
</p>
```
i.e. you can quote the text contained in an element
if you're afraid that it might be interpreted
as an attribute
---------------------------------------
```
#starbucks webpage

p.bold name="mine" "a paragraph"
```
becomes
```
<p name="mine" class="bold">
   a paragraph
</p>
```
Parameters in a component
---------------------------------------------------------------------
```
#starbucks component (name)

h1 title
```
becomes
```
<h1>
   title
</h1>

<script>
   import {undef,say,ask,isEmpty,nonEmpty} from '@jdeighan/coffee-utils'
export var name = undef;

</script>
```
**NOTE:** Whenever there is a <script> section, some common functions are
	automatically imported. TO DO: check which are actually used and
	only import those. Also, there should be a semicolon terminating
	the import statement.

**NOTE:** The export statement should be indented. The blank line
	should not appear.

Parameters in a web page
---------------------------------------------------------------------
```
#starbucks webpage (name)

h1 title
```
becomes
```
<script context="module">
	export function load({page}) {
		return { props: {name}};
		}
</script>
<h1>
	title
</h1>
```






