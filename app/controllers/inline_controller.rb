class InlineController < ApplicationController
  layout "default"
  before_action :member_only, :only => [:create, :copy]

  def create
    # If this user already has an inline with no images, use it.
    inline = Inline.where("(SELECT count(*) FROM inline_images WHERE inline_images.inline_id = inlines.id) = 0").where(:user_id => @current_user.id).take
    inline ||= Inline.create(:user_id => @current_user.id)
    redirect_to :action => "edit", :id => inline.id
  end

  def index
    order = []
    unless @current_user.is_anonymous?
      order << ["user_id = #{@current_user.id} DESC"]
    end
    order << ["created_at DESC"]

    @inlines = Inline.order(order.join(", ")).paginate :per_page => 20, :page => page_number

    respond_to_list("inlines")
  end

  def delete
    @inline = Inline.find(params[:id])

    unless @current_user.has_permission?(@inline)
      access_denied
      return
    end

    @inline.destroy
    respond_to_success("Image group deleted", :action => "index")
  end

  def add_image
    @inline = Inline.find(params[:id])

    unless @current_user.has_permission?(@inline)
      access_denied
      return
    end

    if request.post?
      new_image = @inline.inline_images.create(inline_image_params)

      unless new_image.errors.empty?
        respond_to_error(new_image, :action => "edit", :id => @inline.id)
        return
      end

      redirect_to :action => "edit", :id => @inline.id
      return
    end
  end

  def delete_image
    image = InlineImage.find(params[:id])

    inline = image.inline
    unless @current_user.has_permission?(inline)
      access_denied
      return
    end

    image.destroy
    redirect_to :action => "edit", :id => inline.id
  end

  def update
    inline = Inline.find(params[:id])

    unless @current_user.has_permission?(inline)
      access_denied
      return
    end

    inline.update(inline_params)

    (params[:image] || []).each do |id, p|
      image = inline.inline_images.find(id)

      image.update(p.permit(:description, :sequence))
    end

    inline.reload
    inline.renumber_sequences

    flash[:notice] = "Image updated"
    redirect_to :action => "edit", :id => inline.id
  end

  # Create a copy of an inline image and all of its images.  Allow copying from images
  # owned by someone else.
  def copy
    inline = Inline.find(params[:id])

    new_inline = Inline.create(:user_id => @current_user.id)
    new_inline.update_attributes(:description => inline.description)

    for image in inline.inline_images do
      new_attributes = image.attributes.merge(:inline_id => new_inline.id)
      new_attributes.delete(:id)
      new_image = InlineImage.create(new_attributes)
      new_image.save!
    end

    respond_to_success("Image copied", :action => "edit", :id => new_inline.id)
  end

  def edit
    @inline = Inline.find(params[:id])
    respond_to { |format| format.html }
  end

  def crop
    @inline = Inline.find(params[:id])
    @image = @inline.inline_images.take!

    return access_denied unless @current_user.has_permission? @inline

    if request.post?
      if @inline.crop(params)
        redirect_to :action => "edit", :id => @inline.id
      else
        respond_to_error(@inline, :action => "edit", :id => @inline.id)
      end
    end

    @params = params
  end

  private

  def inline_params
    params.require(:inline).permit(:description)
  end

  def inline_image_params
    params.require(:image).permit(:file, :source)
  end
end
