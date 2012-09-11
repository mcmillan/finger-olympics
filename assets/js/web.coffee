update_intro_wording = ->

	count = $('.users div[data-id]').length

	if count > 0
		$('.intro p').html 'OK, let\'s play! <a href="#" class="begin">Start the game</a> to get going.'
	else
		$('.intro p').html 'We\'re waiting for ' + (2 - count) + ' more player' + (if count isnt 1 then 's' else '') + ' right now. Scan the QR code to get going.'

now.ready ->

	now.receive_new_player = (user) ->

		if $('.users div[data-id=' + user.id + ']').length isnt 0
			return

		$('.users .no-players').slideUp 300
		$('<div data-id="' + user.id + '"><img src="//graph.facebook.com/' + user.id + '/picture">' + user.displayName + '</div>').prependTo('.users').hide().slideDown 300

		update_intro_wording()

	now.receive_lost_player = (user) ->

		$('.users div[data-id=' + user.id + ']').slideUp 300, ->

			$(this).remove()

			if $('.users div[data-id]').length is 0
				$('.users .no-players').slideDown 300

			update_intro_wording()

	now.backfill_players()

	$('.intro p').on 'click', 'a', (event) ->

		event.preventDefault()

		now.start_game()