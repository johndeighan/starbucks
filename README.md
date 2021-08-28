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
------------------------
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
------------------------
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
------------------------
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
------------------------
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
------------------------
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
------------------------
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
------------------------
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
**NOTE:** Whenever there is a `<script>` section, some common functions are
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
export var load = function({page}) {
  return {
    props: {name}
  };
};

</script>

<h1>
	title
</h1>
```

Substitution of env vars using {{name}}
---------------------------------------------------------------------

**NOTE:** This requires a .env file in a valid location, e.g. a
file named `.env` in the same dir containing the source starbucks
file containing:

```
name = John
color = lightGray
```

Then,
```
#starbucks webpage

h1 My name is {{name}}
```
becomes
```
<h1>
	My name is John
</h1>
```
------------------------
```
#starbucks webpage

script
	myName = '{{name}}'
```
becomes
```

<script>
	import {undef,say,ask,isEmpty,nonEmpty} from '@jdeighan/coffee-utils'
var myName;

myName = 'John';

</script>
```
------------------------
```
#starbucks webpage

style
	p
		background-color: {{color}}
```
becomes
```

<style>
p {
		background-color: lightGray;
}
</style>
```

Command #envvar
---------------------------------------------------------------------

**NOTE:** In starbucks syntax, a command is a line on which the
first non-whitespace character is '#', which is immediately followed
by the name of the command, which always consists of one or more
lower-case letters

```
#starbucks webpage

#envvar lastName = Deighan
p My last name is {{lastName}}
```
becomes
```
<p>
	My last name is Deighan
</p>
```
Command #if
---------------------------------------------------------------------

```
#starbucks webpage

#envvar lastName = Deighan

#if known
	p My last name is {{lastName}}
#else
	p I don't know
```
becomes
```
{#if known }
	<p>
		My last name is Deighan
	</p>
{:else}
	<p>
		I don't know
	</p>
{/if}
```

**NOTE:** `known` is a JavaScript variable, and if it changes,
the block of code that is displayed may change. However, `lastName`
is a constant at the time that this code is generated, and as such,
will always be 'Deighan'.

```
#starbucks webpage

#envvar lastName = Deighan

#if known
	p My last name is {{lastName}}
#elsif standard
	p My last name is Smith
#else
	p I don't know
```
becomes
```
{#if known }
	<p>
		My last name is Deighan
	</p>
{:else if standard }
	<p>
		My last name is Smith
	</p>
{:else}
	<p>
		I don't know
	</p>
{/if}
```

Command #for
---------------------------------------------------------------------

```
#starbucks webpage

#envvar lastName = Deighan

#for name in lNames
	p My name is {name}
```
becomes
```
{#each lNames as name}
	<p>
		My name is {name}
	</p>
{/each}
```
------------------------
```
#starbucks webpage

#for name,i in lNames
	p {i}. My name is {name}
```
becomes
```
{#each lNames as name,i}
	<p>
		{i}. My name is {name}
	</p>
{/each}
```
------------------------
```
#starbucks webpage

#for name,i in lNames  (key  =  id)
	p {i}. My name is {name}
```
becomes
```
{#each lNames as name,i (id)}
	<p>
		{i}. My name is {name}
	</p>
{/each}
```

Command #await
---------------------------------------------------------------------

```
#starbucks webpage

#await fetch('https://disease.sh/v3/covid-19/historical/all?lastdays=30')
	p please wait...
#then lData
	ul
		#for n,i in lData
			li [{i}] {n}
#catch err
	div.error {err.message}
```
becomes
```
{#await fetch('https://disease.sh/v3/covid-19/historical/all?lastdays=30')}
	<p>
		please wait...
	</p>
{:then lData}
	<ul>
		{#each lData as n,i}
			<li>
				[{i}] {n}
			</li>
		{/each}
	</ul>
{:catch err}
	<div class="error">
		{err.message}
	</div>
{/await}
```
Nested Styles (a la SASS)
---------------------------------------------------------------------

```
#starbucks webpage

h1.error
	p.message {err.message}
	p.solution Please set env var dir_root

style
	h1.error
		p.message
			background-color: red
		p.solution
			background-color: orange
```
becomes
```
<h1 class="error">
	<p class="message">
		{err.message}
	</p>
	<p class="solution">
		Please set env var dir_root
	</p>
</h1>

<style>
h1.error p.message {
		background-color: red;
}
h1.error p.solution {
		background-color: orange;
}
</style>
```
Attribute values = {...}
---------------------------------------------------------------------

```
```
becomes
```
```


