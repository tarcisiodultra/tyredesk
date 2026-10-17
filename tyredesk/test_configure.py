import base64
import unittest
from configure import validate

PUBLIC_KEY = base64.b64encode(bytes(range(32))).decode()


class ServerConfigurationTests(unittest.TestCase):
    def test_empty_settings_select_public_rustdesk_servers(self):
        self.assertEqual(
            validate("", ""),
            {"TYREDESK_SERVER": "", "TYREDESK_SERVER_KEY": ""},
        )

    def test_public_mode_rejects_custom_server_values(self):
        with self.assertRaises(ValueError):
            validate("server.example", PUBLIC_KEY, "public")

    def test_custom_mode_requires_server_and_public_key(self):
        with self.assertRaises(ValueError):
            validate("", "", "custom")
        self.assertEqual(
            validate("server.example", PUBLIC_KEY, "custom"),
            {"TYREDESK_SERVER": "server.example", "TYREDESK_SERVER_KEY": PUBLIC_KEY},
        )

    def test_ipv4_and_dns_are_supported_without_access_passwords(self):
        for server in ("203.0.113.10", "remoto.tyresoles.example", "127.0.0.1"):
            with self.subTest(server=server):
                result = validate(server, PUBLIC_KEY + "\n")
                self.assertEqual(result, {"TYREDESK_SERVER": server, "TYREDESK_SERVER_KEY": PUBLIC_KEY})

    def test_invalid_hosts_and_command_injection_are_rejected(self):
        for server in ("https://host", "host:21116", "999.999.999.999", "a;b", "a\nb", "$(whoami)", "-host", "host/", "0.0.0.0", "::1"):
            with self.subTest(server=server), self.assertRaises(ValueError):
                validate(server, PUBLIC_KEY)

    def test_partial_custom_configuration_is_rejected(self):
        with self.assertRaises(ValueError):
            validate("server.example", "")
        with self.assertRaises(ValueError):
            validate("", PUBLIC_KEY)

    def test_private_or_malformed_keys_are_rejected(self):
        for key in ("", "password", "not!base64", base64.b64encode(bytes(64)).decode()):
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate("server.example", key)


if __name__ == "__main__":
    unittest.main()
