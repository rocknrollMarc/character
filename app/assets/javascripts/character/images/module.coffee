
@Character.Images ||= {}

@Character.Images.ListItemView = Backbone.Marionette.ItemView.extend
  tagName: 'li'

  template: (item) -> ''

  onRender: ->
    thumbUrl = @model.get('image').image.chr_thumb.url
    @$el.css 'background-image', "url(#{ thumbUrl })"
    @$el.attr 'data-id', @model.id


@Character.Images.ListView = Backbone.Marionette.CollectionView.extend
  tagName: 'ul'
  itemView: Character.Images.ListItemView


@Character.Images.Layout = Backbone.Marionette.Layout.extend
  id:        'chr_images'
  className: 'chr-images'

  template: -> """<div id=chr_images_dialog class='chr-images-dialog'>
                    <header class='chr-images-header'>
                      <span class='title'>Images</span>
                      <button id='chr_images_close' type='button' class='chr-images-close'><i class='chr-icon icon-close-alt'></i></button>
                    </header>
                    <section id=chr_images_grid class='chr-images-grid'></section>
                    <footer class='chr-images-footer'>
                      <button id=chr_images_insert class='button right'>Insert</button>
                      <button id=chr_images_cancel class='button right'>Cancel</button>
                      <div class='button'>
                        <input id=chr_images_upload class='chr-images-upload' type='file' name='character_image[image]' multiple='' />
                        Upload files...
                      </div>
                    </footer>
                  </div>"""

  ui:
    dialog:       '#chr_images_dialog'
    uploadInput:  '#chr_images_upload'
    listContent:  '#chr_images_grid'
    insertButton: '#chr_images_insert'

  regions:
    listContent: '#chr_images_grid'

  events:
    'click #chr_images_close':   'hide'
    'click #chr_images_cancel':  'hide'
    'click #chr_images_insert':  '_insert'
    'click #chr_images_grid li': '_selectImage'

  onRender: ->
    dialogWidth = Math.floor(($(window).width() - 322) / 176 ) * 176 + 20
    @ui.dialog.css { 'margin-left': dialogWidth / -2, 'width': dialogWidth }

    @list = new Character.Images.ListView({ collection: @options.collection })
    @listContent.show(@list)

    @ui.uploadInput.fileupload
      url: '/admin/Character-Image'
      paramName: 'character_image[image]'
      dataType:  'json'
      dropZone:  @ui.listContent
      done: (e, data) => # TODO: prosess multiple file uploads here
        @collection.add([data.result]) # TODO: fix sorting issue

    # TODO: this is hack to prevent blinking when use dragenter/dragleave
    @ui.listContent.on 'dragenter',  => @ui.listContent.addClass('dragover')
    @ui.listContent.on 'mouseleave', => @ui.listContent.removeClass('dragover')

  show: (@callback, @multipleSelection) ->
    @$el.addClass('open')
    @ui.listContent.find('.selected').removeClass('selected')
    @ui.insertButton.addClass('disabled')
    @ui.listContent.removeClass('dragover')

  hide: ->
    @$el.removeClass('open')

  _insert: ->
    if not @ui.insertButton.hasClass 'disabled'
      if @callback
        selectedModels = _.collect $('#chr_images_grid li.selected'), (el) =>
          id = $(el).attr('data-id')
          @options.collection.get(id)

        @callback(selectedModels)
      @hide()

  _selectImage: (e) ->
    $el = $(e.currentTarget)

    if not chr.images.options.multipleSelection
      @ui.listContent.find('.selected').removeClass 'selected'

    $el.toggleClass 'selected'
    @ui.insertButton.removeClass 'disabled'


# module initialization
chr.module 'images', (module) ->
  module.on 'start', ->
    @collection = new Character.Generic.Collection()
    @collection.options =
      collectionUrl: "#{ chr.options.url }/Character-Image"
    @collection.sortField = 'created_at'
    @collection.sortDirection = 'desc'
    @collection.fetchPage(1)

    @layout = new Character.Images.Layout({ collection: @collection })
    $('#character').after(@layout.render().$el)

    # extend character api
    chr.commands.setHandler 'showImages', (multipleSelection=false, callback=false) =>
      @options.multipleSelection = multipleSelection
      @layout.show(callback)

    chr.commands.setHandler 'hideImages', =>
      @layout.hide()