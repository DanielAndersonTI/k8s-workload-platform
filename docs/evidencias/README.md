# Evidence policy

Each evidence file records one command, its timestamp, the environment and the
relevant output.

## Naming

`T<phase>.<task>-<subject>.txt`, for example `T2.3-vm-show.txt`.

## Content

- The command exactly as executed.
- The date and time in UTC.
- The host or environment where it ran.
- The output that supports the report claim.
- The exit code when it matters.

## Sanitization

- Remove tokens, passwords, private keys and `adminPass` values.
- Remove personal identifiers that the report does not need.
- Keep internal addresses and resource IDs, because the report cites them.
- Never commit `docker.env`, `clouds.yaml`, `session.env` or a private key.
