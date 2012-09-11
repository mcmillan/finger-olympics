now.ready ->

	now.receive_new_player = (user) ->

		if $('.users div[data-id=' + user.id + ']').length isnt 0
			return

		$('.users .no-players').slideUp 300
		$('<div data-id="' + user.id + '"><img src="//graph.facebook.com/' + user.id + '/picture">' + user.displayName + '</div>').prependTo('.users').hide().slideDown 300

	now.receive_lost_player = (user) ->

		$('.users div[data-id=' + user.id + ']').slideUp 300, ->

			$(this).remove()

			if $('.users div[data-id]').length is 0
				$('.users .no-players').slideDown 300

	now.backfill_players()