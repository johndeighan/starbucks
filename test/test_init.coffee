# test_init.coffee

import {strict as assert} from 'assert'
import {setUnitTesting} from '@jdeighan/coffee-utils'

export init = () ->
	setUnitTesting(true)

init()
