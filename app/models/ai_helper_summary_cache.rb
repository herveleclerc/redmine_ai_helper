class AiHelperSummaryCache < ApplicationRecord
  validates :object_class, presence: true
  validates :object_id, presence: true, uniqueness: { scope: :object_class }
  validates :content, presence: true

  def self.issue_cache(issue_id:)
    AiHelperSummaryCache.find_by(object_class: "Issue", object_id: issue_id)
  end

  def self.update_issue_cache(issue_id:, content:)
    cache = issue_cache(issue_id: issue_id)
    if cache
      cache.update(content: content)
      cache.save!
    else
      cache = AiHelperSummaryCache.new(object_class: "Issue", object_id: issue_id, content: content)
      cache.save!
    end
    cache
  end

  def self.wiki_cache(wiki_page_id:)
    AiHelperSummaryCache.find_by(object_class: "WikiPage", object_id: wiki_page_id)
  end

  def self.update_wiki_cache(wiki_page_id:, content:)
    cache = wiki_cache(wiki_page_id: wiki_page_id)
    if cache
      cache.update(content: content)
      cache.save!
    else
      cache = AiHelperSummaryCache.new(object_class: "WikiPage", object_id: wiki_page_id, content: content)
      cache.save!
    end
    cache
  end
end
