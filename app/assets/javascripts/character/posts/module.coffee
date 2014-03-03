# ---------------------------------------------------------
# BLOG POSTS
# ---------------------------------------------------------

@Character.Posts = {}

#
# Marionette.js Layout Documentation
# https://github.com/marionettejs/backbone.marionette/blob/master/docs/marionette.itemview.md
# character/generic/details.coffee
@Character.Posts.DetailsLayout = Character.Generic.DetailsLayout.extend
  updateFeaturedImage: (imageData) ->
    imageUrl = imageData.image.url
    thumbUrl = imageData.image.chr_thumb_small.url

    @ui.featuredImageInput.val(imageUrl)
    @ui.featuredThumbInput.val(thumbUrl)

    @ui.featuredImageUploader.children('img').remove()
    @ui.featuredImageUploader.addClass('character-image').append("<img src='#{ imageUrl }' />")

  getSubtitleValue: ->
    # TODO: add case when image is posted first or nothing is posted
    @ui.postContent.children().first().text()

  _bindSubtitleUpdate: ->
    # update subtitle to be first passage of the body text
    @ui.subtitleField.val(@getSubtitleValue())
    @ui.postContent.on 'keyup', => @ui.subtitleField.val(@getSubtitleValue())

  _toggleFullscreen: ->
    # show fullscreen if post is not published
    if not @ui.publishedCheckbox.is(':checked')
      @$el.parent().addClass('fullscreen')

  _hideForm: ->
    @ui.content.find('.blog-post').css { 'min-height': $(window).height() }
    @ui.content.scrollTop @ui.form.innerHeight()

  _bindFeaturedImageUploader: ->
    imageUrl = @ui.featuredImageUploader.attr('data-image-url')
    if imageUrl and imageUrl != ''
      @ui.featuredImageUploader.addClass('character-image').append("<img src='#{ imageUrl }' />")

    @ui.featuredImageUploader.on 'click', (e) =>
      chr.execute 'showImages', false, (images) =>
        model = images[0]
        if model
          @updateFeaturedImage(model.get('image'))

    @ui.featuredImageUploader.fileupload
      url: '/admin/Character-Image'
      paramName: 'character_image[image]'
      dataType:  'json'
      dropZone:  @ui.featuredImageUploader
      done: (e, data) => @updateFeaturedImage(data.result.image)

  afterRenderContent: ->
    @ui.featuredImageUploader = $('#character_post_featured_image_uploader')
    @ui.featuredImageInput    = $('#character_blog_post_featured_image_url')
    @ui.featuredThumbInput    = $('#character_blog_post_featured_image_chr_thumbnail_url')
    @ui.publishedCheckbox     = $('#character_blog_post_published')
    @ui.subtitleField         = $('#character_blog_post_subtitle')
    @ui.postContent           = @ui.content.find('.blog-post .content')

    @_toggleFullscreen()
    @_hideForm()
    @_bindSubtitleUpdate()
    @_bindFeaturedImageUploader()

  afterOnClose: ->
    @ui.postContent.off 'keyup'
    @$el.parent().removeClass('fullscreen')
    @ui.featuredImageUploader.off('click').fileupload('destroy')


chr.postsModule = (opts) ->
  moduleOpts =
    implementation: Character.Posts
    menuIcon:       'rss'
    menuTitle:      'Posts'
    listItem:
      titleField:   'title'
      metaField:    'updated_ago'
      thumbField:   'chr_featured_thumbnail_url'
    modelName:      'Character-Blog-Post'
    listSearch:     true
    listScopes:
      default:
        orderBy:    'published_at:desc'
      published:
        where:      'published=true'
        orderBy:    'published_at:desc'
      drafts:
        where:      'published=false'
        orderBy:    'published_at:desc'

  _(moduleOpts).extend(opts)

  chr.genericModule('Post', moduleOpts)