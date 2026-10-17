"""Validate the public connection settings used by a TyreDesk build."""
import argparse
import base64
import ipaddress
import json
import os
from pathlib import Path
import re


def validate(server, key, mode=""):
    server, key = server.strip(), key.strip()
    if mode == "public":
        if server or key:
            raise ValueError("No modo public, deixe servidor e chave vazios.")
        return {"TYREDESK_SERVER": "", "TYREDESK_SERVER_KEY": ""}
    if mode == "custom" and (not server or not key):
        raise ValueError("No modo custom, informe o servidor e sua chave publica.")
    if mode not in ("", "public", "custom"):
        raise ValueError("Modo invalido: use public ou custom.")
    if not server and not key:
        return {"TYREDESK_SERVER": "", "TYREDESK_SERVER_KEY": ""}
    if not server or len(server) > 253:
        raise ValueError("Informe o IPv4 ou DNS publico e a chave publica, ou deixe ambos vazios para usar os servidores publicos do RustDesk.")
    try:
        address = ipaddress.ip_address(server)
    except ValueError:
        labels = server.split(".")
        if all(c in "0123456789." for c in server) or any(
            not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", p)
            for p in labels
        ):
            raise ValueError("Endereco invalido: use apenas IPv4 ou DNS, sem porta.")
    else:
        if address.version != 4 or address.is_unspecified or address.is_multicast:
            raise ValueError("Use um endereco IPv4 valido ou DNS para este pacote.")
    try:
        decoded = base64.b64decode(key, validate=True)
    except (ValueError, base64.binascii.Error) as exc:
        raise ValueError("A chave publica deve ser o conteudo de id_ed25519.pub.") from exc
    if len(decoded) != 32:
        raise ValueError("A chave publica deve conter exatamente 32 bytes. Nao use a chave privada.")
    return {"TYREDESK_SERVER": server, "TYREDESK_SERVER_KEY": key}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", default=os.getenv("TYREDESK_SERVER", ""))
    parser.add_argument("--key-file", type=Path)
    parser.add_argument("--check", action="store_true", help="Validate only; do not write files")
    args = parser.parse_args()
    try:
        key = args.key_file.read_text(encoding="utf-8-sig") if args.key_file else os.getenv("TYREDESK_SERVER_KEY", "")
        config = validate(args.server, key, os.getenv("TYREDESK_SERVER_MODE", ""))
        if not args.check:
            path = Path(__file__).with_name("build.env.json")
            path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
        print("Configuracao publica do servidor validada. Nenhuma senha de acesso foi incluida.")
    except (ValueError, OSError) as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
