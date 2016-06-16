require "kemal"

# use kemal-pg
#require "kemal-pg"
#pg_connect "postgres://preface@localhost:5432/kemal_sample"

# unuse kemal-pg
require "pg"
require "pool/connection"
pg = ConnectionPool.new(capacity: 25, timeout: 0.1) do
  #PG.connect(ENV["DATABASE_URL"])
  PG.connect("postgres://preface@localhost:5432/kemal_sample")
end


["/", "/articles"].each do |path|
  get path do |env|
    articles = [
      {"id" => 1, "title" => "title1", "body" => "body1"},
      {"id" => 2, "title" => "title2", "body" => "body2"},
      {"id" => 3, "title" => "title3", "body" => "body3"},
    ]

    conn = pg.connection
    result = conn.exec({Int32, String, String}, "select id, title, body from articles")
    pg.release
    articles = result.to_hash
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
  conn = pg.connection
  conn.exec("insert into articles(title, body) values($1::text, $2::text)", params)
  pg.release
  env.redirect "/"
end

get "/articles/:id" do |env|
  id = env.params.url["id"].to_i32
  params = [] of Int32
  params << id
  conn = pg.connection
  result = conn.exec({Int32, String, String}, "select id, title, body from articles where id = $1::int8", params)
  pg.release
  articles = result.to_hash
  render "src/views/articles/show.ecr", "src/views/application.ecr"
end

get "/articles/:id/edit" do |env|
  id = env.params.url["id"].to_i32
  params = [] of Int32
  params << id
  conn = pg.connection
  result = conn.exec({Int32, String, String}, "select id, title, body from articles where id = $1::int8", params)
  pg.release
  articles = result.to_hash
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
  conn = pg.connection
  conn.exec("update articles set title = $1::text, body = $2::text where id = $3::int8", params)
  pg.release
  env.redirect "/articles/#{id}"
end

Kemal.run