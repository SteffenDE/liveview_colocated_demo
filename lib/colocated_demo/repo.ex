defmodule ColocatedDemo.Repo do
  use Ecto.Repo,
    otp_app: :colocated_demo,
    adapter: Ecto.Adapters.Postgres
end
