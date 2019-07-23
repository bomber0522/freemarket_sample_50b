


class CardsController < ApplicationController
  def index
  end

  def new
    render layout: 'application-off-header-footer.html.haml'
  end

  def show
    render layout: 'application-off-header-foote.html.haml'
  end
end
