class PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:new, :pay, :address, :card, :card_index]

  require 'payjp'
  require 'date'

  def new
    @card = current_user.card
    if @card
      Payjp.api_key = Rails.application.credentials.payjp[:test_secret_key]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @default_card_information = customer.cards.retrieve(@card.card_id)
    end
    render layout: 'application-off-header-footer.html.haml'
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

end
