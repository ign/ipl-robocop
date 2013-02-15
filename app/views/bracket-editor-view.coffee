View = require 'views/base/view'
Collection = require 'models/base/collection'
BracketView = require 'views/brackets/bracket-view'
BracketUrls = require 'utility/brackets/bracket-urls'
mediator = require 'mediator'

module.exports = class BracketEditorView extends BracketView
	initialize:(options)->
		super(options)
		@model.url = ()-> BracketUrls.apiBase+"/brackets/v6/api/"
		mediator.subscribe 'save-bracket', @saveBracket
		mediator.subscribe 'save-events', @saveEvents
		mediator.subscribe 'save-matchups', @saveMatchup
		mediator.subscribe 'save-game', @saveGame

		@delegate 'click', '.match', (ev)->@clickMatch(ev)
		@delegate 'click', '.hotzone', ()-> @deselect()
		@delegate 'click', '.bracket-title', (ev)->@editTitle(ev)
		@delegate 'blur', '.bracket-title-input', (ev)->@saveTitle(ev)
		@selected = []

	render: ->
		super
		$('<div class="hotzone">').appendTo(@$el).width(@$el.width()).height(@$el.height())
		$('<input type="text" class="bracket-title-input">').appendTo(@.$('.label-layer span.bracket-title'))
		@

	saveBracket: ()=>
		@model.save null,
			xhrFields:
				withCredentials: true

	clickMatch: (ev)=>
		unless ev.shiftKey is true
			@deselect()
		$(ev.currentTarget).addClass 'activeSelect'
		@selected.push $(ev.currentTarget).data('match')
		mediator.publish 'change:selected', @selected
		@saveEvents _.map @selected, (match)-> match.event()
		@saveMatchups _.map @selected, (match)-> match.matchup()

	deselect: ()=>
		$('.match.activeSelect').removeClass 'activeSelect'
		@selected = []
	editTitle: (ev)=>
		$(ev.currentTarget).addClass 'editing'
		$(ev.currentTarget).find('input').focus().val @model.get('title')

	saveTitle:(ev)=>
		$(ev.currentTarget).parent('span').removeClass 'editing'
		newTitle = String($(ev.currentTarget).val().trim())
		@model.set 'title', newTitle
		@model.set 'slug', newTitle.toLowerCase().replace(/\ /g, '-')
		@.$('.bracket-title h1').text @model.get 'title'
		mediator.publish 'save-bracket'

	saveEvents:(events)->
		if events?
			for event in events
				event.save null,
					success: (model, resp, options)=>
						console.log "it worked", resp
					error: (model, xhr, options)=>
						console.log "oh no", model

	saveMatchups:(matchups)->
		if matchups?
			for matchup in matchups
				matchup.save()

	saveGame:(game)->
		game.save()
