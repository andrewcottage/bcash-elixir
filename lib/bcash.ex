defmodule Bcash do
  @moduledoc """
  Documentation for Bcash.

  https://bcoin.io/api-docs/#introduction
  """
  require Logger

  @doc """
  Create a new wallet via the POST /wallet/:wallet_id endpoint in Bcash.
  """
  @spec create_wallet(String.t, String.t) :: {:ok, Map.t()} | {:error, HTTPoison.Error.t()} | {:error, :invalid_arguments}
  def create_wallet(wallet_id, passphrase) do
    payload = %{
      passphrase: passphrase
    } |> Poison.encode!()

    put("/wallet/#{wallet_id}", payload)
  end

  @doc """
  Derive a new wallet token, required for access of this particular wallet.
  """
  @spec reset_authentication_token(String.t, String.t) :: {:ok, Map.t()} | {:error, Map.t()}
  def reset_authentication_token(wallet_id, passphrase) do
    payload = %{
      passphrase: passphrase
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/retoken", payload)
  end

  @doc """
  Gets information about a wallet.
  """
  @spec get_wallet(String.t()) :: {:ok, Map.t()} | {:error, Map.t()}
  def get_wallet(wallet_id) do
    get("/wallet/#{wallet_id}")
  end

  @doc """
  Get wallet master HD key. This is normally censored in the wallet info route. The provided API key must have admin access.
  """
  def get_master_hd_key(wallet_id) do
    get("/wallet/#{wallet_id}/master")
  end

  @doc """
  Change wallet passphrase. Encrypt if unencrypted.
  """
  def change_passphrase(wallet_id, old_passphrase, new_passphrase) do
    payload = %{
      old: old_passphrase,
      passphrase: new_passphrase
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/passphrase", payload)
  end

  @doc """
  Sign and broadcast a transaction from the given wallet to the specified outputs.
  """
  @spec send_transaction(String.t, [Map.t], String.t) :: {:ok, Map.t()} | {:error, Map.t()} | {:error, HTTPoison.Error.t()}
  def send_transaction(wallet_id, outputs, passphrase) do
    payload = %{
      passphrase: passphrase,
      rate: fee_rate(),
      outputs: outputs
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/send", payload)
  end

  @doc """
  Create and template a transaction (useful for multisig). Does not broadcast or add to wallet.
  """
  def create_transaction(wallet_id, outputs, passphrase) do
    payload = %{
      passphrase: passphrase,
      rate: fee_rate(),
      outputs: outputs
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/create", payload)
  end

  @doc """
  Sign a templated transaction (useful for multisig).
  """
  def sign_transaction(wallet_id, hex, passphrase) do
    payload = %{
      passphrase: passphrase,
      tx: hex
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/sign", payload)
  end

  @doc """
  Broadcast a transaction by adding it to the node's mempool. If mempool verification fails,
  the node will still forcefully advertise and relay the transaction for the next 60 seconds.
  """
  def broadcast_transaction(tx) do
    payload = %{
      tx: tx
    } |> Poison.encode!()

    post("/broadcast", payload)
  end

  @doc """
  Remove all pending transactions older than a specified age.
  """
  def zap_transactions(wallet_id, account, age) do
    payload = %{
      account: account,
      age: age
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/zap", payload)
  end

  def unlock_wallet(wallet_id, passphrase, timeout) do
    payload = %{
      passphrase: passphrase,
      timeout: timeout
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/unlock", payload)
  end


  def lock_wallet(wallet_id) when is_binary(wallet_id) do
    payload = %{} |> Poison.encode!()

    post("/wallet/#{wallet_id}/lock", payload)
  end

  @doc """
  Import a standard WIF key.
  An import can be either a private key or a public key for watch-only. (Watch Only wallets will throw an error if trying to import a private key)
  A rescan will be required to see any transaction history associated with the key.
  """
  def import_key(wallet_id, account, private_key) do
    payload = %{
      account: account,
      private_key: private_key
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/lock", payload)
  end

  def import_address
  def get_blocks_with_wallet_transactions
  def add_xpubkey
  def remove_xpubkey
  def get_public_key_by_address
  def get_private_key_by_address

  @doc """
  Derive new receiving address for account.
  """
  def generate_address(wallet_id, account) do
    payload = %{
      account: account
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/address", payload)
  end

  @doc """
  Derive new change address for account.
  """
  def generate_change_address(wallet_id, account) do
    payload = %{
      account: account
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/change", payload)
  end

  @doc """
  Derive new nested p2sh receiving address for account.
  """
  def derive_nested_address(wallet_id, account) do
    payload = %{
      account: account
    } |> Poison.encode!()

    post("/wallet/#{wallet_id}/nested", payload)
  end

  @doc """
  Get wallet or account balance. If no account option is passed, the call defaults to wallet balance (with account index of -1). Balance values for unconfimred and confirmed are expressed in satoshis.
  """
  def get_balance(wallet_id) do
    get("/wallet/#{wallet_id}/balance")
  end

  @doc """
  Lock outpoints.
  """
  def lock_output(wallet_id, hash, index, passphrase) do
    payload = %{
      password: passphrase
    } |> Poison.encode!()

    put("/wallet/#{wallet_id}/lock/#{hash}/#{index}", payload)
  end

  @doc """
  Unlock outpoints.
  """
  def unlock_output(wallet_id, hash, index, passphrase) do
    payload = %{
      password: passphrase
    } |> Poison.encode!()

    put("/wallet/#{wallet_id}/unlock/#{hash}/#{index}", payload)
  end

  @doc """
  List all wallet coins available.
  """
  def list_all_coins(wallet_id) do
    get("/wallet/#{wallet_id}/coin")
  end

  @doc """
  Get all locked outpoints.
  """
  def get_locked_outputs(wallet_id) do
    get("/wallet/#{wallet_id}/locked")
  end

  @doc """
  Get wallet coin
  """
  def get_wallet_coin(wallet_id, hash, index) do
    get("/wallet/#{wallet_id}/coin/#{hash}/#{index}")
  end

  @doc """
  Get coin objects array by address.
  """
  def get_coins_by_address(address) do
    get("/coin/address/#{address}")
  end

  #######################
  # Wallet Accounts API #
  #######################

  @doc """
  List all account names (array indices map directly to bip44 account indices) associated with a specific wallet id.
  """
  def get_accounts(wallet_id) do
    get("/wallet/#{wallet_id}/account")
  end

  @doc """
  Get account info.
  """
  def get_account(wallet_id, account) do
    get("/wallet/#{wallet_id}/account/#{account}")
  end

  @doc """
  Create account with specified account name.

  ## Examples

      Bcash.create_account(1, "main", "pubkeyhash", "mystrongpassword")
  """
  def create_account(wallet_id, name, type, passphrase) do
    payload = %{
      passphrase: passphrase,
      type: type
    } |> Poison.encode!()

    put("/wallet/#{wallet_id}/account/#{name}", payload)
  end

  ############
  # Node API #
  ############

  def get_info()
  def get_utxo_by_address()
  def get_utxo_by_hash()
  def get_all_utxos
  def get_transaction_by_hash()
  def get_transaction_by_address()
  def get_all_transactions()
  def get_block()
  def get_mempool()

  def estimate_fee() do
    payload = %{
      "method" => "estimatefee",
      "params" => ["1"]
    } |> Poison.encode!()

    post("/", payload)
  end

  def reset_chain()

  ##########################
  # Wallet Transctions API #
  ##########################

  def get_wallet_transaction_details()
  def delete_transaction()

  @doc """
  Get wallet TX history. Returns array of tx details.
  """
  def get_wallet_transaction_history(wallet_id) do
    get("/wallet/#{wallet_id}/tx/history")
  end

  def get_pending_transactions()
  def get_range_of_transactions()

  #############################
  # Wallet Admin Commands API #
  #############################

  def wallet_rescan()
  def wallet_resend()
  def wallet_backup()
  def list_all_wallets()

  #####################
  # Private Functions #
  #####################

  defp get(path) do
    [url(), path]
    |> log_request()
    |> Enum.join()
    |> HTTPoison.get()
    |> format_response()
  end

  defp post(path, body) do
    [url(), path]
    |> log_request()
    |> Enum.join()
    |> HTTPoison.post(body)
    |> format_response()
  end

  defp put(path, body) do
    [url(), path]
    |> log_request()
    |> Enum.join()
    |> HTTPoison.put(body)
    |> format_response()
  end

  defp log_request([_, path] = args) do
    Logger.info("Bcash api called #{path}")
    args
  end

  defp format_response({:ok, %HTTPoison.Response{body: body}}), do: format_response(body)
  defp format_response({:error, err}), do: {:error, err}

  defp format_response(body) do
    case Poison.decode(body) do
      {:ok, %{"error" => data}} ->
        {:error, data}
      {:error, reason, _} ->
        Logger.error("problem with bcash request ")
        {:error, reason}
      "" -> {:error, :invalid}
      data -> data
    end
  end

  defp url(), do: "http://x:#{api_key()}@#{bcash_host()}:#{bcash_port()}"
  defp api_key(), do: Application.get_env(:bcash, :api_key)
  defp bcash_host(), do: Application.get_env(:bcash, :host)
  defp bcash_port(), do: Application.get_env(:bcash, :port)
  defp fee_rate(), do: Application.get_env(:bcash, :fee)
end
