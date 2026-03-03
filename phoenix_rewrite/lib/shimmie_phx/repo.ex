defmodule ShimmiePhoenix.Repo do
  use Ecto.Repo,
    otp_app: :shimmie_phx,
    adapter: Ecto.Adapters.Postgres
end
