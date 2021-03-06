class SuppliersController < ApplicationController
  # before_action :check_for_admin, :only => [:index]
  skip_before_action :verify_authenticity_token, :only => [:search, :create, :show, :update]
  # before_action :check_for_login, :only => [:show, :invite, :new, :create]
  before_action :authenticate_supplier, :only => [:show, :update]

  @_default_search_distanse = 10;

  # POST /suppliers
  # POST /suppliers.json
  def search
    if params[:geocode].present?
      lat = params[:geocode][:latitude]
      lng = params[:geocode][:longitude]
      radius = params[:radius]? params[:radius] : @_default_search_distanse
      skill_category = params[:skill_category]
      if skill_category.present?
        scope1 = Service.where(skill_category_id: skill_category).pluck(:supplier_id)
        scope2 = Supplier.near([lat, lng], radius, {order: "", units: :km}).pluck(:id)
        @suppliers = Supplier.where(isSupplier: true).find(scope1 & scope2)
      else
        @suppliers = Supplier.near([lat, lng], radius, units: :km).where(isSupplier: true)
      end
    elsif params[:skill_category].present?
      @suppliers = Supplier.find(Service.where(skill_category_id: params[:skill_category], isSupplier: true).pluck(:supplier_id));
    else
      @suppliers = Supplier.where(isSupplier: true)
    end
    render :action => 'search_result.json'
  end

  # GET /suppliers/show
  def show
    @supplier = current_supplier
    render :action => 'show.json'
  end

  def index
    @suppliers = Supplier.all
  end

  def update
    @supplier = Supplier.find(current_supplier.id)
    @supplier.update supplier_params
    if params[:services].count
      @supplier.isSupplier = true

      current_supplier.services.destroy_all

      params[:services].each do |request_service|
        Service.create :supplier_id => current_supplier.id, :skill_category_id => request_service[:skill_category_id], :price => request_service[:price]
      end

    else
      @supplier.isSupplier = false
    end

    render :action => 'show.json'
  end

  def new
    @supplier = Supplier.new
  end

  def getSupplier
    @supplier = Supplier.find_by :id => params[:id]
    render :action => 'show.json'
  end

  def create

    @supplier = Supplier.new(supplier_params)
    respond_to do |format|
      if @supplier.save
        # SupplierMailer.welcome(@supplier).deliver_now
        format.html { redirect_to root_path, notice: 'Contractor was created.'}
        format.json { render :show, status: :created, location: @supplier }
      else
        format.html { render :new }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def supplier_params
    params.require(:supplier).permit(:phone, :name, :address, :email, :password, :password_confirmation)
  end
end
