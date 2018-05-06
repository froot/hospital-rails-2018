class SessionsController < ApplicationController
  def new
    #it just needs to show the login stuff!
  end

  def create
    nurse = Nurse.find_by(username: params[:username])
    if nurse.try(:authenticate, params[:password]) # checks if user is nil before trying to call
      # authenticate does the decoding of the hashed password
      session[:nurse_id] = nurse.id
      redirect_to patients_url
    else
      flash[:warning] = 'Invalid user/password combination'
      redirect_to login_url
    end
  end

  def destroy
    session[:nurse_id] = nil
    flash[:success] = 'Logged out'
    redirect_to login_url
  end
end
