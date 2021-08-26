#starbucks component (lItems)

# TopMenu.starbucks

div.main
	#for hItem in lItems
		#if hItem.url
			a href={hItem.url} {hItem.label}
		#elsif hItem.lItems
			div.dropdown
				a href="#junk" role="button" {hItem.label}
				div.submenu
					#for hSubItem in hItem.lItems
						a href={hSubItem.url} {hSubItem.label}
		#else
			#error Bad TopMenu.lItems

style

	div
		font: bold 15px Arial, sans-serif
		background-color: gray

	a
		text-decoration: none
		padding: 12px 14px
		display: inline-block

	# --- There are 3 types of <a> tags:
	#       1. direct children of nav
	#       2. direct children of div.dropdown
	#       3. direct children of div.submenu
	#
	# --- #1 and #2 should appear the same, even with :hover or :active
	#    - however, #2 should cause the div below it to appear on :hover
	#
	# --- #3 will appear different

	# --- #1 and #2 have white, centered text

	div.main > a, div.dropdown > a
		color: white
		text-align: center

	# hovering over #1 or #2 changes background to black
	div.main > a:hover, div.dropdown > a:hover
		background-color: black

	div.dropdown
		display: inline-block

	# hovering over #2's container causes submenu to appear
	div.dropdown:hover > div.submenu
		display: block

	div.submenu
		# --- initially hidden
		display: none
		position: absolute
		background-color: #f9f9f9
		min-width: 160px
		box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2)
		z-index: 1

	div.submenu a
		display: block
		color: black
		text-align: left

	div.submenu a:hover
		background-color: #ccc

# --- Original code:
#	a href="/" Home
#	div.dropdown
#		a href="#junk" role="button" Help
#		div.submenu
#			a href="/about" About
#			a href="/contact" Contact
#
