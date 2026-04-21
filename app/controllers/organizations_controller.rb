class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.active.order(:name)
  end

  def show
    @organization = Organization.find_by!(slug: params[:id])
    # SMELL: No eager loading for the nested tables rendered in the view
    @schools = @organization.schools.order(:name)
  end
end
