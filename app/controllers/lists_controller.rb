class ListsController < ApplicationController
  def show
	@user = User.find(params[:id])
  end

  def create
	@list = List.new
	respond_to do |format| 
        format.html
        format.js
    end
  end

  def submit
	puts "PARAMS: #{params}"
	list_id = params['list']['list_id']
	user_id = params[:user_id]
    list_name = params['list']['name']

    #if list_id exists
    if list_id
      list = List.find(list_id)
      list.name = list_name
      list.save!
    #else
    else
      list = List.new(:user_id => user_id, :name => list_name)
      list.save!
    end
    
    if list.save
      flash[:success] = "Lists updated."
    else
      flash[:error] = "There was an error updating your lists."
    end

    redirect_to show_lists_path(:id => user_id)
  end

  def delete
	list = List.find(params['list_id'])
	list.destroy!
	user_id = params['user_id']
	flash[:success] = 'List deleted'
	redirect_to show_lists_path(:id => user_id)
  end

  def add_product
    @product = Product.new
    @list = List.find(params['list_id'])
    respond_to do |format| 
        format.html
        format.js
    end
  end

  def submit_product
    #puts "PARAMS: #{params}"
    product_id = params['product']['product_id']
    user = User.find(params['user_id'])
    title = params['product']['title']
    url = params['product']['url']
    picture = params['product']['picture']
    list_id = params['product']['list_id']

    #if product_id exists
    if product_id
      product = Product.find(product_id)
      product.title = title
      product.url = url
      product.picture = picture
      product.save!
    #else
    else
      product = Product.new(:user_id => user.id, :title => title, :url => url, :picture => picture)
      product.save!
      listing = Listing.new(:product_id => product.id, :list_id => list_id)
      listing.save!
    end
    
    if product.save
      flash[:success] = "Products updated."
    else
      flash[:error] = "There was an error updating your products."
    end

    redirect_to show_lists_path(:id => user.id)
  end

  def delete_product
    product = Product.find(params['product_id'])
    product.destroy!
    flash[:success] = "Product deleted."
    redirect_to show_lists_path(:id => params['user_id'])
  end

end
