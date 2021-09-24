# StarbucksStores.coffee

import {strict as assert} from 'assert'
import {writable, readable, get} from 'svelte/store'
import {undef, error, localStore} from '@jdeighan/coffee-utils'
import {getFileContents} from '@jdeighan/string-input'

# ---------------------------------------------------------------------------

export class WritableStore

	constructor: (value=undef) ->
		@store = writable value

	subscribe: (callback) ->
		return @store.subscribe(callback)

	set: (value) ->
		@store.set(value)

	update: (func) ->
		@store.update(func)

# ---------------------------------------------------------------------------

export class LocalStorageStore extends WritableStore

	constructor: (@masterKey, defValue=undef) ->

		# --- CoffeeScript forces us to call super first
		#     so we can't get the localStorage value first
		super defValue
		value = localStore(@masterKey)
		if value?
			@set value

	# --- I'm assuming that when update() is called,
	#     set() will also be called

	set: (value) ->
		if not value?
			error "LocalStorageStore.set(): cannont set to undef"
		super value
		localStore @masterKey, value

	update: (func) ->
		super func
		localStore @masterKey, get(@store)

# ---------------------------------------------------------------------------

export class PropStore extends LocalStorageStore

	constructor: (masterKey) ->
		super masterKey, {}

	setProp: (name, value) ->
		if not name?
			error "PropStore.setProp(): empty key"
		@update (hPrefs) ->
			hPrefs[name] = value
			return hPrefs

# ---------------------------------------------------------------------------

export class ReadableStore

	constructor: () ->
		@store = readable null, (set) ->
			@setter = set        # store the setter function
			@start()             # call your start() method
			return () => @stop() # return function capable of stopping

	subscribe: (callback) ->
		return @store.subscribe(callback)

	start: () ->

	stop: () ->

# ---------------------------------------------------------------------------

export class DateTimeStore extends ReadableStore

	start: () ->
		# --- We need to store this interval for use in stop() later
		@interval = setInterval(() ->
			@setter new Date()
			, 1000)

	stop: () ->
		clearInterval @interval

# ---------------------------------------------------------------------------

export class MousePosStore extends ReadableStore

	start: () ->
		# --- We need to store this handler for use in stop() later
		@mouseMoveHandler = (e) ->
			@setter {
				x: e.clientX,
				y: e.clientY,
				}
		document.body.addEventListener('mousemove', @mouseMoveHandler)

	stop: () ->
		document.body.removeEventListener('mousemove', @mouseMoveHandler)

# ---------------------------------------------------------------------------

export class TAMLStore extends WritableStore

	constructor: (fname) ->
		assert fname.match(/\.taml$/), "TamlStore: fname must end in .taml"
		data = getFileContents(fname)
		super data
