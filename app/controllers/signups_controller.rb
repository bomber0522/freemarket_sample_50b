class SignupsController < ApplicationController
  def index
    render layout: 'application-off-header-footer.html.haml'
  end

  def new

  end

  def show
    render layout: 'application-off-header-footer.html.haml'
  end
end
