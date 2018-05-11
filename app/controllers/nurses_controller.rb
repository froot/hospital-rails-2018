require 'date'
class NursesController < ApplicationController
  skip_before_action :authorize, only: :new
  before_action :authorize, unless: :no_nurses?

  layout :resolve_layout

  # this is before the transaction is actually committed
  def index
    # all doctors before queries (seeded)
    @nurses = Nurse.all
    #@is_head_nurse = Nurse.find(session[:nurse_id]).eql?(Nurse.first)

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
    @nurse = Nurse.new(nurse_params)
    @employee = @nurse.build_employee_record(employee_params)

    respond_to do |format|
      if [@nurse.save, @employee.save].all?
        NewAccountMailer.notice_new_account(@nurse).deliver_later
        format.html { flash[:success] = 'Nurse was successfully created'
                      redirect_to nurses_path }
      else
        format.html { render :new }
      end
    end
  end

  def destroy
    nurse = Nurse.find(params[:id])

    nurse.destroy
    respond_to do |format|
      # this is so that if you delete yourself, you are logged out
      if params[:id] == session[:nurse_id].to_s
        session[:nurse_id] = nil
        format.html { flash[:warning] = 'Please log in'
                      redirect_to login_url }
      else
        format.html { flash[:success] = 'Nurse was successfully removed from the system'
                      redirect_to nurses_url }
      end
    end
  end

  # this is bubbled up from the transaction failure
  rescue_from 'Nurse::Error' do |exception|
    flash[:warning] = exception.message
    redirect_to nurses_url
  end

  def edit
    @nurse = Nurse.find(params[:id])
    @employee = @nurse.employee_record
  end

  def update
    @nurse = Nurse.find(params[:id])
    @employee = @nurse.employee_record
    @previous_email = @employee.gravatar

    respond_to do |format|
      if [@nurse.update(nurse_params), @employee.update(employee_params)].all?
        format.html { flash[:success] = 'Nurse was successfully updated'
                      redirect_to nurses_path }
        unless @previous_email.eql?(@nurse.employee_record.email)
          GenerateHashJob.perform_later(@nurse)
        end
      else
        format.html { render :edit }
      end
    end
  end

  def sort
    @nurses = Nurse.all.order(date_of_certification: :asc)
    render 'index'
  end

  def new
    @nurse = Nurse.new
    @employee = EmployeeRecord.new
  end

  private
  def nurse_params
    params.require(:nurse).permit(:'date_of_certification(1i)', :'date_of_certification(2i)', 
                                  :'date_of_certification(3i)', :night_shift, :hours_per_week,
                                  :username, :password, :password_confirmation)
  end

  def employee_params
    params.require(:employee_record).permit(:name, :email, :salary)
  end

  def invalid_nurse
    logger.error "Attempt to access invalid nurse #{params[:id]}"
    flash[:warning] = 'Invalid nurse'
    redirect_to nurses_url
  end

  def resolve_layout
    case action_name
    when "new", "create", "edit", "update"
      "application"
    else # index
      "index_layout"
    end
  end

  def no_nurses?
    Nurse.count == 0
  end

end

