defmodule Bogatka.Rust do
    use Rustler, otp_app: :acari_server, crate: "bogatka_rust"

    # When your NIF is loaded, it will override this function.
    def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
