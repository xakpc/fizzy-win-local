class SessionsController < ApplicationController
  disallow_account_scope
  allow_unauthenticated_access

  layout "public"

  def new
    redirect_to_auto_setup_landing
  end

  def create
    redirect_to_auto_setup_landing
  end

  def destroy
    terminate_session
    # Re-establish session immediately after logout
    setup = AutoSetup.ensure_ready!(request: request)
    set_current_session(setup.session)
    redirect_to landing_path(script_name: setup.account.slug)
  end

  private

  def redirect_to_auto_setup_landing
    setup = AutoSetup.ensure_ready!(request: request)
    set_current_session(setup.session) unless authenticated?
    redirect_to landing_path(script_name: setup.account.slug)
  end
end
