require "kemal"
require "kemal-session"
require "db"
require "pg"

database_url = if ENV["KEMAL_ENV"]? && ENV["KEMAL_ENV"] == "production"
  ENV["DATABASE_URL"]
else
  "postgres://preface@localhost:5432/kemal_sample"
end

db = DB.open(database_url)

Kemal::Session.config do |config|
  config.cookie_name = "session_id"
  config.secret = "some_secret"
  config.gc_interval = 2.minutes # 2 minutes
end

def authorized?(env)
  env.session.string?("username")
end

get "/login" do |env|
  render "src/views/login.ecr", "src/views/application.ecr"
end

post "/login" do |env|
  user_id_param = env.params.body["user_id"]
  password_param = env.params.body["password"]
  if user_id_param == "user1" && password_param == "pass1"
    env.session.string("username", "user1")
    env.redirect "/"
  else
    env.redirect "/login"
  end
end

get "/logout" do |env|
  env.session.destroy
  env.redirect "/"
end

["/", "/articles"].each do |path|
  get path do |env|
    articles = [] of Hash(String, String | Int32)
    db.query("select id, title, body from articles") do |rs|
      rs.each do
        article = {} of String => String | Int32
        article["id"] = rs.read(Int32)
        article["title"] = rs.read(String)
        article["body"] = rs.read(String)
        articles << article
      end
    end
    db.close
    render "src/views/index.ecr", "src/views/application.ecr"
  end
end

get "/articles/new" do |env|
  render "src/views/articles/new.ecr", "src/views/application.ecr"
end

post "/articles" do |env|
  title_param = env.params.body["title"]
  body_param = env.params.body["body"]
  params = [] of String
  params << title_param
  params << body_param
  db.exec("insert into articles(title, body) values($1::text, $2::text)", params)
  db.close
  env.redirect "/"
end

get "/articles/:id" do |env|
  articles = [] of Hash(String, String | Int32)
  article = {} of String => String | Int32
  id = env.params.url["id"].to_i32
  params = [] of Int32
  params << id
  article["id"], article["title"], article["body"] = db.query_one("select id, title, body from articles where id = $1::int8", params, as: {Int32, String, String})
  articles << article
  db.close
  render "src/views/articles/show.ecr", "src/views/application.ecr"
end

get "/articles/:id/edit" do |env|
  articles = [] of Hash(String, String | Int32)
  article = {} of String => String | Int32
  id = env.params.url["id"].to_i32
  params = [] of Int32
  params << id
  article["id"], article["title"], article["body"] = db.query_one("select id, title, body from articles where id = $1::int8", params, as: {Int32, String, String})
  articles << article
  db.close
  render "src/views/articles/edit.ecr", "src/views/application.ecr"
end

put "/articles/:id" do |env|
  id = env.params.url["id"].to_i32
  title_param = env.params.body["title"]
  body_param = env.params.body["body"]
  params = [] of String | Int32
  params << title_param
  params << body_param
  params << id
  db.exec("update articles set title = $1::text, body = $2::text where id = $3::int8", params)
  db.close
  env.redirect "/articles/#{id}"
end

delete "/articles/:id" do |env|
  id = env.params.url["id"].to_i32
  params = [] of Int32
  params << id
  db.exec("delete from articles where id = $1::int8", params)
  db.close
  env.redirect "/"
end

Kemal.run