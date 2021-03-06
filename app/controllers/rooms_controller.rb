# frozen_string_literal: true

class RoomsController < ApplicationController
  def index
    if request.format == :html
      @rooms = Room.accessible_by(current_ability, :read).order(:id)
    elsif request.format == :ics
      @rooms = Room.eager_load(approved_bookings: [:room, :user])
        .preload(approved_bookings: :camdram_model)
        .accessible_by(current_ability, :read).order(:id)
    end
    respond_to do |format|
      format.html
      format.ics
    end
  end

  def new
    authorize! :create, Room
    @room = Room.new
  end

  def edit
    @room = Room.find(params[:id])
    authorize! :edit, @room
  end

  def create
    @room = Room.new(room_params)
    authorize! :create, @room
    if @room.save
      alert = { 'class' => 'success', 'message' => "Added #{@room.name}!" }
      flash[:alert] = alert
      redirect_to @room
    else
      alert = { 'class' => 'danger', 'message' => @room.errors.full_messages.first }
      flash.now[:alert] = alert
      render :new
    end
  end

  def update
    @room = Room.find(params[:id])
    authorize! :edit, @room
    if @room.update(room_params)
      alert = { 'class' => 'success', 'message' => "Updated #{@room.name}!"}
      flash[:alert] = alert
      redirect_to @room
    else
      alert = { 'class' => 'danger', 'message' => @room.errors.full_messages.first }
      flash.now[:alert] = alert
      render :edit
    end
  end

  def show
    if request.format == :html
      @room = Room.find(params[:id])
      @start_date = (params[:start_date] ? Date.parse(params[:start_date]) : Date.today).beginning_of_week
      @end_date = @start_date + 7.days
      @events = @room.events_in_range(@start_date, @end_date)
    elsif request.format == :ics
      @room = Room.eager_load(approved_bookings: [:room, :user])
        .preload(approved_bookings: :camdram_model)
        .find(params[:id])
    end
    authorize! :read, @room
    respond_to do |format|
      format.html
      format.ics
    end
  end

  def destroy
    @room = Room.find(params[:id])
    authorize! :destroy, @room
    @room.destroy
    alert = { 'class' => 'success', 'message' => "Deleted #{@room.name}!"}
    flash[:alert] = alert
    redirect_to rooms_path
  end

  private

  def room_params
    params.require(:room).permit(:name)
  end
end
