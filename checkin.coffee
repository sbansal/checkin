root = global ? window

root.Teams = new Meteor.Collection 'players'
root.Checkins = new Meteor.Collection('checkins')

if root.Meteor.isClient
  root.Template.main.teams = -> root.Teams.find()

  root.Template.main.checkins = () -> root.Checkins.find()

  root.Template.main.days = () ->
    days = root.Template.main.checkins().map (checkin) -> checkin.day
    _.uniq(days).sort().reverse().map (day) -> new Date(day)

  root.Template.main.preview = -> root.Session.get('preview')

  root.Template.main.columnWidth = -> 100 / (root.Template.main.teams().count())

  root.Template.main.events =
    'click #add-new-checkin': ->
      teamId = $('#team').val()
      description = $('#text').val()
      createdDate = new Date()
      root.Checkins.insert
        teamId: teamId
        description: description
        day: new Date(createdDate.getFullYear(), createdDate.getMonth(), createdDate.getDate()).toISOString()
        createdDate: createdDate.toISOString()
      $('#text').val('')
      root.Session.set('preview', '')

    'keyup #text': -> root.Session.set('preview', $('#text').val())

  root.Template.day.displayString = -> @toLocaleDateString()

  root.Template.day.teamDays = -> root.Template.main.teams()
      .map (team) =>
        team: team
        day: @

  root.Template.teamDay.checkins = -> root.Checkins.find(
    {
      teamId: @team._id
      day: @day.toISOString()
    },
    {
      sort: [['createdDate', 'desc']]
    })

  root.Template.teamLatest.checkin = -> root.Checkins.findOne(
    {teamId: @_id},
    {sort: [
      ['day', 'desc']
      ['createdDate', 'desc']]})

if root.Meteor.isServer
  root.Meteor.startup ->
    root.Meteor.settings.teams.forEach (team) ->
      unless root.Teams.findOne(name: team.name)?
        console.log("Adding team #{team.name}")
        root.Teams.insert(name: team.name)

    if root.Meteor.settings.checkins?
      root.Meteor.settings.checkins.forEach (checkinData) ->
        team = root.Teams.findOne(name: checkinData.teamName)
        unless root.Checkins.findOne(day: checkinData.day, teamId: team._id, description: checkinData.description)?
          console.log("Adding checkin for team #{team.name} on #{new Date(checkinData.day).toLocaleDateString()}")
          root.Checkins.insert
            teamId: team._id
            description: checkinData.description
            day: checkinData.day
            createdDate: (new Date()).toISOString()
