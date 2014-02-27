
#
# Marionette.js Item View Documentation
# https://github.com/marionettejs/backbone.marionette/blob/master/docs/marionette.itemview.md
#
@Character.Generic.DetailsHeaderView = Backbone.Marionette.ItemView.extend
  template: -> "<a id=close class=close href='#'><i class='chr-icon icon-close'></i></a>
                <button id=save class=save title='Save changes'>Save</button>
                <div id=details_title class=title></div>
                <a id=delete class=delete href='#' title='Delete this item'>
                  <i class='fa fa-trash-o'></i>
                </a>
                <span id=details_meta class=meta></span>"

  ui:
    title:        '#details_title'
    meta:         '#details_meta'
    actionClose:  '#close'
    actionSave:   '#save'
    actionDelete: '#delete'

  initialize: ->
    if @model
      @listenTo(@model, 'change', @render, @)

  onRender: ->
    if @model
      title = @model.getTitle()
      updatedFromNow = moment(@model.get('updated_at')).fromNow()
      @ui.meta.html("updated #{ updatedFromNow }")
    else
      title = @options.title

    @ui.title.html(title)
    @ui.actionClose.attr 'href', '#/' + chr.currentPath

    if not @options.deletable
      @ui.actionDelete.hide()

  # TODO: update this method
  updateState: (state) ->
    if @ui
      if state == 'saving'
        @ui.actionSave.addClass('disabled')
        @ui.actionSave.html 'Saving...'
      else
        setTimeout ( =>
          @ui.actionSave.removeClass('disabled')
          @ui.actionSave.html('Save')
        ), 500


#
# Marionette.js Layout Documentation
# https://github.com/marionettejs/backbone.marionette/blob/master/docs/marionette.itemview.md
#
@Character.Generic.DetailsLayout = Backbone.Marionette.Layout.extend
  className: 'chr-details'
  template: -> "<header id=details_header class='chr-details-header'></header>
                <section id=details_content class='chr-details-content'></section>"

  regions:
    header: '#details_header'

  ui:
    content: '#details_content'

  initialize: ->
    @module            = @options.module
    @DetailsHeaderView = @module.DetailsHeaderView
    @router            = @module.router

  onRender: ->
    @headerView = new @DetailsHeaderView
      model:     @model
      title:     "New #{ @options.objectName }"
      deletable: @options.deletable

    @header.show(@headerView)

    if @model then @$el.addClass('update')

    $.ajax
      type: 'get'
      url:  @options.formUrl
      success: (data) =>
        @renderContent(data)
      error: (xhr, ajaxOptions, thrownError) =>
        chr.execute('showError', xhr)

  renderContent: (html) ->
    if @ui
      @ui.content.html(html)

      @ui.form = @ui.content.find('form.simple_form')

      if @ui.form.length
        # start form related helpers
        Character.Generic.Helpers.startDateSelect(@ui.form)

      $(document).trigger("chr-details-content.rendered", [ @ui.content ])
      $(document).trigger("chr-#{ @module.moduleName }-details-content.rendered", [ @ui.content ])

      @afterContentRendered?()

  events:
    'click #save':   'onSave'
    'click #delete': 'onDelete'

  onSave: ->
    if @ui.form.length
      Character.Generic.Helpers.serializeDataInputs(@ui.content, @ui.form)

      # include fields to properly update item in a list and sort
      params = _.clone(@collection.options.constantParams)
      if @collection.sortField
        params.f = _([ params.f, @collection.sortField ]).uniq().join(',')

      @ui.form.ajaxSubmit
        data: params
        beforeSubmit: (arr, $form, options) =>
          @headerView.updateState('saving')
          return true
        error: (xhr) =>
          chr.execute('showError', xhr)
          @headerView.updateState()
        success: (responseText, statusText, xhr, $form) =>
          @headerView.updateState()
          @updateModel(responseText)

    return false

  updateModel: (resp) ->
    # when response is a string, that means form with errors returned
    if typeof(resp) == 'string'
      return @renderContent(resp)

    # assuming response is json
    if @model
      @model.set(resp)
      @collection.sort()
    else
      @collection.fetchPage(1)

  onDelete: ->
    if confirm("""Are you sure about deleting "#{ @model.getTitle() }"?""")
      @close()
      @model.destroy
        success: =>
          @router.navigate(chr.currentPath)
        error: (model, response, options) ->
          chr.execute('error', response)
    return false

  onClose: ->
    window.closeDetailsView = null
    if @ui

      if @ui.form
        # Stop form related helpers
        Character.Generic.Helpers.stopDateSelect(@ui.form)

      $(document).trigger("chr-details-content.closed", [ @ui.content ])
      $(document).trigger("chr-#{ @module.moduleName }-details-content.closed", [ @ui.content ])