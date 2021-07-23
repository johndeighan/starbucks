# parsetag.coffee

import {undef, say, pass, error, nonEmpty} from './coffee_utils.js'

# ---------------------------------------------------------------------------
# tag = <tagName> { <attr> } <text>
#
# NOTE: parsetag(line) returns an hToken
#       to get the value of an attribute, use:
#
#          hToken.hAttr.value
#
# ---------------------------------------------------------------------------

export parsetag = (line) ->

	if lMatches = line.match(///^
			([A-Za-z][A-Za-z0-9_]*)    # tag name
			(?:
				\:
				( startup | onmount | ondestroy | markdown | sourcecode )
				)?
			(\S*)                      # modifiers (class names, etc.)
			\s*
			(.*)                       # attributes & enclosed text
			$///)
		[_, tagName, subtype, modifiers, rest] = lMatches
	else
		error "parsetag(): Invalid HTML: '#{line}'"

	switch subtype
		when undef, ''
			pass
		when 'startup', 'onmount', 'ondestroy'
			if (tagName != 'script')
				error "parsetag(): subtype '#{subtype}' only allowed with script"
		when 'markdown', 'sourcecode'
			if (tagName != 'div')
				error "parsetag(): subtype 'markdown' only allowed with div"

	# --- Handle classes added via .<class>
	lClasses = []
	if (subtype == 'markdown')
		lClasses.push 'markdown'

	if modifiers
		# --- currently, these are only class names
		while lMatches = modifiers.match(///^
				\. ([A-Za-z][A-Za-z0-9_]*)
				///)
			[all, className] = lMatches
			lClasses.push className
			modifiers = modifiers.substring(all.length)
		if modifiers
			error "parsetag(): Invalid modifiers in '#{line}'"

	# --- Handle attributes
	hAttr = {}     # { name: {
	               #      value: <value>,
	               #      quote: <quote>,
	               #      }, ...
	               #    }
	if rest
		while lMatches = rest.match(///^
				([A-Za-z][A-Za-z0-9_:]*)     # attribute name
				=
				(?:
					  ( \{ [^}]* \} )         # attribute value
					| " ([^"]*) "
					| ' ([^']*) '
					|   ([^"'\s]+)
					)
				\s*
				///)
			[all, attrName, br_val, dq_val, sq_val, uq_val] = lMatches
			if br_val
				value = br_val
				quote = ''
			else if dq_val
				value = dq_val
				quote = '"'
			else if sq_val
				value = sq_val
				quote = "'"
			else
				value = uq_val
				quote = ''

			if attrName == 'class'
				for className in value.split(/\s+/)
					lClasses.push className
			else
				if hAttr.attrName?
					error "parsetag(): Multiple attributes named '#{attrName}'"
				hAttr[attrName] = { value, quote }

			rest = rest.substring(all.length)

	# --- The rest is contained text
	rest = rest.trim()
	if lMatches = rest.match(///^
			['"]
			(.*)
			['"]
			$///)
		rest = lMatches[1]

	# --- Add class attribute to hAttr if there are classes
	if (lClasses.length > 0)
		hAttr.class = {
			value: lClasses.join(' '),
			quote: '"',
			}

	# --- If subtype == 'startup'
	if subtype == 'startup'
		if not hAttr.context
			hAttr.context = {
				value: 'module',
				quote: '"',
				}

	# --- Build the return value
	hTag = {tag: tagName}
	if subtype
		hTag.subtype = subtype
	if nonEmpty(hAttr)
		hTag.hAttr = hAttr

	# --- Is there contained text?
	if rest
		hTag.containedText = rest

	return hTag

# ---------------------------------------------------------------------------

export tag2str = (hToken) ->

	str = "<#{hToken.tag}"    # build the string bit by bit
	if nonEmpty(hToken.hAttr)
		str += attrStr(hToken.hAttr)
	str += '>'
	return str

# ---------------------------------------------------------------------------

export attrStr = (hAttr) ->

	if not hAttr
		return ''
	str = ''
	for attrName in Object.getOwnPropertyNames(hAttr)
		{value, quote} = hAttr[attrName]
		str += " #{attrName}=#{quote}#{value}#{quote}"
	return str

