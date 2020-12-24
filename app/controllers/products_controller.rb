class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :destroy]
  before_action :authenticate_user!, except: [:show, :search_products]

  def new
    @product = Product.new
    @product.product_images.build
    render layout: 'application-off-header-footer.html.haml'
  end

  def create
    # ブランド名がstringでparamsに入ってくるので、id番号に書き換え
    if brand = Brand.find_by(name: params[:product][:brand_id])
      params[:product][:brand_id] = brand.id
    else
      params[:product][:brand_id] = Brand.create(name: params[:product][:brand_id]).id
    end

    @product = Product.new(product_params)
    if new_image_params[:images][0] != " " && @product.save
      new_image_params[:images].each do |image|
        @product.product_images.create(image_url: image, product_id: @product.id)
      end
      Deal.create(seller_id: current_user.id ,product_id: @product.id, position_id:1)

      flash[:notice] = '出品が完了しました'
      redirect_to root_path
    else
      @product.product_images.build
      flash[:alert] = '未入力項目があります'
      redirect_back(fallback_location: root_path)
    end
  end

  def show
    render layout: 'application-off-header-footer.html.haml'
  end

  def edit
    @product = Product.find(params[:id])
    gon.product = @product
    gon.product_images = @product.product_images

    # @product.product_images.image_urlをバイナリーデータにしてビューで表示できるようにする
    require 'base64'
    require 'aws-sdk'

    gon.product_images_binary_datas = []
    if Rails.env.production?
      client = Aws::S3::Client.new(
                             region: 'ap-northeast-1',
                             access_key_id: Rails.application.credentials.aws[:access_key_id],
                             secret_access_key: Rails.application.credentials.aws[:secret_access_key],
                             )
      @product.product_images.each do |image|
        binary_data = client.get_object(bucket: 'pepe-takafree', key: image.image_url.file.path).body.read
        gon.product_images_binary_datas << Base64.strict_encode64(binary_data)
      end
    else
      @product.product_images.each do |image|
        binary_data = File.read(image.image_url.file.file)
        gon.product_images_binary_datas << Base64.strict_encode64(binary_data)
      end
    end
  end

  def update
    # ブランド名がstringでparamsに入ってくるので、id番号に書き換え
    if  brand = Brand.find_by(name: params[:product][:brand_id])
      params[:product][:brand_id] = brand.id
    else
      params[:product][:brand_id] = Brand.create(name: params[:product][:brand_id]).id
    end

    @product = Product.find(params[:id])

    # 登録済画像のidの配列を生成
    ids = @product.product_images.map{|image| image.id }
    # 登録済画像のうち、編集後もまだ残っている画像のidの配列を生成(文字列から数値に変換)
    exist_ids = registered_image_params[:ids].map(&:to_i)
    # 登録済画像が残っていない場合(配列に０が格納されている)、配列を空にする
    exist_ids.clear if exist_ids[0] == 0
    if (exist_ids.length != 0 || new_image_params[:images][0] != " ") && @product.update(product_params)
      # 登録済画像のうち削除ボタンをおした画像を削除
      unless ids.length == exist_ids.length
        # 削除する画像のidの配列を生成
        delete_ids = ids - exist_ids
        delete_ids.each do |id|
          @product.product_images.find(id).destroy
        end
      end
      # 新規登録画像があればcreate
      unless new_image_params[:images][0] == " "
        new_image_params[:images].each do |image|
          @product.product_images.create(image_url: image, product_id: @product.id)
        end
      end
      flash[:notice] = '編集が完了しました'
      redirect_to product_path(@product), data: {turbolinks: false}
    else
      flash[:alert] = '未入力項目があります'
      redirect_back(fallback_location: root_path)
    end
  end

  def destroy
    if @product.deal.seller == current_user
      @product.destroy
      redirect_to root_path, notice: "削除しました。"
    else
      redirect_to :back, alert: "削除できませんでした。"
    end
  end

  def auto_complete
    brands = Brand.select(:name).where("name like '" + params[:term].tr('ぁ-ん','ァ-ン') + "%'").order(:name).brands.pluck(:name)
    render json: brands.to_json
  end

  def search_category
    category = Category.find(params[:parent_id])
    if params[:parent_id].to_i >= 159
      @children = category.sizes
    else
      @children = category.children
    end
    respond_to do |format|
      format.json
      format.html
    end
  end

  def search_products
    @keyword = params[:keyword]
    @searched_products = Product.where("name LIKE(?)", "%#{@keyword}%").page(params[:page]).per(48)
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :text, :category_id, :size_id, :brand_id, :status, :shipping_fee_payer, :delivery_method, :prefecture_id, :delivery_time, :price)
  end

  def registered_image_params
    params.require(:registered_images_ids).permit({ids: []})
  end

  def new_image_params
    params.require(:new_images).permit({images: []})
  end
end
