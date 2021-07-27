Things to do:

Consider the following syntax for functions:

	x = y | double | square | log | sqrt

Explain my variable naming convention

Allow specifying default values for parameters,
both on a webpage and a component

Allow dispatching of events

Document how to create things like checkbox and
radiobutton groups

in coffee_utils.coffee, provide a function to
back up an entire folder, allowing the option
to give a file extension.

When comments are skipped, all succeeding lines
at greater indent should also be skipped

# ---------------------------------------------------

Environment variables in PowerShell:

> $env:NODE_PATH
c:\Users\johnd\Dropbox\libs

> $env:temp = "a new value"

# ---------------------------------------------------

Creating a shared libs folder:

1. Create these folders and:
	- add your libraries and starbucks.config.coffee
		to folder 'libs'
	- add your tests to folder 'test'

		c:/Users/johnd/Dropbox/starbucks_libs
		c:/Users/johnd/Dropbox/starbucks_test

3. All npm modules used by files in the starbucks_lib folder
	must be installed at the parent folder:

		c:/Users/johnd/Dropbox

	(for some reason, installing them globally doesn't work)

	js-yaml
	coffeescript
	mustache
	deep-equal
	ava
	marked
	sass
	svelte

# ---------------------------------------------------------

Using the shared libs folder in a new project:

1. Create a symbolic link to the folder:
	1. Open a CMD shell with admin rights
	2. cd to the folder where you would have placed
		your 'lib' folder (probably /src) and run command:

		mklink /d lib c:\users\johnd\dropbox\starbucks_lib

	3. cd to the folder where you would have placed
		your 'test' folder (probably the root dir) and
		run command:

		mklink /d test c:\users\johnd\dropbox\starbucks_test

	(for some reason, pasting a shortcut doesn't do the same thing)


# ---------------------------------------------------------

Order of tests:

	 1. utils
	 2. indent
	 3. markdown
	 4. heredoc
	 5. parsetag
	 6. states
	 7. StringInput
	 8. CoffeeMapper
	 9. callbacks
	10. commands
	11. Output
	12. StarbucksInput
	13. StarbucksMapper
	14. starbucks

# --------------------------------------------------------

TO DO:

1. implement style:laptop, style:cellphone, etc.

		when 'include'
			oOut.put getFileContents(argstr)


# ==========================================================











touch README.md
git init
git add README.md
git commit -m "initial commit"
git remote add origin git@github.com:johndeighan/<repo>.git
git push -u origin master

git remote add origin git@github.com:johndeighan/<repo>.git
git push -u origin master

# ==========================================================

Make project installable via npm:

