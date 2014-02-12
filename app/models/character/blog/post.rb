# encoding: UTF-8
class Character::Blog::Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Mongoid::Search
  include ActionView::Helpers::DateHelper

  # attributes
  field :title
  field :body_html
  mount_uploader :featured_image, Character::Blog::FeaturedImageUploader
  field :published_at, type: Date
  field :published,    type: Boolean, default: false
  field :subtitle, default: ''
  field :keywords, default: ''

  # relations
  belongs_to :category, class_name: "Character::Blog::Category"

  # slugs and search
  slug      :title, history: true
  search_in :title, :keywords, :body_html, :category => :title

  # scopes
  default_scope     -> { order_by(published_at: :desc) }
  scope :published, -> { where(published: true) }
  scope :drafts,    -> { where(published: false) }

  # indexes
  index({ slug: 1 })
  index({ published: 1, date: -1 })

  def has_featured_image?
    not ( featured_image.to_s.ends_with?('_old_') or featured_image.to_s.empty? )
  end

  def updated_ago
    "updated #{time_ago_in_words(updated_at)} ago"
  end
end