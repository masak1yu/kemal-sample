require "kemal"

# use kemal-pg
#require "kemal-pg"
#pg_connect "postgres://preface@localhost:5432/kemal_sample"

# unuse kemal-pg
require "pg"
require "pool/connection"
pg = ConnectionPool.new(capacity: 25, timeout: 0.1) do
  PG.connect(ENV["DATABASE_URL"])
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
  conn = pg.connection
  conn.exec("insert into articles(title, body) values('#{title_param}', '#{body_param}')")
  pg.release
  env.redirect "/"
end

get "/articles/:id" do |env|
  id = env.params.url["id"]
  conn = pg.connection
  result = conn.exec({Int32, String, String}, "select id, title, body from articles where id = #{id}")
  pg.release
  articles = result.to_hash
  render "src/views/articles/show.ecr", "src/views/application.ecr"
end

get "/articles/:id/edit" do |env|
  id = env.params.url["id"]
  conn = pg.connection
  result = conn.exec({Int32, String, String}, "select id, title, body from articles where id = #{id}")
  pg.release
  articles = result.to_hash
  render "src/views/articles/edit.ecr", "src/views/application.ecr"
end

put "/articles/:id" do |env|
  id = env.params.url["id"]
  title_param = env.params.body["title"]
  body_param = env.params.body["body"]
  conn = pg.connection
  conn.exec("update articles set title = '#{title_param}', body = '#{body_param}' where id = #{id}")
  pg.release
  env.redirect "/articles/#{id}"
end

Kemal.run