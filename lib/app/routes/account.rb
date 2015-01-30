module ExercismWeb
  module Routes
    class Account < Core
      get '/account' do
        please_login

        title('account')
        erb :"account/show", locals: { profile: Profile.new(current_user) }
      end

      put '/account/email' do
        if current_user.guest?
          halt 403, "You must be logged in to edit your email settings"
        end

        current_user.email = params[:email] if params[:email]
        current_user.source_type = params[:source_type] if params[:source_type]
        current_user.save
        flash[:success] = 'Updated Account Preferences.'
        redirect "/account"
      end
    end
  end
end
