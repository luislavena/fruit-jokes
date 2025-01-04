# Festivus-inspired single-file micro JSON API

require "drift"
require "json"
require "sqlite3"
require "toro"

struct JokesRepository
  getter db : DB::Database

  alias Joke = {id: Int64, content: String, created_at: Time}
  alias Jokes = Array(Joke)

  def initialize(@db)
    migrator = Drift::Migrator.new(@db, drift_context)
    migrator.apply!
  end

  def create_joke(content : String) : Joke?
    clean_content = content.strip
    return if clean_content.empty?

    db.transaction do |tx|
      cnn = tx.connection
      cnn.query_one?(<<-SQL, clean_content, as: Joke.types)
        INSERT INTO jokes (content)
        VALUES ($1)
        RETURNING id, content, created_at;
        SQL
    end
  end

  def find_joke(id) : Joke?
    db.query_one?(<<-SQL, id, as: Joke.types)
      SELECT id, content, created_at
      FROM jokes
      WHERE id = $1;
      SQL
  end

  def recent_jokes(limit = 10) : Jokes
    db.query_all(<<-SQL, limit, as: Joke.types)
      SELECT id, content, created_at
      FROM jokes
      ORDER BY created_at DESC
      LIMIT $1;
      SQL
  end

  # migrations path is relative to this file
  Drift.embed_as("drift_context", "../database/migrations")
end

class WebApp < Toro::Router
  class_property!(repository : JokesRepository)

  alias JokeInput = {content: String?}

  macro repo
    self.class.repository
  end

  def error(code : Int, message : String)
    status code
    json({
      error: message
    })
  end

  def parse_json(io : IO, type)
    type.from_json(io)
  end

  # no-op
  def parse_json(io : Nil, type)
  end

  def routes
    # GET /
    get do
      recent_jokes = repo.recent_jokes
      json({
        jokes: recent_jokes,
      })
    end

    # GET /:id
    on :id do
      get do
        if joke = repo.find_joke(inbox[:id])
          json({
            joke: joke,
          })
        else
          error 404, "Joke not found"
        end
      end
    end

    # POST /
    root do
      post do
        begin
          content = parse_json(context.request.body, JokeInput).try(&.[:content]?)

          if content
            if joke = repo.create_joke(content)
              status 201
              json({
                joke: joke,
              })
            else
              error 400, "Could not create joke"
            end
          else
            error 400, "Content is required and cannot be empty"
          end
        rescue ex : JSON::ParseException
          error 400, "Invalid JSON payload"
        end
      end
    end
  end
end

db = DB.open("sqlite3:./app.db?journal_mode=wal&synchronous=normal&busy_timeout=5000")
WebApp.repository = JokesRepository.new(db)

begin
  WebApp.run do |server|
    puts "Listening on http://[::]:3000"
    server.listen "::", 3000
  end
ensure
  db.close
end

Fiber.yield
