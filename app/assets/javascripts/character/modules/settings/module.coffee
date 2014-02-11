#= require_self
#= require ./layout
#= require ./details

@Character.Settings ||= {}

#
# Marionette.js Module Documentation
# https://github.com/marionettejs/backbone.marionette/blob/master/docs/marionette.application.module.md
#
chr.module 'settings', (module) ->
  module.addInitializer ->
    @layout     = new Character.Settings.Layout({ module: @ })
    @controller = new Character.Settings.Controller({ module: @ })
    @router     = new Character.Settings.Router({ controller: @controller })

#
# Marionette.js Router Documentation
# https://github.com/marionettejs/backbone.marionette/blob/master/docs/marionette.approuter.md
#
@Character.Settings.Router = Backbone.Marionette.AppRouter.extend
  appRoutes:
    'settings': 'index'
    'settings/:settingsModuleName': 'edit'

#
# Marionette.js Controller Documentation
# https://github.com/marionettejs/backbone.marionette/blob/master/docs/marionette.controller.md
#
@Character.Settings.Controller = Marionette.Controller.extend
  initialize: ->
    @module = @options.module

  index: ->
    chr.execute('showModule', @module)
    chr.currentPath = "settings"

  edit: (settingsModuleName) ->
    @index()

    options = @module.submodules[settingsModuleName].options
    detailsView = new options.detailsViewClass(options)

    @module.layout.details.show(detailsView)
    @module.layout.setActiveMenuItem(settingsModuleName)

#
# Character Settings Module
# Initialize function
#
chr.settingsModule = (title, options={}) ->
  options.titleMenu    ?= title
  options.titleDetails ?= title
  options.moduleName   ?= _.underscored(title)

  options.detailsViewClass ?= Character.Settings.DetailsView

  chr.module "settings.#{options.moduleName}", ->
    @options = options


#
# Admin Settings
# Feature: add new admin list item
#
$(document).on 'chr-admins-details-content.rendered', (e) ->
  $('.objects_email input').on 'keyup', (e) ->
    if e.which == 13
      $item = $('#template').clone()
      $item.attr('id', '')
      $item.html $item.html().replace(/objects\[\]\[\]/g, "objects[][#{ new Date().getTime() }]")
      $('#template').before($item)
      $item.find('input').val($(e.currentTarget).val())
      $item.find('.action_delete').show()
      $item.find('.fa-plus').hide()
      $(e.currentTarget).val('')

$(document).on 'chr-admins-details-content.closed', (e) ->
  $('.objects_email input').off 'keyup'