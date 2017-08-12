defmodule Phauxth.CustomConfirmTest do
  use ExUnit.Case
  use Plug.Test

  alias Phauxth.{Confirm, TestAccounts, Token}

  @secret String.duplicate("abcdef0123456789", 6)

  defmodule ConfirmEndpoint do
    def config(:secret_key_base), do: String.duplicate("abcdef0123456789", 6)
  end

  setup do
    conn = conn(:get, "/")
    conn = put_in(conn.secret_key_base, @secret)
    confirm_email = Token.sign(conn, %{"email" => "fred+1@mail.com"})
    reset_email = Token.sign(conn, %{"email" => "froderick@mail.com"})
    {:ok, %{confirm_email: confirm_email, reset_email: reset_email}}
  end

  test "confirmation succeeds for valid token", %{confirm_email: confirm_email} do
    %{params: params} = conn(:get, "/confirm?key=" <> confirm_email) |> fetch_query_params
    {:ok, user} = Confirm.verify(params, TestAccounts, key_source: ConfirmEndpoint)
    assert user
  end

  test "confirmation fails for invalid token" do
    %{params: params} = conn(:get, "/confirm?key=invalidlink") |> fetch_query_params
    {:error, message} = Confirm.verify(params, TestAccounts, key_source: ConfirmEndpoint)
    assert message =~ "Invalid credentials"
  end

  test "reset password succeeds", %{reset_email: reset_email} do
    params = %{"key" => reset_email, "password" => "password"}
    {:ok, user} = Confirm.verify(params, TestAccounts,
                                 key_source: ConfirmEndpoint, mode: :pass_reset)
    assert user
  end

  test "reset password fails with expired token", %{reset_email: reset_email} do
    params = %{"key" => reset_email, "password" => "password"}
    {:error, message} =  Confirm.verify(params, TestAccounts,
                                        key_source: ConfirmEndpoint,
                                        max_age: -1, mode: :pass_reset)
    assert message =~ "Invalid credentials"
  end

end
