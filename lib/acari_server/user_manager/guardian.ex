defmodule AcariServer.UserManager.Guardian do
  use Guardian, otp_app: :acari_server

  alias AcariServer.UserManager

  def subject_for_token(%{user: user}, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case UserManager.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  # Callbacks
  def after_encode_and_sign(resource, claims, token, _options) do
    # IO.inspect({claims, token, resource}, label: "SIGN")

    AcariServer.Mnesia.add_session(
      claims["jti"],
      claims |> Map.merge(resource) |> Map.put(:server, Node.self())
    )

    {:ok, token}
  end

  def on_verify(claims, _token, _options) do
    # IO.inspect({claims, token}, label: "ON_VERIFY")
    AcariServer.Mnesia.update_session_activity(claims["jti"])
    {:ok, claims}
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    # IO.inspect({old_claims, new_claims}, label: "ON_REFRESH")
    {:ok, {old_token, old_claims}, {new_token, new_claims}}
  end

  def on_revoke(claims, _token, _options) do
    # IO.inspect({claims, token}, label: "ON_REVOKE")
    AcariServer.Mnesia.delete_session(claims["jti"])
    {:ok, claims}
  end
end
