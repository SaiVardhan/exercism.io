class Authentication
  def self.perform(code, client_id, client_secret)
    github = Github.new client_id: client_id, client_secret: client_secret
    access_token = github.get_token(authorization_code).token

    github_oauth = Github.new(oauth_token: access_token)
    git_user_info = github_oauth.users.get

    #why not passing user_info object ?
    id = git_user_info.id
    username = git_user_info.login
    email = git_user_info.email
    avatar_url = git_user_info.avatar_url
    User.from_github(id, username, email, avatar_url)
  end
end
