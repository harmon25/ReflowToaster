# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :reflow_controller, ReflowController.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "5BjdVl58lk29odHWwCimWhkMWNvVCC8zwc/k8x715Z/myUqQDcvHE2MYXO6MOCSo",
  render_errors: [view: ReflowController.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ReflowController.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :reflow_controller,
  log_to_file: true
  log_file_path: "log.csv"


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
