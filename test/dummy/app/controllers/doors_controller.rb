class DoorsController < ApplicationController
  def show
    @door = Door.find(params[:id])
  end

  def paint
    @door = Door.find(params[:id])
    enforce_resource_security(:paint, @door)
    render :show
  end

  def change
    @door = Door.find(params[:id])
    enforce_resource_security(:change, @door)
    render :show
  end

  def open
    @door = Door.find(params[:id])
    enforce_resource_security(:open, @door)
    render :show
  end
end
