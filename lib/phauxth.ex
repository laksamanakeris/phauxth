defmodule Phauxth do
  @moduledoc """
  A collection of functions to be used to authenticate Phoenix web apps.

  Phauxth is designed to be secure, extensible and well-documented.

  Phauxth offers two types of functions: Plugs, which are called with plug,
  and verify/2 functions, which are called inside the function bodies.

  ## Plugs

  Plugs take a conn (connection) struct and opts as arguments and return
  a conn struct.

  ### Authenticate

  Phauxth.Authenticate checks to see if there is a valid cookie or token
  for the user and sets the current_user value accordingly.

  This is usually added to the pipeline you want to authenticate in the
  router.ex file, as in the following example.

      pipeline :browser do
        plug Phauxth.Authenticate
      end

  ### Remember

  This Plug provides a check for a remember_me cookie.

      pipeline :browser do
        plug Phauxth.Authenticate
        plug Phauxth.Remember
      end

  This needs to be called after plug Phauxth.Authenticate.

  ## Phauxth verify/2

  Each verify/2 function takes a map (usually Phoenix params) and opts
  (an empty list by default) and returns {:ok, user} or {:error, message}.

  ### Login and One-time passwords

  In the example below, Phauxth.Login.verify is called within the create
  function in the session controller.

      def create(conn, %{"session" => params}) do
        case Phauxth.Login.verify(params) do
          {:ok, user} -> handle_successful_login
          {:error, message} -> handle_error
        end
      end

  Phauxth.Otp.verify is used for logging in with one-time passwords, which
  are often used with two-factor authentication. It is used in the same
  way as Phauxth.Login.verify.

  ### User confirmation

  Phauxth.Confirm.verify is used for user confirmation, using email or phone.

  In the following example, the verify function is called within the
  new function in the confirm controller.

      def new(conn, params) do
        case Phauxth.Confirm.verify(params) do
          {:ok, user} ->
            Accounts.confirm_user(user)
            message = "Your account has been confirmed"
            Message.confirm_success(user.email)
            handle_success(conn, message, session_path(conn, :new))
          {:error, message} ->
            handle_error(conn, message, session_path(conn, :new))
        end
      end

  Phauxth.Confirm.PassReset.verify is used for password resetting.

  In the following example, the verify function is called within the update
  function in the password reset controller, and the key validity is set
  to 20 minutes (the default is 60 minutes).

      def update(conn, %{"password_reset" => params}) do
        case Phauxth.Confirm.PassReset.verify(params, key_validity: 20) do
          {:ok, user} ->
            Accounts.update_user(user, params)
            Message.reset_success(user.email)
            message = "Your password has been reset"
            configure_session(conn, drop: true)
            |> handle_success(message, session_path(conn, :new))
          {:error, message} ->
            conn
            |> put_flash(:error, message)
            |> render("edit.html", email: params["email"], key: params["key"])
        end
      end

  ## Phauxth with a new Phoenix project

  The easiest way to get started is to use the phauxth_new installer.
  First, download and install it:

      mix archive.install https://github.com/riverrun/phauxth/raw/master/installer/archives/phauxth_new.ez

  Then run the `mix phauxth.new` command in the main directory of the
  Phoenix app. The following options are available:

    * `--api` - create files for an api
    * `--confirm` - add files for email confirmation

  ## Customizing Phauxth

  See the documentation for Phauxth.Authenticate.Base, Phauxth.Login.Base
  and Phauxth.Confirm.Base for more information on extending these modules.

  You can find more information at the
  [Phauxth wiki](https://github.com/riverrun/phauxth/wiki).

  """

  @callback verify(map, Keyword.t) ::
    {:ok, user :: Ecto.Schema.t} | {:error, message :: String.t}

end
