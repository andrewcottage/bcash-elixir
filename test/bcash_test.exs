defmodule Bcash.WalletTest do
  use ExUnit.Case, async: true

  @password "password"
  @system_wallet "system"
  # system_address = "bchtest:qpu36djlf3qy669wn8haavvdj890td5ud5apaedc8s"
  @system_passphrase "test"

  describe "Bcash.create_wallet" do
    setup do
      Bcash.create_wallet(@system_wallet, @system_passphrase)
      :ok
    end

    test "creates a wallet successfuly" do
      wallet_id = UUID.uuid4()

      assert {:ok, body} = Bcash.create_wallet(wallet_id, @password)
      assert body["id"]
    end

    test "returns an error when wallet has already been created" do
      wallet_id = UUID.uuid4()

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)
      assert {:error, %{"message" => message }} = Bcash.create_wallet(wallet_id, @password)
      assert message =~ "Wallet already exists"
    end
  end

  describe "Bcash.reset_authentication_token" do
    test "resets the authentication token" do
      wallet_id = UUID.uuid4()

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)
      assert {:ok, body} = Bcash.reset_authentication_token(wallet_id, @password)
      assert body["token"]
    end
  end

  describe "Bcash.get_wallet" do
    test "returns the wallet information" do
      wallet_id = UUID.uuid4()

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)
      assert {:ok, body} = Bcash.get_wallet(wallet_id)
      assert body["id"]
    end

    @tag :skip
    test "returns no wallet" do
      wallet_id = UUID.uuid4()

      assert {:error, :invalid} = Bcash.get_wallet(wallet_id)
    end
  end

  describe "Bcash.get_master_hd_key" do
    test "returns the master hd key for a non-encrypted wallet" do
      wallet_id = UUID.uuid4()

      assert {:ok, _} = Bcash.create_wallet(wallet_id, "")
      assert {:ok, body} = Bcash.get_master_hd_key(wallet_id)
      assert %{"encrypted" => false, "key" => %{"xprivkey" => _}} = body
    end

    test "doesn't return the master hd key for an encrypted wallet" do
      wallet_id = UUID.uuid4()

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)
      assert {:ok, body} = Bcash.get_master_hd_key(wallet_id)
      assert %{"encrypted" => true, "ciphertext" => _} = body
    end
  end

  describe "Bcash.send_transaction" do
    test "sending a transaction to 1 wallet" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, body} = Bcash.send_transaction(@system_wallet, outputs, @system_passphrase)
      assert body["tx"]
    end

    test "sending a transaction to 2 wallets" do
      wallet_id = UUID.uuid4()
      account = "default"

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)
      assert {:ok, data} = Bcash.generate_address(wallet_id, account)

      outputs = [%{value: 1000, address: system_address()}, %{value: 1000, address: data["address"]}]

      assert {:ok, body} = Bcash.send_transaction(@system_wallet, outputs, @system_passphrase)
      assert body["tx"]

      # refund transaction
      outputs = [
        %{value: 700, address: system_address()}
      ]
      assert {:ok, _} = Bcash.send_transaction(wallet_id, outputs, @password)
    end

    test "sending a transaction but balance is too low" do
      outputs = [%{value: 1000000000000000, address: system_address()}]
      assert {:error, %{"message" => message}} = Bcash.send_transaction(@system_wallet, outputs, @system_passphrase)
      assert message =~ "Not enough funds"
    end
  end

  describe "Bcash.change_passphrase" do
    test "it changes the wallets passphrase" do
      wallet_id = UUID.uuid4()
      new_password = "newpassword"

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)

      assert {:ok, %{"success" => true}} = Bcash.change_passphrase(wallet_id, @password, new_password)
    end

    test "it fails if the passphrase is wrong" do
      wallet_id = UUID.uuid4()
      new_password = "newpassword"

      assert {:ok, _} = Bcash.create_wallet(wallet_id, @password)

      assert {:error, %{"message" => message}} = Bcash.change_passphrase(wallet_id, "wrong", new_password)
      assert message =~ "Decipher failed."
    end
  end

  describe "Bcash.create_transaction" do
    test "it builds the transaction" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, %{"inputs" => _, "hex" => _}} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
    end

    test "it fails to build the transaction" do
      outputs = [%{value: 0, address: system_address()}]

      assert {:error, %{"message" => "Output is dust."}} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
    end
  end

  describe "Bcash.sign_transaction" do
    test "it signs an existing transaction" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, %{"inputs" => _, "hex" => hex}} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
      assert {:ok, %{"hash" => _}} = Bcash.sign_transaction(@system_wallet, hex, @system_passphrase)
    end

    test "it fails to sign the transaction" do
      assert {:error, %{"message" => message}} = Bcash.sign_transaction(@system_wallet, "lsjkdaflkjasdf", @system_passphrase)
      assert message =~ "tx must be a hex string."
    end
  end

  describe "Bcash.broadcast_transaction" do
    @tag :skip
    test "it broadcasts the transaction" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, %{"inputs" => _, "hex" => hex1}} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
      assert {:ok, %{"hex" => hex} = resp} = Bcash.sign_transaction(@system_wallet, hex1, @system_passphrase)
      
      assert {:ok, %{"success" => true}} = Bcash.broadcast_transaction(resp["hex"])
    end

    test "it fails to broadcast the transaction" do
      tx = "notatx"

      assert {:error, %{"message" => "Not found."}} = Bcash.broadcast_transaction(tx)
    end
  end

  describe "Bcash.zap_transactions" do
    test "it removes pending transactions" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, %{"inputs" => _, "hex" => hex}} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
      assert {:ok, %{"success" => true}} = Bcash.zap_transactions(@system_wallet, "default", 1)
    end

    test "it fails to remove pending transactions" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, %{"inputs" => _, "hex" => hex}} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
      assert {:error, %{"message" => "Age is required."}} = Bcash.zap_transactions(@system_wallet, "default", 0)
    end
  end

  describe "Bcash.unlock_wallet" do
    test "unlocks a wallet" do
      assert {:ok, %{"success" => true}} = Bcash.unlock_wallet(@system_wallet, @system_passphrase, 10)
    end
  end

  describe "Bcash.lock_wallet" do
    test "locks a wallet" do
      assert {:ok, %{"success" => true}} = Bcash.lock_wallet(@system_wallet)
    end
  end

  # describe "Bcash.import_address"
  # describe "Bcash.get_blocks_with_wallet_transactions"
  # describe "Bcash.add_xpubkey"
  # describe "Bcash.remove_xpubkey"
  # describe "Bcash.get_public_key_by_address"
  # describe "Bcash.get_private_key_by_address"

  describe "Bcash.generate_change_address" do
    test "it returns the new address" do
      {:ok, %{"address" => _}} = Bcash.generate_change_address(@system_wallet, "default")
    end

    @tag :skip
    test "it returns an error if wallet doesn't exist" do
      assert {:error, :invalid} = Bcash.generate_change_address("doesnotexist", "default")
    end
  end

  describe "Bcash.derive_nested_address" do
    @tag :skip
    test "it returns a nested address" do
      
    end

    test "it returns an error if wallet doesn't exist" do
      assert {:error, %{"message" => "Not found."}} = Bcash.derive_nested_address("doesnotexist", "default")
    end
  end

  describe "Bcash.get_balance" do
    test "it returns the balance" do
      assert {:ok, %{"account" => _, "confirmed" => _}} = Bcash.get_balance(@system_wallet)
    end

    @tag :skip
    test "it returns not_found" do
      assert {:error, :invalid} = Bcash.get_balance("doesnotexist")
    end
  end

  @tag :skip
  describe "Bcash.lock_output" do
    test "it locks the output" do
      outputs = [%{value: 1000, address: system_address()}]

      assert {:ok, %{"hash" => tx} = resp} = Bcash.create_transaction(@system_wallet, outputs, @system_passphrase)
      assert {:ok, %{"success" => true}} = Bcash.lock_output(@system_wallet, tx, 0, @system_passphrase)
    end
  end

  @tag :skip
  describe "unlock_output" do
  end

  describe "Bcash.list_all_coins" do
    test "it returns all coins for a wallet" do
      assert {:ok, [%{"address" => _} | _]} = Bcash.list_all_coins(@system_wallet)
    end
  end

  describe "get_locked_outputs" do
    test "it returns locked outputs" do
      assert {:ok, list} = Bcash.get_locked_outputs(@system_wallet)
      assert is_list(list)
    end
  end

  describe "Bcash.get_wallet_coin" do
    test "it returns coins" do
      {:ok, [coin | _]} = Bcash.list_all_coins(@system_wallet)
      assert {:ok, %{"address" => _}} = Bcash.get_wallet_coin(@system_wallet, coin["hash"], coin["index"])
    end
  end

  @tag :skip
  describe "Bcash.get_coins_by_address" do
    test "it returns an array" do
      {:ok, [coin | _]} = Bcash.list_all_coins(@system_wallet)
      assert {:ok, list} = Bcash.get_coins_by_address(coin["address"])
      assert is_list(list)  
    end
  end

  def system_address() do
    {:ok, wallet} = Bcash.generate_address(@system_wallet, "default")
    wallet["address"]
  end
end
