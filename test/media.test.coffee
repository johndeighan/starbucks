# media.test.coffee

import {pass, undef, deepCopy} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {UnitTester} from '@jdeighan/coffee-utils/test'
import {hPrivEnv} from '@jdeighan/coffee-utils/privenv'
import {loadPrivEnvFrom} from '@jdeighan/env'
import {
	hMediaQueries, loadMediaQueries, getMediaQuery,
	} from '@jdeighan/starbucks/media'

loadPrivEnvFrom(mydir(`import.meta.url`))
simple = new UnitTester()

# ---------------------------------------------------------------------------

(() ->
	hSave = deepCopy(hMediaQueries)
	simple.equal 14, hSave, {
		mobile: 'screen and (max-device-width: 6in) and (max-device-height: 6in)',
		tablet: 'screen and (min-device-width: 6in) and (max-device-width: 12in) and (min-device-height: 6in) and (max-device-height: 12in)',
		other:  'screen and (min-device-width: 12in) and (min-device-height: 12in)',
		}
	)()

# ---------------------------------------------------------------------------
# test ability to override defaults

(() ->
	hPrivEnv.MEDIA_MOBILE = "screen and size(2..8, 0..4 in)"
	loadMediaQueries()
	simple.equal 27, hMediaQueries.mobile,
		'screen and (min-device-width: 2in) and (max-device-width: 8in) and (max-device-height: 4in)',
	)()
