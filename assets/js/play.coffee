now.ready ->

	if !user
		return

	now.user = user

	now.new_player user

	now.show_game = ->

		$('h1').html 'Tap!'

		$('body').on 'touchend', ->

			now.on_tap()

	now.finished = (winner) ->

		$('body').off 'touchend'
		now.position = 0
		$('h1').html if winner.id is user.id then 'Well done!' else 'Bad luck.'