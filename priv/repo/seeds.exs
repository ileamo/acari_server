# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AcariServer.Repo.insert!(%AcariServer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias AcariServer.Repo
alias AcariServer.UserManager.User

admin_params = %{
  username: "admin",
  password: "admin",
  rpt_psw: "admin",
  is_admin: true
}

unless Repo.get_by(User, username: admin_params[:username]) do
  %User{}
  |> User.changeset(admin_params)
  |> Repo.insert!()
end
