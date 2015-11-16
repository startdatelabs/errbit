class Api::V1::StatsController < ApplicationController
  respond_to :json, :xml

  # The stats API only requires an api_key for the given app.
  skip_before_action :authenticate_user!
  before_action :require_api_key_or_authenticate_user!

  def app
    if (problem = @app.problems.order_by(:last_notice_at.desc).first)
      @last_error_time = problem.last_notice_at
    end

    stats = {
      name:              @app.name,
      id:                @app.id,
      last_error_time:   @last_error_time,
      unresolved_errors: @app.unresolved_count
    }

    respond_to do |format|
      format.any(:html, :json) { render json: JSON.dump(stats) } # render JSON if no extension specified on path
      format.xml { render xml: stats }
    end
  end

  def daily_report
    date = Date.parse(params[:date]) rescue Date.yesterday
    count_problems = @app.problems.where(:updated_at.gt => date.beginning_of_day).where(:updated_at.lt => date.end_of_day).count
    count_times = @app.problems.where(:updated_at.gt => Date.yesterday.beginning_of_day).where(:updated_at.lt => Date.yesterday.end_of_day).sum(&:notices_count)
    count_resolved = @app.problems.where(:resolved_at.gt => date.beginning_of_day).where(:resolved_at.lt => date.end_of_day).count
    count_all_errors = @app.unresolved_count

    stats = {
      :name => @app.name,
      :id => @app.id,
      :date => date.strftime("%m/%d/%y"),
      :daily_problems_count => count_problems,
      :daily_error_times => count_times,
      :daily_resolved => count_resolved,
      :total_problems => count_all_errors,
      :unresolved_errors => @app.unresolved_count
    }

    respond_to do |format|
      format.any(:html, :json) { render :json => JSON.dump(stats) } # render JSON if no extension specified on path
      format.xml  { render :xml  => stats }
    end
  end

  protected def require_api_key_or_authenticate_user!
    if params[:api_key].present?
      return true if (@app = App.where(api_key: params[:api_key]).first)
    end

    authenticate_user!
  end
end
