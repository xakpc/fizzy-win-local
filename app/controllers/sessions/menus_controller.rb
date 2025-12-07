class Sessions::MenusController < ApplicationController
  disallow_account_scope

  layout "public"

  def show
    setup = AutoSetup.ensure_ready!(request: request)
    set_current_session(setup.session) unless authenticated?

    @accounts = Current.identity&.accounts || [ setup.account ]

    # Always redirect to first/only account
    redirect_to root_path(script_name: @accounts.first.slug)
  end
end
