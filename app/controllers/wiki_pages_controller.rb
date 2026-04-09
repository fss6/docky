# frozen_string_literal: true

class WikiPagesController < ApplicationController
  before_action :authorize_policy

  def index
    @wiki_pages = current_account.wiki_pages.ordered

    @pages_by_type = WikiPage::PAGE_TYPES.index_with do |type|
      @wiki_pages.select { |p| p.page_type == type }
    end

    @selected_page = if params[:slug].present?
      current_account.wiki_pages.find_by(slug: params[:slug])
    else
      @wiki_pages.first
    end
  end

  def show
    @wiki_page = current_account.wiki_pages.find_by!(slug: params[:slug])
    @links_out = @wiki_page.outgoing_links.includes(:target_page)
    @links_in  = @wiki_page.incoming_links.includes(:source_page)
  end

  def log
    @wiki_logs = current_account.wiki_logs.recent.limit(50)
  end

  def lint_report
    last_lint = current_account.wiki_logs.for_operation("lint").recent.first
    @lint_issues = if last_lint&.details.present?
      parsed = JSON.parse(last_lint.details) rescue {}
      parsed["issues"] || []
    else
      []
    end
    @last_lint_at = last_lint&.created_at
  end

  private

  def current_account
    current_user.account
  end

  def authorize_policy
    authorize :wiki_page, policy_class: WikiPagePolicy
  end
end
