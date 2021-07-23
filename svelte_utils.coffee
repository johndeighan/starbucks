# svelte_utils.coffee

# ---------------------------------------------------------------------------
#   svelteEsc - escape svelte code

export svelteEsc = (str) ->

	str = str.replace(/\</g, '&lt;')
	str = str.replace(/\>/g, '&gt;')
	str = str.replace(/\{/g, '&lbrace;')
	str = str.replace(/\}/g, '&rbrace;')
	str = str.replace(/\$/g, '&dollar;')
#	str = str.replace(/\#/g, '&num;')
#	str = str.replace(/\-/g, '&dash;')
#	str = str.replace(/\'/g, '&apos;')
	return str

# ---------------------------------------------------------------------------
