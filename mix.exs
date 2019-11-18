defmodule AcariServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :acari_server,
      version: "1.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        bogatka: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          cookie: "DgZPqZG4H22AZyd_XoZkfdLDqPI4KKeZeI1tJg2yprxm1l4bQ4RJmQ==",
          steps: [:assemble, &copy_extra_files/1],
          runtime_config_path: "config/rt.exs",
          include_erts: false
        ],
        bogatka_docker: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          cookie: "eNBXaWYQFXV_UVi0d7vyEpsz9ZYx0p1fX7SisJ5dtLFdbS-4VqW_OQ==",
          steps: [:assemble, &copy_extra_files/1],
          runtime_config_path: "config/rt_docker.exs"
        ]
      ]
    ]
  end

  def copy_extra_files(release) do
    release
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AcariServer.Application, []},
      extra_applications: [:logger, :runtime_tools, :mnesia]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_),
    do: [
      # "acari_lib",
      "lib"
    ]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:guardian, "~> 1.0"},
      {:comeonin, "~> 5.1"},
      {:bcrypt_elixir, "~> 2.0"},
      {:temp, "~> 0.4"},
      {:erlexec, "~> 1.9"},
      # {:distillery, "~> 2.0.12"},
      {:loggix, "~> 0.0.9"},
      {:httpoison, "~> 1.5"},
      {:sandbox, "~> 0.5"},
      {:nimble_parsec, "~> 0.5"},
      {:acari, git: "https://github.com/ileamo/acari.git"},
      #{:procket, git: "https://github.com/msantos/procket.git", branch: "master", override: true},
      {:tunctl, git: "https://github.com/msantos/tunctl.git"},
      {:gen_icmp, git: "https://github.com/ileamo/gen_icmp.git"
    }
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
