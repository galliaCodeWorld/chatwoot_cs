# frozen_string_literal: true

# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
class Api::V3::Entities::CampaignsController < Api::V3::EntitiesController
  # before_action :get_data_for_sidebar, only: :index

  def index
    # @campaigns = get_campaigns(page: page_param, per_page: per_page_param)
    @campaigns = get_campaigns
    render json: {data: @campaigns.to_json, success: true}, status: 200
  end

  def show
    # respond_with(@campaign) do |format|
    #   format.html do
    #     @stage = Setting.unroll(:opportunity_stage)
    #     @comment = Comment.new
    #     @timeline = timeline(@campaign)
    #   end

    #   format.js do
    #     @stage = Setting.unroll(:opportunity_stage)
    #     @comment = Comment.new
    #     @timeline = timeline(@campaign)
    #   end

    #   format.xls do
    #     @leads = @campaign.leads
    #     render '/leads/index', layout: 'header'
    #   end

    #   format.csv do
    #     render csv: @campaign.leads
    #   end

    #   format.rss do
    #     @items  = "leads"
    #     @assets = @campaign.leads
    #   end

    #   format.atom do
    #     @items  = "leads"
    #     @assets = @campaign.leads
    #   end
    # end
    render json: {data: @campaign.to_json(include: [:tasks, :leads, :opportunities]), success: true}, status:500
  end

  def new
    @campaign.attributes = { user: current_user, access: Setting.default_access, assigned_to: nil }

    if params[:related]
      model, id = params[:related].split('_')
      if related = model.classify.constantize.my(current_user).find_by_id(id)
        instance_variable_set("@#{model}", related)
      else
        respond_to_related_not_found(model) && return
      end
    end

    respond_with(@campaign)
  end

  def edit
    # @previous = Campaign.my(current_user).find_by_id(Regexp.last_match[1]) || Regexp.last_match[1].to_i if params[:previous].to_s =~ /(\d+)\z/

    render json: {data:@campaign.to_json, success: true}, status:200
  end

  def create
    @comment_body = params[:comment_body]
    @campaign = Campaign.new(params[:campaign])
    if @campaign.save
      @campaign.add_comment_by_user(@comment_body, current_user)
      @campaigns = get_campaigns
      # get_data_for_sidebar
      render json: {data: @campaign, success: true}, status: 200
    else
      render json: {msg: @campaign.errors.to_json, success: false}, status: 500
    end
  end

  def update
    @campaign = Campaign.find(params[:id])
    # Must set access before user_ids, because user_ids= method depends on access value.
    @campaign.access = resource_params[:access] if resource_params[:access]
    # get_data_for_sidebar if @campaign.update(resource_params) && called_from_index_page?
    if @campaign.update(params[:campaign])
      render json: {data: @campaign.to_json, success: true}, status: 200
    else
      render json: {msg: @campaign.errors.to_json, success: false}, status: 500
    end
  end

  def delete
    if @campaign.destroy
      render json: {data: @campaign, success: true}, status: 200
    else
      render json: {msg: @campaign.errors.to_json, success: false}, status: 500
    end
  end

  def redraw
    current_user.pref[:campaigns_per_page] = per_page_param if per_page_param
    current_user.pref[:campaigns_sort_by]  = Campaign.sort_by_map[params[:sort_by]] if params[:sort_by]
    @campaigns = get_campaigns(page: 1, per_page: per_page_param)
    set_options # Refresh options

    respond_with(@campaigns) do |format|
      format.js { render :index }
    end
  end

  def filter
    session[:campaigns_filter] = params[:status]
    @campaigns = get_campaigns(page: 1, per_page: per_page_param)

    respond_with(@campaigns) do |format|
      format.js { render :index }
    end
  end

  private

  def get_campaigns
    self.current_page  = params[:page] if params[:page]
    self.current_query = params[:query] if params[:query]

    @search = klass.ransack(params[:q])
    @search.build_grouping unless @search.groupings.any?

    scope = Campaign.text_search(params[:query])
    scope = scope.merge(@search.result)
    scope = scope.text_search(current_query)      if current_query.present?
    scope = scope.paginate(page: current_page) 
    scope
  end

  def list_includes
    %i[tags].freeze
  end

  def respond_to_destroy(method)
    if method == :ajax
      get_data_for_sidebar
      @campaigns = get_campaigns
      if @campaigns.blank?
        @campaigns = get_campaigns(page: current_page - 1) if current_page > 1
        render(:index) && return
      end
      # At this point render destroy.js
    else # :html request
      self.current_page = 1
      flash[:notice] = t(:msg_asset_deleted, @campaign.name)
      redirect_to campaigns_path
    end
  end

  def get_data_for_sidebar
    @campaign_status_total = HashWithIndifferentAccess[
                             all: Campaign.my(current_user).count,
                             other: 0
    ]
    Setting.campaign_status.each do |key|
      @campaign_status_total[key] = 0
    end

    status_counts = Campaign.my(current_user).where(status: Setting.campaign_status).group(:status).count
    status_counts.each do |key, total|
      @campaign_status_total[key.to_sym] = total
      @campaign_status_total[:other] -= total
    end
    @campaign_status_total[:other] += @campaign_status_total[:all]
  end
end
