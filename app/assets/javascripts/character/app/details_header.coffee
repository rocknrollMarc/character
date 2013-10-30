@Character.App ||= {}
@Character.App.DetailsHeaderView = Backbone.Marionette.ItemView.extend
  template: -> "<span id=details_title class='title'></span><span class='chr-actions'><i class='chr-action-pin'></i><a id=action_delete>Delete</a></span>
                <div id=details_meta class='meta'></div>
                <a id='action_save' class='chr-action-save'><span class='create'>Create</span><span class='save'>Save</span></a>"

  ui:
    title: '#details_title'
    meta:  '#details_meta'

  initialize: ->
    @listenTo(@model, 'change', @render, @) if @model

  onRender: ->
    @ui.title.html if @model then @model.getTitle() else @options.name
    @ui.meta.html("Updated #{ moment(@model.get('updated_at')).fromNow() }") if @model