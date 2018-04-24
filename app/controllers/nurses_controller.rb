require 'date'
class NursesController < ApplicationController
  layout :resolve_layout
  def index
    # all doctors before queries (seeded)
    @nurses = Nurse.all

    # first query: get the name of the nurses that take care of employees that are
    # under the care of doctor Lulu Sheng
    @luluDoctor = Doctor.joins(:employee_record).where('employee_records.name':'Lulu Sheng')
    @patientsUnderLulu = Patient.where(doctor_id:@luluDoctor)

    @luluNurses = []
    @patientsUnderLulu.each do |patient|
      @luluNurses << Nurse.joins(:employee_record).where(id: patient.nurses).select('employee_records.name')
    end

    # second query: the name of the nurse who works the least amount of hours per week
    @leastHours = Nurse.minimum(:hours_per_week)
    #@nurseWithLeastHrs = Nurse.where(hours_per_week:@leastHours).first
    @nurseWithLeastHrs = Nurse.joins(:employee_record).where(hours_per_week:@leastHours).select('employee_records.name').first

    # third query: total number of night-shift nurses
    @numOfNightShift = Nurse.where(night_shift:true).count(:id)
  end

  def create
    p params[:nurse][:'date_of_certification(1i)']+params[:nurse][:'date_of_certification(2i)']+params[:nurse][:'date_of_certification(3i)']

    @nurse = Nurse.new(date_of_certification: '20150101',  
                       night_shift: params[:nurse][:night_shift],
                       hours_per_week: params[:nurse][:hours_per_week])

    @employee = @nurse.build_employee_record(employee_params)

    respond_to do |format|
      if @nurse.save && @employee.save
        format.html { redirect_to nurses_path }
      else
        format.html { render :new, notice: 'Line item was unsuccessfully created.'}
      end
    end
  end

  def edit
    @nurse = Nurse.find(params[:id])
    p @nurse
  end

  def sort
    @nurses = Nurse.all.order(date_of_certification: :asc)
    render 'index'
  end

  def new
    @nurse = Nurse.new
  end

  private
  def nurse_params
    params.require(:nurse).permit(:'date_of_certification(1i)', :'date_of_certification(2i)', :'date_of_certification(3i)', :night_shift, :hours_per_week)
  end

  def employee_params
    params.require(:nurse).permit(:name, :email, :salary)
  end

  def resolve_layout
    case action_name
    when "new", "create", "edit"
      "application"
    else # index
      "index_layout"
    end
  end

end
