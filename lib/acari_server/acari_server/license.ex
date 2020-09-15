defmodule AcariServer.License do
  def test() do
    # На сервере
    # Генерим ключ
    {:ok, rsa_private_key} = ExPublicKey.generate_key(2048)

    # И получаем публичный ключ
    {:ok, rsa_public_key} = ExPublicKey.public_key_from_private_key(rsa_private_key)

    # Конвертируем в PEM формат
    {:ok, rsa_public_key_pem} =
      ExPublicKey.pem_encode(rsa_public_key)

    # Публичный ключ надо передать в лицензионный центр
    # В лицензионном центре

    # {:ok, key} = ExPublicKey.load("/file/to/rsa_public_key.pem")
    {:ok, rsa_public_key} = ExPublicKey.loads(rsa_public_key_pem)

    # Текст лицензии
    license = %{
      "user" => "Сбербанк",
      "max_clients" => 1000,
      "expired_date" => "2020-12-31"
    }

    {:ok, license_json} = Jason.encode(license)

    {:ok, cipher_license} =
      ExPublicKey.encrypt_public(license_json, rsa_public_key)

    # Передаем лицензию покупателю
    # На сервере
    # Декодируем
    {:ok, license_json} = ExPublicKey.decrypt_private(cipher_license, rsa_private_key)
    {:ok, license} = Jason.decode(license_json)

    # Разрешаем работу сервера в соответствии с лицензией
    IO.inspect(license)
    :ok
  end
end
