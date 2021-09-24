# pannable.coffee

export pannable = (node) ->

	x = y = 0

	handleMousedown = (event) ->
		x = event.clientX
		y = event.clientY

		node.dispatchEvent(new CustomEvent('panstart', {
			detail: {x, y}
			}))

		window.addEventListener('mousemove', handleMousemove);
		window.addEventListener('mouseup', handleMouseup);

	handleMousemove = (event) ->
		dx = event.clientX - x
		dy = event.clientY - y
		x = event.clientX
		y = event.clientY

		node.dispatchEvent(new CustomEvent('panmove', {
			detail: {x, y, dx, dy}
			}));

	handleMouseup = (event) ->
		x = event.clientX
		y = event.clientY

		node.dispatchEvent(new CustomEvent('panend', {
			detail: {x, y}
			}))

		window.removeEventListener('mousemove', handleMousemove)
		window.removeEventListener('mouseup', handleMouseup)

	node.addEventListener('mousedown', handleMousedown);

	return {
		destroy: () ->
			node.removeEventListener('mousedown', handleMousedown);
		}
