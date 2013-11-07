#= require jquery
#= require browserid
#= require jquery_ujs
#= require jquery.form
#= require jquery_nested_form
#= require underscore
#= require underscore.string
#= require underscore.inflection
#= require backbone
#= require backbone.marionette
#= require foundation
#= require moment

#= require_self

#= require_tree ./plugins
#= require_tree ./app


_.mixin(_.str.exports())


$ ->
  $(document).on 'rendered.chrForm', (e, $form) ->
    Character.Plugins.fix_date_field_layout()
    Character.Plugins.enableDrawers()
    Character.Plugins.imagesHelperReorderable()


@chr = new Backbone.Marionette.Application()

@chr.on "initialize:before", (@options) ->
  main_view = new Character.MainView()
  main_view.render().$el.prependTo('body')

  @main = main_view.content
  @menu = main_view.menu.currentView

  # set user avatar
  @menu.ui.avatar.attr('src', options.user.avatar_url)

  # add project logo
  $("<style>.logo{background-image:url('#{ options.logo }');}</style>").appendTo("head")

  # initialize foundation plugins
  $(document).foundation('section forms dropdown')


@chr.on "initialize:after", ->
  Backbone.history.start() if Backbone.history
  location.hash = @menu.firstItem().attr('href') if location.hash == ""


@Character ||= {}

#========================================================
# Main
#========================================================
@Character.MainView = Backbone.Marionette.Layout.extend
  id:        'character'
  className: 'character'

  template: -> "<div id='menu' class='chr-menu'></div><div id='content' class='chr-content'></div>"

  onRender: ->
    @menu.show(new Character.MenuView())

  regions:
    menu:    '#menu'
    content: '#content'

#========================================================
# Menu
#========================================================
@Character.MenuView = Backbone.Marionette.ItemView.extend
  tagName: 'nav'

  template: -> """<img id='user_avatar' src="">
                  <ul id='menu_items'></ul>
                  <a href='' class='browserid_logout'><i class="fa fa-signout"></i>Sign out</a>"""

  ui:
    items:          '#menu_items'
    avatar:         '#user_avatar'
    action_logout:  '.browserid_logout'

  addItem: (path, icon, title) ->
    @ui.items.append("<li><a href='#/#{ path }' class='mi-#{ path }'><i class='fa fa-#{ icon }'></i>#{ title }</a></li>")

  selectItem: (cls) ->
    @$el.find('a.active').removeClass('active')
    @$el.find("a.mi-#{cls}").addClass('active')

  firstItem: ->
    @ui.items.find('a:eq(0)')

  onRender: ->
    @ui.action_logout.attr 'href', chr.options.url + '/logout'